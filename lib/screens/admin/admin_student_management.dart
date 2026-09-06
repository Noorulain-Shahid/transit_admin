import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transit_core/transit_core.dart';
import '../../data/admin_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';

String subscriptionStatusLabel(SubscriptionStatus s) => switch (s) {
  SubscriptionStatus.active => 'Active',
  SubscriptionStatus.trial => 'Trial',
  SubscriptionStatus.gracePeriod => 'Grace Period',
  SubscriptionStatus.expired => 'Expired',
  SubscriptionStatus.suspended => 'Suspended',
  SubscriptionStatus.cancelled => 'Cancelled',
};

Color subscriptionStatusColor(SubscriptionStatus s) => switch (s) {
  SubscriptionStatus.active => const Color(0xFF10B981),
  SubscriptionStatus.trial => const Color(0xFF3B82F6),
  SubscriptionStatus.gracePeriod => const Color(0xFFF59E0B),
  SubscriptionStatus.expired => const Color(0xFFEF4444),
  SubscriptionStatus.suspended => const Color(0xFFF59E0B),
  SubscriptionStatus.cancelled => const Color(0xFFEF4444),
};

class AdminStudentManagement extends StatefulWidget {
  const AdminStudentManagement({super.key});
  @override
  State<AdminStudentManagement> createState() => _AdminStudentManagementState();
}

class _AdminStudentManagementState extends State<AdminStudentManagement> {
  String _search = '';

  List<Student> _filtered(List<Student> students) => students
      .where(
        (s) =>
            _search.isEmpty ||
            s.name.toLowerCase().contains(_search.toLowerCase()),
      )
      .toList();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Student>>(
      stream: AdminRepository.instance.watchStudents(),
      builder: (context, snap) {
        final students = snap.data ?? const <Student>[];
        final filtered = _filtered(students);
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 120),
          child: Column(
            children: [
              _buildHeader(context, students.length),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildSearch(context),
                    const SizedBox(height: 10),
                    _buildStats(context, students),
                    const SizedBox(height: 14),
                    if (!snap.hasData)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else ...[
                      ...filtered.map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _StudentCard(
                            student: s,
                            onTap: () => context.push(
                              '/admin/student-detail',
                              extra: s.id,
                            ),
                          ),
                        ),
                      ),
                      if (filtered.isEmpty) _buildEmpty(context),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, int total) {
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
                  '$total students enrolled',
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

  Widget _buildStats(BuildContext context, List<Student> students) {
    return Row(
      children: [
        _MiniStat(
          icon: Icons.people_rounded,
          label: 'Total',
          value: '${students.length}',
          color: AppTheme.studentAmber,
        ),
        const SizedBox(width: 8),
        _MiniStat(
          icon: Icons.directions_bus_rounded,
          label: 'With Driver',
          value:
              '${students.where((s) => (s.driverId ?? '').isNotEmpty).length}',
          color: AppTheme.success,
        ),
        const SizedBox(width: 8),
        _MiniStat(
          icon: Icons.block_rounded,
          label: 'Suspended',
          value: '${students.where((s) => s.isTransportSuspended).length}',
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
            'No students match your search',
            style: TextStyle(color: context.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ─── Student Card ────────────────────────────────────────────────────────────
class _StudentCard extends StatelessWidget {
  final Student student;
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
                      '${student.grade.isEmpty ? student.instituteType : student.grade} • ${student.school}',
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
                icon: Icons.directions_bus_rounded,
                label: (student.driverId ?? '').isEmpty
                    ? 'No driver'
                    : 'Assigned',
                color: AppTheme.driverCyan,
              ),
              const Spacer(),
              StatusBadge(
                label: student.isTransportSuspended ? 'Suspended' : 'Active',
                color: student.isTransportSuspended
                    ? AppTheme.warning
                    : AppTheme.success,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Spacer(),
              StatusBadge(
                label:
                    '💳 ${subscriptionStatusLabel(student.subscriptionStatus)}',
                color: subscriptionStatusColor(student.subscriptionStatus),
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
