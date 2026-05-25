import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';

class AdminNotifications extends StatelessWidget {
  const AdminNotifications({super.key});

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
                            AppTheme.adminEmerald.withValues(alpha: 0.14),
                            AppTheme.info.withValues(alpha: 0.08),
                          ],
                        ),
                        borderColor: AppTheme.adminEmerald.withValues(
                          alpha: 0.18,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                gradient: AppTheme.adminGradient,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.notifications_active_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Admin Notifications',
                                    style: TextStyle(
                                      color: context.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'New driver, student, and parent accounts appear here for review.',
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
                      _SectionCard(
                        title: 'New Account Activity',
                        subtitle:
                            'Recent account creations from drivers, students, and parents.',
                        children: const [
                          _NotificationItem(
                            title: 'Driver account created',
                            subtitle:
                                'Imran Khan submitted a new driver profile.',
                            time: '2 min ago',
                            icon: Icons.drive_eta_rounded,
                            color: AppTheme.info,
                          ),
                          _NotificationItem(
                            title: 'Driver account created',
                            subtitle:
                                'Sajid Ali added his driving profile and contact details.',
                            time: '8 min ago',
                            icon: Icons.drive_eta_rounded,
                            color: AppTheme.adminEmerald,
                          ),
                          _NotificationItem(
                            title: 'Driver account created',
                            subtitle:
                                'Hassan Raza submitted a new transport driver account.',
                            time: '19 min ago',
                            icon: Icons.drive_eta_rounded,
                            color: AppTheme.purple,
                          ),
                          _NotificationItem(
                            title: 'Student account created',
                            subtitle:
                                'Ayesha Malik registered a student account.',
                            time: '12 min ago',
                            icon: Icons.school_rounded,
                            color: AppTheme.studentAmber,
                          ),
                          _NotificationItem(
                            title: 'Parent account created',
                            subtitle:
                                'Bilal Ahmed registered as a parent user.',
                            time: '28 min ago',
                            icon: Icons.family_restroom_rounded,
                            color: AppTheme.parentPurple,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _SectionCard(
                        title: 'Driver Verification Queue',
                        subtitle:
                            'Review uploaded documents before allowing the driver to start driving in the app.',
                        children: const [
                          _NotificationItem(
                            title: 'Driver documents uploaded',
                            subtitle:
                                'License, CNIC, and vehicle papers are ready for review.',
                            time: 'Pending review',
                            icon: Icons.description_rounded,
                            color: AppTheme.adminEmerald,
                            actionLabel: 'Review',
                          ),
                          _NotificationItem(
                            title: 'New driver waiting for approval',
                            subtitle:
                                'Usman Tariq completed registration and is waiting for document verification.',
                            time: 'Pending review',
                            icon: Icons.verified_user_rounded,
                            color: AppTheme.info,
                            actionLabel: 'Open',
                          ),
                          _NotificationItem(
                            title: 'Account approval required',
                            subtitle:
                                'Approve once identity and document checks are completed.',
                            time: 'Blocked until approval',
                            icon: Icons.verified_user_rounded,
                            color: AppTheme.warning,
                            actionLabel: 'Approve',
                          ),
                        ],
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

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: context.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final Color color;
  final String? actionLabel;

  const _NotificationItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.color,
    this.actionLabel,
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
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
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
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(color: context.textTertiary, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.adminAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.adminAccent.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  actionLabel!,
                  style: TextStyle(
                    color: AppTheme.adminAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
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
            'Notifications',
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
