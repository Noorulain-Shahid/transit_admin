import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/mini_chart.dart';
import 'admin_user_models.dart';

class AdminDashboard extends StatelessWidget {
  final void Function(int) onNavigate;
  const AdminDashboard({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        children: [
          _buildHeader(context),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildOverviewCards(context),
                const SizedBox(height: 14),
                _buildSubscriptionAnalytics(context),
                const SizedBox(height: 14),
                _buildAlerts(context),
                const SizedBox(height: 14),
                _buildLiveMap(context),
                const SizedBox(height: 14),
                _buildAnalytics(context),
                const SizedBox(height: 14),
                _buildQuickActions(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.adminEmerald.withValues(alpha: 0.2),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TransitPro Admin',
                  style: TextStyle(color: context.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'Command Center',
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'System Online • Real-time',
                      style: TextStyle(
                        color: AppTheme.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/admin/notifications'),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: context.cardBgElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.inputBorder),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.notifications_rounded,
                      color: context.textPrimary,
                      size: 22,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppTheme.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: context.cardBg, width: 1.5),
                      ),
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

  // ── Overview Cards ──────────────────────────────────────────────────────────
  Widget _buildOverviewCards(BuildContext context) {
    return Column(
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          padding: EdgeInsets.zero,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.95,
          children: [
            _StatCard(
              icon: Icons.school_rounded,
              label: 'Students',
              value: '486',
              color: AppTheme.studentAmber,
            ),
            _StatCard(
              icon: Icons.family_restroom_rounded,
              label: 'Parents',
              value: '312',
              color: AppTheme.parentPurple,
            ),
            _StatCard(
              icon: Icons.directions_bus_rounded,
              label: 'Drivers',
              value: '24',
              color: AppTheme.driverCyan,
            ),
            _StatCard(
              icon: Icons.navigation_rounded,
              label: 'Active Trips',
              value: '18',
              color: AppTheme.adminEmerald,
            ),
            _StatCard(
              icon: Icons.wifi_tethering_rounded,
              label: 'Online',
              value: '12',
              color: AppTheme.success,
            ),
            _StatCard(
              icon: Icons.pending_actions_rounded,
              label: 'Pending',
              value: '7',
              color: AppTheme.warning,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _WideStatCard(
                icon: Icons.check_circle_rounded,
                label: 'Active Subs',
                value: '298',
                sub: '+12 this week',
                color: AppTheme.success,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _WideStatCard(
                icon: Icons.cancel_rounded,
                label: 'Expired',
                value: '14',
                sub: '3 expiring soon',
                color: AppTheme.error,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _WideStatCard(
                icon: Icons.attach_money_rounded,
                label: 'MRR',
                value: '₨4.2L',
                sub: '+8% growth',
                color: AppTheme.info,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Subscription Analytics ─────────────────────────────────────────────────
  Widget _buildSubscriptionAnalytics(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subscription Analytics',
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.purple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '💳 SaaS',
                  style: TextStyle(
                    color: AppTheme.purple,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bars
          _SubAnalyticBar(
            label: 'Active',
            count: 298,
            total: 326,
            color: AppTheme.success,
          ),
          const SizedBox(height: 8),
          _SubAnalyticBar(
            label: 'Expired',
            count: 14,
            total: 326,
            color: AppTheme.error,
          ),
          const SizedBox(height: 8),
          _SubAnalyticBar(
            label: 'Trial',
            count: 14,
            total: 326,
            color: AppTheme.info,
          ),
          const SizedBox(height: 16),
          // Revenue chart
          Text(
            'Monthly Revenue',
            style: TextStyle(color: context.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          MiniBarChart(
            values: const [320, 380, 350, 420, 390, 460],
            labels: const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
            barColor: AppTheme.purple,
            barActiveColor: AppTheme.parentPurple,
            height: 70,
            barWidth: 18,
          ),
          const SizedBox(height: 16),
          // Rates
          Row(
            children: [
              Expanded(
                child: _RateCard(
                  label: 'Payment\nSuccess',
                  pct: 94,
                  color: AppTheme.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RateCard(
                  label: 'Payment\nFailure',
                  pct: 6,
                  color: AppTheme.error,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RateCard(
                  label: 'Renewal\nRate',
                  pct: 87,
                  color: AppTheme.info,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Alerts Panel ────────────────────────────────────────────────────────────
  Widget _buildAlerts(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      gradient: LinearGradient(
        colors: [AppTheme.error.withValues(alpha: 0.06), Colors.transparent],
      ),
      borderColor: AppTheme.error.withValues(alpha: 0.12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppTheme.error,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Alerts',
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              StatusBadge(label: '5 Active', color: AppTheme.error),
            ],
          ),
          const SizedBox(height: 12),
          ..._mockAlerts.map((a) => _AlertRow(alert: a)),
        ],
      ),
    );
  }

  // ── Live Map ────────────────────────────────────────────────────────────────
  Widget _buildLiveMap(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.map_rounded,
                color: AppTheme.adminEmerald,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Live Tracking',
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              StatusBadge(label: '● 12 Live', color: AppTheme.success),
            ],
          ),
          const SizedBox(height: 12),
          // Map placeholder
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: context.isDark
                  ? const Color(0xFF1A1A2E)
                  : const Color(0xFFE8F4FD),
              border: Border.all(color: context.surfaceBorder),
            ),
            child: Stack(
              children: [
                // Grid pattern
                CustomPaint(
                  size: const Size(double.infinity, 180),
                  painter: _GridPainter(color: context.surfaceBorder),
                ),
                // Mock bus markers
                Positioned(
                  left: 60,
                  top: 40,
                  child: _BusMarker(color: AppTheme.success, label: '#42'),
                ),
                Positioned(
                  left: 150,
                  top: 80,
                  child: _BusMarker(color: AppTheme.success, label: '#43'),
                ),
                Positioned(
                  right: 60,
                  top: 50,
                  child: _BusMarker(color: AppTheme.warning, label: '#44'),
                ),
                Positioned(
                  left: 100,
                  bottom: 30,
                  child: _BusMarker(color: AppTheme.success, label: '#45'),
                ),
                // Legend
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: context.cardBg.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Active',
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 9,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.warning,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Delayed',
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Route list
          Row(
            children: [
              _RoutePill(name: 'Route A', buses: 2, color: AppTheme.info),
              const SizedBox(width: 6),
              _RoutePill(name: 'Route B', buses: 1, color: AppTheme.purple),
              const SizedBox(width: 6),
              _RoutePill(
                name: 'Route C',
                buses: 1,
                color: AppTheme.adminEmerald,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Analytics ───────────────────────────────────────────────────────────────
  Widget _buildAnalytics(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analytics',
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Trips',
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '36 completed',
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const MiniLineChart(
                      values: [28, 32, 30, 36, 34, 36],
                      lineColor: AppTheme.adminEmerald,
                      height: 40,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attendance Rate',
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '94.2%',
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const MiniLineChart(
                      values: [90, 92, 91, 94, 93, 94.2],
                      lineColor: AppTheme.info,
                      height: 40,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vehicle Efficiency',
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '87%',
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const MiniLineChart(
                      values: [80, 82, 85, 83, 86, 87],
                      lineColor: AppTheme.purple,
                      height: 40,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sub Growth',
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '+12 this month',
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const MiniLineChart(
                      values: [280, 285, 288, 292, 295, 298],
                      lineColor: AppTheme.warning,
                      height: 40,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Quick Actions ───────────────────────────────────────────────────────────
  Widget _buildQuickActions(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _QuickAction(
                icon: Icons.person_add_rounded,
                label: 'Add Student',
                color: AppTheme.studentAmber,
                onTap: () => onNavigate(1),
              ),
              const SizedBox(width: 8),
              _QuickAction(
                icon: Icons.family_restroom_rounded,
                label: 'Add Parent',
                color: AppTheme.parentPurple,
                onTap: () => onNavigate(2),
              ),
              const SizedBox(width: 8),
              _QuickAction(
                icon: Icons.drive_eta_rounded,
                label: 'Add Driver',
                color: AppTheme.driverCyan,
                onTap: () => onNavigate(3),
              ),
              const SizedBox(width: 8),
              _QuickAction(
                icon: Icons.subscriptions_rounded,
                label: 'Billing',
                color: AppTheme.purple,
                onTap: () => context.push('/admin/subscription'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Widgets
// ═════════════════════════════════════════════════════════════════════════════
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(10),
      gradient: LinearGradient(
        colors: [color.withValues(alpha: 0.12), color.withValues(alpha: 0.04)],
      ),
      borderColor: color.withValues(alpha: 0.18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 6),
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
    );
  }
}

class _WideStatCard extends StatelessWidget {
  final IconData icon;
  final String label, value, sub;
  final Color color;
  const _WideStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      gradient: LinearGradient(
        colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.03)],
      ),
      borderColor: color.withValues(alpha: 0.15),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
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
            style: TextStyle(color: context.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
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

class _SubAnalyticBar extends StatelessWidget {
  final String label;
  final int count, total;
  final Color color;
  const _SubAnalyticBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 55,
          child: Text(
            label,
            style: TextStyle(color: context.textSecondary, fontSize: 12),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: count / total,
              backgroundColor: context.cardBgElevated,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _RateCard extends StatelessWidget {
  final String label;
  final int pct;
  final Color color;
  const _RateCard({
    required this.label,
    required this.pct,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          RingIndicator(
            percentage: pct.toDouble(),
            color: color,
            size: 44,
            strokeWidth: 4,
            center: Text(
              '$pct%',
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(color: context.textSecondary, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  final AlertItem alert;
  const _AlertRow({required this.alert});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: alert.severityColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: alert.severityColor.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: alert.severityColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(alert.typeIcon, color: alert.severityColor, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.title,
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    alert.message,
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              alert.timestamp,
              style: TextStyle(color: context.textTertiary, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _BusMarker extends StatelessWidget {
  final Color color;
  final String label;
  const _BusMarker({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.directions_bus_rounded,
            color: Colors.white,
            size: 12,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutePill extends StatelessWidget {
  final String name;
  final int buses;
  final Color color;
  const _RoutePill({
    required this.name,
    required this.buses,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              name,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '$buses buses',
              style: TextStyle(color: context.textTertiary, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;
  _GridPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Mock Alerts ────────────────────────────────────────────────────────────
final _mockAlerts = [
  const AlertItem(
    id: 'a1',
    type: AlertType.sos,
    title: '🚨 SOS Alert',
    message: 'Bus #44 emergency button pressed',
    severity: AlertSeverity.critical,
    timestamp: '2m ago',
  ),
  const AlertItem(
    id: 'a2',
    type: AlertType.missedBus,
    title: 'Missed Bus',
    message: 'Ali Hassan missed pickup at East Wing',
    severity: AlertSeverity.warning,
    timestamp: '15m ago',
  ),
  const AlertItem(
    id: 'a3',
    type: AlertType.lateDriver,
    title: 'Late Driver',
    message: 'Ravi Kumar 8 min late on Route C',
    severity: AlertSeverity.warning,
    timestamp: '22m ago',
  ),
  const AlertItem(
    id: 'a4',
    type: AlertType.paymentFailure,
    title: 'Payment Failed',
    message: 'Fatima Khan — card declined',
    severity: AlertSeverity.warning,
    timestamp: '1h ago',
  ),
  const AlertItem(
    id: 'a5',
    type: AlertType.subscriptionExpiry,
    title: 'Sub Expiring',
    message: 'Farooq Ahmed — 3 days left',
    severity: AlertSeverity.info,
    timestamp: '3h ago',
  ),
];
