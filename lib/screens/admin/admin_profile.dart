import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transit_core/transit_core.dart';
import '../../app/auth_service.dart';
import '../../app/locale_provider.dart';
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
    // `AppStrings.t()` reads `LocaleProvider` directly rather than through
    // an `InheritedWidget`, so nothing rebuilds this screen automatically
    // when the language changes elsewhere (e.g. the language picker sheet
    // above this screen) — this screen has to ask to be told, exactly like
    // every `transit_pro` screen that calls `AppStrings.t()` already does.
    LocaleProvider.instance.addListener(_onLangChanged);
  }

  void _onLangChanged() => setState(() {});

  @override
  void dispose() {
    _meSub?.cancel();
    _busesSub?.cancel();
    _routesSub?.cancel();
    _studentsSub?.cancel();
    _parentsSub?.cancel();
    _driversSub?.cancel();
    LocaleProvider.instance.removeListener(_onLangChanged);
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
          StatusBadge(label: AppStrings.t('admin_role'), color: AppTheme.adminEmerald),
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
          label: AppStrings.t('buses_lbl'),
          value: fmt(_busCount),
        ),
        const SizedBox(width: 10),
        _ProfileStat(
          icon: Icons.map_rounded,
          label: AppStrings.t('routes_lbl'),
          value: fmt(_routeCount),
        ),
        const SizedBox(width: 10),
        _ProfileStat(
          icon: Icons.people_alt_rounded,
          label: AppStrings.t('users_lbl'),
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
                AppStrings.t('profile_information'),
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
            label: AppStrings.t('role_lbl'),
            value: AppStrings.t('admin_role'),
            color: AppTheme.purple,
          ),
          _InfoRow(
            icon: Icons.email_rounded,
            label: AppStrings.t('email_lbl'),
            value: email,
            color: AppTheme.info,
          ),
          _InfoRow(
            icon: Icons.phone_rounded,
            label: AppStrings.t('phone_lbl'),
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
            label: AppStrings.t('fee_management'),
            onTap: () => context.push('/admin/fees'),
          ),
          _OptionRow(
            icon: Icons.route_rounded,
            label: AppStrings.t('route_management'),
            onTap: () => context.push('/admin/routes'),
          ),
          _OptionRow(
            icon: Icons.directions_bus_filled_rounded,
            label: AppStrings.t('vehicle_management'),
            onTap: () => context.push('/admin/vehicles'),
          ),
          _OptionRow(
            icon: Icons.notifications_rounded,
            label: AppStrings.t('notification_preferences'),
            onTap: () => context.push('/admin/notifications'),
          ),
          _OptionRow(
            icon: Icons.subscriptions_rounded,
            label: AppStrings.t('subscription_management'),
            onTap: () => context.push('/admin/subscription'),
          ),
          _OptionRow(
            icon: Icons.lock_rounded,
            label: AppStrings.t('change_password'),
            comingSoon: true,
            onTap: () => _msg(context, 'Change Password — coming soon'),
          ),
          _OptionRow(
            icon: Icons.language_rounded,
            label: AppStrings.t('language_settings'),
            onTap: () => _showLanguagePicker(context),
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
                AppStrings.t('security'),
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
            label: AppStrings.t('login_session_history'),
            detail: AppStrings.t('not_available_yet'),
            color: AppTheme.info,
            comingSoon: true,
            onTap: () => _msg(context, 'Session History — coming soon'),
          ),
          _SecurityRow(
            icon: Icons.devices_rounded,
            label: AppStrings.t('active_devices'),
            detail: AppStrings.t('not_available_yet'),
            color: AppTheme.adminEmerald,
            comingSoon: true,
            onTap: () => _msg(context, 'Active Devices — coming soon'),
          ),
          _SecurityRow(
            icon: Icons.logout_rounded,
            label: AppStrings.t('logout_all_sessions'),
            detail: AppStrings.t('not_available_yet'),
            color: AppTheme.error,
            comingSoon: true,
            onTap: () => _msg(context, 'Logout All Sessions — coming soon'),
          ),
          _SecurityRow(
            icon: Icons.admin_panel_settings_rounded,
            label: AppStrings.t('role_based_permissions'),
            detail: AppStrings.t('single_admin_role_desc'),
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
                AppStrings.t('system_controls'),
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              StatusBadge(
                label: AppStrings.t('advanced_badge'),
                color: AppTheme.warning,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SecurityRow(
            icon: Icons.article_rounded,
            label: AppStrings.t('system_logs'),
            detail: AppStrings.t('not_available_yet'),
            color: AppTheme.info,
            comingSoon: true,
            onTap: () => _msg(context, 'System Logs — coming soon'),
          ),
          _SecurityRow(
            icon: Icons.history_edu_rounded,
            label: AppStrings.t('audit_history'),
            detail: AppStrings.t('now_recording_viewer_soon'),
            color: AppTheme.purple,
            comingSoon: true,
            onTap: () => _msg(context, 'Audit History viewer — coming soon'),
          ),
          _SecurityRow(
            icon: Icons.analytics_rounded,
            label: AppStrings.t('admin_activity_tracking'),
            detail: AppStrings.t('not_available_yet'),
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
              AppStrings.t(context.isDark ? 'dark_mode' : 'light_mode'),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🚪', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              AppStrings.t('sign_out'),
              style: const TextStyle(
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

  Future<void> _showLanguagePicker(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _LanguagePickerSheet(
        current: LocaleProvider.instance.locale,
        onSelected: (locale) {
          LocaleProvider.instance.setLocale(locale);
          AuthService.instance.saveLocale(locale);
          Navigator.of(sheetContext).pop();
        },
      ),
    );
  }
}

/// Neumorphic bottom sheet for picking English or Urdu — two opposing
/// shadows on the sheet itself and on each option row, matching the
/// neumorphic recipe already used elsewhere in this app (e.g. the Fee/Route/
/// Fleet Management summary cards) rather than this screen's usual
/// glassmorphic `GlassCard`, since the task asked specifically for a
/// neumorphic treatment here.
class _LanguagePickerSheet extends StatelessWidget {
  final Locale current;
  final ValueChanged<Locale> onSelected;
  const _LanguagePickerSheet({required this.current, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Container(
          padding: const EdgeInsets.all(20),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Language',
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              _LanguageOption(
                label: 'English',
                selected: current.languageCode == 'en',
                onTap: () => onSelected(const Locale('en')),
              ),
              const SizedBox(height: 10),
              _LanguageOption(
                label: 'Urdu (اردو)',
                selected: current.languageCode == 'ur',
                onTap: () => onSelected(const Locale('ur')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.adminEmerald.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppTheme.adminAccent.withValues(alpha: 0.5)
                : context.inputBorder,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? AppTheme.adminAccent : context.textPrimary,
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: AppTheme.adminAccent, size: 18),
          ],
        ),
      ),
    );
  }
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
              StatusBadge(label: AppStrings.t('soon_badge'), color: context.textTertiary)
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
                StatusBadge(label: AppStrings.t('soon_badge'), color: context.textTertiary)
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
