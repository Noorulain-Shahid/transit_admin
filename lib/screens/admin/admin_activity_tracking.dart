import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/locale_provider.dart';
import '../../services/audit_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';

/// Real "Admin Activity Tracking" view — this app is single-admin (see
/// `single_admin_role_desc`), so "my activity" and "the audit log" are the
/// same underlying data; this screen just summarizes the `auditLogs`
/// collection `AuditService` already writes to (counts by action type, plus
/// today's count) instead of listing every entry like Audit History does.
/// Replaces the old "coming soon" stub on the Profile screen's System
/// Controls section.
class AdminActivityTracking extends StatefulWidget {
  const AdminActivityTracking({super.key});

  @override
  State<AdminActivityTracking> createState() => _AdminActivityTrackingState();
}

class _AdminActivityTrackingState extends State<AdminActivityTracking> {
  late Future<List<AuditLogEntry>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _logsFuture = AuditService.instance.fetchRecentLogs();
    LocaleProvider.instance.addListener(_onLangChanged);
  }

  void _onLangChanged() => setState(() {});

  @override
  void dispose() {
    LocaleProvider.instance.removeListener(_onLangChanged);
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _logsFuture = AuditService.instance.fetchRecentLogs());
    await _logsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: context.scaffoldBg,
        child: SafeArea(
          child: Column(
            children: [
              _Header(onBack: () => context.pop()),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: FutureBuilder<List<AuditLogEntry>>(
                    future: _logsFuture,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final logs = snap.data ?? const <AuditLogEntry>[];
                      if (logs.isEmpty) return _EmptyState();
                      final today = DateTime.now();
                      final todayCount = logs
                          .where(
                            (l) =>
                                l.timestamp.year == today.year &&
                                l.timestamp.month == today.month &&
                                l.timestamp.day == today.day,
                          )
                          .length;
                      final byType = <AuditActionType, int>{};
                      for (final l in logs) {
                        byType[l.actionType] = (byType[l.actionType] ?? 0) + 1;
                      }
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        children: [
                          _SummaryRow(total: logs.length, today: todayCount),
                          const SizedBox(height: 16),
                          ...AuditActionType.values
                              .where((t) => (byType[t] ?? 0) > 0)
                              .map((t) => _TypeCountRow(type: t, count: byType[t]!)),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  const _Header({required this.onBack});

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
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: context.textPrimary,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            AppStrings.t('admin_activity_tracking'),
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

class _SummaryRow extends StatelessWidget {
  final int total;
  final int today;
  const _SummaryRow({required this.total, required this.today});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Text(
                  '$total',
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  AppStrings.t('total_actions_lbl'),
                  style: TextStyle(color: context.textTertiary, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Text(
                  '$today',
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  AppStrings.t('today_actions_lbl'),
                  style: TextStyle(color: context.textTertiary, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

Color _colorFor(AuditActionType type) => switch (type) {
  AuditActionType.create => AppTheme.success,
  AuditActionType.update => AppTheme.info,
  AuditActionType.delete => AppTheme.error,
  AuditActionType.override => AppTheme.warning,
  AuditActionType.statusChange => AppTheme.purple,
  AuditActionType.broadcast => AppTheme.driverCyan,
  AuditActionType.emergencyTrigger => AppTheme.error,
};

IconData _iconFor(AuditActionType type) => switch (type) {
  AuditActionType.create => Icons.add_circle_outline_rounded,
  AuditActionType.update => Icons.edit_outlined,
  AuditActionType.delete => Icons.delete_outline_rounded,
  AuditActionType.override => Icons.sync_problem_rounded,
  AuditActionType.statusChange => Icons.swap_horiz_rounded,
  AuditActionType.broadcast => Icons.campaign_outlined,
  AuditActionType.emergencyTrigger => Icons.warning_amber_rounded,
};

class _TypeCountRow extends StatelessWidget {
  final AuditActionType type;
  final int count;
  const _TypeCountRow({required this.type, required this.count});

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(type);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_iconFor(type), color: color, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                type.name,
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$count',
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.analytics_outlined, size: 48, color: context.textTertiary),
            const SizedBox(height: 12),
            Text(
              AppStrings.t('no_activity_recorded'),
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textTertiary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
