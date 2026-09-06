import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transit_core/transit_core.dart';
import '../../data/admin_repository.dart';
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
                      _RecentAccountsSection(),
                      const SizedBox(height: 12),
                      _PendingDriversSection(),
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

/// Real, live-Firestore replacement for the old hardcoded "Driver
/// Verification Queue" list — pending drivers land here and "Review" opens
/// the same [AdminDriverDetail] screen used for Approve/Reject elsewhere,
/// instead of re-implementing approval logic in this list item.
class _PendingDriversSection extends StatelessWidget {
  const _PendingDriversSection();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Driver>>(
      stream: AdminRepository.instance.watchDrivers(
        status: DriverStatus.pendingVerification,
      ),
      builder: (context, snapshot) {
        final drivers = snapshot.data ?? const <Driver>[];
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        return _SectionCard(
          title: 'Driver Verification Queue',
          subtitle: drivers.isEmpty
              ? 'No drivers are waiting for verification right now.'
              : 'Review uploaded documents before allowing the driver to start driving in the app.',
          children: drivers
              .map(
                (d) => _NotificationItem(
                  title: '${d.name} — driver awaiting approval',
                  subtitle: 'Registered, pending document verification.',
                  time: 'Pending review',
                  icon: Icons.verified_user_rounded,
                  color: AppTheme.warning,
                  actionLabel: 'Review',
                  onAction: () =>
                      context.push('/admin/driver-detail', extra: d.id),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

/// Real, live-Firestore replacement for the old hardcoded "New Account
/// Activity" list — the 5 most recently created accounts across every role.
class _RecentAccountsSection extends StatelessWidget {
  const _RecentAccountsSection();

  static const _roleIcons = {
    UserRole.driver: Icons.drive_eta_rounded,
    UserRole.student: Icons.school_rounded,
    UserRole.parent: Icons.family_restroom_rounded,
    UserRole.admin: Icons.admin_panel_settings_rounded,
  };

  static const _roleColors = {
    UserRole.driver: AppTheme.info,
    UserRole.student: AppTheme.studentAmber,
    UserRole.parent: AppTheme.parentPurple,
    UserRole.admin: AppTheme.adminEmerald,
  };

  String _timeAgo(DateTime? t) {
    if (t == null) return '';
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppUser>>(
      stream: AdminRepository.instance.watchRecentUsers(),
      builder: (context, snapshot) {
        final users = snapshot.data ?? const <AppUser>[];
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        return _SectionCard(
          title: 'New Account Activity',
          subtitle: users.isEmpty
              ? 'No accounts have been created yet.'
              : 'Recent account creations from drivers, students, and parents.',
          children: users
              .map(
                (u) => _NotificationItem(
                  title: '${u.role.name[0].toUpperCase()}${u.role.name.substring(1)} account created',
                  subtitle: '${u.name} registered as a ${u.role.name}.',
                  time: _timeAgo(u.createdAt),
                  icon: _roleIcons[u.role] ?? Icons.person_rounded,
                  color: _roleColors[u.role] ?? AppTheme.info,
                ),
              )
              .toList(),
        );
      },
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
  final VoidCallback? onAction;

  const _NotificationItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.color,
    this.actionLabel,
    this.onAction,
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
              GestureDetector(
                onTap: onAction,
                child: Container(
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
