import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transit_core/transit_core.dart';
import '../../app/locale_provider.dart';
import '../../data/admin_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';

class AdminNotifications extends StatefulWidget {
  const AdminNotifications({super.key});

  @override
  State<AdminNotifications> createState() => _AdminNotificationsState();
}

class _AdminNotificationsState extends State<AdminNotifications> {
  @override
  void initState() {
    super.initState();
    LocaleProvider.instance.addListener(_onLangChanged);
  }

  void _onLangChanged() => setState(() {});

  @override
  void dispose() {
    LocaleProvider.instance.removeListener(_onLangChanged);
    super.dispose();
  }

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
                                    AppStrings.t('admin_notifications_title'),
                                    style: TextStyle(
                                      color: context.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppStrings.t('admin_notifications_desc'),
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
                      _RecentFeedbackSection(),
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
          title: AppStrings.t('driver_verification_queue'),
          subtitle: drivers.isEmpty
              ? AppStrings.t('no_drivers_pending_verification')
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

/// Real, live-Firestore replacement for the old hardcoded "Recent Reviews"
/// notice — every "Rate the App" submission, newest first.
class _RecentFeedbackSection extends StatelessWidget {
  const _RecentFeedbackSection();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppFeedback>>(
      stream: AdminRepository.instance.watchRecentFeedback(),
      builder: (context, snapshot) {
        final feedback = snapshot.data ?? const <AppFeedback>[];
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        return _SectionCard(
          title: 'Recent Feedback',
          subtitle: feedback.isEmpty
              ? 'No one has rated the app yet.'
              : 'Ratings and comments submitted from "Rate the App".',
          children: feedback
              .map(
                (f) => _NotificationItem(
                  title: '${'⭐' * f.rating}${'☆' * (5 - f.rating)} rating',
                  subtitle: (f.comment == null || f.comment!.isEmpty)
                      ? 'No comment left.'
                      : f.comment!,
                  time: _timeAgo(f.timestamp),
                  icon: Icons.star_rounded,
                  color: f.rating >= 4
                      ? AppTheme.success
                      : f.rating == 3
                      ? AppTheme.warning
                      : AppTheme.error,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

// Only the day-based branch was in this task's requested term list ('ago',
// 'd') — 'Just now'/'min ago'/'h ago' stay hardcoded English rather than
// inventing keys nobody asked for. English's unit sits directly against the
// number ('5d'); Urdu's needs a space before it ('5 دن') — that space lives
// inside the `day_unit` dictionary value itself, not here, so this one
// composition works correctly for both languages unchanged.
String _timeAgo(DateTime? t) {
  if (t == null) return '';
  final diff = DateTime.now().difference(t);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}${AppStrings.t('day_unit')} ${AppStrings.t('ago_suffix')}';
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

  // Per-role title/subtitle, rather than capitalizing `u.role.name` — that
  // trick doesn't generalize to translation, since Urdu word order/grammar
  // isn't "capitalize a role name and append a fixed suffix".
  String _accountCreatedTitle(UserRole role) => switch (role) {
    UserRole.parent => AppStrings.t('parent_account_created'),
    UserRole.student => AppStrings.t('student_account_created'),
    UserRole.driver => AppStrings.t('driver_account_created'),
    UserRole.admin => '${role.name} account created',
  };

  String _registeredAsSubtitle(String name, UserRole role) => switch (role) {
    UserRole.parent => AppStrings.t(
      'registered_as_parent',
    ).replaceFirst('{name}', name),
    UserRole.student => AppStrings.t(
      'registered_as_student',
    ).replaceFirst('{name}', name),
    UserRole.driver => AppStrings.t(
      'registered_as_driver',
    ).replaceFirst('{name}', name),
    UserRole.admin => '$name registered as a ${role.name}.',
  };

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
          title: AppStrings.t('new_account_activity_title'),
          subtitle: users.isEmpty
              ? 'No accounts have been created yet.'
              : AppStrings.t('new_account_activity_desc'),
          children: users
              .map(
                (u) => _NotificationItem(
                  title: _accountCreatedTitle(u.role),
                  subtitle: _registeredAsSubtitle(u.name, u.role),
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
            AppStrings.t('notifications_title'),
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
