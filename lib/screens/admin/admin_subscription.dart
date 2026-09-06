import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transit_core/transit_core.dart';
import '../../data/admin_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';

/// Manages each student's real `subscriptionStatus` and shows real collected/
/// pending/overdue totals from `payments`. The screen used to model a flat
/// per-role "admin collects a subscription fee from drivers/students/parents"
/// business — that concept has no backing field anywhere in `transit_core`'s
/// schema (fees are per-student, paid by a parent, not a platform fee on
/// every account type), so it was replaced rather than wired to fake data.
class AdminSubscription extends StatefulWidget {
  const AdminSubscription({super.key});

  @override
  State<AdminSubscription> createState() => _AdminSubscriptionState();
}

class _AdminSubscriptionState extends State<AdminSubscription> {
  final _repo = AdminRepository.instance;
  List<Student>? _students;
  List<Payment>? _payments;

  StreamSubscription<List<Student>>? _studentsSub;
  StreamSubscription<List<Payment>>? _paymentsSub;

  @override
  void initState() {
    super.initState();
    _studentsSub = _repo.watchStudents().listen(
      (v) => setState(() => _students = v),
      onError: (e) => debugPrint('[AdminSubscription] students error: $e'),
    );
    _paymentsSub = _repo.watchAllPayments().listen(
      (v) => setState(() => _payments = v),
      onError: (e) => debugPrint('[AdminSubscription] payments error: $e'),
    );
  }

  @override
  void dispose() {
    _studentsSub?.cancel();
    _paymentsSub?.cancel();
    super.dispose();
  }

  static String _fmtPaisa(int paisa) {
    final rupees = (paisa / 100).round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < rupees.length; i++) {
      if (i > 0 && (rupees.length - i) % 3 == 0) buf.write(',');
      buf.write(rupees[i]);
    }
    return '₨$buf';
  }

  Color _statusColor(SubscriptionStatus s) {
    switch (s) {
      case SubscriptionStatus.active:
        return AppTheme.success;
      case SubscriptionStatus.trial:
        return AppTheme.info;
      case SubscriptionStatus.gracePeriod:
        return AppTheme.warning;
      case SubscriptionStatus.expired:
      case SubscriptionStatus.suspended:
      case SubscriptionStatus.cancelled:
        return AppTheme.error;
    }
  }

  String _statusLabel(SubscriptionStatus s) {
    switch (s) {
      case SubscriptionStatus.gracePeriod:
        return 'Grace Period';
      default:
        final name = s.name;
        return name[0].toUpperCase() + name.substring(1);
    }
  }

  Future<void> _toggleSubscription(Student s) async {
    final cancelling = s.subscriptionStatus != SubscriptionStatus.cancelled;
    await _repo.updateStudent(s.id, {
      'subscriptionStatus': cancelling
          ? SubscriptionStatus.cancelled.name
          : SubscriptionStatus.active.name,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            cancelling
                ? '${s.name}\'s subscription cancelled'
                : '${s.name}\'s subscription reactivated',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final students = _students;
    final payments = _payments;
    final loading = students == null || payments == null;

    final collected = loading
        ? 0
        : payments
              .where((p) => p.status == PaymentStatus.paid)
              .fold<int>(0, (s, p) => s + p.amountPaisa);
    final pending = loading
        ? 0
        : payments
              .where((p) => p.status == PaymentStatus.pending)
              .fold<int>(0, (s, p) => s + p.amountPaisa);
    final overdue = loading
        ? 0
        : payments
              .where((p) => p.status == PaymentStatus.overdue)
              .fold<int>(0, (s, p) => s + p.amountPaisa);

    return Scaffold(
      body: Container(
        decoration: context.scaffoldBg,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              children: [
                _Header(onBack: () => context.pop()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      GlassCard(
                        padding: const EdgeInsets.all(18),
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.purple.withValues(alpha: 0.14),
                            AppTheme.info.withValues(alpha: 0.08),
                          ],
                        ),
                        borderColor: AppTheme.purple.withValues(alpha: 0.2),
                        child: Row(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                gradient: AppTheme.mainGradient,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.subscriptions_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Subscription Management',
                                    style: TextStyle(
                                      color: context.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Each student's transport subscription status, and what's been collected in fees.",
                                    style: TextStyle(
                                      color: context.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      GlassCard(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fee Collection',
                              style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _StatPill(
                                  label: 'Collected',
                                  value: loading ? '…' : _fmtPaisa(collected),
                                  color: AppTheme.success,
                                ),
                                const SizedBox(width: 8),
                                _StatPill(
                                  label: 'Pending',
                                  value: loading ? '…' : _fmtPaisa(pending),
                                  color: AppTheme.warning,
                                ),
                                const SizedBox(width: 8),
                                _StatPill(
                                  label: 'Overdue',
                                  value: loading ? '…' : _fmtPaisa(overdue),
                                  color: AppTheme.error,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () => context.push('/admin/fees'),
                              child: Row(
                                children: [
                                  Text(
                                    'View full fee breakdown',
                                    style: TextStyle(
                                      color: AppTheme.adminAccent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: AppTheme.adminAccent,
                                    size: 14,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      GlassCard(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Students',
                              style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (loading)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else if (students.isEmpty)
                              Text(
                                'No students registered yet.',
                                style: TextStyle(
                                  color: context.textSecondary,
                                ),
                              )
                            else
                              ...students.map(
                                (s) => _SubscriberRow(
                                  student: s,
                                  color: _statusColor(s.subscriptionStatus),
                                  statusLabel: _statusLabel(
                                    s.subscriptionStatus,
                                  ),
                                  onToggle: () => _toggleSubscription(s),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: context.textTertiary, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriberRow extends StatelessWidget {
  final Student student;
  final Color color;
  final String statusLabel;
  final VoidCallback onToggle;

  const _SubscriberRow({
    required this.student,
    required this.color,
    required this.statusLabel,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isCancelled =
        student.subscriptionStatus == SubscriptionStatus.cancelled;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.14)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.school_rounded, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    statusLabel,
                    style: TextStyle(color: color, fontSize: 12),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onToggle,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Text(
                  isCancelled ? 'Reactivate' : 'Cancel',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: context.cardBgElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.inputBorder),
              ),
              child: Center(
                child: Text(
                  '←',
                  style: TextStyle(color: context.textPrimary, fontSize: 18),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            'Subscription',
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
