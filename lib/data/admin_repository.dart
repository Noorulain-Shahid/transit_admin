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

  // ── Drivers ───────────────────────────────────────────────────────────────

  Stream<List<Driver>> watchDrivers({DriverStatus? status}) {
    final query = status == null
        ? Db.drivers
        : Db.drivers.where('status', isEqualTo: status.name);
    return query.snapshots().docsList;
  }

  Stream<Driver?> watchDriver(String driverId) =>
      Db.drivers.doc(driverId).snapshots().map((s) => s.data());

  Future<void> updateDriverStatus(String driverId, DriverStatus status) => Db
      .drivers
      .doc(driverId)
      .update({'status': status.name, 'updatedAt': Db.now});

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
      Db.users.where('role', isEqualTo: role.name).snapshots().docsList;

  Stream<AppUser?> watchUser(String uid) =>
      Db.users.doc(uid).snapshots().map((s) => s.data());

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

  Stream<List<Student>> watchStudents() => Db.students.snapshots().docsList;

  Stream<Student?> watchStudent(String studentId) =>
      Db.students.doc(studentId).snapshots().map((s) => s.data());

  Future<void> updateStudent(String studentId, Map<String, dynamic> fields) =>
      Db.fs.collection('students').doc(studentId).update({
        ...fields,
        'updatedAt': Db.now,
      });

  // ── Fleet: buses & routes ─────────────────────────────────────────────────

  Stream<List<Bus>> watchBuses() => Db.buses.snapshots().docsList;

  Future<void> updateBus(String busId, Map<String, dynamic> fields) =>
      Db.buses.doc(busId).update({...fields, 'updatedAt': Db.now});

  Stream<List<BusRoute>> watchRoutes() => Db.routes.snapshots().docsList;

  Future<void> updateRoute(String routeId, Map<String, dynamic> fields) =>
      Db.routes.doc(routeId).update({...fields, 'updatedAt': Db.now});

  // ── Payments ──────────────────────────────────────────────────────────────

  /// Every payment on file — used by the Fees screen, which filters/searches
  /// client-side rather than by a single month.
  Stream<List<Payment>> watchAllPayments() => Db.payments.snapshots().docsList;

  /// Payments due/paid in [monthKey] (`YYYY-MM`) — used to derive MRR and
  /// payment success/failure rates. Pass [Payment.monthKeyFor(DateTime.now())]
  /// for the current month.
  Stream<List<Payment>> watchPaymentsForMonth(String monthKey) => Db.payments
      .where('monthKey', isEqualTo: monthKey)
      .snapshots()
      .docsList;

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
          .fold<int>(0, (sum, p) => sum + p.amountPaisa);
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
