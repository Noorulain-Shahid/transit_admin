import 'dart:async';
import 'package:flutter/material.dart';
import 'package:transit_core/transit_core.dart';
import '../../data/admin_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';

class AdminFees extends StatefulWidget {
  final VoidCallback? onBack;
  const AdminFees({super.key, this.onBack});

  @override
  State<AdminFees> createState() => _AdminFeesState();
}

class _AdminFeesState extends State<AdminFees> {
  final _repo = AdminRepository.instance;
  int _filter = 0; // 0=All, 1=Paid, 2=Pending, 3=Overdue

  List<Payment>? _payments;
  List<Student>? _students;

  StreamSubscription<List<Payment>>? _paymentsSub;
  StreamSubscription<List<Student>>? _studentsSub;

  @override
  void initState() {
    super.initState();
    _paymentsSub = _repo.watchAllPayments().listen(
      (v) => setState(() => _payments = v),
      onError: (e) => debugPrint('[AdminFees] payments stream error: $e'),
    );
    _studentsSub = _repo.watchStudents().listen(
      (v) => setState(() => _students = v),
      onError: (e) => debugPrint('[AdminFees] students stream error: $e'),
    );
  }

  @override
  void dispose() {
    _paymentsSub?.cancel();
    _studentsSub?.cancel();
    super.dispose();
  }

  String _studentName(String studentId) {
    final match = (_students ?? const <Student>[]).where(
      (s) => s.id == studentId,
    );
    return match.isEmpty ? 'Unknown student' : match.first.name;
  }

  List<Payment> _getFiltered() {
    final all = _payments ?? const <Payment>[];
    switch (_filter) {
      case 1:
        return all.where((p) => p.status == PaymentStatus.paid).toList();
      case 2:
        return all.where((p) => p.status == PaymentStatus.pending).toList();
      case 3:
        return all.where((p) => p.status == PaymentStatus.overdue).toList();
      default:
        return all;
    }
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

  Future<void> _sendReminder(Payment p) async {
    await _repo.messageUser(
      p.parentId,
      title: 'Payment reminder',
      body:
          'Your ${p.monthKey} transport fee (${p.displayAmount}) is overdue. Please arrange payment soon.',
    );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reminder sent')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final payments = _payments;
    final loading = payments == null;

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
    final overduePayments = loading
        ? const <Payment>[]
        : payments.where((p) => p.status == PaymentStatus.overdue).toList();

    return Scaffold(
      body: Container(
        decoration: context.scaffoldBg,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              children: [
                _Header(title: 'Fee Management', onBack: widget.onBack),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // ── Revenue overview (neumorphic) ─────────
                      _NeumorphicCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Collected',
                                      style: TextStyle(
                                        color: context.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      loading ? '…' : _fmtPaisa(collected),
                                      style: TextStyle(
                                        color: context.textPrimary,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _FeeStatPill(
                                  label: 'Collected',
                                  value: loading ? '…' : _fmtPaisa(collected),
                                  color: AppTheme.success,
                                ),
                                const SizedBox(width: 8),
                                _FeeStatPill(
                                  label: 'Pending',
                                  value: loading ? '…' : _fmtPaisa(pending),
                                  color: AppTheme.warning,
                                ),
                                const SizedBox(width: 8),
                                _FeeStatPill(
                                  label: 'Overdue',
                                  value: loading ? '…' : _fmtPaisa(overdue),
                                  color: AppTheme.error,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Filters (segmented control) ───────────
                      _FilterSegmentedControl(
                        labels: const ['All', 'Paid', 'Pending', 'Overdue'],
                        selected: _filter,
                        onChanged: (i) => setState(() => _filter = i),
                      ),
                      const SizedBox(height: 14),

                      // ── Payment records ───────────────────────
                      if (loading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_getFiltered().isEmpty)
                        const _EmptyState(
                          message: 'No payments found in this category.',
                        )
                      else
                        ..._getFiltered().map(
                          (p) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _FeeCard(
                              payment: p,
                              studentName: _studentName(p.studentId),
                            ),
                          ),
                        ),

                      const SizedBox(height: 12),

                      // ── Payment reminders ─────────────────────
                      if (overduePayments.isNotEmpty)
                        GlassCard(
                          padding: const EdgeInsets.all(18),
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.warning.withValues(alpha: 0.1),
                              Colors.transparent,
                            ],
                          ),
                          borderColor: AppTheme.warning.withValues(alpha: 0.2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    '🔔',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Payment Reminders',
                                    style: TextStyle(
                                      color: context.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...overduePayments.take(5).map(
                                (p) => _ReminderRow(
                                  name: _studentName(p.studentId),
                                  amount: p.displayAmount,
                                  dueDate: p.dueDate,
                                  onSend: () => _sendReminder(p),
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

// ── Widgets ──────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  const _Header({required this.title, this.onBack});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          if (onBack != null)
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
            title,
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

class _FeeStatPill extends StatelessWidget {
  final String label, value;
  final Color color;
  const _FeeStatPill({
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
                fontSize: 15,
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

/// Soft, elevated card (two opposing shadows) used for the summary card —
/// deliberately distinct from this screen's `GlassCard` sections, since the
/// task asked specifically for a neumorphic treatment here.
class _NeumorphicCard extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final Widget child;
  const _NeumorphicCard({required this.padding, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.45)
                : const Color(0xFFB8BEC8).withValues(alpha: 0.6),
            offset: const Offset(6, 6),
            blurRadius: 14,
          ),
          BoxShadow(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.white.withValues(alpha: 0.9),
            offset: const Offset(-6, -6),
            blurRadius: 14,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Sleek segmented control replacing the old horizontally-scrolling chip
/// row — all four filters fit on screen at once, and the active segment
/// gets an elevated pill so it reads as "one control", not four buttons.
class _FilterSegmentedControl extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  const _FilterSegmentedControl({
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.inputBorder),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final active = i == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: active
                      ? AppTheme.adminEmerald.withValues(alpha: 0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: active
                      ? Border.all(
                          color: AppTheme.adminAccent.withValues(alpha: 0.5),
                        )
                      : null,
                ),
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: active
                        ? AppTheme.adminAccent
                        : context.textSecondary,
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Professional empty state — a subtle icon over properly sized, muted
/// text, replacing the old single unstyled `Text` line. Uses the theme's
/// own muted color token rather than a fixed `Colors.grey`, so it still
/// reads correctly in dark mode.
class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: context.textTertiary,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.textTertiary, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

Color _statusColor(PaymentStatus status) {
  switch (status) {
    case PaymentStatus.paid:
      return AppTheme.success;
    case PaymentStatus.pending:
      return AppTheme.warning;
    case PaymentStatus.overdue:
      return AppTheme.error;
    case PaymentStatus.refunded:
      return AppTheme.info;
  }
}

String _statusLabel(PaymentStatus status) {
  final name = status.name;
  return name[0].toUpperCase() + name.substring(1);
}

class _FeeCard extends StatelessWidget {
  final Payment payment;
  final String studentName;
  const _FeeCard({required this.payment, required this.studentName});
  @override
  Widget build(BuildContext context) {
    final color = _statusColor(payment.status);
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text('💰', style: TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        studentName,
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      payment.displayAmount,
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      payment.monthKey,
                      style: TextStyle(
                        color: context.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    StatusBadge(
                      label: _statusLabel(payment.status),
                      color: color,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  final String name, amount;
  final DateTime? dueDate;
  final VoidCallback onSend;
  const _ReminderRow({
    required this.name,
    required this.amount,
    required this.dueDate,
    required this.onSend,
  });
  @override
  Widget build(BuildContext context) {
    final overdueDays = dueDate == null
        ? null
        : DateTime.now().difference(dueDate!).inDays;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    overdueDays == null
                        ? '$amount overdue'
                        : '$amount · $overdueDays days overdue',
                    style: TextStyle(
                      color: AppTheme.error.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onSend,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: const Text(
                  'Send Reminder',
                  style: TextStyle(
                    color: AppTheme.warning,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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
