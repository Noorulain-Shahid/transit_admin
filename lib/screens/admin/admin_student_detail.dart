import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import 'admin_user_models.dart';

class AdminStudentDetail extends StatefulWidget {
  final StudentRecord student;
  const AdminStudentDetail({super.key, required this.student});
  @override
  State<AdminStudentDetail> createState() => _AdminStudentDetailState();
}

class _AdminStudentDetailState extends State<AdminStudentDetail> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  late bool _emergencyAccess;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _emergencyAccess = false;
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final s = widget.student;
    return Scaffold(
      body: Container(
        decoration: context.scaffoldBg,
        child: SafeArea(child: Column(children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(width: 38, height: 38,
                  decoration: BoxDecoration(color: context.cardBgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.inputBorder)),
                  child: Center(child: Icon(Icons.arrow_back_rounded, color: context.textPrimary, size: 18)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text('Student Detail', style: TextStyle(color: context.textPrimary, fontSize: 20, fontWeight: FontWeight.w800))),
              GestureDetector(
                onTap: () => _msg('Edit student form will open'),
                child: Container(width: 38, height: 38,
                  decoration: BoxDecoration(color: AppTheme.studentAmber.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.studentAmber.withValues(alpha: 0.25))),
                  child: const Icon(Icons.edit_rounded, color: AppTheme.studentAmber, size: 18),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 40),
            child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(children: [
              // Profile card
              GlassCard(padding: const EdgeInsets.all(18), child: Row(children: [
                Container(width: 56, height: 56,
                  decoration: BoxDecoration(color: AppTheme.studentAmber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.studentAmber.withValues(alpha: 0.25))),
                  child: const Center(child: Text('🎓', style: TextStyle(fontSize: 26))),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.name, style: TextStyle(color: context.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('${s.grade} • ${s.route}', style: TextStyle(color: context.textSecondary, fontSize: 13)),
                  const SizedBox(height: 4),
                  Row(children: [
                    StatusBadge(label: s.statusLabel, color: s.statusColor),
                    const SizedBox(width: 6),
                    StatusBadge(label: '💳 ${s.subscriptionLabel}', color: s.subscriptionColor),
                  ]),
                ])),
              ])),
              const SizedBox(height: 12),

              // Info grid
              GlassCard(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Details', style: TextStyle(color: context.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                _InfoRow(icon: Icons.family_restroom_rounded, label: 'Parent', value: s.parentName, color: AppTheme.parentPurple),
                _InfoRow(icon: Icons.directions_bus_rounded, label: 'Driver', value: s.driver, color: AppTheme.driverCyan),
                _InfoRow(icon: Icons.route_rounded, label: 'Route', value: s.route, color: AppTheme.info),
                _InfoRow(icon: Icons.schedule_rounded, label: 'Pickup', value: '${s.pickupTime} — ${s.pickupLocation}', color: AppTheme.adminEmerald),
                _InfoRow(icon: Icons.schedule_rounded, label: 'Drop', value: '${s.dropTime} — ${s.dropLocation}', color: AppTheme.warning),
              ])),
              const SizedBox(height: 12),

              // Management actions
              GlassCard(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Management Actions', style: TextStyle(color: context.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _ActionBtn(label: 'Assign Route', color: AppTheme.info, icon: Icons.route_rounded, onTap: () => _msg('Route assignment panel'))),
                  const SizedBox(width: 8),
                  Expanded(child: _ActionBtn(label: 'Assign Driver', color: AppTheme.driverCyan, icon: Icons.directions_bus_rounded, onTap: () => _msg('Driver assignment panel'))),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: _ActionBtn(label: 'Update Location', color: AppTheme.adminEmerald, icon: Icons.location_on_rounded, onTap: () => _msg('Location update form'))),
                  const SizedBox(width: 8),
                  Expanded(child: _ActionBtn(label: 'Delete Student', color: AppTheme.error, icon: Icons.delete_rounded, onTap: () => _msg('Delete confirmation'))),
                ]),
                const SizedBox(height: 12),
                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  gradient: LinearGradient(colors: [AppTheme.error.withValues(alpha: 0.08), AppTheme.error.withValues(alpha: 0.03)]),
                  borderColor: AppTheme.error.withValues(alpha: 0.15),
                  child: Row(children: [
                    const Icon(Icons.emergency_rounded, color: AppTheme.error, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Emergency Access', style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('Enable manual emergency access override', style: TextStyle(color: context.textSecondary, fontSize: 11)),
                    ])),
                    AppSwitch(value: _emergencyAccess, activeColor: AppTheme.error, onChanged: (v) => setState(() => _emergencyAccess = v)),
                  ]),
                ),
              ])),
              const SizedBox(height: 12),

              // Data tabs
              GlassCard(padding: const EdgeInsets.all(14), child: Column(children: [
                TabBar(controller: _tabCtrl, isScrollable: true, labelColor: AppTheme.studentAmber,
                  unselectedLabelColor: context.textTertiary, indicatorColor: AppTheme.studentAmber,
                  indicatorSize: TabBarIndicatorSize.label, labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  tabAlignment: TabAlignment.start,
                  tabs: const [Tab(text: 'Attendance'), Tab(text: 'Trip History'), Tab(text: 'Missed Logs'), Tab(text: 'Access')]),
                SizedBox(
                  height: 260,
                  child: TabBarView(controller: _tabCtrl, children: [
                    _buildAttendance(context),
                    _buildTripHistory(context),
                    _buildMissedLogs(context),
                    _buildAccessLogs(context),
                  ]),
                ),
              ])),
            ])),
          )),
        ])),
      ),
    );
  }

  Widget _buildAttendance(BuildContext context) {
    final items = [('May 26', 'Present', AppTheme.success), ('May 25', 'Present', AppTheme.success),
      ('May 24', 'Absent', AppTheme.error), ('May 23', 'Present', AppTheme.success), ('May 22', 'Late', AppTheme.warning)];
    return ListView(padding: const EdgeInsets.only(top: 12), children: items.map((e) => _LogRow(date: e.$1, status: e.$2, color: e.$3)).toList());
  }

  Widget _buildTripHistory(BuildContext context) {
    final items = [('May 26', 'Route A — Completed', AppTheme.success), ('May 25', 'Route A — Completed', AppTheme.success),
      ('May 24', 'Route A — Missed', AppTheme.error), ('May 23', 'Route A — Completed', AppTheme.success)];
    return ListView(padding: const EdgeInsets.only(top: 12), children: items.map((e) => _LogRow(date: e.$1, status: e.$2, color: e.$3)).toList());
  }

  Widget _buildMissedLogs(BuildContext context) {
    final items = [('May 24', 'Missed pickup — no show at stop', AppTheme.error), ('May 18', 'Missed drop — parent picked up early', AppTheme.warning)];
    return ListView(padding: const EdgeInsets.only(top: 12), children: items.map((e) => _LogRow(date: e.$1, status: e.$2, color: e.$3)).toList());
  }

  Widget _buildAccessLogs(BuildContext context) {
    final items = [('May 26', 'Access: Active (subscription valid)', AppTheme.success), ('May 20', 'Access: Renewed after payment', AppTheme.info),
      ('May 15', 'Access: Blocked (subscription expired)', AppTheme.error)];
    return ListView(padding: const EdgeInsets.only(top: 12), children: items.map((e) => _LogRow(date: e.$1, status: e.$2, color: e.$3)).toList());
  }

  void _msg(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
}

// ─── Sub-widgets ────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon; final String label, value; final Color color;
  const _InfoRow({required this.icon, required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.12))),
      child: Row(children: [
        Icon(icon, color: color, size: 18), const SizedBox(width: 10),
        SizedBox(width: 56, child: Text(label, style: TextStyle(color: context.textSecondary, fontSize: 11, fontWeight: FontWeight.w600))),
        Expanded(child: Text(value, style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
      ]),
    ));
  }
}

class _ActionBtn extends StatelessWidget {
  final String label; final Color color; final IconData icon; final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.color, required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withValues(alpha: 0.14), color.withValues(alpha: 0.06)]),
        borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 16), const SizedBox(width: 6),
        Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      ]),
    ));
  }
}

class _LogRow extends StatelessWidget {
  final String date, status; final Color color;
  const _LogRow({required this.date, required this.status, required this.color});
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.12))),
      child: Row(children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Text(date, style: TextStyle(color: context.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(width: 12),
        Expanded(child: Text(status, style: TextStyle(color: context.textPrimary, fontSize: 12))),
      ]),
    ));
  }
}
