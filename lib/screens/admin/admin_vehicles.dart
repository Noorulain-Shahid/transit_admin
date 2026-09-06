import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transit_core/transit_core.dart';
import '../../data/admin_repository.dart';
import '../../theme/app_theme.dart';

class AdminVehicles extends StatefulWidget {
  final VoidCallback? onBack;
  const AdminVehicles({super.key, this.onBack});

  @override
  State<AdminVehicles> createState() => _AdminVehiclesState();
}

class _AdminVehiclesState extends State<AdminVehicles> {
  final _repo = AdminRepository.instance;
  List<Bus>? _buses;
  List<BusRoute>? _routes;
  List<Driver>? _drivers;

  StreamSubscription<List<Bus>>? _busesSub;
  StreamSubscription<List<BusRoute>>? _routesSub;
  StreamSubscription<List<Driver>>? _driversSub;

  @override
  void initState() {
    super.initState();
    _busesSub = _repo.watchBuses().listen(
      (v) => setState(() => _buses = v),
      onError: (e) => debugPrint('[AdminVehicles] buses stream error: $e'),
    );
    _routesSub = _repo.watchRoutes().listen(
      (v) => setState(() => _routes = v),
      onError: (e) => debugPrint('[AdminVehicles] routes stream error: $e'),
    );
    _driversSub = _repo.watchDrivers().listen(
      (v) => setState(() => _drivers = v),
      onError: (e) => debugPrint('[AdminVehicles] drivers stream error: $e'),
    );
  }

  @override
  void dispose() {
    _busesSub?.cancel();
    _routesSub?.cancel();
    _driversSub?.cancel();
    super.dispose();
  }

  String _routeNameFor(String? routeId) {
    if (routeId == null) return 'Unassigned route';
    final match = (_routes ?? const <BusRoute>[]).where(
      (r) => r.id == routeId,
    );
    return match.isEmpty ? 'Unassigned route' : match.first.name;
  }

  String _driverNameFor(String? driverId) {
    if (driverId == null) return 'No driver';
    final match = (_drivers ?? const <Driver>[]).where(
      (d) => d.id == driverId,
    );
    return match.isEmpty ? 'No driver' : match.first.name;
  }

  (String, Color) _healthOf(Bus bus) {
    if (bus.needsMaintenance) return ('Critical', AppTheme.error);
    if (bus.needsInsuranceRenewal) return ('Warning', AppTheme.warning);
    if (bus.status == VehicleStatus.outOfService) {
      return ('Out of Service', AppTheme.error);
    }
    return ('Good', AppTheme.success);
  }

  @override
  Widget build(BuildContext context) {
    final buses = _buses;
    final loading = buses == null;
    final activeCount = loading
        ? 0
        : buses.where((b) => b.status == VehicleStatus.active).length;
    final serviceCount = loading
        ? 0
        : buses.where((b) => b.status == VehicleStatus.maintenance).length;

    return Scaffold(
      body: Container(
        decoration: context.scaffoldBg,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              children: [
                // ── Header ──────────────────────────────────────
                _Header(title: 'Vehicle Management', onBack: widget.onBack),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // ── Summary cards (neumorphic) ─────────────
                      Row(
                        children: [
                          _MiniStat(
                            icon: Icons.directions_bus_rounded,
                            label: 'Total',
                            value: loading ? '…' : '${buses.length}',
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
                            icon: Icons.build_circle_rounded,
                            label: 'Service',
                            value: loading ? '…' : '$serviceCount',
                            color: AppTheme.warning,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Vehicle list ────────────────────────────
                      if (loading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (buses.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'No vehicles have been registered yet.',
                            style: TextStyle(color: context.textSecondary),
                          ),
                        )
                      else
                        ...buses.map((bus) {
                          final (health, healthColor) = _healthOf(bus);
                          final nextService = bus.nextMaintenanceDate;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _NeumorphicCard(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: healthColor.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border: Border.all(
                                            color: healthColor.withValues(
                                              alpha: 0.3,
                                            ),
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    bus.busNumber,
                                                    style: TextStyle(
                                                      color:
                                                          context.textPrimary,
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                _HealthChip(
                                                  label: health,
                                                  color: healthColor,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              _routeNameFor(bus.routeId),
                                              style: TextStyle(
                                                color: context.textSecondary,
                                                fontSize: 12,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              'Driver: ${_driverNameFor(bus.driverId)}',
                                              style: TextStyle(
                                                color: context.textTertiary,
                                                fontSize: 11,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _VehicleInfo(
                                        icon: Icons.calendar_today_rounded,
                                        label: 'Next Service',
                                        value: nextService == null
                                            ? 'Not scheduled'
                                            : '${nextService.day}/${nextService.month}/${nextService.year}',
                                      ),
                                      _VehicleInfo(
                                        icon: Icons.speed_rounded,
                                        label: 'Mileage',
                                        value:
                                            '${bus.currentMileage.toStringAsFixed(0)} km',
                                      ),
                                      _VehicleInfo(
                                        icon: Icons
                                            .airline_seat_recline_normal_rounded,
                                        label: 'Capacity',
                                        value: '${bus.capacity}',
                                      ),
                                    ],
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

/// Neumorphic shell (two opposing shadows, `context.isDark`-aware) shared by
/// the stat cards and the vehicle list card — same recipe already used
/// elsewhere in this app (Fee Management/Route Management summary cards,
/// the student/driver detail empty states).
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
              style: TextStyle(color: context.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

/// Solid, high-contrast status chip for the vehicle card — deliberately not
/// the shared `StatusBadge` (a translucent-tint style used app-wide, e.g. on
/// Fee Management/Route Management), since this task specifically asked for
/// a solid-fill chip (colored background, white text) for vehicle health.
class _HealthChip extends StatelessWidget {
  final String label;
  final Color color;
  const _HealthChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
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
    return Flexible(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: context.textPrimary),
              const SizedBox(width: 6),
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
            style: TextStyle(color: context.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
