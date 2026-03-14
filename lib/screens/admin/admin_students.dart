import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';

class AdminStudents extends StatefulWidget {
  final VoidCallback onBack;
  const AdminStudents({super.key, required this.onBack});

  @override
  State<AdminStudents> createState() => _AdminStudentsState();
}

class _AdminStudentsState extends State<AdminStudents> {
  int _filter = 0; // 0=All, 1=Students, 2=Parents, 3=Drivers, 4=Pending

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        children: [
          _Header(title: 'User Management', onBack: widget.onBack),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // ── Stats ──────────────────────────────
                Row(
                  children: [
                    _MiniStat(
                      icon: Icons.people_alt_rounded,
                      label: 'Total',
                      value: '562',
                      color: AppTheme.adminEmerald,
                    ),
                    const SizedBox(width: 10),
                    _MiniStat(
                      icon: Icons.school_rounded,
                      label: 'Students',
                      value: '486',
                      color: AppTheme.studentAmber,
                    ),
                    const SizedBox(width: 10),
                    _MiniStat(
                      icon: Icons.hourglass_empty_rounded,
                      label: 'Pending',
                      value: '14',
                      color: AppTheme.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Filter chips ──────────────────────
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        active: _filter == 0,
                        onTap: () => setState(() => _filter = 0),
                      ),
                      _FilterChip(
                        label: 'Students',
                        active: _filter == 1,
                        onTap: () => setState(() => _filter = 1),
                      ),
                      _FilterChip(
                        label: 'Parents',
                        active: _filter == 2,
                        onTap: () => setState(() => _filter = 2),
                      ),
                      _FilterChip(
                        label: 'Drivers',
                        active: _filter == 3,
                        onTap: () => setState(() => _filter = 3),
                      ),
                      _FilterChip(
                        label: 'Pending',
                        active: _filter == 4,
                        onTap: () => setState(() => _filter = 4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── Pending approvals section ──────────
                if (_filter == 0 || _filter == 4) ...[
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.warning.withValues(alpha: 0.1),
                        Colors.transparent,
                      ],
                    ),
                    borderColor: AppTheme.warning.withValues(alpha: 0.2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('⏳', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Text(
                              'Pending Registrations',
                              style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.warning.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '14 new',
                                style: TextStyle(
                                  color: AppTheme.warning,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ..._pendingUsers.map((u) => _PendingUserRow(user: u)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── User list ─────────────────────────
                ..._getFilteredUsers().map(
                  (u) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _UserCard(user: u),
                  ),
                ),

                // ── Vacancy section ───────────────────
                if (_filter == 0 || _filter == 1) ...[
                  const SizedBox(height: 12),
                  GlassCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Seat Availability',
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _SeatRow(route: 'Route A', total: 40, filled: 36),
                        _SeatRow(route: 'Route B', total: 35, filled: 28),
                        _SeatRow(route: 'Route C', total: 40, filled: 40),
                        _SeatRow(route: 'Route D', total: 38, filled: 22),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_UserData> _getFilteredUsers() {
    switch (_filter) {
      case 1:
        return _allUsers.where((u) => u.role == 'Student').toList();
      case 2:
        return _allUsers.where((u) => u.role == 'Parent').toList();
      case 3:
        return _allUsers.where((u) => u.role == 'Driver').toList();
      default:
        return _allUsers;
    }
  }
}

// ── Data models ───────────────────────────────────────────────────────────

final _pendingUsers = [
  _PendingUser(
    'Ali Hassan',
    'Student',
    '🎓',
    'Grade 8 · Lincoln Elem',
    AppTheme.studentAmber,
  ),
  _PendingUser(
    'Fatima Khan',
    'Parent',
    '👨‍👩‍👧',
    'Child: Zara (Grade 5)',
    AppTheme.parentPurple,
  ),
  _PendingUser(
    'Ravi Kumar',
    'Driver',
    '🚌',
    'License: DL-2026-1234',
    AppTheme.driverCyan,
  ),
];

final _allUsers = [
  _UserData(
    'Noorulain Shahid',
    'Student',
    '🎓',
    'Grade 5 · Bus #42',
    AppTheme.studentAmber,
    true,
  ),
  _UserData(
    'Emma Watson',
    'Student',
    '🎓',
    'Grade 7 · Bus #43',
    AppTheme.studentAmber,
    true,
  ),
  _UserData(
    'Shahid Ali',
    'Parent',
    '👨‍👩‍👧',
    '2 children enrolled',
    AppTheme.parentPurple,
    true,
  ),
  _UserData(
    'Mike Johnson',
    'Driver',
    '🚌',
    'Route A · Bus #42',
    AppTheme.driverCyan,
    true,
  ),
  _UserData(
    'Sarah Ahmed',
    'Parent',
    '👨‍👩‍👧',
    '1 child enrolled',
    AppTheme.parentPurple,
    true,
  ),
  _UserData(
    'Ahmed Ali',
    'Driver',
    '🚌',
    'Route B · Bus #43',
    AppTheme.driverCyan,
    true,
  ),
];

class _PendingUser {
  final String name, role, icon, detail;
  final Color color;
  const _PendingUser(this.name, this.role, this.icon, this.detail, this.color);
}

class _UserData {
  final String name, role, icon, detail;
  final Color color;
  final bool active;
  const _UserData(
    this.name,
    this.role,
    this.icon,
    this.detail,
    this.color,
    this.active,
  );
}

// ── Widgets ───────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  const _Header({required this.title, required this.onBack});
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? AppTheme.adminEmerald.withValues(alpha: 0.2)
                : context.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active
                  ? AppTheme.adminAccent.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? AppTheme.adminAccent : context.textSecondary,
              fontSize: 13,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _PendingUserRow extends StatelessWidget {
  final _PendingUser user;
  const _PendingUserRow({required this.user});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
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

class _UserCard extends StatelessWidget {
  final _UserData user;
  const _UserCard({required this.user});
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: user.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: user.color.withValues(alpha: 0.3)),
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
                    Text(
                      user.name,
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(label: user.role, color: user.color),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  user.detail,
                  style: TextStyle(color: context.textTertiary, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: user.active ? AppTheme.success : AppTheme.error,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeatRow extends StatelessWidget {
  final String route;
  final int total, filled;
  const _SeatRow({
    required this.route,
    required this.total,
    required this.filled,
  });
  @override
  Widget build(BuildContext context) {
    final available = total - filled;
    final isFull = available == 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 65,
            child: Text(
              route,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: filled / total,
                backgroundColor: context.cardBgElevated,
                valueColor: AlwaysStoppedAnimation(
                  isFull ? AppTheme.error : AppTheme.success,
                ),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            isFull ? 'Full' : '$available seats',
            style: TextStyle(
              color: isFull ? AppTheme.error : AppTheme.success,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
