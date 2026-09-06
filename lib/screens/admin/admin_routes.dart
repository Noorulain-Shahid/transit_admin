import 'dart:async';
import 'package:flutter/material.dart';
import 'package:transit_core/transit_core.dart';
import '../../data/admin_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';

class AdminRoutes extends StatefulWidget {
  final VoidCallback? onBack;
  const AdminRoutes({super.key, this.onBack});

  @override
  State<AdminRoutes> createState() => _AdminRoutesState();
}

class _AdminRoutesState extends State<AdminRoutes> {
  final _repo = AdminRepository.instance;
  List<BusRoute>? _routes;
  List<Bus>? _buses;

  StreamSubscription<List<BusRoute>>? _routesSub;
  StreamSubscription<List<Bus>>? _busesSub;

  static const _colors = [
    AppTheme.success,
    AppTheme.info,
    AppTheme.purple,
    AppTheme.warning,
    AppTheme.driverCyan,
    AppTheme.parentPurple,
  ];

  @override
  void initState() {
    super.initState();
    _routesSub = _repo.watchRoutes().listen(
      (v) => setState(() => _routes = v),
      onError: (e) => debugPrint('[AdminRoutes] routes stream error: $e'),
    );
    _busesSub = _repo.watchBuses().listen(
      (v) => setState(() => _buses = v),
      onError: (e) => debugPrint('[AdminRoutes] buses stream error: $e'),
    );
  }

  @override
  void dispose() {
    _routesSub?.cancel();
    _busesSub?.cancel();
    super.dispose();
  }

  String _busNumberFor(String? busId) {
    if (busId == null) return 'Unassigned';
    final match = (_buses ?? const <Bus>[]).where((b) => b.id == busId);
    return match.isEmpty ? 'Unassigned' : match.first.busNumber;
  }

  @override
  Widget build(BuildContext context) {
    final routes = _routes;
    final loading = routes == null;
    final totalStops = loading
        ? 0
        : routes.fold<int>(0, (s, r) => s + r.stops.length);
    final activeCount = loading
        ? 0
        : routes.where((r) => r.isActive).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        children: [
          _Header(title: 'Route Management', onBack: widget.onBack),
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
                      value: loading ? '…' : '${routes.length}',
                      color: AppTheme.adminEmerald,
                    ),
                    const SizedBox(width: 10),
                    _MiniStat(
                      icon: Icons.check_circle_rounded,
                      label: 'Active',
                      value: loading ? '…' : '$activeCount',
                      color: AppTheme.success,
                    ),
                    const SizedBox(width: 10),
                    _MiniStat(
                      icon: Icons.location_on_rounded,
                      label: 'Stops',
                      value: loading ? '…' : '$totalStops',
                      color: AppTheme.info,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Route list ────────────────────────────────
                if (loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (routes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No routes have been created yet.',
                      style: TextStyle(color: context.textSecondary),
                    ),
                  )
                else
                  ...routes.asMap().entries.map((entry) {
                    final i = entry.key;
                    final r = entry.value;
                    final color = _colors[i % _colors.length];
                    final stops = r.orderedStops;
                    final desc = stops.isEmpty
                        ? 'No stops added yet'
                        : stops.map((s) => s.name).join(' ↔ ');
                    final pickup = stops.isEmpty
                        ? '—'
                        : (stops.first.scheduledTime.isEmpty
                              ? '—'
                              : stops.first.scheduledTime);
                    final drop = stops.isEmpty
                        ? '—'
                        : (stops.last.scheduledTime.isEmpty
                              ? '—'
                              : stops.last.scheduledTime);

                    return Padding(
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
                                    color: color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: color.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '🗺️',
                                      style: TextStyle(fontSize: 20),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        desc,
                                        style: TextStyle(
                                          color: context.textSecondary,
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                StatusBadge(
                                  label: r.isActive ? 'Active' : 'Inactive',
                                  color: r.isActive
                                      ? AppTheme.success
                                      : context.textTertiary,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _RouteDetail(
                                  icon: Icons.location_on_rounded,
                                  label: 'Stops',
                                  value: '${stops.length}',
                                ),
                                _RouteDetail(
                                  icon: Icons.timer_rounded,
                                  label: 'Duration',
                                  value: r.averageDurationMinutes == 0
                                      ? '—'
                                      : '${r.averageDurationMinutes} min',
                                ),
                                _RouteDetail(
                                  icon: Icons.directions_bus_rounded,
                                  label: 'Bus',
                                  value: _busNumberFor(r.busId),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '🌅 Pickup: $pickup',
                                    style: TextStyle(
                                      color: context.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '🌇 Drop: $drop',
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
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets ──────────────────────────────────────────────────────

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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: context.textPrimary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
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
