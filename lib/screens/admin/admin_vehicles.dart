import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';

class AdminVehicles extends StatelessWidget {
  final VoidCallback? onBack;
  const AdminVehicles({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────
          _Header(title: 'Fleet Management', onBack: onBack),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // ── Summary cards ─────────────────────────────
                Row(
                  children: [
                    _MiniStat(
                      icon: Icons.directions_bus_rounded,
                      label: 'Total',
                      value: '12',
                      color: AppTheme.adminEmerald,
                    ),
                    const SizedBox(width: 10),
                    _MiniStat(
                      icon: Icons.check_circle_rounded,
                      label: 'Active',
                      value: '10',
                      color: AppTheme.success,
                    ),
                    const SizedBox(width: 10),
                    _MiniStat(
                      icon: Icons.build_circle_rounded,
                      label: 'Service',
                      value: '2',
                      color: AppTheme.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Vehicle list ──────────────────────────────
                ..._vehicles.map(
                  (v) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      gradient: LinearGradient(
                        colors: [
                          v.healthColor.withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                      ),
                      borderColor: v.healthColor.withValues(alpha: 0.15),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: v.healthColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: v.healthColor.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: const Center(
                                  child: Text(
                                    '🚌',
                                    style: TextStyle(fontSize: 24),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          v.name,
                                          style: TextStyle(
                                            color: context.textPrimary,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        StatusBadge(
                                          label: v.health,
                                          color: v.healthColor,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${v.route} · Driver: ${v.driver}',
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
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _VehicleInfo(
                                icon: Icons.calendar_today_rounded,
                                label: 'Last Service',
                                value: v.lastService,
                              ),
                              _VehicleInfo(
                                icon: Icons.star_rounded,
                                label: 'Mileage',
                                value: v.mileage,
                              ),
                              _VehicleInfo(
                                icon: Icons.airline_seat_recline_normal_rounded,
                                label: 'Capacity',
                                value: v.capacity,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Maintenance history ───────────────────────
                GlassCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Maintenance History',
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _MaintRow(
                        bus: 'Bus #42',
                        task: 'Oil Change',
                        date: 'Feb 15',
                        cost: '₨2,500',
                      ),
                      _MaintRow(
                        bus: 'Bus #43',
                        task: 'Brake Pads Replaced',
                        date: 'Feb 10',
                        cost: '₨4,800',
                      ),
                      _MaintRow(
                        bus: 'Bus #44',
                        task: 'AC Repair',
                        date: 'Feb 05',
                        cost: '₨3,200',
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

final _vehicles = [
  _Vehicle(
    'Bus #42',
    'Route A',
    'Mike Johnson',
    'Good',
    AppTheme.success,
    'Feb 15',
    '45,230 km',
    '40',
  ),
  _Vehicle(
    'Bus #43',
    'Route B',
    'Ahmed Ali',
    'Good',
    AppTheme.success,
    'Feb 10',
    '38,100 km',
    '35',
  ),
  _Vehicle(
    'Bus #44',
    'Route C',
    'Ravi Kumar',
    'Critical',
    AppTheme.error,
    'Jan 28',
    '52,400 km',
    '40',
  ),
  _Vehicle(
    'Bus #45',
    'Route D',
    'Sarah Lee',
    'Warning',
    AppTheme.warning,
    'Feb 02',
    '41,800 km',
    '38',
  ),
];

class _Vehicle {
  final String name, route, driver, health, lastService, mileage, capacity;
  final Color healthColor;
  const _Vehicle(
    this.name,
    this.route,
    this.driver,
    this.health,
    this.healthColor,
    this.lastService,
    this.mileage,
    this.capacity,
  );
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

class _VehicleInfo extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _VehicleInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: context.textPrimary),
              const SizedBox(width: 6),
              Text(
                value,
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _MaintRow extends StatelessWidget {
  final String bus, task, date, cost;
  const _MaintRow({
    required this.bus,
    required this.task,
    required this.date,
    required this.cost,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text('🔧', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$bus · $task',
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    date,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              cost,
              style: TextStyle(
                color: AppTheme.adminAccent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
