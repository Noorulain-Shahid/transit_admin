import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import 'admin_dashboard.dart';
import 'admin_vehicles.dart';
import 'admin_routes.dart';
import 'admin_students.dart';
import 'admin_fees.dart';
import 'admin_profile.dart';

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  int _tab = 0;

  void _goToTab(int index) => setState(() => _tab = index);

  List<_NavItem> get _navItems => const [
    _NavItem(
      iconPath: 'assets/images/navbar/home_transparent.png',
      label: 'Dashboard',
    ),
    _NavItem(
      iconPath: 'assets/images/splash_screen/bus_splash_icon.png',
      label: 'Fleet',
    ),
    _NavItem(
      iconPath: 'assets/images/navbar/track_transparent.png',
      label: 'Routes',
    ),
    _NavItem(iconPath: 'assets/images/navbar/student.png', label: 'Users'),
    _NavItem(iconPath: 'assets/images/navbar/fees.png', label: 'Fees'),
    _NavItem(
      iconPath: 'assets/images/navbar/user_transparent.png',
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: context.scaffoldBg,
        child: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _tab,
            children: [
              AdminDashboard(onNavigate: _goToTab),
              AdminVehicles(),
              AdminRoutes(),
              AdminStudents(),
              AdminFees(),
              AdminProfile(
                onNavigate: _goToTab,
                onLogout: () => context.go('/login'),
              ),
            ],
          ),
        ),
      ),
      extendBody: true,
      bottomNavigationBar: _buildNav(),
    );
  }

  Widget _buildNav() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: context.isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.white.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: context.isDark
                      ? Colors.white.withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.80),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 28,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Row(
                children: List.generate(_navItems.length, (i) {
                  final isActive = _tab == i;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _goToTab(i),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 4,
                        ),
                        decoration: isActive
                            ? BoxDecoration(
                                color: context.isDark
                                    ? Colors.white.withValues(alpha: 0.20)
                                    : Colors.white.withValues(alpha: 0.72),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.10),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              )
                            : null,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              _navItems[i].iconPath,
                              width: isActive ? 26 : 22,
                              height: isActive ? 26 : 22,
                              cacheWidth: 64,
                              cacheHeight: 64,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.medium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _navItems[i].label,
                              style: TextStyle(
                                color: isActive
                                    ? AppTheme.adminAccent
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
  final String iconPath;
  final String label;
  const _NavItem({required this.iconPath, required this.label});
}
