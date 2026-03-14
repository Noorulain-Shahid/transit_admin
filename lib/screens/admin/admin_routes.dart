import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';

class AdminRoutes extends StatelessWidget {
  final VoidCallback onBack;
  const AdminRoutes({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        children: [
          _Header(title: 'Route Management', onBack: onBack),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // ── Route stats ────────────────────────────────
                Row(
                  children: [
                    _MiniStat(
                      icon: Icons.map_rounded,
                      label: 'Total Routes',
                      value: '18',
                      color: AppTheme.adminEmerald,
                    ),
                    const SizedBox(width: 10),
                    _MiniStat(
                      icon: Icons.star_rounded,
                      label: 'AI Optimized',
                      value: '6',
                      color: AppTheme.purple,
                    ),
                    const SizedBox(width: 10),
                    _MiniStat(
                      icon: Icons.location_on_rounded,
                      label: 'Stops',
                      value: '84',
                      color: AppTheme.info,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── AI optimization card ──────────────────────
                GlassCard(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.purple.withValues(alpha: 0.15),
                      AppTheme.info.withValues(alpha: 0.08),
                    ],
                  ),
                  borderColor: AppTheme.purple.withValues(alpha: 0.25),
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: AppTheme.mainGradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text('🤖', style: TextStyle(fontSize: 26)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Route Optimization',
                              style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '3 routes can be optimized to save 22 min total',
                              style: TextStyle(
                                color: context.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppTheme.mainGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Optimize',
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Route list ────────────────────────────────
                ..._routes.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: r.color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: r.color.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    r.icon,
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.name,
                                      style: TextStyle(
                                        color: context.textPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      r.desc,
                                      style: TextStyle(
                                        color: context.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              StatusBadge(
                                label: r.status,
                                color: r.statusColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Route details row
                          Row(
                            children: [
                              _RouteDetail(
                                icon: Icons.location_on_rounded,
                                label: 'Stops',
                                value: r.stops,
                              ),
                              _RouteDetail(
                                icon: Icons.star_rounded,
                                label: 'Duration',
                                value: r.duration,
                              ),
                              _RouteDetail(
                                icon: Icons.star_rounded,
                                label: 'Distance',
                                value: r.distance,
                              ),
                              _RouteDetail(
                                icon: Icons.directions_bus_rounded,
                                label: 'Bus',
                                value: r.bus,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Pickup/drop times
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '🌅 Pickup: ${r.pickupTime}',
                                  style: TextStyle(
                                    color: context.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '🌇 Drop: ${r.dropTime}',
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

final _routes = [
  _Route(
    'Route A – North Zone',
    'Lincoln Elem ↔ Pine Road ↔ Oak Street',
    '🗺️',
    AppTheme.success,
    'Active',
    AppTheme.success,
    '8',
    '35 min',
    '12.4 km',
    '#42',
    '07:00 AM',
    '03:15 PM',
  ),
  _Route(
    'Route B – South Zone',
    'Maple School ↔ Cedar Ave ↔ Elm Drive',
    '🗺️',
    AppTheme.info,
    'Active',
    AppTheme.success,
    '6',
    '28 min',
    '9.8 km',
    '#43',
    '07:15 AM',
    '03:30 PM',
  ),
  _Route(
    'Route C – East Zone',
    'Sunrise Academy ↔ Park Rd ↔ Hill View',
    '🗺️',
    AppTheme.purple,
    'Optimizing',
    AppTheme.warning,
    '10',
    '42 min',
    '15.2 km',
    '#44',
    '06:45 AM',
    '03:00 PM',
  ),
  _Route(
    'Route D – West Zone',
    'Green Valley ↔ Lake Side ↔ River Bend',
    '🗺️',
    AppTheme.warning,
    'Draft',
    AppTheme.info,
    '5',
    '25 min',
    '8.1 km',
    '#45',
    '07:30 AM',
    '03:45 PM',
  ),
];

class _Route {
  final String name, desc, icon;
  final Color color;
  final String status;
  final Color statusColor;
  final String stops, duration, distance, bus, pickupTime, dropTime;
  const _Route(
    this.name,
    this.desc,
    this.icon,
    this.color,
    this.status,
    this.statusColor,
    this.stops,
    this.duration,
    this.distance,
    this.bus,
    this.pickupTime,
    this.dropTime,
  );
}

// ── Shared widgets ──────────────────────────────────────────────────────

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
              style: TextStyle(color: context.textSecondary, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteDetail extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _RouteDetail({
    required this.icon,
    required this.label,
    required this.value,
  });
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$icon $value',
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
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
