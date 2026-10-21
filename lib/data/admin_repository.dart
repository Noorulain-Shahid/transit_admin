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

  // ── Shared broadcast-stream cache ───────────────────────────────────────
  //
  // `watchDrivers()` (no status filter), `watchStudents()`, and
  // `watchUsersByRole(UserRole.parent)` are each independently called by
  // several screens (Dashboard, Profile's old badge counts, Vehicles,
  // Driver/Student/Parent Management, Parent/Driver Detail…) that have no
  // reason to each open their own Firestore listener on the exact same
  // query. Memoizing the stream here — and making it a broadcast stream so
  // more than one `StreamBuilder`/`StreamSubscription` can attach to it —
  // means every caller shares one underlying listener instead of one each.
  Stream<List<Driver>>? _allDriversCache;
  Stream<List<Student>>? _studentsCache;
  final Map<UserRole, Stream<List<AppUser>>> _usersByRoleCache = {};

  // ── Drivers ───────────────────────────────────────────────────────────────

  Stream<List<Driver>> watchDrivers({DriverStatus? status}) {
    if (status == null) {
      return _allDriversCache ??= _watchDriversUncached(null);
    }
    // Status-filtered variants are used by far fewer call sites and each
    // wants a different status, so they aren't worth caching individually —
    // only the common no-filter case is.
    return _watchDriversUncached(status);
  }

  Stream<List<Driver>> _watchDriversUncached(DriverStatus? status) {
    final query = status == null
        ? Db.drivers
        : Db.drivers.where('status', isEqualTo: status.name);
    // `!isDeleted` is applied client-side (consistent with every other
    // filter in this repository) rather than as a `.where()` clause, so an
    // admin-soft-deleted driver vanishes from every list immediately
    // without needing a new composite index for the common case of also
    // filtering by `status`.
    return query.snapshots().docsList
        .map((drivers) => drivers.where((d) => !d.isDeleted).toList())
        .asBroadcastStream();
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

  Stream<List<AppUser>> watchUsersByRole(UserRole role) =>
      _usersByRoleCache[role] ??= Db.users
          .where('role', isEqualTo: role.name)
          .snapshots()
          .docsList
          .map((users) => users.where((u) => !u.isDeleted).toList())
          .asBroadcastStream();

  Stream<AppUser?> watchUser(String uid) =>
      Db.users.doc(uid).snapshots().map((s) => s.data());

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

  Stream<List<Student>> watchStudents() =>
      _studentsCache ??= Db.students
          .snapshots()
          .docsList
          .map((students) => students.where((s) => !s.isDeleted).toList())
          .asBroadcastStream();

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

  Future<void> updateBus(String busId, Map<String, dynamic> fields) =>
      Db.buses.doc(busId).update({...fields, 'updatedAt': Db.now});

  Stream<List<BusRoute>> watchRoutes() => Db.routes.snapshots().docsList;

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

  // `AppFeedback` only stores `userId` (see its doc comment — there's no
  // denormalized name field on the feedback document itself), so showing a
  // submitter's name on the Notifications screen means a lookup against
  // `users/{uid}`. Cached in memory and keyed by uid: the "Recent Feedback"
  // list re-fetches every name on each rebuild otherwise, and the same admin
  // or driver showing up across several feedback entries would mean a
  // repeated read for a name that never changes mid-session.
  final Map<String, String?> _userNameCache = {};

  /// Resolves a feedback submitter's display name, or `null` if the account
  /// no longer exists (e.g. hard-deleted before soft delete existed) — the
  /// caller decides the "Anonymous User" fallback text, this just reports
  /// what's actually in Firestore.
  Future<String?> fetchUserName(String uid) async {
    if (_userNameCache.containsKey(uid)) return _userNameCache[uid];
    final user = await Db.users.doc(uid).get();
    final name = user.data()?.name;
    final resolved = (name == null || name.isEmpty) ? null : name;
    _userNameCache[uid] = resolved;
    return resolved;
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
