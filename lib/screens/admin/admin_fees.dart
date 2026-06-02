import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';

class AdminFees extends StatefulWidget {
  final VoidCallback? onBack;
  const AdminFees({super.key, this.onBack});

  @override
  State<AdminFees> createState() => _AdminFeesState();
}

class _AdminFeesState extends State<AdminFees> {
  int _filter = 0; // 0=Overview, 1=Paid, 2=Pending, 3=Overdue

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        children: [
          _Header(title: 'Fee Management', onBack: widget.onBack),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // ── Revenue overview ──────────────────────────
                GlassCard(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.adminEmerald.withValues(alpha: 0.15),
                      AppTheme.adminEmerald.withValues(alpha: 0.05),
                    ],
                  ),
                  borderColor: AppTheme.adminEmerald.withValues(alpha: 0.25),
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
                                'Total Revenue',
                                style: TextStyle(
                                  color: context.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₨4,20,000',
                                style: TextStyle(
                                  color: context.textPrimary,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  '↑ ',
                                  style: TextStyle(
                                    color: AppTheme.success,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '12.5%',
                                  style: TextStyle(
                                    color: AppTheme.success,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _FeeStatPill(
                            label: 'Collected',
                            value: '₨3.82L',
                            color: AppTheme.success,
                          ),
                          const SizedBox(width: 8),
                          _FeeStatPill(
                            label: 'Pending',
                            value: '₨28K',
                            color: AppTheme.warning,
                          ),
                          const SizedBox(width: 8),
                          _FeeStatPill(
                            label: 'Overdue',
                            value: '₨10K',
                            color: AppTheme.error,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── Filters ───────────────────────────────────
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        active: _filter == 0,
                        onTap: () => setState(() => _filter = 0),
                      ),
                      _FilterChip(
                        label: 'Paid',
                        active: _filter == 1,
                        onTap: () => setState(() => _filter = 1),
                      ),
                      _FilterChip(
                        label: 'Pending',
                        active: _filter == 2,
                        onTap: () => setState(() => _filter = 2),
                      ),
                      _FilterChip(
                        label: 'Overdue',
                        active: _filter == 3,
                        onTap: () => setState(() => _filter = 3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── Fee records ───────────────────────────────
                ..._getFiltered().map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _FeeCard(fee: f),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Invoice section ───────────────────────────
                GlassCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Invoices',
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._invoices.map((inv) => _InvoiceRow(inv: inv)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Payment reminders ─────────────────────────
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
                          const Text('🔔', style: TextStyle(fontSize: 18)),
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
                      _ReminderRow(
                        name: 'Ahmed Khan',
                        amount: '₨3,500',
                        daysOverdue: 15,
                      ),
                      _ReminderRow(
                        name: 'Sara Ali',
                        amount: '₨3,500',
                        daysOverdue: 8,
                      ),
                      _ReminderRow(
                        name: 'Ravi Sharma',
                        amount: '₨3,500',
                        daysOverdue: 3,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_FeeData> _getFiltered() {
    switch (_filter) {
      case 1:
        return _fees.where((f) => f.status == 'Paid').toList();
      case 2:
        return _fees.where((f) => f.status == 'Pending').toList();
      case 3:
        return _fees.where((f) => f.status == 'Overdue').toList();
      default:
        return _fees;
    }
  }
}

// ── Data ──────────────────────────────────────────────────────────────────

final _fees = [
  _FeeData(
    'Noorulain Shahid',
    'STU-1001',
    '₨3,500',
    'Paid',
    AppTheme.success,
    'Feb 2026',
  ),
  _FeeData(
    'Emma Watson',
    'STU-1002',
    '₨3,500',
    'Paid',
    AppTheme.success,
    'Feb 2026',
  ),
  _FeeData(
    'Ali Hassan',
    'STU-1003',
    '₨3,500',
    'Pending',
    AppTheme.warning,
    'Feb 2026',
  ),
  _FeeData(
    'Ahmed Khan',
    'STU-1004',
    '₨3,500',
    'Overdue',
    AppTheme.error,
    'Jan 2026',
  ),
  _FeeData(
    'Zara Fatima',
    'STU-1005',
    '₨3,500',
    'Paid',
    AppTheme.success,
    'Feb 2026',
  ),
  _FeeData(
    'Sara Ali',
    'STU-1006',
    '₨3,500',
    'Overdue',
    AppTheme.error,
    'Jan 2026',
  ),
];

final _invoices = [
  _Invoice('INV-2026-042', 'Noorulain Shahid', '₨3,500', 'Feb 15, 2026'),
  _Invoice('INV-2026-041', 'Emma Watson', '₨3,500', 'Feb 14, 2026'),
  _Invoice('INV-2026-040', 'Zara Fatima', '₨3,500', 'Feb 12, 2026'),
];

class _FeeData {
  final String name, id, amount, status, month;
  final Color statusColor;
  const _FeeData(
    this.name,
    this.id,
    this.amount,
    this.status,
    this.statusColor,
    this.month,
  );
}

class _Invoice {
  final String id, name, amount, date;
  const _Invoice(this.id, this.name, this.amount, this.date);
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? AppTheme.adminEmerald.withValues(alpha: 0.2)
                : context.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active
                  ? AppTheme.adminAccent.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? AppTheme.adminAccent : context.textSecondary,
              fontSize: 13,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _FeeCard extends StatelessWidget {
  final _FeeData fee;
  const _FeeCard({required this.fee});
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: fee.statusColor.withValues(alpha: 0.12),
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
                    Text(
                      fee.name,
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      fee.amount,
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
                      '${fee.id} · ${fee.month}',
                      style: TextStyle(
                        color: context.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    StatusBadge(label: fee.status, color: fee.statusColor),
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

class _InvoiceRow extends StatelessWidget {
  final _Invoice inv;
  const _InvoiceRow({required this.inv});
  @override
  Widget build(BuildContext context) {
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
            Text('📄', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    inv.id,
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${inv.name} · ${inv.date}',
                    style: TextStyle(color: context.textTertiary, fontSize: 11),
                  ),
                ],
              ),
            ),
            Text(
              inv.amount,
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.info.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '↓',
                style: TextStyle(color: AppTheme.info, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  final String name, amount;
  final int daysOverdue;
  const _ReminderRow({
    required this.name,
    required this.amount,
    required this.daysOverdue,
  });
  @override
  Widget build(BuildContext context) {
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
                    '$amount · $daysOverdue days overdue',
                    style: TextStyle(
                      color: AppTheme.error.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
          ],
        ),
      ),
    );
  }
}
