import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/locale_provider.dart';
import '../../services/audit_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';

/// Real "Login Session History" viewer — reads the `loginSessions`
/// collection, which `AuthService.signInWithEmail` now writes to on every
/// successful admin sign-in, replacing the old "coming soon" stub on the
/// Profile screen's Security section.
class AdminSessionHistory extends StatefulWidget {
  const AdminSessionHistory({super.key});

  @override
  State<AdminSessionHistory> createState() => _AdminSessionHistoryState();
}

class _AdminSessionHistoryState extends State<AdminSessionHistory> {
  late Future<List<LoginSessionEntry>> _sessionsFuture;

  @override
  void initState() {
    super.initState();
    _sessionsFuture = _fetch();
    LocaleProvider.instance.addListener(_onLangChanged);
  }

  Future<List<LoginSessionEntry>> _fetch() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Future.value(const []);
    return AuditService.instance.fetchLoginSessions(adminId: uid);
  }

  void _onLangChanged() => setState(() {});

  @override
  void dispose() {
    LocaleProvider.instance.removeListener(_onLangChanged);
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _sessionsFuture = _fetch());
    await _sessionsFuture;
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
                  child: FutureBuilder<List<LoginSessionEntry>>(
                    future: _sessionsFuture,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final sessions = snap.data ?? const <LoginSessionEntry>[];
                      if (sessions.isEmpty) {
                        return _EmptyState();
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: sessions.length,
                        itemBuilder: (context, i) =>
                            _SessionRow(entry: sessions[i], isCurrent: i == 0),
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
            AppStrings.t('login_session_history'),
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

class _SessionRow extends StatelessWidget {
  final LoginSessionEntry entry;
  final bool isCurrent;
  const _SessionRow({required this.entry, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
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
                color: AppTheme.info.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.login_rounded, color: AppTheme.info, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        entry.platform,
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(width: 8),
                        StatusBadge(
                          label: AppStrings.t('current_session_badge'),
                          color: AppTheme.success,
                        ),
                      ],
                    ],
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
            Icon(Icons.history_rounded, size: 48, color: context.textTertiary),
            const SizedBox(height: 12),
            Text(
              AppStrings.t('no_sessions_recorded'),
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textTertiary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
