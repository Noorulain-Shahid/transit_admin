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

  static const _navItems = [
    _NavItem(icon: '📊', label: 'Dashboard'),
    _NavItem(icon: '🚌', label: 'Fleet'),
    _NavItem(icon: '🗺️', label: 'Routes'),
    _NavItem(icon: '👥', label: 'Users'),
    _NavItem(icon: '💰', label: 'Fees'),
    _NavItem(icon: '👤', label: 'Profile'),
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
              AdminVehicles(onBack: () => _goToTab(0)),
              AdminRoutes(onBack: () => _goToTab(0)),
              AdminStudents(onBack: () => _goToTab(0)),
              AdminFees(onBack: () => _goToTab(0)),
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
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: context.isDark
                ? Colors.black.withOpacity(0.45)
                : Colors.white.withOpacity(0.85),
            border: Border(top: BorderSide(color: context.cardBgElevated)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: List.generate(_navItems.length, (i) {
                  final isActive = _tab == i;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _goToTab(i),
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(6),
                            decoration: isActive
                                ? BoxDecoration(
                                    color: AppTheme.adminEmerald.withOpacity(
                                      0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  )
                                : null,
                            child: Text(
                              _navItems[i].icon,
                              style: TextStyle(fontSize: isActive ? 20 : 18),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _navItems[i].label,
                            style: TextStyle(
                              color: isActive
                                  ? AppTheme.adminAccent
                                  : context.textTertiary,
                              fontSize: 10,
                              fontWeight: isActive
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
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
  final String icon, label;
  const _NavItem({required this.icon, required this.label});
}
