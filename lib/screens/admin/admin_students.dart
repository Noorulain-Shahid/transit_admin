import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import 'admin_user_models.dart';

class AdminStudents extends StatelessWidget {
  final VoidCallback? onBack;
  const AdminStudents({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        children: [
          _Header(title: 'User Management', onBack: onBack),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    _MiniStat(
                      icon: Icons.school_rounded,
                      label: 'Students',
                      value: _students.length.toString(),
                      color: AppTheme.studentAmber,
                    ),
                    const SizedBox(width: 10),
                    _MiniStat(
                      icon: Icons.drive_eta_rounded,
                      label: 'Drivers',
                      value: _drivers.length.toString(),
                      color: AppTheme.driverCyan,
                    ),
                    const SizedBox(width: 10),
                    _MiniStat(
                      icon: Icons.family_restroom_rounded,
                      label: 'Parents',
                      value: _parents.length.toString(),
                      color: AppTheme.parentPurple,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _RoleSection(
                  title: 'Students',
                  subtitle: 'Tap a student to view and edit their details.',
                  color: AppTheme.studentAmber,
                  users: _students,
                ),
                const SizedBox(height: 12),
                _RoleSection(
                  title: 'Drivers',
                  subtitle:
                      'Tap a driver to update documents, route assignment, or active status.',
                  color: AppTheme.driverCyan,
                  users: _drivers,
                ),
                const SizedBox(height: 12),
                _RoleSection(
                  title: 'Parents',
                  subtitle:
                      'Tap a parent to update linked children, contact info, or account state.',
                  color: AppTheme.parentPurple,
                  users: _parents,
                ),
                const SizedBox(height: 12),
                GlassCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pending Registrations',
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._pendingUsers.map(
                        (u) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _PendingUserRow(user: u),
                        ),
                      ),
                    ],
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

final _students = [
  AdminUserRecord(
    id: 'stu_1',
    name: 'Noorulain Shahid',
    role: 'Student',
    icon: '🎓',
    detail: 'Grade 5 · Bus #42',
    color: AppTheme.studentAmber,
    active: true,
    contact: '0300-1111111',
    address: 'Lincoln Elementary',
    extra: 'Pickup: 07:10 AM',
  ),
  AdminUserRecord(
    id: 'stu_2',
    name: 'Emma Watson',
    role: 'Student',
    icon: '🎓',
    detail: 'Grade 7 · Bus #43',
    color: AppTheme.studentAmber,
    active: true,
    contact: '0300-2222222',
    address: 'Maple School',
    extra: 'Pickup: 07:25 AM',
  ),
];

final _drivers = [
  AdminUserRecord(
    id: 'drv_1',
    name: 'Mike Johnson',
    role: 'Driver',
    icon: '🚌',
    detail: 'Route A · Bus #42',
    color: AppTheme.driverCyan,
    active: true,
    contact: '0311-4444444',
    address: 'Vehicle: Bus #42',
    extra: 'License: DL-2026-0042',
  ),
  AdminUserRecord(
    id: 'drv_2',
    name: 'Ahmed Ali',
    role: 'Driver',
    icon: '🚌',
    detail: 'Route B · Bus #43',
    color: AppTheme.driverCyan,
    active: true,
    contact: '0312-5555555',
    address: 'Vehicle: Bus #43',
    extra: 'License: DL-2026-0043',
  ),
];

final _parents = [
  AdminUserRecord(
    id: 'par_1',
    name: 'Shahid Ali',
    role: 'Parent',
    icon: '👨‍👩‍👧',
    detail: '2 children enrolled',
    color: AppTheme.parentPurple,
    active: true,
    contact: '0321-6666666',
    address: 'North Colony',
    extra: 'Children: Noor, Haya',
  ),
  AdminUserRecord(
    id: 'par_2',
    name: 'Sarah Ahmed',
    role: 'Parent',
    icon: '👨‍👩‍👧',
    detail: '1 child enrolled',
    color: AppTheme.parentPurple,
    active: true,
    contact: '0333-7777777',
    address: 'Civic Center',
    extra: 'Child: Ali',
  ),
];

final _pendingUsers = [
  AdminUserRecord(
    id: 'pen_1',
    name: 'Ali Hassan',
    role: 'Student',
    icon: '🎓',
    detail: 'Grade 8 · Lincoln Elem',
    color: AppTheme.studentAmber,
    active: false,
    contact: '0340-8888888',
    address: 'Lincoln Elementary',
    extra: 'Pending approval',
  ),
  AdminUserRecord(
    id: 'pen_2',
    name: 'Fatima Khan',
    role: 'Parent',
    icon: '👨‍👩‍👧',
    detail: 'Child: Zara (Grade 5)',
    color: AppTheme.parentPurple,
    active: false,
    contact: '0345-9999999',
    address: 'West Town',
    extra: 'Pending approval',
  ),
  AdminUserRecord(
    id: 'pen_3',
    name: 'Ravi Kumar',
    role: 'Driver',
    icon: '🚌',
    detail: 'License: DL-2026-1234',
    color: AppTheme.driverCyan,
    active: false,
    contact: '0309-0000000',
    address: 'Vehicle documents uploaded',
    extra: 'Pending approval',
  ),
];

class _RoleSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final List<AdminUserRecord> users;

  const _RoleSection({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.users,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: context.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          ...users.map(
            (user) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _UserCard(
                user: user,
                onTap: () => context.push('/admin/user-detail', extra: user),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final AdminUserRecord user;
  final VoidCallback onTap;

  const _UserCard({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: user.color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: user.color.withValues(alpha: 0.14)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: user.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: user.color.withValues(alpha: 0.25)),
              ),
              child: Center(
                child: Text(user.icon, style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.name,
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      StatusBadge(label: user.role, color: user.color),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.detail,
                    style: TextStyle(color: context.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to view and edit details',
                    style: TextStyle(color: context.textTertiary, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: context.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.12),
            color.withValues(alpha: 0.04),
          ],
        ),
        borderColor: color.withValues(alpha: 0.2),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: TextStyle(color: context.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingUserRow extends StatelessWidget {
  final AdminUserRecord user;
  const _PendingUserRow({required this.user});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.cardBg),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: user.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(user.icon, style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user.name,
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    StatusBadge(label: user.role, color: user.color),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  user.detail,
                  style: TextStyle(color: context.textTertiary, fontSize: 11),
                ),
              ],
            ),
          ),
          _ActionBtn(label: '✓', color: AppTheme.success),
          const SizedBox(width: 6),
          _ActionBtn(label: '✕', color: AppTheme.error),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  const _ActionBtn({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  const _Header({required this.title, this.onBack});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          if (onBack != null)
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
            title,
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
