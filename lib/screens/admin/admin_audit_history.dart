import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/locale_provider.dart';
import '../../services/audit_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';

/// Real Audit History viewer — reads the `auditLogs` collection
/// `AuditService` has always written to (every approve/suspend/archive
/// action elsewhere in this app already calls `AuditService.logAction`),
/// replacing the old "coming soon" stub on the Profile screen's Security
/// section.
class AdminAuditHistory extends StatefulWidget {
  const AdminAuditHistory({super.key});

  @override
  State<AdminAuditHistory> createState() => _AdminAuditHistoryState();
}

class _AdminAuditHistoryState extends State<AdminAuditHistory> {
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
                      if (logs.isEmpty) {
                        return _EmptyState();
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: logs.length,
                        itemBuilder: (context, i) =>
                            _AuditLogRow(entry: logs[i]),
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
            AppStrings.t('audit_history'),
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

class _AuditLogRow extends StatelessWidget {
  final AuditLogEntry entry;
  const _AuditLogRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(entry.actionType);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_iconFor(entry.actionType), color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.description,
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${entry.timestamp.toLocal()}'.split('.').first,
                    style: TextStyle(color: context.textTertiary, fontSize: 11),
                  ),
                ],
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
            Icon(
              Icons.history_edu_outlined,
              size: 48,
              color: context.textTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              'No administrative actions recorded yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textTertiary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
