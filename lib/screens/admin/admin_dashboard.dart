import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';

class AdminDashboard extends StatelessWidget {
  final void Function(int) onNavigate;
  const AdminDashboard({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        children: [
          // ── Header ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.adminEmerald.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin Panel',
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Control Center',
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: context.cardBgElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.inputBorder),
                  ),
                  child: const Center(
                    child: Text('🔔', style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.adminEmerald.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Text('🛡️', style: TextStyle(fontSize: 22)),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // ── Overview stats ─────────────────────────────────
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.6,
                  children: [
                    _AdminStatCard(
                      icon: '🚌',
                      label: 'Active Buses',
                      value: '12',
                      sub: '2 delayed',
                      color: AppTheme.adminEmerald,
                    ),
                    _AdminStatCard(
                      icon: '👨‍🎓',
                      label: 'Students',
                      value: '486',
                      sub: '14 pending',
                      color: AppTheme.info,
                    ),
                    _AdminStatCard(
                      icon: '🗺️',
                      label: 'Routes',
                      value: '18',
                      sub: '3 optimized today',
                      color: AppTheme.purple,
                    ),
                    _AdminStatCard(
                      icon: '💰',
                      label: 'Revenue',
                      value: '₹4.2L',
                      sub: '₹38K pending',
                      color: AppTheme.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Fleet health overview ──────────────────────────
                GlassCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Fleet Health',
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => onNavigate(1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.adminAccent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppTheme.adminAccent.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                'View All',
                                style: TextStyle(
                                  color: AppTheme.adminAccent,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _FleetBar(
                        label: 'Good',
                        count: 9,
                        total: 12,
                        color: AppTheme.success,
                      ),
                      const SizedBox(height: 8),
                      _FleetBar(
                        label: 'Warning',
                        count: 2,
                        total: 12,
                        color: AppTheme.warning,
                      ),
                      const SizedBox(height: 8),
                      _FleetBar(
                        label: 'Critical',
                        count: 1,
                        total: 12,
                        color: AppTheme.error,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Live bus status ────────────────────────────────
                GlassCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Live Bus Status',
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          StatusBadge(
                            label: '● 10 On Route',
                            color: AppTheme.success,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(
                        3,
                        (i) => _BusStatusRow(
                          bus: 'Bus #${42 + i}',
                          route: 'Route ${String.fromCharCode(65 + i)}',
                          status: i == 2 ? 'Delayed' : 'On Time',
                          statusColor: i == 2
                              ? AppTheme.warning
                              : AppTheme.success,
                          students: '${28 + i * 3}',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Pending approvals ──────────────────────────────
                GlassCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Pending Approvals',
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => onNavigate(3),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.adminAccent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppTheme.adminAccent.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                'View All',
                                style: TextStyle(
                                  color: AppTheme.adminAccent,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _ApprovalRow(
                        name: 'Ali Hassan',
                        type: 'Student Registration',
                        icon: '🎓',
                        color: AppTheme.studentAmber,
                      ),
                      _ApprovalRow(
                        name: 'Fatima Khan',
                        type: 'Parent Registration',
                        icon: '👨‍👩‍👧',
                        color: AppTheme.parentPurple,
                      ),
                      _ApprovalRow(
                        name: 'Route C Extension',
                        type: 'Route Change Request',
                        icon: '🗺️',
                        color: AppTheme.info,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Maintenance alerts ─────────────────────────────
                GlassCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Maintenance Alerts',
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _MaintenanceRow(
                        bus: 'Bus #44',
                        issue: 'Oil change overdue by 200 km',
                        severity: 'Critical',
                        color: AppTheme.error,
                      ),
                      _MaintenanceRow(
                        bus: 'Bus #41',
                        issue: 'Tire rotation due in 5 days',
                        severity: 'Warning',
                        color: AppTheme.warning,
                      ),
                      _MaintenanceRow(
                        bus: 'Bus #43',
                        issue: 'Brake inspection scheduled',
                        severity: 'Info',
                        color: AppTheme.info,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Quick actions ──────────────────────────────────
                GlassCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Actions',
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _QuickAction(
                            icon: '🗺️',
                            label: 'Add Route',
                            color: AppTheme.info,
                            onTap: () => onNavigate(2),
                          ),
                          const SizedBox(width: 10),
                          _QuickAction(
                            icon: '👥',
                            label: 'Add User',
                            color: AppTheme.purple,
                            onTap: () => onNavigate(3),
                          ),
                          const SizedBox(width: 10),
                          _QuickAction(
                            icon: '🚌',
                            label: 'Add Bus',
                            color: AppTheme.adminEmerald,
                            onTap: () => onNavigate(1),
                          ),
                          const SizedBox(width: 10),
                          _QuickAction(
                            icon: '📊',
                            label: 'Report',
                            color: AppTheme.warning,
                            onTap: () {},
                          ),
                        ],
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

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _AdminStatCard extends StatelessWidget {
  final String icon, label, value, sub;
  final Color color;
  const _AdminStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      gradient: LinearGradient(
        colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
      ),
      borderColor: color.withOpacity(0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(icon, style: const TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            sub,
            style: TextStyle(color: color.withOpacity(0.8), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _FleetBar extends StatelessWidget {
  final String label;
  final int count, total;
  final Color color;
  const _FleetBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(color: context.textSecondary, fontSize: 12),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: count / total,
              backgroundColor: context.cardBgElevated,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _BusStatusRow extends StatelessWidget {
  final String bus, route, status, students;
  final Color statusColor;
  const _BusStatusRow({
    required this.bus,
    required this.route,
    required this.status,
    required this.statusColor,
    required this.students,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.cardBg),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('🚌', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bus,
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    route,
                    style: TextStyle(color: context.textTertiary, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusBadge(label: status, color: statusColor),
                const SizedBox(height: 4),
                Text(
                  '$students students',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.35),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ApprovalRow extends StatelessWidget {
  final String name, type, icon;
  final Color color;
  const _ApprovalRow({
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.cardBg),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    type,
                    style: TextStyle(color: context.textTertiary, fontSize: 12),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                _SmallBtn(label: '✓', color: AppTheme.success),
                const SizedBox(width: 6),
                _SmallBtn(label: '✕', color: AppTheme.error),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallBtn extends StatelessWidget {
  final String label;
  final Color color;
  const _SmallBtn({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
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

class _MaintenanceRow extends StatelessWidget {
  final String bus, issue, severity;
  final Color color;
  const _MaintenanceRow({
    required this.bus,
    required this.issue,
    required this.severity,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('🔧', style: TextStyle(fontSize: 18)),
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
                        bus,
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(label: severity, color: color),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    issue,
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String icon, label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
