import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transit_core/transit_core.dart';
import '../../data/admin_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';

const _statusFilters = [
  'All',
  'Pending',
  'Online',
  'Offline',
  'On Trip',
  'Suspended',
];

bool _matchesFilter(Driver d, String filter) => switch (filter) {
  'Pending' => d.status == DriverStatus.pendingVerification,
  'Online' => d.status == DriverStatus.online,
  'Offline' => d.status == DriverStatus.offline,
  'On Trip' => d.status == DriverStatus.onTrip,
  'Suspended' => d.status == DriverStatus.suspended,
  _ => true,
};

String driverStatusLabel(DriverStatus status) => switch (status) {
  DriverStatus.online => 'Online',
  DriverStatus.offline => 'Offline',
  DriverStatus.onTrip => 'On Trip',
  DriverStatus.suspended => 'Suspended',
  DriverStatus.pendingVerification => 'Pending Verification',
};

Color driverStatusColor(DriverStatus status) => switch (status) {
  DriverStatus.online => const Color(0xFF10B981),
  DriverStatus.offline => const Color(0xFF94A3B8),
  DriverStatus.onTrip => const Color(0xFF3B82F6),
  DriverStatus.suspended => const Color(0xFFEF4444),
  DriverStatus.pendingVerification => const Color(0xFFF59E0B),
};

class AdminDriverManagement extends StatefulWidget {
  const AdminDriverManagement({super.key});
  @override
  State<AdminDriverManagement> createState() => _AdminDriverManagementState();
}

class _AdminDriverManagementState extends State<AdminDriverManagement> {
  String _search = '';
  String _filterStatus = 'All';

  List<Driver> _filtered(List<Driver> drivers) => drivers.where((d) {
    if (_search.isNotEmpty &&
        !d.name.toLowerCase().contains(_search.toLowerCase())) {
      return false;
    }
    return _matchesFilter(d, _filterStatus);
  }).toList();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Driver>>(
      stream: AdminRepository.instance.watchDrivers(),
      builder: (context, snap) {
        final drivers = snap.data ?? const <Driver>[];
        final filtered = _filtered(drivers);
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 120),
          child: Column(
            children: [
              _buildHeader(context, drivers.length),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildSearch(context),
                    const SizedBox(height: 10),
                    _buildFilters(),
                    const SizedBox(height: 12),
                    _buildStats(context, drivers),
                    const SizedBox(height: 14),
                    if (!snap.hasData)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else ...[
                      ...filtered.map(
                        (d) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _DriverCard(
                            driver: d,
                            onTap: () => context.push(
                              '/admin/driver-detail',
                              extra: d.id,
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
            AppTheme.driverCyan.withValues(alpha: 0.15),
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
              gradient: AppTheme.driverGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.directions_bus_rounded,
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
                  'Driver Management',
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$total drivers registered',
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
          hintText: 'Search drivers...',
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
            label: 'Status: $_filterStatus',
            icon: Icons.circle,
            color: AppTheme.driverCyan,
            onTap: () {
              setState(
                () => _filterStatus =
                    _statusFilters[(_statusFilters.indexOf(_filterStatus) + 1) %
                        _statusFilters.length],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context, List<Driver> drivers) {
    return Row(
      children: [
        _MiniStat(
          icon: Icons.people_rounded,
          label: 'Total',
          value: '${drivers.length}',
          color: AppTheme.driverCyan,
        ),
        const SizedBox(width: 8),
        _MiniStat(
          icon: Icons.hourglass_top_rounded,
          label: 'Pending',
          value:
              '${drivers.where((d) => d.status == DriverStatus.pendingVerification).length}',
          color: const Color(0xFFF59E0B),
        ),
        const SizedBox(width: 8),
        _MiniStat(
          icon: Icons.wifi_off_rounded,
          label: 'Suspended',
          value:
              '${drivers.where((d) => d.status == DriverStatus.suspended).length}',
          color: const Color(0xFFEF4444),
        ),
      ],
    );
  }

  Widget _buildEmpty(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40),
    child: Column(
      children: [
        Icon(Icons.search_off_rounded, color: context.textTertiary, size: 48),
        const SizedBox(height: 12),
        Text(
          'No drivers match your filters',
          style: TextStyle(color: context.textSecondary, fontSize: 14),
        ),
      ],
    ),
  );
}

// ─── Driver Card ─────────────────────────────────────────────────────────────
class _DriverCard extends StatelessWidget {
  final Driver driver;
  final VoidCallback onTap;
  const _DriverCard({required this.driver, required this.onTap});
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
                  color: AppTheme.driverCyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.driverCyan.withValues(alpha: 0.2),
                  ),
                ),
                child: const Center(
                  child: Text('🚐', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.name,
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      driver.busId?.isNotEmpty == true
                          ? 'Bus ${driver.busId}'
                          : 'No bus assigned',
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
              // Rating stars
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < driver.rating.floor()
                        ? Icons.star_rounded
                        : (i < driver.rating
                              ? Icons.star_half_rounded
                              : Icons.star_border_rounded),
                    color: AppTheme.studentAmber,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                driver.rating.toStringAsFixed(1),
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              StatusBadge(
                label: driverStatusLabel(driver.status),
                color: driverStatusColor(driver.status),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _InfoPill(
                icon: Icons.badge_rounded,
                label: driver.licenseNumber.isEmpty
                    ? 'No license on file'
                    : driver.licenseNumber,
                color: AppTheme.adminEmerald,
              ),
              const Spacer(),
              _InfoPill(
                icon: Icons.phone_rounded,
                label: driver.phone,
                color: AppTheme.info,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────
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
  final Color color;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.color,
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
            Icon(icon, size: 14, color: color),
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
