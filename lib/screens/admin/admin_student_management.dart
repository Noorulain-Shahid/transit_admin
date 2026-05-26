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
    if (_search.isNotEmpty && !s.name.toLowerCase().contains(_search.toLowerCase())) return false;
    if (_filterRoute != 'All' && s.route != _filterRoute) return false;
    if (_filterSub != 'All' && s.subscriptionLabel != _filterSub) return false;
    return true;
  }).toList();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 120),
      child: Column(children: [
        _buildHeader(context),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: [
            _buildSearch(context),
            const SizedBox(height: 10),
            _buildFilters(),
            const SizedBox(height: 12),
            _buildStats(context),
            const SizedBox(height: 14),
            ..._filtered.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _StudentCard(student: s, onTap: () => context.push('/admin/student-detail', extra: s)),
            )),
            if (_filtered.isEmpty) _buildEmpty(context),
          ]),
        ),
      ]),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [
          AppTheme.studentAmber.withValues(alpha: 0.15), Colors.transparent,
        ]),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(gradient: AppTheme.studentGradient, borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.school_rounded, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Student Management', style: TextStyle(color: context.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text('${mockStudents.length} students enrolled', style: TextStyle(color: context.textSecondary, fontSize: 13)),
        ])),
        GestureDetector(
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add student form will open'))),
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(gradient: AppTheme.studentGradient, borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: AppTheme.studentAmber.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
          ),
        ),
      ]),
    );
  }

  Widget _buildSearch(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(4),
      child: TextField(
        onChanged: (v) => setState(() => _search = v),
        style: TextStyle(color: context.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search students...', prefixIcon: Icon(Icons.search_rounded, color: context.textTertiary),
          border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 36,
      child: ListView(scrollDirection: Axis.horizontal, children: [
        _FilterChip(label: 'Route: $_filterRoute', icon: Icons.route_rounded, onTap: () {
          final r = ['All', 'Route A', 'Route B', 'Route C', 'Route D'];
          setState(() => _filterRoute = r[(r.indexOf(_filterRoute) + 1) % r.length]);
        }),
        const SizedBox(width: 8),
        _FilterChip(label: 'Sub: $_filterSub', icon: Icons.credit_card_rounded, onTap: () {
          final s = ['All', 'Active', 'Expired', 'Trial', 'Blocked'];
          setState(() => _filterSub = s[(s.indexOf(_filterSub) + 1) % s.length]);
        }),
      ]),
    );
  }

  Widget _buildStats(BuildContext context) {
    return Row(children: [
      _MiniStat(icon: Icons.people_rounded, label: 'Total', value: '${mockStudents.length}', color: AppTheme.studentAmber),
      const SizedBox(width: 8),
      _MiniStat(icon: Icons.directions_bus_rounded, label: 'On Bus',
        value: '${mockStudents.where((s) => s.status == StudentStatus.onBus).length}', color: AppTheme.success),
      const SizedBox(width: 8),
      _MiniStat(icon: Icons.warning_amber_rounded, label: 'Missed',
        value: '${mockStudents.where((s) => s.status == StudentStatus.missed).length}', color: AppTheme.warning),
    ]);
  }

  Widget _buildEmpty(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(children: [
        Icon(Icons.search_off_rounded, color: context.textTertiary, size: 48),
        const SizedBox(height: 12),
        Text('No students match your filters', style: TextStyle(color: context.textSecondary, fontSize: 14)),
      ]),
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
    return GlassCard(onTap: onTap, padding: const EdgeInsets.all(14), child: Column(children: [
      Row(children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(color: AppTheme.studentAmber.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.studentAmber.withValues(alpha: 0.2))),
          child: const Center(child: Text('🎓', style: TextStyle(fontSize: 22))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(student.name, style: TextStyle(color: context.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text('${student.grade} • Parent: ${student.parentName}', style: TextStyle(color: context.textSecondary, fontSize: 12)),
        ])),
        Icon(Icons.chevron_right_rounded, color: context.textTertiary),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        _InfoPill(icon: Icons.route_rounded, label: student.route, color: AppTheme.info),
        const SizedBox(width: 6),
        _InfoPill(icon: Icons.directions_bus_rounded, label: student.driver, color: AppTheme.driverCyan),
        const Spacer(),
        StatusBadge(label: student.statusLabel, color: student.statusColor),
      ]),
      const SizedBox(height: 6),
      Row(children: [
        _InfoPill(icon: Icons.schedule_rounded, label: 'Pickup: ${student.pickupTime}', color: AppTheme.adminEmerald),
        const Spacer(),
        StatusBadge(label: '💳 ${student.subscriptionLabel}', color: student.subscriptionColor),
      ]),
    ]));
  }
}

// ─── Shared sub-widgets ─────────────────────────────────────────────────────
class _InfoPill extends StatelessWidget {
  final IconData icon; final String label; final Color color;
  const _InfoPill({required this.icon, required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color), const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon; final String label, value; final Color color;
  const _MiniStat({required this.icon, required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Expanded(child: GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      gradient: LinearGradient(colors: [color.withValues(alpha: 0.12), color.withValues(alpha: 0.04)]),
      borderColor: color.withValues(alpha: 0.18),
      child: Column(children: [
        Icon(icon, color: color, size: 20), const SizedBox(height: 4),
        Text(value, style: TextStyle(color: context.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
        Text(label, style: TextStyle(color: context.textSecondary, fontSize: 10)),
      ]),
    ));
  }
}

class _FilterChip extends StatelessWidget {
  final String label; final IconData icon; final VoidCallback onTap;
  const _FilterChip({required this.label, required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: context.cardBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: context.surfaceBorder)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: AppTheme.studentAmber), const SizedBox(width: 6),
        Text(label, style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(width: 4), Icon(Icons.unfold_more_rounded, size: 14, color: context.textTertiary),
      ]),
    ));
  }
}

// ─── Mock Data ──────────────────────────────────────────────────────────────
final mockStudents = [
  const StudentRecord(id: 'stu_1', name: 'Noorulain Shahid', parentName: 'Shahid Ali', route: 'Route A', driver: 'Mike Johnson',
    status: StudentStatus.onBus, subscriptionStatus: SubscriptionStatus.active, grade: 'Grade 5', pickupTime: '07:10 AM', dropTime: '02:30 PM',
    pickupLocation: 'North Colony Stop #2', dropLocation: 'Lincoln Elementary'),
  const StudentRecord(id: 'stu_2', name: 'Emma Watson', parentName: 'Sarah Ahmed', route: 'Route B', driver: 'Ahmed Ali',
    status: StudentStatus.onBus, subscriptionStatus: SubscriptionStatus.active, grade: 'Grade 7', pickupTime: '07:25 AM', dropTime: '02:45 PM',
    pickupLocation: 'Civic Center Stop', dropLocation: 'Maple School'),
  const StudentRecord(id: 'stu_3', name: 'Ali Hassan', parentName: 'Hassan Raza', route: 'Route A', driver: 'Mike Johnson',
    status: StudentStatus.missed, subscriptionStatus: SubscriptionStatus.active, grade: 'Grade 8', pickupTime: '07:15 AM', dropTime: '02:35 PM',
    pickupLocation: 'East Wing Stop', dropLocation: 'Lincoln Elementary'),
  const StudentRecord(id: 'stu_4', name: 'Zara Khan', parentName: 'Fatima Khan', route: 'Route C', driver: 'Ravi Kumar',
    status: StudentStatus.inactive, subscriptionStatus: SubscriptionStatus.expired, grade: 'Grade 6', pickupTime: '07:30 AM', dropTime: '02:50 PM',
    pickupLocation: 'West Town Stop', dropLocation: 'City School'),
  const StudentRecord(id: 'stu_5', name: 'Haya Shahid', parentName: 'Shahid Ali', route: 'Route A', driver: 'Mike Johnson',
    status: StudentStatus.onBus, subscriptionStatus: SubscriptionStatus.active, grade: 'Grade 3', pickupTime: '07:10 AM', dropTime: '01:30 PM',
    pickupLocation: 'North Colony Stop #2', dropLocation: 'Lincoln Elementary'),
  const StudentRecord(id: 'stu_6', name: 'Omar Farooq', parentName: 'Farooq Ahmed', route: 'Route D', driver: 'Bilal Shah',
    status: StudentStatus.onBus, subscriptionStatus: SubscriptionStatus.trial, grade: 'Grade 4', pickupTime: '07:20 AM', dropTime: '02:00 PM',
    pickupLocation: 'Model Town Stop', dropLocation: 'National School'),
];
