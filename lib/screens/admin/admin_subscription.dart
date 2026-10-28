import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transit_core/transit_core.dart';
import '../../app/locale_provider.dart';
import '../../data/admin_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';

/// Manages each student's real `subscriptionStatus` and shows real collected/
/// pending/overdue totals from `payments`. The screen used to model a flat
/// per-role "admin collects a subscription fee from drivers/students/parents"
/// business — that concept has no backing field anywhere in `transit_core`'s
/// schema (fees are per-student, paid by a parent, not a platform fee on
/// every account type), so it was replaced rather than wired to fake data.
class AdminSubscription extends StatefulWidget {
  const AdminSubscription({super.key});

  @override
  State<AdminSubscription> createState() => _AdminSubscriptionState();
}

class _AdminSubscriptionState extends State<AdminSubscription> {
  final _repo = AdminRepository.instance;
  List<Student>? _students;
  List<Payment>? _payments;

  // Previously these errors were only `debugPrint`ed — `_students`/
  // `_payments` stayed `null` forever, which `build()` reads as "still
  // loading", so the screen span forever on a spinner instead of ever
  // surfacing what actually went wrong (a permission error, a dropped
  // connection, etc.). Tracked separately per stream so one failing while
  // the other succeeds still shows real data for the one that's fine.
  Object? _studentsError;
  Object? _paymentsError;

  StreamSubscription<List<Student>>? _studentsSub;
  StreamSubscription<List<Payment>>? _paymentsSub;

  @override
  void initState() {
    super.initState();
    _subscribe();
    LocaleProvider.instance.addListener(_onLangChanged);
  }

  /// Checklist item #1: is the stream firing before auth is actually ready?
  /// By the time this screen builds, `AuthService.signInWithEmail` has
  /// already `await`ed the sign-in and the Firestore role check, and
  /// `AdminLayout`'s router guard requires `cachedRole == 'admin'` before
  /// `/admin` is even reachable — so in *this* app's flow, auth should
  /// already be settled. This just makes that assumption visible instead of
  /// assumed: if `currentUser` ever prints `null` here, that assumption is
  /// wrong and is the actual bug, not the stream.
  void _logAuthState() {
    final user = FirebaseAuth.instance.currentUser;
    // ignore: avoid_print
    print(
      '[AdminSubscription] auth state: uid=${user?.uid}, '
      'email=${user?.email}, emailVerified=${user?.emailVerified}',
    );
  }

  /// Checklist item #3: does a one-time `.get()` from the server succeed
  /// while the persistent `.snapshots()` listener hangs? `.snapshots()` uses
  /// Firestore's long-lived streaming channel (gRPC/HTTP2, falling back to
  /// WebChannel long-polling); `.get()` is a single request/response. Some
  /// networks (corporate proxies, certain mobile carriers, some VPNs) allow
  /// normal HTTPS request/response through but block or kill long-lived
  /// streaming connections — "internet works fine" in a browser while every
  /// Firestore listener hangs is the exact fingerprint of that. If this
  /// succeeds while `.snapshots()` times out, that's the answer.
  Future<void> _testServerFetch() async {
    // ignore: avoid_print
    print('[AdminSubscription] diagnostic: one-time server fetch...');
    try {
      final snap = await Db.students
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 8));
      // ignore: avoid_print
      print(
        '[AdminSubscription] diagnostic: server fetch OK, '
        '${snap.docs.length} doc(s) — if .snapshots() still hangs, this '
        'confirms a streaming-channel-specific block (ISP/firewall), not a '
        'rules, auth, or project-config problem.',
      );
    } catch (e) {
      // ignore: avoid_print
      print(
        '[AdminSubscription] diagnostic: server fetch FAILED -> $e — this '
        'is a more informative error than the stream ever showed (look for '
        'UNAVAILABLE, DEADLINE_EXCEEDED, or a clear permission/config code).',
      );
    }
  }

  // A 5s `.timeout()` on each stream is diagnostic scaffolding, not a
  // permanent fix: Firestore's realtime listeners are meant to sit open
  // indefinitely waiting for the *next* change, so a silent, truly-never-
  // completing subscription (no data, no error — a genuine engine/transport
  // hang rather than a rejected query) was otherwise indistinguishable from
  // "haven't typed anything new to sync yet". This forces a `TimeoutException`
  // onto the stream after 5s of silence so that case is visible instead of
  // looking identical to an infinite spinner. `print()` (not `debugPrint`)
  // deliberately, per request, so it's unmistakable in the Debug Console.
  void _subscribe() {
    _logAuthState();
    _testServerFetch();
    // ignore: avoid_print
    print('[AdminSubscription] students: subscribing...');
    _studentsSub = _repo.watchStudents().timeout(const Duration(seconds: 5)).listen(
      (v) {
        // ignore: avoid_print
        print('[AdminSubscription] students: got ${v.length} doc(s)');
        setState(() {
          _students = v;
          _studentsError = null;
        });
      },
      onError: (e) {
        // ignore: avoid_print
        print('[AdminSubscription] students: ERROR -> $e');
        if (mounted) setState(() => _studentsError = e);
      },
    );
    // ignore: avoid_print
    print('[AdminSubscription] payments: subscribing...');
    _paymentsSub = _repo.watchAllPayments().timeout(const Duration(seconds: 5)).listen(
      (v) {
        // ignore: avoid_print
        print('[AdminSubscription] payments: got ${v.length} doc(s)');
        setState(() {
          _payments = v;
          _paymentsError = null;
        });
      },
      onError: (e) {
        // ignore: avoid_print
        print('[AdminSubscription] payments: ERROR -> $e');
        if (mounted) setState(() => _paymentsError = e);
      },
    );
  }

  Future<void> _retry() async {
    await _studentsSub?.cancel();
    await _paymentsSub?.cancel();
    setState(() {
      _studentsError = null;
      _paymentsError = null;
    });
    _subscribe();
  }

  void _onLangChanged() => setState(() {});

  @override
  void dispose() {
    LocaleProvider.instance.removeListener(_onLangChanged);
    _studentsSub?.cancel();
    _paymentsSub?.cancel();
    super.dispose();
  }

  static String _fmtPaisa(int paisa) {
    final rupees = (paisa / 100).round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < rupees.length; i++) {
      if (i > 0 && (rupees.length - i) % 3 == 0) buf.write(',');
      buf.write(rupees[i]);
    }
    return '₨$buf';
  }

  Color _statusColor(SubscriptionStatus s) {
    switch (s) {
      case SubscriptionStatus.active:
        return AppTheme.success;
      case SubscriptionStatus.trial:
        return AppTheme.info;
      case SubscriptionStatus.gracePeriod:
        return AppTheme.warning;
      case SubscriptionStatus.expired:
      case SubscriptionStatus.suspended:
      case SubscriptionStatus.cancelled:
        return AppTheme.error;
    }
  }

  String _statusLabel(SubscriptionStatus s) {
    switch (s) {
      case SubscriptionStatus.active:
        return AppStrings.t('active_lbl');
      case SubscriptionStatus.gracePeriod:
        return 'Grace Period'; // not requested this pass
      default:
        final name = s.name;
        return name[0].toUpperCase() + name.substring(1);
    }
  }

  Future<void> _toggleSubscription(Student s) async {
    final cancelling = s.subscriptionStatus != SubscriptionStatus.cancelled;
    await _repo.updateStudent(s.id, {
      'subscriptionStatus': cancelling
          ? SubscriptionStatus.cancelled.name
          : SubscriptionStatus.active.name,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            cancelling
                ? '${s.name}\'s subscription cancelled'
                : '${s.name}\'s subscription reactivated',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final students = _students;
    final payments = _payments;
    final paymentsLoading = payments == null && _paymentsError == null;

    final collected = payments == null
        ? 0
        : payments
              .where((p) => p.status == PaymentStatus.paid)
              .fold<int>(0, (s, p) => s + p.amountPaisa);
    final pending = payments == null
        ? 0
        : payments
              .where((p) => p.status == PaymentStatus.pending)
              .fold<int>(0, (s, p) => s + p.amountPaisa);
    final overdue = payments == null
        ? 0
        : payments
              .where((p) => p.status == PaymentStatus.overdue)
              .fold<int>(0, (s, p) => s + p.amountPaisa);
    String feeValue(String ok) =>
        paymentsLoading ? '…' : (_paymentsError != null ? '—' : ok);

    return Scaffold(
      body: Container(
        decoration: context.scaffoldBg,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              children: [
                _Header(onBack: () => context.pop()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      GlassCard(
                        padding: const EdgeInsets.all(18),
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.purple.withValues(alpha: 0.14),
                            AppTheme.info.withValues(alpha: 0.08),
                          ],
                        ),
                        borderColor: AppTheme.purple.withValues(alpha: 0.2),
                        child: Row(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                gradient: AppTheme.mainGradient,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.subscriptions_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppStrings.t('subscription_management'),
                                    style: TextStyle(
                                      color: context.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppStrings.t('subscription_desc'),
                                    style: TextStyle(
                                      color: context.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      GlassCard(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.t('fee_collection_title'),
                              style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _StatPill(
                                  label: AppStrings.t('collected_lbl'),
                                  value: feeValue(_fmtPaisa(collected)),
                                  color: AppTheme.success,
                                ),
                                const SizedBox(width: 8),
                                _StatPill(
                                  label: AppStrings.t('pending_lbl'),
                                  value: feeValue(_fmtPaisa(pending)),
                                  color: AppTheme.warning,
                                ),
                                const SizedBox(width: 8),
                                _StatPill(
                                  label: AppStrings.t('overdue_lbl'),
                                  value: feeValue(_fmtPaisa(overdue)),
                                  color: AppTheme.error,
                                ),
                              ],
                            ),
                            if (_paymentsError != null) ...[
                              const SizedBox(height: 8),
                              _InlineError(
                                error: _paymentsError!,
                                onRetry: _retry,
                              ),
                            ],
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () => context.push('/admin/fees'),
                              child: Row(
                                children: [
                                  Text(
                                    AppStrings.t(
                                      'view_full_fee_breakdown_action',
                                    ),
                                    style: TextStyle(
                                      color: AppTheme.adminAccent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: AppTheme.adminAccent,
                                    size: 14,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      GlassCard(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.t('students_lbl'),
                              style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (_studentsError != null)
                              _InlineError(
                                error: _studentsError!,
                                onRetry: _retry,
                              )
                            else if (students == null)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else if (students.isEmpty)
                              Text(
                                'No students registered yet.',
                                style: TextStyle(
                                  color: context.textSecondary,
                                ),
                              )
                            else
                              ...students.map(
                                (s) => _SubscriberRow(
                                  student: s,
                                  color: _statusColor(s.subscriptionStatus),
                                  statusLabel: _statusLabel(
                                    s.subscriptionStatus,
                                  ),
                                  onToggle: () => _toggleSubscription(s),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown in place of an endless spinner when a Firestore stream errors —
/// the whole point of tracking `_studentsError`/`_paymentsError` instead of
/// just `debugPrint`ing them (see `_AdminSubscriptionState`'s doc comment).
class _InlineError extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const _InlineError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 18),
              const SizedBox(width: 8),
              Text(
                'Firestore error',
                style: TextStyle(
                  color: AppTheme.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // The raw exception text, verbatim — e.g.
          // `[cloud_firestore/failed-precondition] The query requires an
          // index...` or `[cloud_firestore/permission-denied] Missing or
          // insufficient permissions.` — shown directly rather than a
          // generic "couldn't load" message, so the actual Firebase error
          // code is visible on-device without needing logcat.
          SelectableText(
            error.toString(),
            style: const TextStyle(
              color: Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: onRetry, child: const Text('Retry')),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: context.textTertiary, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriberRow extends StatelessWidget {
  final Student student;
  final Color color;
  final String statusLabel;
  final VoidCallback onToggle;

  const _SubscriberRow({
    required this.student,
    required this.color,
    required this.statusLabel,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isCancelled =
        student.subscriptionStatus == SubscriptionStatus.cancelled;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.14)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.school_rounded, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    statusLabel,
                    style: TextStyle(color: color, fontSize: 12),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onToggle,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Text(
                  isCancelled
                      ? 'Reactivate' // not requested this pass
                      : AppStrings.t('cancel_action'),
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
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
                child: Text(
                  '←',
                  style: TextStyle(color: context.textPrimary, fontSize: 18),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            AppStrings.t('subscription_title'),
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
