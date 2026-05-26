import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import 'admin_user_models.dart';

class AdminDriverManagement extends StatefulWidget {
  const AdminDriverManagement({super.key});
  @override
  State<AdminDriverManagement> createState() => _AdminDriverManagementState();
}

class _AdminDriverManagementState extends State<AdminDriverManagement> {
  String _search = '';
  String _filterStatus = 'All';

  List<DriverRecord> get _filtered => mockDrivers.where((d) {
    if (_search.isNotEmpty && !d.name.toLowerCase().contains(_search.toLowerCase())) return false;
    if (_filterStatus != 'All' && d.statusLabel != _filterStatus) return false;
    return true;
  }).toList();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 120),
      child: Column(children: [
        _buildHeader(context),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(children: [
          _buildSearch(context),
          const SizedBox(height: 10),
          _buildFilters(),
          const SizedBox(height: 12),
          _buildStats(context),
          const SizedBox(height: 14),
          ..._filtered.map((d) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _DriverCard(driver: d, onTap: () => context.push('/admin/driver-detail', extra: d)),
          )),
          if (_filtered.isEmpty) _buildEmpty(context),
        ])),
      ]),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [AppTheme.driverCyan.withValues(alpha: 0.15), Colors.transparent])),
      child: Row(children: [
        Container(width: 44, height: 44,
          decoration: BoxDecoration(gradient: AppTheme.driverGradient, borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 24)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Driver Management', style: TextStyle(color: context.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text('${mockDrivers.length} drivers registered', style: TextStyle(color: context.textSecondary, fontSize: 13)),
        ])),
        GestureDetector(
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add driver form'))),
          child: Container(width: 40, height: 40,
            decoration: BoxDecoration(gradient: AppTheme.driverGradient, borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: AppTheme.driverCyan.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 22)),
        ),
      ]),
    );
  }

  Widget _buildSearch(BuildContext context) {
    return GlassCard(padding: const EdgeInsets.all(4), child: TextField(
      onChanged: (v) => setState(() => _search = v),
      style: TextStyle(color: context.textPrimary, fontSize: 14),
      decoration: InputDecoration(hintText: 'Search drivers...', prefixIcon: Icon(Icons.search_rounded, color: context.textTertiary),
        border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14)),
    ));
  }

  Widget _buildFilters() {
    return SizedBox(height: 36, child: ListView(scrollDirection: Axis.horizontal, children: [
      _FilterChip(label: 'Status: $_filterStatus', icon: Icons.circle, color: AppTheme.driverCyan, onTap: () {
        final s = ['All', 'Online', 'Offline', 'On Trip'];
        setState(() => _filterStatus = s[(s.indexOf(_filterStatus) + 1) % s.length]);
      }),
    ]));
  }

  Widget _buildStats(BuildContext context) {
    return Row(children: [
      _MiniStat(icon: Icons.people_rounded, label: 'Total', value: '${mockDrivers.length}', color: AppTheme.driverCyan),
      const SizedBox(width: 8),
      _MiniStat(icon: Icons.wifi_tethering_rounded, label: 'Online', value: '${mockDrivers.where((d) => d.status == DriverStatus.online || d.status == DriverStatus.onTrip).length}', color: AppTheme.success),
      const SizedBox(width: 8),
      _MiniStat(icon: Icons.wifi_off_rounded, label: 'Offline', value: '${mockDrivers.where((d) => d.status == DriverStatus.offline).length}', color: const Color(0xFF94A3B8)),
    ]);
  }

  Widget _buildEmpty(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 40),
    child: Column(children: [
      Icon(Icons.search_off_rounded, color: context.textTertiary, size: 48), const SizedBox(height: 12),
      Text('No drivers match your filters', style: TextStyle(color: context.textSecondary, fontSize: 14)),
    ]));
}

// ─── Driver Card ─────────────────────────────────────────────────────────────
class _DriverCard extends StatelessWidget {
  final DriverRecord driver; final VoidCallback onTap;
  const _DriverCard({required this.driver, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GlassCard(onTap: onTap, padding: const EdgeInsets.all(14), child: Column(children: [
      Row(children: [
        Container(width: 46, height: 46,
          decoration: BoxDecoration(color: AppTheme.driverCyan.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.driverCyan.withValues(alpha: 0.2))),
          child: const Center(child: Text('🚐', style: TextStyle(fontSize: 22)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(driver.name, style: TextStyle(color: context.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text('${driver.vehicle} • ${driver.route}', style: TextStyle(color: context.textSecondary, fontSize: 12)),
        ])),
        Icon(Icons.chevron_right_rounded, color: context.textTertiary),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        // Rating stars
        Row(children: List.generate(5, (i) => Icon(
          i < driver.rating.floor() ? Icons.star_rounded : (i < driver.rating ? Icons.star_half_rounded : Icons.star_border_rounded),
          color: AppTheme.studentAmber, size: 16))),
        const SizedBox(width: 6),
        Text('${driver.rating}', style: TextStyle(color: context.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
        const Spacer(),
        StatusBadge(label: driver.statusLabel, color: driver.statusColor),
      ]),
      const SizedBox(height: 6),
      Row(children: [
        _InfoPill(icon: Icons.trip_origin_rounded, label: '${driver.activeTrips} active trips', color: AppTheme.info),
        const Spacer(),
        _InfoPill(icon: Icons.badge_rounded, label: driver.licenseNo, color: AppTheme.adminEmerald),
      ]),
    ]));
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────
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
  final String label; final IconData icon; final Color color; final VoidCallback onTap;
  const _FilterChip({required this.label, required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: context.cardBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: context.surfaceBorder)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color), const SizedBox(width: 6),
        Text(label, style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(width: 4), Icon(Icons.unfold_more_rounded, size: 14, color: context.textTertiary),
      ]),
    ));
  }
}

// ─── Mock Data ──────────────────────────────────────────────────────────────
final mockDrivers = [
  const DriverRecord(id: 'drv_1', name: 'Mike Johnson', vehicle: 'Bus #42', route: 'Route A', status: DriverStatus.onTrip,
    rating: 4.8, activeTrips: 1, licenseNo: 'DL-2026-0042', contact: '0311-4444444', totalTrips: 342),
  const DriverRecord(id: 'drv_2', name: 'Ahmed Ali', vehicle: 'Bus #43', route: 'Route B', status: DriverStatus.online,
    rating: 4.5, activeTrips: 0, licenseNo: 'DL-2026-0043', contact: '0312-5555555', totalTrips: 287),
  const DriverRecord(id: 'drv_3', name: 'Ravi Kumar', vehicle: 'Bus #44', route: 'Route C', status: DriverStatus.offline,
    rating: 4.2, activeTrips: 0, licenseNo: 'DL-2026-1234', contact: '0309-0000000', approved: false, totalTrips: 45),
  const DriverRecord(id: 'drv_4', name: 'Bilal Shah', vehicle: 'Bus #45', route: 'Route D', status: DriverStatus.onTrip,
    rating: 4.9, activeTrips: 1, licenseNo: 'DL-2026-0045', contact: '0315-1111111', totalTrips: 510),
  const DriverRecord(id: 'drv_5', name: 'Imran Khan', vehicle: 'Bus #46', route: 'Route A', status: DriverStatus.online,
    rating: 3.8, activeTrips: 0, licenseNo: 'DL-2026-0046', contact: '0316-2222222', totalTrips: 128),
];
