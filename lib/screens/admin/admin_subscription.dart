import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';

class AdminSubscription extends StatelessWidget {
  const AdminSubscription({super.key});

  @override
  Widget build(BuildContext context) {
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
                                    'Admin owns the app and collects subscription amounts from drivers, students, and parents.',
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
                              'Revenue Collection',
                              style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _PlanTile(
                              title: 'Owner Collection Plan',
                              subtitle:
                                  'All subscription income is routed to the admin account',
                              badge: 'Collecting',
                              badgeColor: AppTheme.success,
                              icon: Icons.workspace_premium_rounded,
                            ),
                            const SizedBox(height: 12),
                            const _FeatureRow(
                              title: 'Student subscription amount',
                              value: 'Rs 450 / month',
                              icon: Icons.school_rounded,
                              color: AppTheme.studentAmber,
                            ),
                            const _FeatureRow(
                              title: 'Driver subscription amount',
                              value: 'Rs 900 / month',
                              icon: Icons.drive_eta_rounded,
                              color: AppTheme.adminEmerald,
                            ),
                            const _FeatureRow(
                              title: 'Parent subscription amount',
                              value: 'Rs 300 / month',
                              icon: Icons.family_restroom_rounded,
                              color: AppTheme.parentPurple,
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
                              'Subscription Controls',
                              style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const _FeatureRow(
                              title: 'Auto cut amount',
                              value: 'Enabled',
                              icon: Icons.verified_user_rounded,
                              color: AppTheme.adminEmerald,
                            ),
                            const _FeatureRow(
                              title: 'Cancel student subscription',
                              value: 'Available',
                              icon: Icons.school_rounded,
                              color: AppTheme.info,
                            ),
                            const _FeatureRow(
                              title: 'Cancel driver subscription',
                              value: 'Available',
                              icon: Icons.drive_eta_rounded,
                              color: AppTheme.warning,
                            ),
                            const _FeatureRow(
                              title: 'Cancel parent subscription',
                              value: 'Available',
                              icon: Icons.family_restroom_rounded,
                              color: AppTheme.parentPurple,
                            ),
                            const _FeatureRow(
                              title: 'Payout to admin wallet',
                              value: 'Automatic',
                              icon: Icons.route_rounded,
                              color: AppTheme.info,
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
                              'Management Actions',
                              style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _ActionBtn(
                                    label: 'Auto Deduct',
                                    color: AppTheme.adminEmerald,
                                    onTap: () => _showMessage(
                                      context,
                                      'Auto deduction is enabled for all active subscriptions.',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _ActionBtn(
                                    label: 'Cancel Subscription',
                                    color: AppTheme.info,
                                    onTap: () => _showMessage(
                                      context,
                                      'Subscription cancellation flow will open here.',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _ActionBtn(
                                    label: 'View Collected Amount',
                                    color: AppTheme.warning,
                                    onTap: () => _showMessage(
                                      context,
                                      'Admin collection summary will be shown here.',
                                    ),
                                  ),
                                ),
                              ],
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
                              'Subscribers',
                              style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const _SubscriberRow(
                              name: 'Imran Khan',
                              role: 'Driver',
                              amount: 'Rs 900',
                              status: 'Active',
                              color: AppTheme.adminEmerald,
                            ),
                            const _SubscriberRow(
                              name: 'Ayesha Malik',
                              role: 'Student',
                              amount: 'Rs 450',
                              status: 'Auto cut',
                              color: AppTheme.studentAmber,
                            ),
                            const _SubscriberRow(
                              name: 'Bilal Ahmed',
                              role: 'Parent',
                              amount: 'Rs 300',
                              status: 'Pending',
                              color: AppTheme.parentPurple,
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

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PlanTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final IconData icon;

  const _PlanTile({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: badgeColor.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: badgeColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: context.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: badgeColor.withValues(alpha: 0.25)),
            ),
            child: Text(
              badge,
              style: TextStyle(
                color: badgeColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _FeatureRow({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriberRow extends StatelessWidget {
  final String name;
  final String role;
  final String amount;
  final String status;
  final Color color;

  const _SubscriberRow({
    required this.name,
    required this.role,
    required this.amount,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
              child: Icon(
                role == 'Driver'
                    ? Icons.drive_eta_rounded
                    : role == 'Student'
                    ? Icons.school_rounded
                    : Icons.family_restroom_rounded,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$role • $amount',
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.16),
              color.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
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
