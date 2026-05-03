import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_provider.dart';
import '../../widgets/glass_card.dart';

class AdminProfile extends StatelessWidget {
  final void Function(int) onNavigate;
  final VoidCallback onLogout;
  const AdminProfile({
    super.key,
    required this.onNavigate,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // ── Avatar & name ────────────────────────────────
          Center(
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
                  child: Center(
                    child: Image.asset(
                      'assets/images/navbar/user_transparent.png',
                      width: 40,
                      height: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Admin User',
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'admin@transitpro.com',
                  style: TextStyle(color: context.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 4),
                StatusBadge(label: 'Super Admin', color: AppTheme.adminEmerald),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // ── Quick stats ──────────────────────────────
                Row(
                  children: [
                    _ProfileStat(
                      icon: Icons.directions_bus_rounded,
                      label: 'Buses',
                      value: '12',
                    ),
                    const SizedBox(width: 10),
                    _ProfileStat(
                      icon: Icons.map_rounded,
                      label: 'Routes',
                      value: '18',
                    ),
                    const SizedBox(width: 10),
                    _ProfileStat(
                      icon: Icons.people_alt_rounded,
                      label: 'Users',
                      value: '562',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Management options ───────────────────────
                GlassCard(
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    children: [
                      _OptionRow(
                        icon: Icons.star_rounded,
                        label: 'Dashboard',
                        onTap: () => onNavigate(0),
                      ),
                      _OptionRow(
                        icon: Icons.directions_bus_rounded,
                        label: 'Fleet Management',
                        onTap: () => onNavigate(1),
                      ),
                      _OptionRow(
                        icon: Icons.map_rounded,
                        label: 'Route Management',
                        onTap: () => onNavigate(2),
                      ),
                      _OptionRow(
                        icon: Icons.people_alt_rounded,
                        label: 'User Management',
                        onTap: () => onNavigate(3),
                      ),
                      _OptionRow(
                        icon: Icons.account_balance_wallet_rounded,
                        label: 'Fee Management',
                        onTap: () => onNavigate(4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Settings ─────────────────────────────────
                GlassCard(
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    children: [
                      _OptionRow(
                        icon: Icons.settings_rounded,
                        label: 'App Settings',
                        onTap: () {},
                      ),
                      _OptionRow(
                        icon: Icons.notifications_rounded,
                        label: 'Notification Settings',
                        onTap: () {},
                      ),
                      _OptionRow(
                        icon: Icons.lock_rounded,
                        label: 'Security & Privacy',
                        onTap: () {},
                      ),
                      _OptionRow(
                        icon: Icons.star_rounded,
                        label: 'Audit Logs',
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Theme toggle ─────────────────────────────
                GlassCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
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
                ),
                const SizedBox(height: 12),
                GestureDetector(
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
                        const Text(
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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

class _OptionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _OptionRow({
    required this.icon,
    required this.label,
    required this.onTap,
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
            Icon(icon, color: AppTheme.adminAccent, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
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
