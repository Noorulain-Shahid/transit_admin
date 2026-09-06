import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transit_core/transit_core.dart';
import '../../data/admin_repository.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_provider.dart';
import '../../widgets/glass_card.dart';

class AdminProfile extends StatefulWidget {
  final void Function(int) onNavigate;
  final VoidCallback onLogout;
  const AdminProfile({
    super.key,
    required this.onNavigate,
    required this.onLogout,
  });

  @override
  State<AdminProfile> createState() => _AdminProfileState();
}

class _AdminProfileState extends State<AdminProfile> {
  final _repo = AdminRepository.instance;

  AppUser? _me;
  int? _busCount;
  int? _routeCount;
  int? _userCount;

  StreamSubscription<AppUser?>? _meSub;
  StreamSubscription<List<Bus>>? _busesSub;
  StreamSubscription<List<BusRoute>>? _routesSub;
  StreamSubscription<List<Student>>? _studentsSub;
  StreamSubscription<List<AppUser>>? _parentsSub;
  StreamSubscription<List<Driver>>? _driversSub;

  int _students = 0, _parents = 0, _drivers = 0;

  void Function(int) get onNavigate => widget.onNavigate;
  VoidCallback get onLogout => widget.onLogout;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _meSub = _repo.watchUser(uid).listen((v) => setState(() => _me = v));
    }
    _busesSub = _repo.watchBuses().listen(
      (v) => setState(() => _busCount = v.length),
    );
    _routesSub = _repo.watchRoutes().listen(
      (v) => setState(() => _routeCount = v.length),
    );
    _studentsSub = _repo.watchStudents().listen((v) {
      _students = v.length;
      setState(() => _userCount = _students + _parents + _drivers);
    });
    _parentsSub = _repo.watchUsersByRole(UserRole.parent).listen((v) {
      _parents = v.length;
      setState(() => _userCount = _students + _parents + _drivers);
    });
    _driversSub = _repo.watchDrivers().listen((v) {
      _drivers = v.length;
      setState(() => _userCount = _students + _parents + _drivers);
    });
  }

  @override
  void dispose() {
    _meSub?.cancel();
    _busesSub?.cancel();
    _routesSub?.cancel();
    _studentsSub?.cancel();
    _parentsSub?.cancel();
    _driversSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildAvatar(context),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildQuickStats(context),
                const SizedBox(height: 16),
                _buildProfileInfo(context),
                const SizedBox(height: 12),
                _buildSettings(context),
                const SizedBox(height: 12),
                _buildSecurity(context),
                const SizedBox(height: 12),
                _buildSystemControls(context),
                const SizedBox(height: 12),
                _buildThemeToggle(context),
                const SizedBox(height: 12),
                _buildLogout(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final name = _me?.name.isNotEmpty == true ? _me!.name : 'Admin';
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    return Center(
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppTheme.adminGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.adminEmerald.withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.admin_panel_settings_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: TextStyle(color: context.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 6),
          StatusBadge(label: 'Admin', color: AppTheme.adminEmerald),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    String fmt(int? n) => n == null ? '…' : '$n';
    return Row(
      children: [
        _ProfileStat(
          icon: Icons.directions_bus_rounded,
          label: 'Buses',
          value: fmt(_busCount),
        ),
        const SizedBox(width: 10),
        _ProfileStat(
          icon: Icons.map_rounded,
          label: 'Routes',
          value: fmt(_routeCount),
        ),
        const SizedBox(width: 10),
        _ProfileStat(
          icon: Icons.people_alt_rounded,
          label: 'Users',
          value: fmt(_userCount),
        ),
      ],
    );
  }

  Widget _buildProfileInfo(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '—';
    final phone = _me?.phone.isNotEmpty == true ? _me!.phone : 'Not set';
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.person_rounded,
                color: AppTheme.adminAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Profile Information',
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.work_rounded,
            label: 'Role',
            value: 'Admin',
            color: AppTheme.purple,
          ),
          _InfoRow(
            icon: Icons.email_rounded,
            label: 'Email',
            value: email,
            color: AppTheme.info,
          ),
          _InfoRow(
            icon: Icons.phone_rounded,
            label: 'Phone',
            value: phone,
            color: AppTheme.driverCyan,
          ),
        ],
      ),
    );
  }

  Widget _buildSettings(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          _OptionRow(
            icon: Icons.account_balance_wallet_rounded,
            label: 'Fee Management',
            onTap: () => context.push('/admin/fees'),
          ),
          _OptionRow(
            icon: Icons.route_rounded,
            label: 'Route Management',
            onTap: () => context.push('/admin/routes'),
          ),
          _OptionRow(
            icon: Icons.directions_bus_filled_rounded,
            label: 'Vehicle Management',
            onTap: () => context.push('/admin/vehicles'),
          ),
          _OptionRow(
            icon: Icons.notifications_rounded,
            label: 'Notification Preferences',
            onTap: () => context.push('/admin/notifications'),
          ),
          _OptionRow(
            icon: Icons.subscriptions_rounded,
            label: 'Subscription Management',
            onTap: () => context.push('/admin/subscription'),
          ),
          _OptionRow(
            icon: Icons.lock_rounded,
            label: 'Change Password',
            comingSoon: true,
            onTap: () => _msg(context, 'Change Password — coming soon'),
          ),
          _OptionRow(
            icon: Icons.language_rounded,
            label: 'Language Settings',
            comingSoon: true,
            onTap: () => _msg(context, 'Language Settings — coming soon'),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurity(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.security_rounded,
                color: AppTheme.adminAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Security',
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SecurityRow(
            icon: Icons.history_rounded,
            label: 'Login Session History',
            detail: 'Not available yet',
            color: AppTheme.info,
            comingSoon: true,
            onTap: () => _msg(context, 'Session History — coming soon'),
          ),
          _SecurityRow(
            icon: Icons.devices_rounded,
            label: 'Active Devices',
            detail: 'Not available yet',
            color: AppTheme.adminEmerald,
            comingSoon: true,
            onTap: () => _msg(context, 'Active Devices — coming soon'),
          ),
          _SecurityRow(
            icon: Icons.logout_rounded,
            label: 'Logout All Sessions',
            detail: 'Not available yet',
            color: AppTheme.error,
            comingSoon: true,
            onTap: () => _msg(context, 'Logout All Sessions — coming soon'),
          ),
          _SecurityRow(
            icon: Icons.admin_panel_settings_rounded,
            label: 'Role-Based Permissions',
            detail: 'Single Admin role — no sub-roles yet',
            color: AppTheme.purple,
            comingSoon: true,
            onTap: () => _msg(context, 'Role-Based Permissions — coming soon'),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemControls(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.settings_suggest_rounded,
                color: AppTheme.adminAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'System Controls',
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              StatusBadge(label: 'Advanced', color: AppTheme.warning),
            ],
          ),
          const SizedBox(height: 12),
          _SecurityRow(
            icon: Icons.article_rounded,
            label: 'System Logs',
            detail: 'Not available yet',
            color: AppTheme.info,
            comingSoon: true,
            onTap: () => _msg(context, 'System Logs — coming soon'),
          ),
          _SecurityRow(
            icon: Icons.history_edu_rounded,
            label: 'Audit History',
            detail: 'Now recording — viewer coming soon',
            color: AppTheme.purple,
            comingSoon: true,
            onTap: () => _msg(context, 'Audit History viewer — coming soon'),
          ),
          _SecurityRow(
            icon: Icons.analytics_rounded,
            label: 'Admin Activity Tracking',
            detail: 'Not available yet',
            color: AppTheme.warning,
            comingSoon: true,
            onTap: () => _msg(context, 'Activity Tracking — coming soon'),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeToggle(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            context.isDark ? '🌙' : '☀️',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              context.isDark ? 'Dark Mode' : 'Light Mode',
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          AppSwitch(
            value: context.isDark,
            activeColor: AppTheme.adminEmerald,
            onChanged: (_) => ThemeProvider.instance.toggle(),
          ),
        ],
      ),
    );
  }

  Widget _buildLogout(BuildContext context) {
    return GestureDetector(
      onTap: onLogout,
      child: GlassCard(
        gradient: LinearGradient(
          colors: [
            AppTheme.error.withValues(alpha: 0.1),
            AppTheme.error.withValues(alpha: 0.04),
          ],
        ),
        borderColor: AppTheme.error.withValues(alpha: 0.2),
        padding: const EdgeInsets.all(16),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🚪', style: TextStyle(fontSize: 18)),
            SizedBox(width: 8),
            Text(
              'Sign Out',
              style: TextStyle(
                color: AppTheme.error,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _msg(BuildContext context, String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────
class _ProfileStat extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _ProfileStat({
    required this.icon,
    required this.label,
    required this.value,
  });
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.adminAccent, size: 26),
            const SizedBox(height: 4),
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
              style: TextStyle(color: context.textTertiary, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
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
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            SizedBox(
              width: 50,
              child: Text(
                label,
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 13,
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

class _OptionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool comingSoon;
  const _OptionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.comingSoon = false,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              color: comingSoon
                  ? context.textTertiary
                  : AppTheme.adminAccent,
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: comingSoon
                      ? context.textTertiary
                      : context.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (comingSoon)
              StatusBadge(label: 'Soon', color: context.textTertiary)
            else
              Text(
                '›',
                style: TextStyle(color: context.textTertiary, fontSize: 20),
              ),
          ],
        ),
      ),
    );
  }
}

class _SecurityRow extends StatelessWidget {
  final IconData icon;
  final String label, detail;
  final Color color;
  final VoidCallback onTap;
  final bool comingSoon;
  const _SecurityRow({
    required this.icon,
    required this.label,
    required this.detail,
    required this.color,
    required this.onTap,
    this.comingSoon = false,
  });
  @override
  Widget build(BuildContext context) {
    final rowColor = comingSoon ? context.textTertiary : color;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: rowColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: rowColor.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Icon(icon, color: rowColor, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      detail,
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (comingSoon)
                StatusBadge(label: 'Soon', color: context.textTertiary)
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: context.textTertiary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
