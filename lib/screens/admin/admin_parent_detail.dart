import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transit_core/transit_core.dart';
import '../../app/admin_format.dart';
import '../../app/locale_provider.dart';
import '../../data/admin_repository.dart';
import '../../services/audit_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/confirm_delete_dialog.dart';
import '../../widgets/entity_widgets.dart';
import '../../widgets/glass_card.dart';
import 'admin_history_tabs.dart';
import 'admin_links.dart';
import '../../widgets/responsive.dart';

class AdminParentDetail extends StatefulWidget {
  final String parentId;
  const AdminParentDetail({super.key, required this.parentId});

  @override
  State<AdminParentDetail> createState() => _AdminParentDetailState();
}

class _AdminParentDetailState extends State<AdminParentDetail> {
  final _repo = AdminRepository.instance;
  bool _editing = false;
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _saving = false;
  // Set in `initState` (not a field initializer — `widget` isn't attached
  // yet at that point) exactly once, same fix applied across every other
  // screen in this app that built its stream inline inside `build()`.
  late final Stream<({AppUser user, String deletedBy})?> _parentStream;

  /// This parent's children, queried directly (`parentId == uid`). It used
  /// to filter the shared all-students stream, which — being a cached
  /// broadcast stream — never re-delivered its data to this late
  /// subscriber, so "Children" spun forever.
  late final Stream<List<Student>> _childrenStream;

  final _historyKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _parentStream = _repo.watchUserRecord(widget.parentId);
    _childrenStream = widget.parentId.isEmpty
        ? Stream.value(const <Student>[])
        : _repo.watchStudentsOfParent(widget.parentId);
    LocaleProvider.instance.addListener(_onLangChanged);
  }

  void _onLangChanged() => setState(() {});

  @override
  void dispose() {
    LocaleProvider.instance.removeListener(_onLangChanged);
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _startEditing(AppUser p) {
    _nameCtrl.text = p.name;
    _phoneCtrl.text = p.phone;
    _emailCtrl.text = p.email;
    setState(() => _editing = true);
  }

  Future<void> _save(AppUser p) async {
    setState(() => _saving = true);
    try {
      await _repo.updateUser(p.uid, {
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
      });
      if (mounted) {
        setState(() => _editing = false);
        _msg('Saved');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleActive(AppUser p) async {
    await _repo.updateUser(p.uid, {'isActive': !p.isActive});
    if (mounted) _msg(p.isActive ? 'Account deactivated' : 'Account activated');
  }

  /// Soft-delete (archive) — see `AdminRepository.deleteParent`'s doc
  /// comment. Cascades to the parent's own students, so pops back to the
  /// list rather than leaving the admin on a detail screen for an account
  /// that has just been archived.
  Future<void> _deleteParent(AppUser p) async {
    final confirmed = await showConfirmDeleteDialog(context);
    if (!confirmed) return;
    await _repo.deleteParent(p.uid);
    await AuditService.instance.logAction(
      adminId: FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
      actionType: AuditActionType.delete,
      targetEntityId: p.uid,
      description: 'Archived parent ${p.name}',
    );
    if (mounted) context.pop();
  }

  Future<void> _message(AppUser p) async {
    final ctrl = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Message ${p.name}'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. We\'ve fixed the pickup time issue you reported.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    if (text == null || text.isEmpty) return;
    await _repo.messageUser(p.uid, title: 'Message from admin', body: text);
    if (mounted) _msg('Message sent to ${p.name}');
  }

  void _msg(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: context.scaffoldBg,
        child: SafeArea(
          child: StreamBuilder<({AppUser user, String deletedBy})?>(
            stream: _parentStream,
            builder: (context, snap) {
              final record = snap.data;
              final Widget body;
              if (snap.hasError) {
                body = Center(
                  child: LoadErrorView(error: snap.error, what: 'this parent'),
                );
              } else if (snap.connectionState == ConnectionState.waiting &&
                  !snap.hasData) {
                body = const Center(child: CircularProgressIndicator());
              } else if (record == null) {
                body = Center(
                  child: Text(
                    'Parent not found.',
                    style: TextStyle(color: context.textSecondary),
                  ),
                );
              } else {
                body = _buildBody(context, record.user, record.deletedBy);
              }
              return Column(
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 12),
                  Expanded(child: body),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppUser p, String deletedBy) {
    return StreamBuilder<List<Student>>(
      stream: _childrenStream,
      builder: (context, childSnap) {
        final children = childSnap.data ?? const <Student>[];
        // One column on a phone; on a wide window the account sits left,
        // the children and their history right.
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 40),
          child: ResponsiveBody(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TwoPane(
                primary: [
                  _buildProfileCard(context, p, deletedBy),
                  _buildContactCard(context, p, children),
                  _buildControls(context, p),
                ],
                secondary: [
                  _buildChildrenSection(context, childSnap),
                  // Keyed so a resize across the breakpoint keeps the open
                  // tab and loaded history.
                  KeyedSubtree(
                    key: _historyKey,
                    child: _buildHistory(context, p, childSnap),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Clickable(
            onTap: () => context.pop(),
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
              AppStrings.t('parent_detail_title'),
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

  Widget _buildProfileCard(BuildContext context, AppUser p, String deletedBy) {
    final deactivated = isAccountDeactivated(p);
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EntityAvatar(
                photoUrl: p.photoUrl,
                color: AppTheme.parentPurple,
                fallbackEmoji: '👨‍👩‍👧',
                size: 60,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name.isEmpty ? 'Unnamed parent' : p.name,
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        AccountStatusBadge(user: p),
                        PresenceBadge(user: p),
                      ],
                    ),
                  ],
                ),
              ),
              if (!_editing && !p.isDeleted)
                IconButton(
                  onPressed: () => _startEditing(p),
                  icon: Icon(Icons.edit_rounded, color: context.textSecondary),
                ),
            ],
          ),
          const SizedBox(height: 12),
          LastSeenLine(user: p, fontSize: 12),
          if (deactivated) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.error.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                deactivationReason(p, deletedBy: deletedBy),
                style: const TextStyle(
                  color: AppTheme.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (_editing) ...[
            const SizedBox(height: 14),
            _EditField(label: AppStrings.t('name_lbl'), controller: _nameCtrl),
            const SizedBox(height: 8),
            _EditField(
              label: AppStrings.t('phone_lbl'),
              controller: _phoneCtrl,
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 8),
            _EditField(
              label: AppStrings.t('email_lbl'),
              controller: _emailCtrl,
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    label: AppStrings.t('cancel_action'),
                    color: AppTheme.error,
                    icon: Icons.close_rounded,
                    onTap: _saving
                        ? null
                        : () => setState(() => _editing = false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionBtn(
                    label: _saving
                        ? AppStrings.t('saving_action')
                        : AppStrings.t('save_action'),
                    color: AppTheme.success,
                    icon: Icons.check_rounded,
                    onTap: _saving ? null : () => _save(p),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Contact details, the family home (the children's pickup pin — a parent
  /// account has no address of its own), and the account's emergency
  /// contacts.
  Widget _buildContactCard(
    BuildContext context,
    AppUser p,
    List<Student> children,
  ) {
    // One "Home" block per distinct pin: siblings usually share one.
    final seen = <GeoCoord>{};
    final distinctHomes = [
      for (final c in children)
        if (c.pickupLocation != null && seen.add(c.pickupLocation!)) c,
    ];
    return SectionCard(
      title: 'Contact & home',
      icon: Icons.contact_phone_rounded,
      color: AppTheme.parentPurple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoLine(
            icon: Icons.phone_rounded,
            label: AppStrings.t('phone_lbl'),
            value: p.phone.isEmpty ? '—' : p.phone,
            color: AppTheme.adminEmerald,
          ),
          InfoLine(
            icon: Icons.email_rounded,
            label: AppStrings.t('email_lbl'),
            value: p.email.isEmpty ? '—' : p.email,
            color: AppTheme.driverCyan,
          ),
          InfoLine(
            icon: Icons.workspace_premium_rounded,
            label: 'Subscription',
            value: _accountSubscription(p),
            color: p.isSubscriptionActive ? AppTheme.success : AppTheme.warning,
          ),
          if (p.createdAt != null)
            InfoLine(
              icon: Icons.event_rounded,
              label: 'Member since',
              value: formatDate(p.createdAt!),
              color: AppTheme.info,
            ),
          const SizedBox(height: 4),
          if (distinctHomes.isEmpty)
            const LocationBlock(
              title: 'Home',
              coord: null,
              icon: Icons.home_rounded,
              color: AppTheme.parentPurple,
              note: 'Set when a child\'s pickup point is pinned.',
            )
          else
            ...distinctHomes.map(
              (c) => LocationBlock(
                title: distinctHomes.length == 1
                    ? 'Home (pickup point)'
                    : 'Home — ${c.name}\'s pickup point',
                coord: c.pickupLocation,
                icon: Icons.home_rounded,
                color: AppTheme.parentPurple,
              ),
            ),
          const SizedBox(height: 8),
          EmergencyContactsBlock(
            title: 'Emergency contacts',
            contacts: p.emergencyContacts,
          ),
        ],
      ),
    );
  }

  String _accountSubscription(AppUser p) {
    if (p.isSubscriptionActive) return 'Active (purchased)';
    if (p.subscriptionStatus == 'trial') {
      final end = p.trialEndDate;
      if (end == null) return 'Trial';
      return p.isTrialExpired
          ? 'Trial ended ${formatDate(end)}'
          : 'Trial until ${formatDate(end)}';
    }
    final s = p.subscriptionStatus;
    return s.isEmpty ? 'None' : '${s[0].toUpperCase()}${s.substring(1)}';
  }

  Widget _buildChildrenSection(
    BuildContext context,
    AsyncSnapshot<List<Student>> snap,
  ) {
    return SectionCard(
      title: AppStrings.t('children_section_title'),
      icon: Icons.child_care_rounded,
      color: AppTheme.parentPurple,
      trailing: snap.hasData
          ? StatusBadge(
              label: '${snap.data!.length}',
              color: AppTheme.parentPurple,
            )
          : null,
      child: snapshotView<List<Student>>(
        snap,
        what: 'children',
        builder: (children) {
          if (children.isEmpty) {
            return Text(
              'No linked children.',
              style: TextStyle(color: context.textSecondary, fontSize: 12),
            );
          }
          return Column(
            children: [
              for (final c in children) StudentSummaryCard(student: c),
            ],
          );
        },
      ),
    );
  }

  /// Attendance, missed-bus requests and sign-ins for this family. The
  /// first two are per child (the child is who rides); access is the
  /// parent's own account.
  Widget _buildHistory(
    BuildContext context,
    AppUser p,
    AsyncSnapshot<List<Student>> childSnap,
  ) {
    if (!childSnap.hasData) {
      return SectionCard(
        title: 'History',
        icon: Icons.history_rounded,
        color: AppTheme.parentPurple,
        child: snapshotView<List<Student>>(
          childSnap,
          what: 'children',
          builder: (_) => const SizedBox.shrink(),
        ),
      );
    }
    final children = childSnap.data!;
    final ids = [for (final c in children) c.id]..sort();
    final names = {for (final c in children) c.id: c.name};
    return HistoryTabs(
      color: AppTheme.parentPurple,
      tabs: [
        (
          'Attendance trips',
          AttendanceHistoryList(
            studentIds: ids,
            names: names,
            showStudent: true,
          ),
        ),
        (
          AppStrings.t('missed_logs_tab'),
          MissedBusHistoryList(studentIds: ids, showStudent: true),
        ),
        (AppStrings.t('access_tab'), AccessLogList(uid: p.uid)),
      ],
    );
  }

  Widget _buildControls(BuildContext context, AppUser p) {
    // A deleted account is a tombstone: there is nothing to switch back on
    // (the user's sign-in is gone, or an admin archived it), so the
    // activate/delete actions would only mislead.
    if (p.isDeleted) {
      return SectionCard(
        title: AppStrings.t('controls_title'),
        icon: Icons.tune_rounded,
        color: AppTheme.parentPurple,
        child: Text(
          'This account has been deleted. Its history stays on record; it '
          'can no longer be activated or messaged.',
          style: TextStyle(color: context.textSecondary, fontSize: 12),
        ),
      );
    }
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.t('controls_title'),
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionBtn(
                  label: p.isActive
                      ? AppStrings.t('deactivate_action')
                      : 'Activate', // not requested this pass
                  color: p.isActive ? AppTheme.error : AppTheme.success,
                  icon: p.isActive
                      ? Icons.block_rounded
                      : Icons.check_circle_rounded,
                  onTap: () => _toggleActive(p),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionBtn(
                  label: AppStrings.t('message_action'),
                  color: AppTheme.parentPurple,
                  icon: Icons.chat_bubble_rounded,
                  onTap: () => _message(p),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: _ActionBtn(
              label: AppStrings.t('delete_action'),
              color: AppTheme.error,
              icon: Icons.delete_outline_rounded,
              onTap: () => _deleteParent(p),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────
class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  // Email/Phone must stay LTR even under the Urdu/RTL locale so the admin
  // can type the value naturally (digits, '@', '.') without it reordering
  // mid-keystroke; left null for fields like Name that should follow the
  // ambient (possibly RTL) directionality.
  final TextDirection? textDirection;
  const _EditField({
    required this.label,
    required this.controller,
    this.textDirection,
  });
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textDirection: textDirection,
      style: TextStyle(color: context.textPrimary, fontSize: 14),
      decoration: InputDecoration(labelText: label),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;
  const _ActionBtn({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Clickable(
      onTap: onTap,
      child: Opacity(
        opacity: disabled ? 0.5 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.14),
                color.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 15),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
