import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/mini_chart.dart';
import 'admin_user_models.dart';

class AdminDriverDetail extends StatefulWidget {
  final DriverRecord driver;
  const AdminDriverDetail({super.key, required this.driver});
  @override
  State<AdminDriverDetail> createState() => _AdminDriverDetailState();
}

class _AdminDriverDetailState extends State<AdminDriverDetail> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 4, vsync: this); }
  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final d = widget.driver;
    return Scaffold(
      body: Container(
        decoration: context.scaffoldBg,
        child: SafeArea(child: Column(children: [
          // Header
          Container(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), child: Row(children: [
            GestureDetector(onTap: () => context.pop(), child: Container(width: 38, height: 38,
              decoration: BoxDecoration(color: context.cardBgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.inputBorder)),
              child: Center(child: Icon(Icons.arrow_back_rounded, color: context.textPrimary, size: 18)))),
            const SizedBox(width: 14),
            Expanded(child: Text('Driver Detail', style: TextStyle(color: context.textPrimary, fontSize: 20, fontWeight: FontWeight.w800))),
          ])),
          const SizedBox(height: 16),

          Expanded(child: SingleChildScrollView(padding: const EdgeInsets.only(bottom: 40), child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(children: [
              // Profile card
              GlassCard(padding: const EdgeInsets.all(18), child: Row(children: [
                Container(width: 56, height: 56,
                  decoration: BoxDecoration(color: AppTheme.driverCyan.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.driverCyan.withValues(alpha: 0.25))),
                  child: const Center(child: Text('🚐', style: TextStyle(fontSize: 26)))),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d.name, style: TextStyle(color: context.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('${d.vehicle} • ${d.route}', style: TextStyle(color: context.textSecondary, fontSize: 13)),
                  const SizedBox(height: 6),
                  Row(children: [
                    StatusBadge(label: d.statusLabel, color: d.statusColor),
                    const SizedBox(width: 6),
                    if (!d.approved) StatusBadge(label: 'Pending', color: AppTheme.warning),
                    if (d.approved) StatusBadge(label: 'Approved', color: AppTheme.success),
                  ]),
                ])),
              ])),
              const SizedBox(height: 12),

              // Details
              GlassCard(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Details', style: TextStyle(color: context.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                _InfoRow(icon: Icons.badge_rounded, label: 'License', value: d.licenseNo, color: AppTheme.info),
                _InfoRow(icon: Icons.phone_rounded, label: 'Contact', value: d.contact, color: AppTheme.adminEmerald),
                _InfoRow(icon: Icons.directions_bus_rounded, label: 'Vehicle', value: d.vehicle, color: AppTheme.driverCyan),
                _InfoRow(icon: Icons.route_rounded, label: 'Route', value: d.route, color: AppTheme.purple),
                _InfoRow(icon: Icons.trip_origin_rounded, label: 'Total Trips', value: '${d.totalTrips}', color: AppTheme.warning),
              ])),
              const SizedBox(height: 12),

              // Performance
              GlassCard(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Performance Score', style: TextStyle(color: context.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                Row(children: [
                  RingIndicator(percentage: d.rating / 5 * 100, color: AppTheme.driverCyan, size: 72, strokeWidth: 7,
                    center: Text('${d.rating}', style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.w800))),
                  const SizedBox(width: 18),
                  Expanded(child: Column(children: [
                    _PerfBar(label: 'On-time', pct: 0.92, color: AppTheme.success),
                    const SizedBox(height: 8),
                    _PerfBar(label: 'Safety', pct: 0.88, color: AppTheme.info),
                    const SizedBox(height: 8),
                    _PerfBar(label: 'Feedback', pct: 0.95, color: AppTheme.purple),
                  ])),
                ]),
              ])),
              const SizedBox(height: 12),

              // Controls
              GlassCard(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Controls', style: TextStyle(color: context.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _ActionBtn(label: d.approved ? 'Approved' : 'Approve', color: AppTheme.success, icon: Icons.check_circle_rounded,
                    onTap: () => _msg('Driver approved'))),
                  const SizedBox(width: 8),
                  Expanded(child: _ActionBtn(label: 'Reject', color: AppTheme.error, icon: Icons.cancel_rounded, onTap: () => _msg('Driver rejected'))),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: _ActionBtn(label: 'Assign Vehicle', color: AppTheme.driverCyan, icon: Icons.directions_bus_rounded, onTap: () => _msg('Assign vehicle'))),
                  const SizedBox(width: 8),
                  Expanded(child: _ActionBtn(label: 'Assign Route', color: AppTheme.info, icon: Icons.route_rounded, onTap: () => _msg('Assign route'))),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: _ActionBtn(label: 'Suspend', color: AppTheme.warning, icon: Icons.block_rounded, onTap: () => _msg('Driver suspended'))),
                  const SizedBox(width: 8),
                  Expanded(child: _ActionBtn(label: 'View Docs', color: AppTheme.purple, icon: Icons.description_rounded, onTap: () => _msg('Documents viewer'))),
                ]),
              ])),
              const SizedBox(height: 12),

              // Tabs
              GlassCard(padding: const EdgeInsets.all(14), child: Column(children: [
                TabBar(controller: _tabCtrl, isScrollable: true, labelColor: AppTheme.driverCyan,
                  unselectedLabelColor: context.textTertiary, indicatorColor: AppTheme.driverCyan,
                  indicatorSize: TabBarIndicatorSize.label, labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  tabAlignment: TabAlignment.start,
                  tabs: const [Tab(text: 'Trip History'), Tab(text: 'Attendance'), Tab(text: 'SOS History'), Tab(text: 'Earnings')]),
                SizedBox(height: 260, child: TabBarView(controller: _tabCtrl, children: [
                  _buildTrips(context), _buildAttendance(context), _buildSOS(context), _buildEarnings(context),
                ])),
              ])),
            ])))),
        ])),
      ),
    );
  }

  Widget _buildTrips(BuildContext context) {
    final items = [('May 26', 'Route A — Completed (34 students)', AppTheme.success), ('May 25', 'Route A — Completed (32 students)', AppTheme.success),
      ('May 24', 'Route A — Delayed 8 min', AppTheme.warning), ('May 23', 'Route A — Completed (35 students)', AppTheme.success)];
    return ListView(padding: const EdgeInsets.only(top: 12), children: items.map((e) => _LogRow(date: e.$1, status: e.$2, color: e.$3)).toList());
  }

  Widget _buildAttendance(BuildContext context) {
    final items = [('May 26', 'Present — On time', AppTheme.success), ('May 25', 'Present — On time', AppTheme.success),
      ('May 24', 'Present — Late 8 min', AppTheme.warning), ('May 22', 'Absent', AppTheme.error)];
    return ListView(padding: const EdgeInsets.only(top: 12), children: items.map((e) => _LogRow(date: e.$1, status: e.$2, color: e.$3)).toList());
  }

  Widget _buildSOS(BuildContext context) {
    final items = [('May 20', 'Vehicle breakdown — Route A', AppTheme.error), ('Apr 15', 'Medical emergency — student fainted', AppTheme.error)];
    return ListView(padding: const EdgeInsets.only(top: 12), children: items.map((e) => _LogRow(date: e.$1, status: e.$2, color: e.$3)).toList());
  }

  Widget _buildEarnings(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(top: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Monthly Earnings', style: TextStyle(color: context.textSecondary, fontSize: 12)),
        Text('₨45,000', style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
      ]),
      const SizedBox(height: 12),
      MiniBarChart(values: const [35, 42, 38, 45, 40, 48], labels: const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
        barColor: AppTheme.driverCyan, barActiveColor: AppTheme.driverCyan, height: 70, barWidth: 16),
      const SizedBox(height: 16),
      _EarnRow(label: 'Base Salary', value: '₨30,000', color: AppTheme.info),
      _EarnRow(label: 'Trip Bonus', value: '₨10,000', color: AppTheme.success),
      _EarnRow(label: 'Deductions', value: '-₨2,000', color: AppTheme.error),
    ]));
  }

  void _msg(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────
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
        SizedBox(width: 60, child: Text(label, style: TextStyle(color: context.textSecondary, fontSize: 11, fontWeight: FontWeight.w600))),
        Expanded(child: Text(value, style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
      ]),
    ));
  }
}

class _PerfBar extends StatelessWidget {
  final String label; final double pct; final Color color;
  const _PerfBar({required this.label, required this.pct, required this.color});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      SizedBox(width: 60, child: Text(label, style: TextStyle(color: context.textSecondary, fontSize: 11))),
      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(value: pct, backgroundColor: context.cardBgElevated, valueColor: AlwaysStoppedAnimation(color), minHeight: 6))),
      const SizedBox(width: 6),
      Text('${(pct * 100).toInt()}%', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    ]);
  }
}

class _ActionBtn extends StatelessWidget {
  final String label; final Color color; final IconData icon; final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.color, required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withValues(alpha: 0.14), color.withValues(alpha: 0.06)]),
        borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 15), const SizedBox(width: 5),
        Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
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

class _EarnRow extends StatelessWidget {
  final String label, value; final Color color;
  const _EarnRow({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: context.textSecondary, fontSize: 12)),
      Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
    ]));
  }
}
