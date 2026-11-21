import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/admin_format.dart';
import '../../app/audit_format.dart';
import '../../app/locale_provider.dart';
import '../../services/audit_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/entity_widgets.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/responsive.dart';
import 'admin_audit_history.dart';

/// "Admin Activity Tracking" — the `auditLogs` collection summarised: how
/// many actions in total and today, and how many in each category. Every
/// category is tappable and opens the detailed Audit History filtered to
/// it (each record with its time, admin, target and before → after
/// values); the newest few actions are shown in full underneath.
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

  Future<void> _open(AuditActionType? category) async {
    await context.push('/admin/audit-history', extra: category?.name);
    // Actions taken meanwhile (e.g. from a target opened in the log) show
    // up in the counts when coming back.
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: context.scaffoldBg,
        child: SafeArea(
          child: Column(
            children: [
              AuditScreenHeader(
                title: AppStrings.t('admin_activity_tracking'),
                onBack: () => context.pop(),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: FutureBuilder<List<AuditLogEntry>>(
                    future: _logsFuture,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snap.hasError) {
                        return ListView(
                          children: [
                            LoadErrorView(
                              error: snap.error,
                              what: 'the activity log',
                            ),
                          ],
                        );
                      }
                      final logs = snap.data ?? const <AuditLogEntry>[];
                      if (logs.isEmpty) {
                        return ListView(
                          children: [
                            EmptyHint(
                              text: AppStrings.t('no_activity_recorded'),
                              icon: Icons.analytics_outlined,
                            ),
                          ],
                        );
                      }
                      return _buildBody(context, logs);
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

  Widget _buildBody(BuildContext context, List<AuditLogEntry> logs) {
    final today = DateTime.now();
    final todayCount = logs.where((l) {
      final t = l.timestamp.toLocal();
      return t.year == today.year &&
          t.month == today.month &&
          t.day == today.day;
    }).length;
    final counts = auditCountsByCategory(logs);
    DateTime? latestOf(AuditActionType t) {
      for (final l in logs) {
        if (l.actionType == t) return l.timestamp; // newest first
      }
      return null;
    }

    return ListView(
      padding: centeredListPadding(context, maxWidth: 1100, bottom: 40),
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryTile(
                value: '${logs.length}',
                label: AppStrings.t('total_actions_lbl'),
                onTap: () => _open(null),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryTile(
                value: '$todayCount',
                label: AppStrings.t('today_actions_lbl'),
                onTap: () => _open(null),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SectionTitle(AppStrings.t('audit_categories_lbl')),
        const SizedBox(height: 8),
        ResponsiveGrid(
          minItemWidth: 320,
          maxColumns: 3,
          children: [
            for (final c in counts)
              _CategoryTile(
                type: c.key,
                count: c.value,
                latest: latestOf(c.key),
                onTap: () => _open(c.key),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton.icon(
            onPressed: () => _open(null),
            icon: const Icon(Icons.list_alt_rounded, size: 18),
            label: Text(AppStrings.t('view_all_actions')),
          ),
        ),
        const SizedBox(height: 8),
        _SectionTitle(AppStrings.t('latest_actions_lbl')),
        const SizedBox(height: 8),
        ResponsiveGrid(
          minItemWidth: 460,
          maxColumns: 2,
          children: [for (final e in logs.take(6)) AuditEntryCard(entry: e)],
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      color: context.textSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _SummaryTile extends StatelessWidget {
  final String value;
  final String label;
  final VoidCallback onTap;
  const _SummaryTile({
    required this.value,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: context.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

/// One category: its count, what it holds, the newest action's time, and a
/// chevron — tapping opens the filtered log.
class _CategoryTile extends StatelessWidget {
  final AuditActionType type;
  final int count;
  final DateTime? latest;
  final VoidCallback onTap;
  const _CategoryTile({
    required this.type,
    required this.count,
    required this.latest,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = auditCategoryColor(type);
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(auditCategoryIcon(type), color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auditCategoryText(type),
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  auditCategoryHint(type),
                  style: TextStyle(color: context.textSecondary, fontSize: 11),
                ),
                if (latest != null)
                  Text(
                    AppStrings.t(
                      'audit_latest_at',
                    ).replaceFirst('{time}', formatExactTime(latest!)),
                    style: TextStyle(color: context.textTertiary, fontSize: 11),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusBadge(label: '$count', color: color),
          Icon(Icons.chevron_right_rounded, color: context.textTertiary),
        ],
      ),
    );
  }
}
