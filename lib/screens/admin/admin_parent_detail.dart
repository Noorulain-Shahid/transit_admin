import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import 'admin_user_models.dart';

class AdminParentDetail extends StatelessWidget {
  final ParentRecord parent;
  const AdminParentDetail({super.key, required this.parent});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: context.scaffoldBg,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _buildProfileCard(context),
                        const SizedBox(height: 12),
                        _buildChildrenSection(context),
                        const SizedBox(height: 12),
                        _buildSubscriptionPanel(context),
                        const SizedBox(height: 12),
                        _buildPaymentSystem(context),
                        const SizedBox(height: 12),
                        _buildPlanInfo(context),
                        const SizedBox(height: 12),
                        _buildEnforcement(context),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: context.cardBgElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.inputBorder),
              ),
              child: Center(
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: context.textPrimary,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Billing Control',
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.parentPurple.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppTheme.parentPurple.withValues(alpha: 0.25),
              ),
            ),
            child: const Center(
              child: Text('👨‍👩‍👧', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parent.name,
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${parent.childrenCount} children • ${parent.contact}',
                  style: TextStyle(color: context.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    StatusBadge(
                      label: parent.planLabel,
                      color: parent.planColor,
                    ),
                    const SizedBox(width: 6),
                    StatusBadge(
                      label: parent.statusLabel,
                      color: parent.statusColor,
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

  Widget _buildChildrenSection(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.child_care_rounded,
                color: AppTheme.parentPurple,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Children Details',
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (parent.children.isEmpty)
            Text(
              'No linked children data available.',
              style: TextStyle(color: context.textSecondary, fontSize: 12),
            )
          else
            ...parent.children.map(
              (child) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.parentPurple.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.parentPurple.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.parentPurple.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          child.level == 'College'
                              ? Icons.school_rounded
                              : Icons.menu_book_rounded,
                          color: AppTheme.parentPurple,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              child.name,
                              style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${child.level} • ${child.institution}',
                              style: TextStyle(
                                color: context.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${child.classOrSemester} • ${child.route}',
                              style: TextStyle(
                                color: context.textTertiary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(
                        label: child.status,
                        color: child.status == 'Expired'
                            ? AppTheme.error
                            : AppTheme.success,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionPanel(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.credit_card_rounded,
                color: AppTheme.parentPurple,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Subscription Management',
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Info rows
          _DetailRow(
            label: 'Current Plan',
            value: parent.planLabel,
            color: parent.planColor,
          ),
          _DetailRow(
            label: 'Status',
            value: parent.statusLabel,
            color: parent.statusColor,
          ),
          _DetailRow(
            label: 'Next Billing',
            value: parent.nextBillingDate,
            color: AppTheme.info,
          ),
          _DetailRow(
            label: 'Amount Due',
            value: '₨${parent.amountDue.toInt()}',
            color: AppTheme.warning,
          ),
          _DetailRow(
            label: 'Days Overdue',
            value: '${parent.overdueDays} days',
            color: AppTheme.error,
          ),
          const SizedBox(height: 12),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: _ActionBtn(
                  label: 'Activate',
                  color: AppTheme.success,
                  icon: Icons.play_arrow_rounded,
                  onTap: () => _msg(context, 'Subscription activated'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionBtn(
                  label: 'Pause',
                  color: AppTheme.warning,
                  icon: Icons.pause_rounded,
                  onTap: () => _msg(context, 'Subscription paused'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionBtn(
                  label: 'Cancel',
                  color: AppTheme.error,
                  icon: Icons.stop_rounded,
                  onTap: () => _msg(context, 'Subscription cancelled'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSystem(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payment_rounded, color: AppTheme.info, size: 20),
              const SizedBox(width: 8),
              Text(
                'Payment History',
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _PaymentRow(
            date: 'May 15, 2026',
            amount: '₨${parent.amountDue.toInt()}',
            status: 'Paid',
            color: AppTheme.success,
          ),
          _PaymentRow(
            date: 'Apr 15, 2026',
            amount: '₨${parent.amountDue.toInt()}',
            status: 'Paid',
            color: AppTheme.success,
          ),
          _PaymentRow(
            date: 'Mar 15, 2026',
            amount: '₨${parent.amountDue.toInt()}',
            status: 'Failed',
            color: AppTheme.error,
          ),
          _PaymentRow(
            date: 'Feb 15, 2026',
            amount: '₨${parent.amountDue.toInt()}',
            status: 'Refunded',
            color: AppTheme.warning,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionBtn(
                  label: 'Generate Invoice',
                  color: AppTheme.info,
                  icon: Icons.receipt_long_rounded,
                  onTap: () => _msg(context, 'Invoice generated'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionBtn(
                  label: 'Retry Payment',
                  color: AppTheme.adminEmerald,
                  icon: Icons.refresh_rounded,
                  onTap: () => _msg(context, 'Retrying last failed payment'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _ActionBtn(
            label: 'Refund Management',
            color: AppTheme.warning,
            icon: Icons.undo_rounded,
            onTap: () => _msg(context, 'Refund management panel'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanInfo(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Plan Details',
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _PlanDetail(
            plan: 'Basic',
            price: '₨300/mo',
            features: [
              '1 child tracking',
              'Standard notifications',
              'Basic support',
            ],
            color: const Color(0xFF94A3B8),
            isActive: parent.plan == ParentPlan.basic,
          ),
          const SizedBox(height: 8),
          _PlanDetail(
            plan: 'Standard',
            price: '₨700/mo',
            features: [
              '2-3 children tracking',
              'Priority notifications',
              'Email support',
            ],
            color: AppTheme.info,
            isActive: parent.plan == ParentPlan.standard,
          ),
          const SizedBox(height: 8),
          _PlanDetail(
            plan: 'Premium',
            price: '₨1200/mo',
            features: [
              'Unlimited children',
              'Priority tracking',
              'Priority support',
              'Real-time alerts',
            ],
            color: AppTheme.purple,
            isActive: parent.plan == ParentPlan.premium,
          ),
        ],
      ),
    );
  }

  Widget _buildEnforcement(BuildContext context) {
    final isExpired = parent.status == SubscriptionStatus.expired;
    return GlassCard(
      padding: const EdgeInsets.all(18),
      gradient: LinearGradient(
        colors: [
          (isExpired ? AppTheme.error : AppTheme.success).withValues(
            alpha: 0.06,
          ),
          (isExpired ? AppTheme.error : AppTheme.success).withValues(
            alpha: 0.02,
          ),
        ],
      ),
      borderColor: (isExpired ? AppTheme.error : AppTheme.success).withValues(
        alpha: 0.15,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isExpired ? Icons.warning_rounded : Icons.verified_rounded,
                color: isExpired ? AppTheme.error : AppTheme.success,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Subscription Enforcement',
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _EnforcementRow(
            icon: Icons.block_rounded,
            label: isExpired
                ? 'Student access: BLOCKED'
                : 'Student access: ACTIVE',
            color: isExpired ? AppTheme.error : AppTheme.success,
          ),
          _EnforcementRow(
            icon: Icons.timer_rounded,
            label: isExpired
                ? 'Grace period: ENDED'
                : 'Grace period: 7 days after expiry',
            color: isExpired ? AppTheme.error : AppTheme.info,
          ),
          _EnforcementRow(
            icon: Icons.notifications_active_rounded,
            label: isExpired
                ? 'Warning sent: 3 days before expiry'
                : 'Warning: Will notify 3 days before expiry',
            color: AppTheme.warning,
          ),
        ],
      ),
    );
  }

  void _msg(BuildContext context, String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final String label, value;
  final Color color;
  const _DetailRow({
    required this.label,
    required this.value,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: context.textSecondary, fontSize: 12),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.14),
              color.withValues(alpha: 0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final String date, amount, status;
  final Color color;
  const _PaymentRow({
    required this.date,
    required this.amount,
    required this.status,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Text(
              date,
              style: TextStyle(color: context.textSecondary, fontSize: 11),
            ),
            const Spacer(),
            Text(
              amount,
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 10),
            StatusBadge(label: status, color: color),
          ],
        ),
      ),
    );
  }
}

class _PlanDetail extends StatelessWidget {
  final String plan, price;
  final List<String> features;
  final Color color;
  final bool isActive;
  const _PlanDetail({
    required this.plan,
    required this.price,
    required this.features,
    required this.color,
    required this.isActive,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isActive ? 0.1 : 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: isActive ? 0.3 : 0.1),
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                plan,
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                price,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (isActive) StatusBadge(label: 'Current', color: color),
            ],
          ),
          const SizedBox(height: 8),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: color, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    f,
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 12,
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
}

class _EnforcementRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _EnforcementRow({
    required this.icon,
    required this.label,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
