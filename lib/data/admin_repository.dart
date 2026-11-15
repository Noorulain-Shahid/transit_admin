import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:transit_core/transit_core.dart';

/// Admin-only reads and writes on top of the shared [Db]/[MessagingRepository]
/// from `transit_core`. These queries (list every driver, list every user of a
/// role) have no mobile-app equivalent — a parent or driver never needs to see
/// everyone, only an admin does.
class AdminRepository {
  AdminRepository._();
  static final AdminRepository instance = AdminRepository._();

  String? get _adminUid => FirebaseAuth.instance.currentUser?.uid;

  // ── Why the list streams are not cached ────────────────────────────────
  //
  // `watchDrivers()`, `watchStudents()` and `watchUsersByRole()` used to hand
  // every caller one memoized `.asBroadcastStream()`. A broadcast stream does
  // not replay its last event to a late subscriber: the first screen to
  // listen (the Dashboard, at app start) received the snapshot, and every
  // screen that subscribed afterwards — Parent Detail's "Children" section,
  // Student/Parent Management opened from the nav bar — waited for a *next*
  // change that might never come. That was the spinner that never stopped.
  //
  // Each call now returns its own `snapshots()` stream. The Firestore SDK
  // already shares one watch target per identical query and answers a new
  // listener from its local cache straight away, so this costs no extra
  // reads — and every subscriber gets the current data the moment it
  // listens, which is the contract a `StreamBuilder` expects.

  // ── Drivers ───────────────────────────────────────────────────────────────

  Stream<List<Driver>> watchDrivers({DriverStatus? status}) {
    final query = status == null
        ? Db.drivers
        : Db.drivers.where('status', isEqualTo: status.name);
    // `!isDeleted` is applied client-side (consistent with every other
    // filter in this repository) rather than as a `.where()` clause, so an
    // admin-soft-deleted driver vanishes from every list immediately
    // without needing a new composite index for the common case of also
    // filtering by `status`.
    return query.snapshots().docsList.map(
      (drivers) => drivers.where((d) => !d.isDeleted).toList(),
    );
  }

  Stream<Driver?> watchDriver(String driverId) =>
      Db.drivers.doc(driverId).snapshots().map((s) => s.data());

  Future<void> updateDriverStatus(String driverId, DriverStatus status) => Db
      .drivers
      .doc(driverId)
      .update({'status': status.name, 'updatedAt': Db.now});

  /// Archives the driver (see `Driver.isDeleted`'s doc comment — this never
  /// physically deletes the document or the matching Firebase Auth
  /// account; only a server-side Cloud Function with Admin SDK access can
  /// do that and free the email for reuse). Also clears every student's
  /// assignment to this driver, so no roster is left silently pointing at
  /// an archived account.
  ///
  /// A driver exists as *two* documents sharing one uid — `drivers/{uid}`
  /// (this repository's own domain) and `users/{uid}` (`role: driver`,
  /// read by `transit_pro`'s sign-in gate) — both must be marked deleted or
  /// the driver could still sign in and use the mobile app even though the
  /// admin app shows them as removed.
  Future<void> deleteDriver(String driverId) async {
    final batch = Db.fs.batch();
    batch.update(Db.drivers.doc(driverId), {
      'isDeleted': true,
      'deletedAt': Db.now,
      'updatedAt': Db.now,
    });
    batch.update(Db.fs.collection('users').doc(driverId), {
      'isDeleted': true,
      'deletedAt': Db.now,
      'updatedAt': Db.now,
    });
    await batch.commit();
    await reassignStudentsOffDriver(driverId);
  }

  /// Clears `driverId`/`routeId`/`scheduleId`/`busId` on every student
  /// currently assigned to [driverId] — used when a driver is archived (or
  /// could be reused if a driver is simply removed from a route) so no
  /// student roster is left pointing at a driver who no longer operates.
  /// A single `WriteBatch` (first one in this repository): all affected
  /// students for one driver commit atomically, and realistically never
  /// approach Firestore's 500-write batch limit for a single driver's
  /// roster.
  Future<void> reassignStudentsOffDriver(String driverId) async {
    final snap = await Db.students
        .where('driverId', isEqualTo: driverId)
        .get();
    if (snap.docs.isEmpty) return;
    final batch = Db.fs.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {
        'driverId': FieldValue.delete(),
        'routeId': FieldValue.delete(),
        'scheduleId': FieldValue.delete(),
        'busId': FieldValue.delete(),
        'updatedAt': Db.now,
      });
    }
    await batch.commit();
  }

  Stream<List<DriverDocument>> watchDriverDocuments(String driverId) =>
      Db.documents.where('driverId', isEqualTo: driverId).snapshots().docsList;

  Future<void> updateDriverDocument(
    String documentId, {
    required DocumentStatus status,
    String? rejectionReason,
  }) => Db.documents.doc(documentId).update({
    'status': status.name,
    'verifiedBy': _adminUid,
    'verifiedAt': Db.now,
    'rejectionReason': rejectionReason,
  });

  // ── Users (parents & students share the `users` role field) ─────────────────

  /// Every account of [role]. Archived and self-deleted accounts
  /// (`isDeleted`) are dropped unless [includeDeleted] — the Parent
  /// Management list keeps them, labelled "Deactivated", because an account
  /// that silently vanished looked exactly like one that never existed.
  Stream<List<AppUser>> watchUsersByRole(
    UserRole role, {
    bool includeDeleted = false,
  }) => Db.users
      .where('role', isEqualTo: role.name)
      .snapshots()
      .docsList
      .map(
        (users) => includeDeleted
            ? users
            : users.where((u) => !u.isDeleted).toList(),
      );

  Stream<AppUser?> watchUser(String uid) =>
      Db.users.doc(uid).snapshots().map((s) => s.data());

  /// [watchUser] plus the raw `deletedBy` field (not part of `AppUser`),
  /// which tells a self-deleted account (its own uid) from an admin archive.
  Stream<({AppUser user, String deletedBy})?> watchUserRecord(String uid) {
    if (uid.isEmpty) return Stream.value(null);
    return Db.fs.collection('users').doc(uid).snapshots().map((s) {
      final data = s.data();
      if (!s.exists || data == null) return null;
      return (
        user: AppUser.fromMap(s.id, data),
        deletedBy: asString(data['deletedBy']),
      );
    });
  }

  /// Archives a parent account (see `AppUser.isDeleted`'s doc comment).
  /// Their students are dependent profiles, not independent accounts, so
  /// they're archived alongside the parent rather than left behind as
  /// orphaned-but-still-active records.
  Future<void> deleteParent(String uid) async {
    await Db.fs.collection('users').doc(uid).update({
      'isDeleted': true,
      'deletedAt': Db.now,
      'updatedAt': Db.now,
    });
    final snap = await Db.students.where('parentId', isEqualTo: uid).get();
    if (snap.docs.isEmpty) return;
    final batch = Db.fs.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {
        'isDeleted': true,
        'deletedAt': Db.now,
        'updatedAt': Db.now,
      });
    }
    await batch.commit();
  }

  /// Newest accounts across every role — used for the admin notifications
  /// feed's "New Account Activity" section.
  Stream<List<AppUser>> watchRecentUsers({int limit = 5}) => Db.users
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .docsList;

  Future<void> updateUser(String uid, Map<String, dynamic> fields) => Db.fs
      .collection('users')
      .doc(uid)
      .update({...fields, 'updatedAt': Db.now});

  // ── Students ──────────────────────────────────────────────────────────────

  Stream<List<Student>> watchStudents() => Db.students
      .snapshots()
      .docsList
      .map((students) => students.where((s) => !s.isDeleted).toList());

  /// One parent's children, queried directly (`parentId == uid`, the same
  /// query the mobile app's own children list runs) rather than filtered
  /// out of the whole `students` collection. Archived children are kept so
  /// a deactivated family still shows who was on the account; the screen
  /// labels them.
  Stream<List<Student>> watchStudentsOfParent(String parentId) => Db.students
      .where('parentId', isEqualTo: parentId)
      .snapshots()
      .docsList;

  /// A driver's roster: `students where driverId == uid`, which is how the
  /// driver app defines it (see `Student.driverId`).
  Stream<List<Student>> watchStudentsOfDriver(String driverId) => Db.students
      .where('driverId', isEqualTo: driverId)
      .snapshots()
      .docsList
      .map((students) => students.where((s) => !s.isDeleted).toList());

  Stream<Student?> watchStudent(String studentId) =>
      Db.students.doc(studentId).snapshots().map((s) => s.data());

  Future<void> updateStudent(String studentId, Map<String, dynamic> fields) =>
      Db.fs.collection('students').doc(studentId).update({
        ...fields,
        'updatedAt': Db.now,
      });

  /// Archives the student (see `Student.isDeleted`'s doc comment) — used
  /// when a single dependent profile is removed without touching the
  /// parent's own account (removing the parent instead cascades via
  /// [deleteParent]).
  Future<void> deleteStudent(String studentId) =>
      Db.fs.collection('students').doc(studentId).update({
        'isDeleted': true,
        'deletedAt': Db.now,
        'updatedAt': Db.now,
      });

  // ── Fleet: buses & routes ─────────────────────────────────────────────────

  Stream<List<Bus>> watchBuses() => Db.buses.snapshots().docsList;

  /// One vehicle, for a screen that holds a `busId` and needs the number a
  /// person would recognise it by.
  Stream<Bus?> watchBus(String busId) =>
      Db.buses.doc(busId).snapshots().map((s) => s.data());

  Future<void> updateBus(String busId, Map<String, dynamic> fields) =>
      Db.buses.doc(busId).update({...fields, 'updatedAt': Db.now});

  Stream<List<BusRoute>> watchRoutes() => Db.routes.snapshots().docsList;

  Stream<BusRoute?> watchRoute(String routeId) =>
      Db.routes.doc(routeId).snapshots().map((s) => s.data());

  Future<void> updateRoute(String routeId, Map<String, dynamic> fields) =>
      Db.routes.doc(routeId).update({...fields, 'updatedAt': Db.now});

  /// Creates a new route document. `route.id` is ignored — a fresh
  /// Firestore-generated id is always used, matching how every other
  /// create-style write in this repo lets Firestore assign the id rather
  /// than the client choosing one. Caller is expected to set `createdAt`
  /// on [route] itself (`BusRoute`'s `copyWith` has no `createdAt`
  /// parameter — it's treated as set-once at construction, not an update
  /// via `Db.now`'s server-timestamp sentinel, which only fits a raw map
  /// write, not this typed model).
  Future<void> createRoute(BusRoute route) => Db.routes.doc().set(route);

  // ── Aggregation counts ────────────────────────────────────────────────────
  //
  // These use Firestore's `.count()` server-side aggregation (one small
  // billed read regardless of collection size) instead of fetching every
  // document just to call `.length` on the result — for a badge/stat number
  // that doesn't also need the underlying documents for anything else on
  // screen. None of these can express `!isDeleted` server-side without a
  // composite index per role/status combination, so they intentionally
  // accept being a hair stale on deleted-but-not-yet-reindexed edge cases in
  // exchange for a single aggregation read; screens that need an exact
  // post-deletion number keep using the client-filtered `watchX()` streams
  // above instead.
  Future<int> countStudents() async =>
      (await Db.students.count().get()).count ?? 0;

  Future<int> countDrivers() async =>
      (await Db.drivers.count().get()).count ?? 0;

  Future<int> countParents() async => (await Db.users
          .where('role', isEqualTo: UserRole.parent.name)
          .count()
          .get())
      .count ??
      0;

  Future<int> countBuses() async => (await Db.buses.count().get()).count ?? 0;

  Future<int> countRoutes() async =>
      (await Db.routes.count().get()).count ?? 0;

  // ── Payments ──────────────────────────────────────────────────────────────

  /// Every payment on file — used by the Fees screen, which filters/searches
  /// client-side rather than by a single month.
  Stream<List<Payment>> watchAllPayments() => Db.payments.snapshots().docsList;

  /// Payments due/paid in [monthKey] (`YYYY-MM`) — used to derive MRR and
  /// payment success/failure rates. Pass [Payment.monthKeyFor(DateTime.now())]
  /// for the current month.
  Stream<List<Payment>> watchPaymentsForMonth(String monthKey) =>
      Db.payments.where('monthKey', isEqualTo: monthKey).snapshots().docsList;

  /// One-time (not live) sum of `paid` payments for each of [monthKeys], in
  /// paisa — used for the dashboard's revenue trend chart. A `Future`, not a
  /// `Stream`: past months' totals don't change on their own, so there's no
  /// need to keep a listener open on them the way the current month's live
  /// figures do.
  Future<Map<String, int>> fetchRevenueByMonth(List<String> monthKeys) async {
    final result = <String, int>{};
    for (final key in monthKeys) {
      final snap = await Db.payments.where('monthKey', isEqualTo: key).get();
      result[key] = snap.docs
          .map((d) => d.data())
          .where((p) => p.status == PaymentStatus.paid)
          .fold<int>(0, (total, p) => total + p.amountPaisa);
    }
    return result;
  }

  // ── Trips ─────────────────────────────────────────────────────────────────

  /// Today's trips (any status) — used to derive the "Active Trips" count
  /// (`status == inProgress`) on the dashboard.
  Stream<List<Trip>> watchTripsToday() {
    final today = Trip.dateKeyFor(DateTime.now());
    return Db.trips.where('dateKey', isEqualTo: today).snapshots().docsList;
  }

  /// One-time fetch of every trip on [date] — used for the dashboard's
  /// multi-day trend charts (Daily Trips, Attendance Rate). A `Future`,
  /// not a `Stream`, for the same reason as [fetchRevenueByMonth]: a past
  /// day's trips are done, they don't need a live listener.
  Future<List<Trip>> fetchTripsOn(DateTime date) async {
    final dateKey = Trip.dateKeyFor(date);
    final snap = await Db.trips.where('dateKey', isEqualTo: dateKey).get();
    return snap.docs.map((d) => d.data()).toList();
  }

  /// The driver's running trip, if any — the same query the driver app
  /// uses for its Start/End button (`TripRepository.watchActiveTripForDriver`),
  /// equality filters only, so no composite index.
  Stream<Trip?> watchActiveTripForDriver(String driverId) => Db.trips
      .where('driverId', isEqualTo: driverId)
      .where('status', isEqualTo: TripStatus.inProgress.name)
      .snapshots()
      .map((s) {
        final trips = s.docs.map((d) => d.data()).toList()
          ..sort(
            (a, b) => (b.startedAt ?? DateTime(0)).compareTo(
              a.startedAt ?? DateTime(0),
            ),
          );
        return trips.isEmpty ? null : trips.first;
      });

  /// A driver's trips, newest first (`driverId` + `dateKey desc` — the
  /// indexed shape the driver app's own history uses).
  Stream<List<Trip>> watchTripsForDriver(String driverId, {int limit = 60}) =>
      Db.trips
          .where('driverId', isEqualTo: driverId)
          .orderBy('dateKey', descending: true)
          .limit(limit)
          .snapshots()
          .docsList;

  /// Every attendance mark on one trip, live.
  Stream<List<AttendanceRecord>> watchTripAttendance(String tripId) =>
      Db.attendance(tripId).snapshots().docsList;

  /// One student's attendance across every trip, newest first.
  ///
  /// The exact collection-group shape the mobile app's ride history runs
  /// (`studentId ==` + `dateKey desc`), so it rides on the index that
  /// already exists. `students/{id}/attendance/{dateKey}` (a family's own
  /// advance absence notes) shares the subcollection name, so rows are kept
  /// only when they really live under `trips/`.
  Future<List<AttendanceRecord>> fetchStudentAttendance(
    String studentId, {
    int limit = 60,
  }) async {
    if (studentId.isEmpty) return const [];
    final snap = await Db.fs
        .collectionGroup('attendance')
        .where('studentId', isEqualTo: studentId)
        .orderBy('dateKey', descending: true)
        .limit(limit)
        .get();
    final rows = <AttendanceRecord>[];
    for (final doc in snap.docs) {
      final trip = doc.reference.parent.parent;
      if (trip == null || trip.parent.id != 'trips') continue;
      final record = AttendanceRecord.fromMap(doc.id, doc.data());
      rows.add(
        record.tripId.isNotEmpty
            ? record
            : AttendanceRecord(
                studentId: record.studentId,
                studentName: record.studentName,
                status: record.status,
                stopId: record.stopId,
                markedAt: record.markedAt,
                markedBy: record.markedBy,
                tripId: trip.id,
                dateKey: record.dateKey,
                driverId: record.driverId,
              ),
      );
    }
    return rows;
  }

  /// [fetchStudentAttendance] for several students (a parent's children),
  /// merged newest first. One query per child keeps every query on the
  /// existing index.
  Future<List<AttendanceRecord>> fetchAttendanceForStudents(
    Iterable<String> studentIds, {
    int limitEach = 40,
  }) async {
    final ids = studentIds.where((id) => id.isNotEmpty).toSet();
    final lists = await Future.wait(
      ids.map((id) => fetchStudentAttendance(id, limit: limitEach)),
    );
    final all = [for (final l in lists) ...l]
      ..sort((a, b) => b.dateKey.compareTo(a.dateKey));
    return all;
  }

  /// The trip documents behind [tripIds], keyed by id — for turning a list
  /// of attendance rows into a trip history (type, times, driver).
  Future<Map<String, Trip>> fetchTripsByIds(Iterable<String> tripIds) async {
    final ids = tripIds.where((id) => id.isNotEmpty).toSet().toList();
    final result = <String, Trip>{};
    for (var i = 0; i < ids.length; i += 30) {
      final chunk = ids.sublist(i, i + 30 > ids.length ? ids.length : i + 30);
      final snap = await Db.trips
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final d in snap.docs) {
        result[d.id] = d.data();
      }
    }
    return result;
  }

  // ── Missed-bus requests ──────────────────────────────────────────────────

  /// Every missed-bus request raised for [studentIds], newest first.
  /// Single-field `whereIn` (chunks of 30) — no composite index; ordering
  /// is done here.
  Future<List<MissedBusRequest>> fetchMissedBusForStudents(
    Iterable<String> studentIds,
  ) async {
    final ids = studentIds.where((id) => id.isNotEmpty).toSet().toList();
    final byId = <String, MissedBusRequest>{};
    for (var i = 0; i < ids.length; i += 30) {
      final chunk = ids.sublist(i, i + 30 > ids.length ? ids.length : i + 30);
      final snap = await Db.missedBusRequests
          .where('studentId', whereIn: chunk)
          .get();
      for (final d in snap.docs) {
        byId[d.id] = d.data();
      }
    }
    final list = byId.values.toList()
      ..sort(
        (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
          a.createdAt ?? DateTime(0),
        ),
      );
    return list;
  }

  /// Missed-bus pickups a driver accepted (`assignedDriverId`), newest
  /// first, ordered here rather than by a composite index.
  Stream<List<MissedBusRequest>> watchMissedBusForDriver(String driverId) =>
      Db.missedBusRequests
          .where('assignedDriverId', isEqualTo: driverId)
          .snapshots()
          .docsList
          .map(
            (list) => list
              ..sort(
                (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
                  a.createdAt ?? DateTime(0),
                ),
              ),
          );

  // ── Access history ───────────────────────────────────────────────────────

  /// `users/{uid}/accessLog`, newest first — written by the mobile app on
  /// every sign-in and sign-out. Single-field ordering, no composite index.
  Stream<List<AccessLogEntry>> watchAccessLog(String uid, {int limit = 50}) {
    if (uid.isEmpty) return Stream.value(const []);
    return Db.fs
        .collection('users')
        .doc(uid)
        .collection('accessLog')
        .orderBy('at', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => AccessLogEntry.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  // ── Safety, money and ratings per driver ─────────────────────────────────

  /// SOS and safety incidents raised by / about [driverId], newest first.
  Stream<List<Incident>> watchIncidentsForDriver(String driverId) => Db
      .incidents
      .where('driverId', isEqualTo: driverId)
      .snapshots()
      .docsList
      .map(
        (list) => list
          ..sort(
            (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
              a.createdAt ?? DateTime(0),
            ),
          ),
      );

  /// Every payment addressed to [driverId] (any status) — the Earnings tab
  /// keeps only `paid` ones; single-field filter, no composite index.
  Stream<List<Payment>> watchPaymentsForDriver(String driverId) =>
      Db.payments.where('driverId', isEqualTo: driverId).snapshots().docsList;

  /// Seat requests addressed to [driverId] — the fee a family agreed is
  /// read from here when the student document predates `monthlyFeePaisa`.
  Stream<List<RideRequest>> watchRideRequestsForDriver(String driverId) => Db
      .rideRequests
      .where('driverId', isEqualTo: driverId)
      .snapshots()
      .docsList;

  /// One driver's ratings. `Driver.rating`/`ratingCount` are never kept
  /// current, so the figure is always computed from these
  /// (`DriverRatingSummary.of`).
  Stream<List<DriverRating>> watchRatingsForDriver(String driverId) => Db
      .ratings
      .where('driverId', isEqualTo: driverId)
      .snapshots()
      .docsList;

  /// Every driver rating, for the driver list's per-driver summaries.
  Stream<List<DriverRating>> watchAllRatings() =>
      Db.ratings.snapshots().docsList;

  // ── App feedback ──────────────────────────────────────────────────────────

  /// Newest "Rate the App" submissions — used for the admin notifications
  /// feed's "Recent Feedback" section, the same live-Firestore pattern as
  /// [watchRecentUsers]/[watchDrivers] rather than a separate stored
  /// notification record: the feedback documents themselves are the source
  /// of truth, and there's nothing a notification doc would carry that this
  /// stream doesn't already have.
  Stream<List<AppFeedback>> watchRecentFeedback({int limit = 10}) => Db
      .appFeedback
      .orderBy('timestamp', descending: true)
      .limit(limit)
      .snapshots()
      .docsList;

  /// Every "Rate the App" submission, newest first — the full Feedback
  /// screen and the dashboard's average.
  Stream<List<AppFeedback>> watchAllFeedback({int limit = 500}) => Db
      .appFeedback
      .orderBy('timestamp', descending: true)
      .limit(limit)
      .snapshots()
      .docsList;

  // Feedback written before `userName`/`userRole` existed carries only
  // `userId`, so showing who wrote it means a lookup against `users/{uid}`.
  // Cached in memory and keyed by uid: a list rebuild would otherwise
  // re-read the same account for every row, for a name that never changes
  // mid-session. The in-flight future is cached, not just the result, so a
  // list of twenty rows by one person costs one read, not twenty.
  final Map<String, Future<AppUser?>> _userCache = {};

  /// The account behind [uid], or null if it no longer exists.
  Future<AppUser?> fetchUserCached(String uid) {
    if (uid.isEmpty) return Future.value(null);
    return _userCache.putIfAbsent(uid, () async {
      try {
        return (await Db.users.doc(uid).get()).data();
      } catch (_) {
        // Don't pin a transient failure in the cache forever.
        _userCache.remove(uid);
        return null;
      }
    });
  }

  /// Resolves a feedback submitter's display name, or `null` if the account
  /// no longer exists (e.g. hard-deleted before soft delete existed) — the
  /// caller decides the "Anonymous User" fallback text, this just reports
  /// what's actually in Firestore.
  Future<String?> fetchUserName(String uid) async {
    final name = (await fetchUserCached(uid))?.name;
    return (name == null || name.isEmpty) ? null : name;
  }

  // ── Live Chat support inbox ──────────────────────────────────────────────

  /// Every "Live Chat" support thread, most recently active first — the
  /// query "which users currently need help" resolves to. Support threads
  /// have `[realUserUid, kSupportParticipantId]` as `participants`, not a
  /// specific admin's uid (see `kSupportParticipantId`'s doc comment in
  /// `transit_core`), so this filters on that fixed sentinel instead of
  /// [watchDrivers]/[watchRecentUsers]'s pattern of filtering on this
  /// admin's own uid — any admin reading this stream sees every open
  /// support thread, not just ones addressed to them personally, since
  /// there is no "addressed to them personally". Messages within a thread
  /// (`MessagingRepository.watchMessages`/`.sendMessage`) work unchanged —
  /// this is only the missing piece: finding which threads exist at all.
  Stream<List<ChatThread>> watchSupportThreads() => Db.chats
      .where('participants', arrayContains: kSupportParticipantId)
      .orderBy('updatedAt', descending: true)
      .snapshots()
      .docsList;

  // ── Messaging ─────────────────────────────────────────────────────────────

  /// Sends an in-app notification to a driver/parent/student about an issue
  /// admin found (a rejected document, an account problem, etc.). Lands in
  /// that user's existing notification inbox in the mobile app immediately.
  Future<void> messageUser(
    String uid, {
    required String title,
    required String body,
  }) => MessagingRepository.instance.push(
    uid,
    UserNotification(
      id: '',
      type: NotificationType.adminMessage,
      title: title,
      body: body,
      read: false,
      createdAt: DateTime.now(),
    ),
  );
}

/// One row of `users/{uid}/accessLog` — a sign-in or sign-out, written by
/// the mobile app's presence service.
class AccessLogEntry {
  final String id;

  /// `signIn` / `signOut`.
  final String event;

  /// `android`, `iOS`, … as the device reported it.
  final String platform;
  final DateTime? at;

  const AccessLogEntry({
    required this.id,
    required this.event,
    this.platform = '',
    this.at,
  });

  bool get isSignIn => event == 'signIn';

  /// "Signed in" / "Signed out", or the raw event for anything newer.
  String get label => switch (event) {
    'signIn' => 'Signed in',
    'signOut' => 'Signed out',
    _ => event.isEmpty ? 'Activity' : event,
  };

  factory AccessLogEntry.fromMap(String id, Map<String, dynamic> m) =>
      AccessLogEntry(
        id: id,
        event: asString(m['event']),
        platform: asString(m['platform']),
        at: asDateOrNull(m['at']),
      );
}
