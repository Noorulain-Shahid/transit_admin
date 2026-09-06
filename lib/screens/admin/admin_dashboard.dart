import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transit_core/transit_core.dart';
import '../../app/auth_service.dart';
import '../../data/admin_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/mini_chart.dart';
import 'admin_user_models.dart' hide DriverStatus, SubscriptionStatus;

class AdminDashboard extends StatefulWidget {
  final void Function(int) onNavigate;
  const AdminDashboard({super.key, required this.onNavigate});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _repo = AdminRepository.instance;

  List<Student>? _students;
  List<AppUser>? _parents;
  List<Driver>? _drivers;
  List<Trip>? _tripsToday;
  List<Payment>? _paymentsThisMonth;

  /// Set the moment any dashboard stream errors (e.g. a Firestore
  /// permission or parsing failure) — surfaced in the UI instead of being
  /// silently swallowed or, worse, crashing as an unhandled async error.
  String? _loadError;

  StreamSubscription<List<Student>>? _studentsSub;
  StreamSubscription<List<AppUser>>? _parentsSub;
  StreamSubscription<List<Driver>>? _driversSub;
  StreamSubscription<List<Trip>>? _tripsSub;
  StreamSubscription<List<Payment>>? _paymentsSub;

  // Historical trends (6-day/6-month) — one-time fetches, not live streams;
  // past days/months don't change, so there's nothing to keep listening to.
  Map<String, int>? _dailyTripCounts; // dateKey -> completed trips that day
  Map<String, double>? _dailyAttendanceRates; // dateKey -> % boarded
  Map<String, int>? _monthlyRevenuePaisa; // monthKey -> paid total

  bool _handlingPermissionDenied = false;

  void _onStreamError(String source, Object error) {
    debugPrint('[AdminDashboard] $source stream error: $error');
    if (error is FirebaseException && error.code == 'permission-denied') {
      _handlePermissionDenied();
      return;
    }
    if (mounted) setState(() => _loadError = '$source: $error');
  }

  /// A `permission-denied` here means Firestore itself no longer considers
  /// this session an admin — most likely `role: admin` was never set (or was
  /// removed) on this account's `users/{uid}` document after it signed in.
  /// The old session stays "signed in" to Firebase Auth regardless (that
  /// only requires a valid password, not the Firestore role), so every
  /// screen just keeps hammering denied queries forever unless something
  /// actively signs it out — this is that something.
  void _handlePermissionDenied() {
    if (_handlingPermissionDenied) return;
    _handlingPermissionDenied = true;
    AuthService.instance.signOut().whenComplete(() {
      if (mounted) {
        context.go('/login');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Your account isn't recognized as an admin — signed out. "
              "Check that role: admin is set on this account's Firestore user document.",
            ),
            duration: Duration(seconds: 6),
          ),
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _studentsSub = _repo.watchStudents().listen(
      (v) => setState(() => _students = v),
      onError: (e) => _onStreamError('Students', e),
    );
    _parentsSub = _repo.watchUsersByRole(UserRole.parent).listen(
      (v) => setState(() => _parents = v),
      onError: (e) => _onStreamError('Parents', e),
    );
    _driversSub = _repo.watchDrivers().listen(
      (v) => setState(() => _drivers = v),
      onError: (e) => _onStreamError('Drivers', e),
    );
    _tripsSub = _repo.watchTripsToday().listen(
      (v) => setState(() => _tripsToday = v),
      onError: (e) => _onStreamError('Trips', e),
    );
    _paymentsSub = _repo
        .watchPaymentsForMonth(Payment.monthKeyFor(DateTime.now()))
        .listen(
          (v) => setState(() => _paymentsThisMonth = v),
          onError: (e) => _onStreamError('Payments', e),
        );
    _loadHistoricalStats();
  }

  Future<void> _loadHistoricalStats() async {
    try {
      final now = DateTime.now();
      final days = List.generate(6, (i) => now.subtract(Duration(days: 5 - i)));

      final tripCounts = <String, int>{};
      final attendanceRates = <String, double>{};
      for (final day in days) {
        final trips = await _repo.fetchTripsOn(day);
        final key = Trip.dateKeyFor(day);
        tripCounts[key] = trips
            .where((t) => t.status == TripStatus.completed)
            .length;
        final expected = trips.fold<int>(0, (s, t) => s + t.studentsExpected);
        final boarded = trips.fold<int>(0, (s, t) => s + t.studentsBoarded);
        attendanceRates[key] = expected == 0 ? 0 : (boarded / expected * 100);
      }

      final months = List.generate(
        6,
        (i) => Payment.monthKeyFor(DateTime(now.year, now.month - (5 - i))),
      );
      final revenue = await _repo.fetchRevenueByMonth(months);

      if (mounted) {
        setState(() {
          _dailyTripCounts = tripCounts;
          _dailyAttendanceRates = attendanceRates;
          _monthlyRevenuePaisa = revenue;
        });
      }
    } catch (e) {
      _onStreamError('Historical stats', e);
    }
  }

  @override
  void dispose() {
    _studentsSub?.cancel();
    _parentsSub?.cancel();
    _driversSub?.cancel();
    _tripsSub?.cancel();
    _paymentsSub?.cancel();
    super.dispose();
  }

  void Function(int) get onNavigate => widget.onNavigate;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        children: [
          _buildHeader(context),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                if (_loadError != null) ...[
                  _buildLoadErrorBanner(context),
                  const SizedBox(height: 14),
                ],
                _buildOverviewCards(context),
                const SizedBox(height: 14),
                _buildSubscriptionAnalytics(context),
                const SizedBox(height: 14),
                _buildAlerts(context),
                const SizedBox(height: 14),
                _buildAnalytics(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.adminEmerald.withValues(alpha: 0.2),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TransitPro Admin',
                  style: TextStyle(color: context.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'Command Center',
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'System Online • Real-time',
                      style: TextStyle(
                        color: AppTheme.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/admin/notifications'),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: context.cardBgElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.inputBorder),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.notifications_rounded,
                      color: context.textPrimary,
                      size: 22,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppTheme.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: context.cardBg, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadErrorBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Some dashboard data failed to load: $_loadError',
              style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ── Overview Cards ──────────────────────────────────────────────────────────
  Widget _buildOverviewCards(BuildContext context) {
    final studentCount = _students?.length;
    final parentCount = _parents?.length;
    final driverCount = _drivers?.length;
    final activeTrips = _tripsToday
        ?.where((t) => t.status == TripStatus.inProgress)
        .length;
    final online = _drivers?.where((d) => d.status == DriverStatus.online).length;
    final pending = _drivers
        ?.where((d) => d.status == DriverStatus.pendingVerification)
        .length;

    final activeSubs = _students
        ?.where((s) => s.subscriptionStatus == SubscriptionStatus.active)
        .length;
    final expiredSubs = _students
        ?.where((s) => s.subscriptionStatus == SubscriptionStatus.expired)
        .length;
    final mrrPaisa = _paymentsThisMonth
        ?.where((p) => p.status == PaymentStatus.paid)
        .fold<int>(0, (total, p) => total + p.amountPaisa);

    return Column(
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          padding: EdgeInsets.zero,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.95,
          children: [
            _StatCard(
              icon: Icons.school_rounded,
              label: 'Students',
              value: _fmtCount(studentCount),
              color: AppTheme.studentAmber,
            ),
            _StatCard(
              icon: Icons.family_restroom_rounded,
              label: 'Parents',
              value: _fmtCount(parentCount),
              color: AppTheme.parentPurple,
            ),
            _StatCard(
              icon: Icons.directions_bus_rounded,
              label: 'Drivers',
              value: _fmtCount(driverCount),
              color: AppTheme.driverCyan,
            ),
            _StatCard(
              icon: Icons.navigation_rounded,
              label: 'Active Trips',
              value: _fmtCount(activeTrips),
              color: AppTheme.adminEmerald,
            ),
            _StatCard(
              icon: Icons.wifi_tethering_rounded,
              label: 'Online',
              value: _fmtCount(online),
              color: AppTheme.success,
            ),
            _StatCard(
              icon: Icons.pending_actions_rounded,
              label: 'Pending',
              value: _fmtCount(pending),
              color: AppTheme.warning,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _WideStatCard(
                icon: Icons.check_circle_rounded,
                label: 'Active Subs',
                value: _fmtCount(activeSubs),
                sub: 'of ${_fmtCount(studentCount)} students',
                color: AppTheme.success,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _WideStatCard(
                icon: Icons.cancel_rounded,
                label: 'Expired',
                value: _fmtCount(expiredSubs),
                sub: 'this billing cycle',
                color: AppTheme.error,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _WideStatCard(
                icon: Icons.attach_money_rounded,
                label: 'Revenue (MTD)',
                value: mrrPaisa == null ? '…' : _fmtPaisa(mrrPaisa),
                sub: 'this month, collected',
                color: AppTheme.info,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String _fmtCount(int? n) => n == null ? '…' : '$n';

  static String _fmtPaisa(int paisa) {
    final rupees = (paisa / 100).round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < rupees.length; i++) {
      if (i > 0 && (rupees.length - i) % 3 == 0) buf.write(',');
      buf.write(rupees[i]);
    }
    return '₨$buf';
  }

  // ── Subscription Analytics ─────────────────────────────────────────────────
  Widget _buildSubscriptionAnalytics(BuildContext context) {
    final total = _students?.length ?? 0;
    final active = _students
            ?.where((s) => s.subscriptionStatus == SubscriptionStatus.active)
            .length ??
        0;
    final expired = _students
            ?.where((s) => s.subscriptionStatus == SubscriptionStatus.expired)
            .length ??
        0;
    final trial = _students
            ?.where((s) => s.subscriptionStatus == SubscriptionStatus.trial)
            .length ??
        0;
    // A zero total (no data yet, or genuinely no students) would divide by
    // zero in the progress bars below — show an empty bar instead.
    final barTotal = total == 0 ? 1 : total;

    final paid = _paymentsThisMonth
        ?.where((p) => p.status == PaymentStatus.paid)
        .length;
    final overdue = _paymentsThisMonth
        ?.where((p) => p.status == PaymentStatus.overdue)
        .length;
    final paymentTotal = _paymentsThisMonth?.length;
    final successPct = (paymentTotal == null || paymentTotal == 0 || paid == null)
        ? null
        : (paid / paymentTotal * 100).round();
    final failurePct = (paymentTotal == null || paymentTotal == 0 || overdue == null)
        ? null
        : (overdue / paymentTotal * 100).round();

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subscription Analytics',
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          // Progress bars
          _SubAnalyticBar(
            label: 'Active',
            count: active,
            total: barTotal,
            color: AppTheme.success,
          ),
          const SizedBox(height: 8),
          _SubAnalyticBar(
            label: 'Expired',
            count: expired,
            total: barTotal,
            color: AppTheme.error,
          ),
          const SizedBox(height: 8),
          _SubAnalyticBar(
            label: 'Trial',
            count: trial,
            total: barTotal,
            color: AppTheme.info,
          ),
          const SizedBox(height: 16),
          Text(
            'Monthly Revenue',
            style: TextStyle(color: context.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          if (_monthlyRevenuePaisa == null)
            const SizedBox(
              height: 70,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            MiniBarChart(
              values: _monthlyRevenuePaisa!.values
                  .map((paisa) => paisa / 100)
                  .toList(),
              labels: _monthlyRevenuePaisa!.keys
                  .map((k) => k.split('-').last)
                  .toList(),
              barColor: AppTheme.purple,
              barActiveColor: AppTheme.parentPurple,
              height: 70,
              barWidth: 18,
            ),
          const SizedBox(height: 16),
          // Rates
          Row(
            children: [
              Expanded(
                child: _RateCard(
                  label: 'Payment\nSuccess',
                  pct: successPct,
                  color: AppTheme.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RateCard(
                  label: 'Payment\nFailure',
                  pct: failurePct,
                  color: AppTheme.error,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RateCard(
                  label: 'Renewal\nRate',
                  pct: null,
                  color: AppTheme.info,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Alerts Panel ────────────────────────────────────────────────────────────
  /// Real alerts derived from data this screen already streams — overdue
  /// payments and lapsed subscriptions. Deliberately doesn't include SOS,
  /// missed-bus, or late-driver alerts: those need a cross-collection
  /// aggregator over `incidents`/`missedBusRequests` that doesn't exist yet
  /// (see README §11) — showing nothing for them beats fabricating them.
  List<AlertItem> _computeAlerts() {
    final studentNames = {for (final s in _students ?? const []) s.id: s.name};
    final alerts = <AlertItem>[];

    for (final p in _paymentsThisMonth ?? const <Payment>[]) {
      if (p.status != PaymentStatus.overdue) continue;
      final name = studentNames[p.studentId] ?? 'Student';
      alerts.add(
        AlertItem(
          id: p.id,
          type: AlertType.paymentFailure,
          title: 'Payment Overdue',
          message: '$name — ${p.displayAmount} for ${p.monthKey}',
          severity: AlertSeverity.warning,
          timestamp: p.monthKey,
        ),
      );
    }

    for (final s in _students ?? const <Student>[]) {
      final isLapsed = s.subscriptionStatus == SubscriptionStatus.expired ||
          s.subscriptionStatus == SubscriptionStatus.gracePeriod;
      if (!isLapsed) continue;
      alerts.add(
        AlertItem(
          id: s.id,
          type: AlertType.subscriptionExpiry,
          title: s.subscriptionStatus == SubscriptionStatus.expired
              ? 'Subscription Expired'
              : 'Subscription in Grace Period',
          message: '${s.name} — transport subscription needs renewal',
          severity: AlertSeverity.warning,
          timestamp: '',
        ),
      );
    }

    return alerts;
  }

  Widget _buildAlerts(BuildContext context) {
    final alerts = _computeAlerts();

    return GlassCard(
      padding: const EdgeInsets.all(18),
      gradient: LinearGradient(
        colors: [AppTheme.error.withValues(alpha: 0.06), Colors.transparent],
      ),
      borderColor: AppTheme.error.withValues(alpha: 0.12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppTheme.error,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Alerts',
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              StatusBadge(
                label: alerts.isEmpty ? 'All clear' : '${alerts.length} Active',
                color: alerts.isEmpty ? AppTheme.success : AppTheme.error,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (alerts.isEmpty)
            Text(
              'No overdue payments or lapsed subscriptions right now.',
              style: TextStyle(color: context.textSecondary, fontSize: 12),
            )
          else
            ...alerts.map((a) => _AlertRow(alert: a)),
        ],
      ),
    );
  }

  // ── Analytics ───────────────────────────────────────────────────────────────
  /// Vehicle Efficiency and Sub(scriber) Growth were dropped entirely rather
  /// than kept as placeholders — neither has any real backing data (no
  /// scheduled-vs-actual trip comparison, no historical subscriber-count
  /// snapshots exist anywhere in the schema), and there's no `Db` query that
  /// could ever fill them in without inventing a new collection.
  Widget _buildAnalytics(BuildContext context) {
    final dailyTrips = _dailyTripCounts;
    final attendanceRates = _dailyAttendanceRates;

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analytics',
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          if (dailyTrips == null || attendanceRates == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Trips',
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${dailyTrips.values.last} completed',
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      MiniLineChart(
                        values: dailyTrips.values
                            .map((v) => v.toDouble())
                            .toList(),
                        lineColor: AppTheme.adminEmerald,
                        height: 40,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attendance Rate',
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${attendanceRates.values.last.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      MiniLineChart(
                        values: attendanceRates.values.toList(),
                        lineColor: AppTheme.info,
                        height: 40,
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Widgets
// ═════════════════════════════════════════════════════════════════════════════
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(10),
      gradient: LinearGradient(
        colors: [color.withValues(alpha: 0.12), color.withValues(alpha: 0.04)],
      ),
      borderColor: color.withValues(alpha: 0.18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: context.textSecondary, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _WideStatCard extends StatelessWidget {
  final IconData icon;
  final String label, value, sub;
  final Color color;
  const _WideStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      gradient: LinearGradient(
        colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.03)],
      ),
      borderColor: color.withValues(alpha: 0.15),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: context.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubAnalyticBar extends StatelessWidget {
  final String label;
  final int count, total;
  final Color color;
  const _SubAnalyticBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 55,
          child: Text(
            label,
            style: TextStyle(color: context.textSecondary, fontSize: 12),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: count / total,
              backgroundColor: context.cardBgElevated,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _RateCard extends StatelessWidget {
  final String label;
  /// `null` renders as "—" — either still loading, or (for Renewal Rate)
  /// genuinely unavailable: no renewal/cancellation history exists in the
  /// schema yet.
  final int? pct;
  final Color color;
  const _RateCard({
    required this.label,
    required this.pct,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    final ringColor = pct == null ? context.textTertiary : color;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ringColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ringColor.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          RingIndicator(
            percentage: (pct ?? 0).toDouble(),
            color: ringColor,
            size: 44,
            strokeWidth: 4,
            center: Text(
              pct == null ? '—' : '$pct%',
              style: TextStyle(
                color: ringColor,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(color: context.textSecondary, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  final AlertItem alert;
  const _AlertRow({required this.alert});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: alert.severityColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: alert.severityColor.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: alert.severityColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(alert.typeIcon, color: alert.severityColor, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.title,
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    alert.message,
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              alert.timestamp,
              style: TextStyle(color: context.textTertiary, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Mock Alerts ────────────────────────────────────────────────────────────
