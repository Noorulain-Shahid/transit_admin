import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import 'admin_user_models.dart';

class AdminStudentManagement extends StatefulWidget {
  const AdminStudentManagement({super.key});
  @override
  State<AdminStudentManagement> createState() => _AdminStudentManagementState();
}

class _AdminStudentManagementState extends State<AdminStudentManagement> {
  String _search = '';
  String _filterRoute = 'All';
  String _filterSub = 'All';

  List<StudentRecord> get _filtered => mockStudents.where((s) {
    if (_search.isNotEmpty &&
        !s.name.toLowerCase().contains(_search.toLowerCase()))
      return false;
    if (_filterRoute != 'All' && s.route != _filterRoute) return false;
    if (_filterSub != 'All' && s.subscriptionLabel != _filterSub) return false;
    return true;
  }).toList();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 120),
      child: Column(
        children: [
          _buildHeader(context),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildSearch(context),
                const SizedBox(height: 10),
                _buildFilters(),
                const SizedBox(height: 12),
                _buildStats(context),
                const SizedBox(height: 14),
                ..._filtered.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _StudentCard(
                      student: s,
                      onTap: () =>
                          context.push('/admin/student-detail', extra: s),
                    ),
                  ),
                ),
                if (_filtered.isEmpty) _buildEmpty(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.studentAmber.withValues(alpha: 0.15),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppTheme.studentGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student Management',
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${mockStudents.length} students enrolled',
                  style: TextStyle(color: context.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(4),
      child: TextField(
        onChanged: (v) => setState(() => _search = v),
        style: TextStyle(color: context.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search students...',
          prefixIcon: Icon(Icons.search_rounded, color: context.textTertiary),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _FilterChip(
            label: 'Route: $_filterRoute',
            icon: Icons.route_rounded,
            onTap: () {
              final r = ['All', 'Route A', 'Route B', 'Route C', 'Route D'];
              setState(
                () =>
                    _filterRoute = r[(r.indexOf(_filterRoute) + 1) % r.length],
              );
            },
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Sub: $_filterSub',
            icon: Icons.credit_card_rounded,
            onTap: () {
              final s = ['All', 'Active', 'Expired', 'Trial', 'Blocked'];
              setState(
                () => _filterSub = s[(s.indexOf(_filterSub) + 1) % s.length],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context) {
    return Row(
      children: [
        _MiniStat(
          icon: Icons.people_rounded,
          label: 'Total',
          value: '${mockStudents.length}',
          color: AppTheme.studentAmber,
        ),
        const SizedBox(width: 8),
        _MiniStat(
          icon: Icons.directions_bus_rounded,
          label: 'On Bus',
          value:
              '${mockStudents.where((s) => s.status == StudentStatus.onBus).length}',
          color: AppTheme.success,
        ),
        const SizedBox(width: 8),
        _MiniStat(
          icon: Icons.warning_amber_rounded,
          label: 'Missed',
          value:
              '${mockStudents.where((s) => s.status == StudentStatus.missed).length}',
          color: AppTheme.warning,
        ),
      ],
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, color: context.textTertiary, size: 48),
          const SizedBox(height: 12),
          Text(
            'No students match your filters',
            style: TextStyle(color: context.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ─── Student Card ────────────────────────────────────────────────────────────
class _StudentCard extends StatelessWidget {
  final StudentRecord student;
  final VoidCallback onTap;
  const _StudentCard({required this.student, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppTheme.studentAmber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.studentAmber.withValues(alpha: 0.2),
                  ),
                ),
                child: const Center(
                  child: Text('🎓', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      student.university != null
                          ? '${student.university} • ${student.department ?? ''} • ${student.studentId ?? ''}'
                          : '${student.grade} • Parent: ${student.parentName}',
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: context.textTertiary),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _InfoPill(
                icon: Icons.route_rounded,
                label: student.route,
                color: AppTheme.info,
              ),
              const SizedBox(width: 6),
              _InfoPill(
                icon: Icons.directions_bus_rounded,
                label: student.driver,
                color: AppTheme.driverCyan,
              ),
              const Spacer(),
              StatusBadge(
                label: student.statusLabel,
                color: student.statusColor,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              student.university == null
                  ? _InfoPill(
                      icon: Icons.schedule_rounded,
                      label: 'Pickup: ${student.pickupTime}',
                      color: AppTheme.adminEmerald,
                    )
                  : _InfoPill(
                      icon: Icons.school_rounded,
                      label:
                          '${student.program ?? ''}${student.year != null ? ' · ${student.year}' : ''}',
                      color: AppTheme.purple,
                    ),
              const Spacer(),
              StatusBadge(
                label: '💳 ${student.subscriptionLabel}',
                color: student.subscriptionColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Shared sub-widgets ─────────────────────────────────────────────────────
class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
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
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.12),
            color.withValues(alpha: 0.04),
          ],
        ),
        borderColor: color.withValues(alpha: 0.18),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
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
              style: TextStyle(color: context.textSecondary, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.surfaceBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppTheme.studentAmber),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.unfold_more_rounded,
              size: 14,
              color: context.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Mock Data ──────────────────────────────────────────────────────────────
final mockStudents = [
  const StudentRecord(
    id: 'stu_u1',
    name: 'Ayesha Khan',
    parentName: 'Nadia Khan',
    route: 'Route A',
    driver: 'Mike Johnson',
    status: StudentStatus.onBus,
    subscriptionStatus: SubscriptionStatus.active,
    grade: 'N/A',
    pickupTime: '08:10 AM',
    dropTime: '02:00 PM',
    pickupLocation: 'City Hostel',
    dropLocation: 'City University',
    university: 'City University',
    department: 'Computer Science',
    studentId: 'CU-24-105',
    program: 'BS Computer Science',
    year: '2nd Year',
    overdueDays: 0,
    subscriptionPlan: SubscriptionPlan.premium,
  ),
  const StudentRecord(
    id: 'stu_u2',
    name: 'Ahmed Raza',
    parentName: 'Shahid Ali',
    route: 'Route B',
    driver: 'Ahmed Ali',
    status: StudentStatus.onBus,
    subscriptionStatus: SubscriptionStatus.active,
    grade: 'N/A',
    pickupTime: '08:25 AM',
    dropTime: '03:10 PM',
    pickupLocation: 'North Hostel',
    dropLocation: 'National Institute of Technology',
    university: 'National Institute of Technology',
    department: 'Mechanical Engineering',
    studentId: 'NIT-UG-221',
    program: 'BEng Mechanical',
    year: '3rd Year',
    overdueDays: 2,
    subscriptionPlan: SubscriptionPlan.family,
  ),
  const StudentRecord(
    id: 'stu_u3',
    name: 'Mariam Shah',
    parentName: 'Farah Shah',
    route: 'Route C',
    driver: 'Ravi Kumar',
    status: StudentStatus.missed,
    subscriptionStatus: SubscriptionStatus.trial,
    grade: 'N/A',
    pickupTime: '07:55 AM',
    dropTime: '01:50 PM',
    pickupLocation: 'East Hostel',
    dropLocation: 'Women University',
    university: 'Women University',
    department: 'Business Administration',
    studentId: 'WU-BBA-018',
    program: 'BBA',
    year: '1st Year',
    overdueDays: 6,
    subscriptionPlan: SubscriptionPlan.free,
  ),
  const StudentRecord(
    id: 'stu_u4',
    name: 'Zain Malik',
    parentName: 'Fatima Malik',
    route: 'Route D',
    driver: 'Bilal Shah',
    status: StudentStatus.inactive,
    subscriptionStatus: SubscriptionStatus.expired,
    grade: 'N/A',
    pickupTime: '08:15 AM',
    dropTime: '02:45 PM',
    pickupLocation: 'Model Town Residence',
    dropLocation: 'Institute of Technology',
    university: 'Institute of Technology',
    department: 'Software Engineering',
    studentId: 'IOT-SE-404',
    program: 'BS Software Engineering',
    year: '4th Year',
    overdueDays: 14,
    subscriptionPlan: SubscriptionPlan.premium,
  ),
];
