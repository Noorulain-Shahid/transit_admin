import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/audit_format.dart';
import '../../app/locale_provider.dart';
import '../../data/admin_repository.dart';
import '../../services/audit_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/entity_widgets.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/responsive.dart';
import 'admin_links.dart';

/// The detailed audit log: every record of the `auditLogs` collection
/// `AuditService` writes — when, which admin, what was done, to whom
/// (name, role, id) and the specifics (status before → after, a rejection
/// reason, the children restored with a parent…).
///
/// Opened from Profile → Audit History (every category), or from Admin
/// Activity Tracking already filtered to the category that was tapped
/// ([initialCategory]). The category chips switch the filter in place.
class AdminAuditHistory extends StatefulWidget {
  final AuditActionType? initialCategory;
  const AdminAuditHistory({super.key, this.initialCategory});

  @override
  State<AdminAuditHistory> createState() => _AdminAuditHistoryState();
}

class _AdminAuditHistoryState extends State<AdminAuditHistory> {
  late Future<List<AuditLogEntry>> _logsFuture;
  AuditActionType? _category;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
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

  bool _matchesSearch(AuditLogEntry e) {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return true;
    final haystack = [
      auditActionTitle(e),
      e.description,
      e.targetName,
      e.targetRole,
      e.targetEntityId,
      e.adminEmail,
      ...auditDetailLines(e),
    ].join(' ').toLowerCase();
    return haystack.contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final title = _category == null
        ? AppStrings.t('audit_history')
        : '${AppStrings.t('audit_history')} · ${auditCategoryText(_category!)}';
    return Scaffold(
      body: Container(
        decoration: context.scaffoldBg,
        child: SafeArea(
          child: Column(
            children: [
              AuditScreenHeader(title: title, onBack: () => context.pop()),
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
                              what: 'the audit log',
                            ),
                          ],
                        );
                      }
                      final all = snap.data ?? const <AuditLogEntry>[];
                      if (all.isEmpty) {
                        return ListView(
                          children: [
                            EmptyHint(
                              text: AppStrings.t('no_admin_actions'),
                              icon: Icons.history_edu_outlined,
                            ),
                          ],
                        );
                      }
                      return _buildList(context, all);
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

  Widget _buildList(BuildContext context, List<AuditLogEntry> all) {
    final counts = auditCountsByCategory(all);
    final inCategory = _category == null
        ? all
        : all.where((e) => e.actionType == _category).toList();
    final shown = inCategory.where(_matchesSearch).toList();
    return ListView(
      padding: centeredListPadding(context, maxWidth: 1100, bottom: 40),
      children: [
        GlassCard(
          padding: const EdgeInsets.all(4),
          child: TextField(
            onChanged: (v) => setState(() => _search = v),
            style: TextStyle(color: context.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: AppStrings.t('audit_search_hint'),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: context.textTertiary,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text('${AppStrings.t('status_all')} (${all.length})'),
              selected: _category == null,
              onSelected: (_) => setState(() => _category = null),
            ),
            for (final c in counts)
              ChoiceChip(
                avatar: Icon(
                  auditCategoryIcon(c.key),
                  size: 16,
                  color: auditCategoryColor(c.key),
                ),
                label: Text('${auditCategoryText(c.key)} (${c.value})'),
                selected: _category == c.key,
                onSelected: (_) => setState(() => _category = c.key),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.t('audit_showing')
              .replaceFirst('{shown}', '${shown.length}')
              .replaceFirst('{total}', '${all.length}'),
          style: TextStyle(color: context.textTertiary, fontSize: 11),
        ),
        const SizedBox(height: 10),
        if (shown.isEmpty)
          EmptyHint(
            text: AppStrings.t('no_actions_in_category'),
            icon: Icons.filter_alt_off_rounded,
          )
        else
          ResponsiveGrid(
            minItemWidth: 460,
            maxColumns: 2,
            children: [for (final e in shown) AuditEntryCard(entry: e)],
          ),
      ],
    );
  }
}

/// Category name in the current language.
String auditCategoryText(AuditActionType type) {
  final key = 'audit_cat_${type.name}';
  final text = AppStrings.t(key);
  return text == key ? auditCategoryLabel(type) : text;
}

Color auditCategoryColor(AuditActionType type) => switch (type) {
  AuditActionType.create => AppTheme.success,
  AuditActionType.update => AppTheme.info,
  AuditActionType.delete => AppTheme.error,
  AuditActionType.override => AppTheme.warning,
  AuditActionType.statusChange => AppTheme.purple,
  AuditActionType.broadcast => AppTheme.driverCyan,
  AuditActionType.emergencyTrigger => AppTheme.error,
};

IconData auditCategoryIcon(AuditActionType type) => switch (type) {
  AuditActionType.create => Icons.add_circle_outline_rounded,
  AuditActionType.update => Icons.edit_outlined,
  AuditActionType.delete => Icons.delete_outline_rounded,
  AuditActionType.override => Icons.sync_problem_rounded,
  AuditActionType.statusChange => Icons.swap_horiz_rounded,
  AuditActionType.broadcast => Icons.campaign_outlined,
  AuditActionType.emergencyTrigger => Icons.warning_amber_rounded,
};

/// Back button + title, shared with Activity Tracking.
class AuditScreenHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  const AuditScreenHeader({
    super.key,
    required this.title,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          Clickable(
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
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One audit record in full: what, when, which admin, the target (tap it
/// to open that parent / driver / student) and every specific recorded.
///
/// Older entries carry only a sentence and an id; the admin's and the
/// target's names are looked up (`users/{id}`, else `students/{id}`) so
/// they still read as people, not ids.
class AuditEntryCard extends StatefulWidget {
  final AuditLogEntry entry;
  const AuditEntryCard({super.key, required this.entry});

  @override
  State<AuditEntryCard> createState() => _AuditEntryCardState();
}

class _AuditEntryCardState extends State<AuditEntryCard> {
  late final Future<(String?, String?)> _names = _resolve();

  Future<(String?, String?)> _resolve() async {
    final e = widget.entry;
    final repo = AdminRepository.instance;
    final results = await Future.wait([
      repo.fetchUserName(e.adminId).catchError((_) => null),
      e.targetName.isEmpty
          ? repo.resolveTargetName(e.targetEntityId).catchError((_) => null)
          : Future<String?>.value(null),
    ]);
    return (results[0], results[1]);
  }

  VoidCallback? _openTarget(BuildContext context) {
    final e = widget.entry;
    final id = e.targetEntityId;
    if (id.isEmpty) return null;
    return switch (e.targetType) {
      'parent' => () => openParentDetail(context, id),
      'driver' => () => openDriverDetail(context, id),
      'student' => () => openStudentDetail(context, id),
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final color = auditCategoryColor(e.actionType);
    final lines = auditDetailLines(e);
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: FutureBuilder<(String?, String?)>(
        future: _names,
        builder: (context, snap) {
          final adminName = snap.data?.$1;
          final targetName = snap.data?.$2;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(auditCategoryIcon(e.actionType), color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          auditActionTitle(e),
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        StatusBadge(
                          label: auditCategoryText(e.actionType),
                          color: color,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      auditWhen(e),
                      style: TextStyle(
                        color: context.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _AuditLine(
                      icon: Icons.admin_panel_settings_rounded,
                      label: AppStrings.t('audit_by_lbl'),
                      value: auditAdminLine(e, resolvedName: adminName),
                    ),
                    _AuditLine(
                      icon: Icons.person_search_rounded,
                      label: AppStrings.t('audit_target_lbl'),
                      value: auditTargetLine(e, resolvedName: targetName),
                      onTap: _openTarget(context),
                    ),
                    if (lines.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: color.withValues(alpha: 0.14),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final line in lines)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: SelectableText(
                                  '• $line',
                                  style: TextStyle(
                                    color: context.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AuditLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  const _AuditLine({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final linked = onTap != null;
    return Clickable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: context.textTertiary),
            const SizedBox(width: 6),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$label: ',
                      style: TextStyle(
                        color: context.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: value,
                      style: TextStyle(
                        color: linked ? AppTheme.info : context.textPrimary,
                        decoration: linked ? TextDecoration.underline : null,
                      ),
                    ),
                  ],
                ),
                style: const TextStyle(fontSize: 12),
              ),
            ),
            if (linked)
              Icon(
                Icons.open_in_new_rounded,
                size: 13,
                color: context.textTertiary,
              ),
          ],
        ),
      ),
    );
  }
}
