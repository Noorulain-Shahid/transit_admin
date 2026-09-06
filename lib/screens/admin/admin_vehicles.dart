import 'dart:async';
import 'package:flutter/material.dart';
import 'package:transit_core/transit_core.dart';
import '../../data/admin_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';

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

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────
          _Header(title: 'Fleet Management', onBack: widget.onBack),
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

                // ── Vehicle list ──────────────────────────────
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
                      child: GlassCard(
                        padding: const EdgeInsets.all(16),
                        gradient: LinearGradient(
                          colors: [
                            healthColor.withValues(alpha: 0.08),
                            Colors.transparent,
                          ],
                        ),
                        borderColor: healthColor.withValues(alpha: 0.15),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: healthColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(14),
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
                                          Text(
                                            bus.busNumber,
                                            style: TextStyle(
                                              color: context.textPrimary,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          StatusBadge(
                                            label: health,
                                            color: healthColor,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${_routeNameFor(bus.routeId)} · Driver: ${_driverNameFor(bus.driverId)}',
                                        style: TextStyle(
                                          color: context.textSecondary,
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
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
                                  icon: Icons.airline_seat_recline_normal_rounded,
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
