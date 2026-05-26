import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_provider.dart';
import '../../widgets/glass_card.dart';

class AdminProfile extends StatelessWidget {
  final void Function(int) onNavigate;
  final VoidCallback onLogout;
  const AdminProfile({super.key, required this.onNavigate, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(children: [
        const SizedBox(height: 20),
        _buildAvatar(context),
        const SizedBox(height: 24),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(children: [
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
        ])),
      ]),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return Center(child: Column(children: [
      Container(width: 80, height: 80,
        decoration: BoxDecoration(gradient: AppTheme.adminGradient, borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: AppTheme.adminEmerald.withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 10))]),
        child: const Center(child: Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 36))),
      const SizedBox(height: 14),
      Text('Admin User', style: TextStyle(color: context.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text('admin@transitpro.com', style: TextStyle(color: context.textSecondary, fontSize: 13)),
      const SizedBox(height: 6),
      StatusBadge(label: 'Super Admin', color: AppTheme.adminEmerald),
    ]));
  }

  Widget _buildQuickStats(BuildContext context) {
    return Row(children: [
      _ProfileStat(icon: Icons.directions_bus_rounded, label: 'Buses', value: '12'),
      const SizedBox(width: 10),
      _ProfileStat(icon: Icons.map_rounded, label: 'Routes', value: '18'),
      const SizedBox(width: 10),
      _ProfileStat(icon: Icons.people_alt_rounded, label: 'Users', value: '562'),
    ]);
  }

  Widget _buildProfileInfo(BuildContext context) {
    return GlassCard(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.person_rounded, color: AppTheme.adminAccent, size: 20),
        const SizedBox(width: 8),
        Text('Profile Information', style: TextStyle(color: context.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
      ]),
      const SizedBox(height: 12),
      _InfoRow(icon: Icons.badge_rounded, label: 'Name', value: 'Admin User', color: AppTheme.adminEmerald),
      _InfoRow(icon: Icons.work_rounded, label: 'Role', value: 'Super Admin', color: AppTheme.purple),
      _InfoRow(icon: Icons.email_rounded, label: 'Email', value: 'admin@transitpro.com', color: AppTheme.info),
      _InfoRow(icon: Icons.phone_rounded, label: 'Phone', value: '+92 300-1234567', color: AppTheme.driverCyan),
    ]));
  }

  Widget _buildSettings(BuildContext context) {
    return GlassCard(padding: const EdgeInsets.all(4), child: Column(children: [
      _OptionRow(icon: Icons.lock_rounded, label: 'Change Password', onTap: () => _msg(context, 'Change password form')),
      _OptionRow(icon: Icons.language_rounded, label: 'Language Settings', onTap: () => _msg(context, 'Language selector')),
      _OptionRow(icon: Icons.notifications_rounded, label: 'Notification Preferences', onTap: () => context.push('/admin/notifications')),
      _OptionRow(icon: Icons.subscriptions_rounded, label: 'Subscription Management', onTap: () => context.push('/admin/subscription')),
    ]));
  }

  Widget _buildSecurity(BuildContext context) {
    return GlassCard(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.security_rounded, color: AppTheme.adminAccent, size: 20),
        const SizedBox(width: 8),
        Text('Security', style: TextStyle(color: context.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
      ]),
      const SizedBox(height: 12),
      _SecurityRow(icon: Icons.history_rounded, label: 'Login Session History', detail: 'Last login: 2h ago', color: AppTheme.info,
        onTap: () => _msg(context, 'Session history')),
      _SecurityRow(icon: Icons.devices_rounded, label: 'Active Devices', detail: '2 devices active', color: AppTheme.adminEmerald,
        onTap: () => _msg(context, 'Active devices list')),
      _SecurityRow(icon: Icons.logout_rounded, label: 'Logout All Sessions', detail: 'Terminate all active sessions', color: AppTheme.error,
        onTap: () => _msg(context, 'All sessions terminated')),
      _SecurityRow(icon: Icons.admin_panel_settings_rounded, label: 'Role-Based Permissions', detail: 'Super Admin — Full access', color: AppTheme.purple,
        onTap: () => _msg(context, 'Permissions panel')),
    ]));
  }

  Widget _buildSystemControls(BuildContext context) {
    return GlassCard(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.settings_suggest_rounded, color: AppTheme.adminAccent, size: 20),
        const SizedBox(width: 8),
        Text('System Controls', style: TextStyle(color: context.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
        const Spacer(),
        StatusBadge(label: 'Advanced', color: AppTheme.warning),
      ]),
      const SizedBox(height: 12),
      _SecurityRow(icon: Icons.cloud_rounded, label: 'Firebase Configuration', detail: 'Connected — transit-pro-app', color: AppTheme.adminEmerald,
        onTap: () => _msg(context, 'Firebase config')),
      _SecurityRow(icon: Icons.article_rounded, label: 'System Logs', detail: '1,247 entries today', color: AppTheme.info,
        onTap: () => _msg(context, 'System logs viewer')),
      _SecurityRow(icon: Icons.history_edu_rounded, label: 'Audit History', detail: 'Full activity audit trail', color: AppTheme.purple,
        onTap: () => _msg(context, 'Audit history')),
      _SecurityRow(icon: Icons.analytics_rounded, label: 'Admin Activity Tracking', detail: '23 actions today', color: AppTheme.warning,
        onTap: () => _msg(context, 'Activity tracking')),
    ]));
  }

  Widget _buildThemeToggle(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Text(context.isDark ? '🌙' : '☀️', style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 14),
        Expanded(child: Text(context.isDark ? 'Dark Mode' : 'Light Mode',
          style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))),
        AppSwitch(value: context.isDark, activeColor: AppTheme.adminEmerald, onChanged: (_) => ThemeProvider.instance.toggle()),
      ]),
    );
  }

  Widget _buildLogout(BuildContext context) {
    return GestureDetector(onTap: onLogout, child: GlassCard(
      gradient: LinearGradient(colors: [AppTheme.error.withValues(alpha: 0.1), AppTheme.error.withValues(alpha: 0.04)]),
      borderColor: AppTheme.error.withValues(alpha: 0.2),
      padding: const EdgeInsets.all(16),
      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('🚪', style: TextStyle(fontSize: 18)),
        SizedBox(width: 8),
        Text('Sign Out', style: TextStyle(color: AppTheme.error, fontSize: 15, fontWeight: FontWeight.w600)),
      ]),
    ));
  }

  void _msg(BuildContext context, String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────
class _ProfileStat extends StatelessWidget {
  final IconData icon; final String label, value;
  const _ProfileStat({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Expanded(child: GlassCard(padding: const EdgeInsets.symmetric(vertical: 14), child: Column(children: [
      Icon(icon, color: AppTheme.adminAccent, size: 26), const SizedBox(height: 4),
      Text(value, style: TextStyle(color: context.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
      Text(label, style: TextStyle(color: context.textTertiary, fontSize: 11)),
    ])));
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon; final String label, value; final Color color;
  const _InfoRow({required this.icon, required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.12))),
      child: Row(children: [
        Icon(icon, color: color, size: 18), const SizedBox(width: 10),
        SizedBox(width: 50, child: Text(label, style: TextStyle(color: context.textSecondary, fontSize: 11, fontWeight: FontWeight.w600))),
        Expanded(child: Text(value, style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
      ]),
    ));
  }
}

class _OptionRow extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _OptionRow({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Icon(icon, color: AppTheme.adminAccent, size: 22), const SizedBox(width: 14),
        Expanded(child: Text(label, style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))),
        Text('›', style: TextStyle(color: context.textTertiary, fontSize: 20)),
      ]),
    ));
  }
}

class _SecurityRow extends StatelessWidget {
  final IconData icon; final String label, detail; final Color color; final VoidCallback onTap;
  const _SecurityRow({required this.icon, required this.label, required this.detail, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Padding(padding: const EdgeInsets.only(bottom: 10), child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.12))),
      child: Row(children: [
        Icon(icon, color: color, size: 18), const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          Text(detail, style: TextStyle(color: context.textSecondary, fontSize: 11)),
        ])),
        Icon(Icons.chevron_right_rounded, color: context.textTertiary, size: 20),
      ]),
    )));
  }
}
