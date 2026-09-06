import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

    return Scaffold(
      body: Container(
        decoration: context.scaffoldBg,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              children: [
                _Header(title: 'Route Management', onBack: widget.onBack),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // ── Route stats (neumorphic) ───────────────
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

                      // ── Route list ──────────────────────────────
                      if (loading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (routes.isEmpty)
                        _EmptyState(
                          onCreateRoute: () => ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(
                            const SnackBar(
                              content: Text('Route creation — coming soon'),
                            ),
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
          ),
        ),
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            onPressed: onBack ?? () => context.pop(),
            style: IconButton.styleFrom(
              backgroundColor: context.cardBgElevated,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: context.inputBorder),
              ),
            ),
            icon: Icon(Icons.arrow_back, color: context.textPrimary, size: 18),
          ),
          const SizedBox(width: 10),
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

/// Neumorphic shell shared by the stat cards and the "Create Route" CTA —
/// two opposing shadows, `context.isDark`-aware, matching the recipe already
/// used elsewhere in this app (student/driver detail empty states, the Fee
/// Management summary card).
class _NeumorphicCard extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final Widget child;
  const _NeumorphicCard({required this.padding, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.45)
                : const Color(0xFFB8BEC8).withValues(alpha: 0.6),
            offset: const Offset(5, 5),
            blurRadius: 12,
          ),
          BoxShadow(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.white.withValues(alpha: 0.9),
            offset: const Offset(-5, -5),
            blurRadius: 12,
          ),
        ],
      ),
      child: child,
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
      child: _NeumorphicCard(
        padding: const EdgeInsets.all(12),
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

/// Professional empty state — a subtle route-path icon over properly sized,
/// muted text, plus a neumorphic "Create Route" CTA so the admin has
/// something to do next rather than a dead end. Uses the theme's own muted
/// color token rather than a fixed `Colors.grey` so it still reads correctly
/// in dark mode.
class _EmptyState extends StatelessWidget {
  final VoidCallback onCreateRoute;
  const _EmptyState({required this.onCreateRoute});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(
            Icons.signpost_outlined,
            size: 48,
            color: context.textTertiary,
          ),
          const SizedBox(height: 12),
          Text(
            'No routes have been created yet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.textTertiary, fontSize: 16),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onCreateRoute,
            child: _NeumorphicCard(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    color: AppTheme.adminAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Create Route',
                    style: TextStyle(
                      color: AppTheme.adminAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
