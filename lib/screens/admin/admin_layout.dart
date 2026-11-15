import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/auth_service.dart';
import '../../app/locale_provider.dart';
import '../../theme/app_theme.dart';
import 'admin_dashboard.dart';
import 'admin_student_management.dart';
import 'admin_parent_management.dart';
import 'admin_driver_management.dart';
import 'admin_profile.dart';
import '../../widgets/responsive.dart';

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  int _tab = 0;

  void _goToTab(int index) => setState(() => _tab = index);

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

  // `label` holds an AppStrings key, not display text — `_navItems` is
  // `static const`, which can't call `AppStrings.t()` at construction time,
  // so the lookup happens where it's rendered below instead.
  static const _navItems = [
    _NavItem(icon: Icons.dashboard_rounded, label: 'nav_dashboard'),
    _NavItem(icon: Icons.school_rounded, label: 'nav_student'),
    _NavItem(icon: Icons.family_restroom_rounded, label: 'nav_parent'),
    _NavItem(icon: Icons.directions_bus_rounded, label: 'nav_driver'),
    _NavItem(icon: Icons.person_rounded, label: 'nav_profile'),
  ];

  static const _navColors = [
    AppTheme.adminEmerald,
    AppTheme.studentAmber,
    AppTheme.parentPurple,
    AppTheme.driverCyan,
    AppTheme.adminAccent,
  ];

  // Built once and reused by every layout below, so resizing the window
  // across a breakpoint keeps each tab's state (scroll position, search
  // text, open streams) instead of rebuilding the screens from scratch.
  final _stackKey = GlobalKey();

  Widget _buildStack(BuildContext context) => IndexedStack(
    key: _stackKey,
    index: _tab,
    children: [
      AdminDashboard(onNavigate: _goToTab),
      const AdminStudentManagement(),
      const AdminParentManagement(),
      const AdminDriverManagement(),
      AdminProfile(
        onNavigate: _goToTab,
        onLogout: () async {
          await AuthService.instance.signOut();
          if (context.mounted) context.go('/login');
        },
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final windowClass = windowClassOf(context);
    if (windowClass == WindowClass.compact) {
      // Phone: the floating bottom navigation bar.
      return Scaffold(
        body: Container(
          decoration: context.scaffoldBg,
          child: SafeArea(bottom: false, child: _buildStack(context)),
        ),
        extendBody: true,
        bottomNavigationBar: _buildNav(),
      );
    }
    // Tablet / desktop window: navigation down the left — an icon rail on
    // medium widths, a labelled side bar once the window is wide.
    final expanded = windowClass == WindowClass.expanded;
    return Scaffold(
      body: Container(
        decoration: context.scaffoldBg,
        child: SafeArea(
          child: Row(
            children: [
              _buildRail(context, extended: expanded),
              VerticalDivider(width: 1, color: context.surfaceBorder),
              Expanded(child: _buildStack(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRail(BuildContext context, {required bool extended}) {
    final activeColor = _navColors[_tab];
    return NavigationRail(
      selectedIndex: _tab,
      onDestinationSelected: _goToTab,
      extended: extended,
      minExtendedWidth: 220,
      labelType: extended
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.all,
      backgroundColor: context.isDark
          ? Colors.white.withValues(alpha: 0.04)
          : Colors.white.withValues(alpha: 0.7),
      indicatorColor: activeColor.withValues(alpha: 0.16),
      selectedIconTheme: IconThemeData(color: activeColor, size: 24),
      unselectedIconTheme: IconThemeData(color: context.textTertiary, size: 22),
      selectedLabelTextStyle: TextStyle(
        color: activeColor,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: context.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      leading: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: AppTheme.adminGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.directions_bus_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            if (extended) ...[
              const SizedBox(width: 10),
              Text(
                'Transit Admin',
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
      ),
      destinations: [
        for (final item in _navItems)
          NavigationRailDestination(
            icon: Icon(item.icon),
            label: Text(AppStrings.t(item.label)),
          ),
      ],
    );
  }

  Widget _buildNav() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              decoration: BoxDecoration(
                color: context.isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: context.isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.85),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(
                children: List.generate(_navItems.length, (i) {
                  final isActive = _tab == i;
                  final activeColor = _navColors[i];
                  return Expanded(
                    child: Clickable(
                      onTap: () => _goToTab(i),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 4,
                        ),
                        decoration: isActive
                            ? BoxDecoration(
                                color: context.isDark
                                    ? activeColor.withValues(alpha: 0.18)
                                    : activeColor.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: activeColor.withValues(alpha: 0.25),
                                ),
                              )
                            : null,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _navItems[i].icon,
                              size: isActive ? 24 : 22,
                              color: isActive
                                  ? activeColor
                                  : context.textTertiary,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              AppStrings.t(_navItems[i].label),
                              style: TextStyle(
                                color: isActive
                                    ? activeColor
                                    : context.textTertiary,
                                fontSize: isActive ? 10 : 9,
                                fontWeight: isActive
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
