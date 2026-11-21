import 'package:flutter/material.dart';
import 'package:transit_core/transit_core.dart';

import '../app/admin_format.dart';
import '../app/locale_provider.dart';
import '../data/account_actions.dart';
import '../theme/app_theme.dart';
import 'entity_widgets.dart';
import 'responsive.dart';

/// Account controls shared by Parent, Driver and (self-registered) Student
/// Detail: Deactivate or Activate, and Delete permanently — each behind a
/// confirmation dialog, each written to the audit log by [AccountActions].
///
/// A Deleted account (removed permanently, or deleted by the user from the
/// app) gets no actions, only the reason.
class AccountControls extends StatefulWidget {
  final AccountRecord record;

  /// Extra lines for the confirmation dialogs, e.g. "Her 2 children will be
  /// archived too." for a parent.
  final String? deleteNote;
  final String? activateNote;

  const AccountControls({
    super.key,
    required this.record,
    this.deleteNote,
    this.activateNote,
  });

  @override
  State<AccountControls> createState() => _AccountControlsState();
}

class _AccountControlsState extends State<AccountControls> {
  bool _busy = false;

  AccountRecord get _r => widget.record;

  String get _name =>
      _r.user.name.trim().isEmpty ? 'this account' : _r.user.name.trim();

  Future<void> _run(
    Future<void> Function() action, {
    required String done,
  }) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(done)));
      }
    } on AccountActionException catch (e) {
      if (mounted) await _showError(e.message);
    } catch (e) {
      if (mounted) await _showError('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showError(String message) => showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(AppStrings.t('action_failed_title')),
      content: ConstrainedBox(
        constraints: kDialogConstraints,
        child: Text(message),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(AppStrings.t('ok_action')),
        ),
      ],
    ),
  );

  Future<void> _deactivate() async {
    final ok = await showAccountConfirmDialog(
      context,
      title: AppStrings.t(
        'deactivate_confirm_title',
      ).replaceFirst('{name}', _name),
      lines: [AppStrings.t('deactivate_confirm_body')],
      confirmLabel: AppStrings.t('deactivate_action'),
      color: AppTheme.warning,
    );
    if (!ok) return;
    await _run(
      () => AccountActions.instance.deactivate(_r),
      done: AppStrings.t('account_deactivated_msg'),
    );
  }

  Future<void> _activate() async {
    final ok = await showAccountConfirmDialog(
      context,
      title: AppStrings.t(
        'activate_confirm_title',
      ).replaceFirst('{name}', _name),
      lines: [
        AppStrings.t('activate_confirm_body'),
        if (_r.isLegacyArchive) AppStrings.t('activate_archived_note'),
        if (_r.isLegacyArchive && _r.user.role == UserRole.driver)
          AppStrings.t('activate_driver_roster_note'),
        if (widget.activateNote != null) widget.activateNote!,
      ],
      confirmLabel: AppStrings.t('activate_action'),
      color: AppTheme.success,
    );
    if (!ok) return;
    await _run(
      () => AccountActions.instance.activate(_r),
      done: AppStrings.t('account_activated_msg'),
    );
  }

  Future<void> _delete() async {
    final email = _r.user.email.trim();
    final ok = await showAccountConfirmDialog(
      context,
      title: AppStrings.t(
        'delete_permanently_confirm_title',
      ).replaceFirst('{name}', _name),
      lines: [
        AppStrings.t('delete_permanently_body'),
        if (email.isNotEmpty)
          AppStrings.t(
            'delete_permanently_email_note',
          ).replaceFirst('{email}', email),
        AppStrings.t('delete_permanently_history_note'),
        if (widget.deleteNote != null) widget.deleteNote!,
      ],
      confirmLabel: AppStrings.t('delete_permanently_action'),
      color: AppTheme.error,
      requireAcknowledgement: AppStrings.t('delete_permanently_ack'),
    );
    if (!ok) return;
    await _run(
      () => AccountActions.instance.deletePermanently(_r),
      done: AppStrings.t('account_deleted_msg'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = _r.state;
    if (state == AccountState.deleted) {
      return Text(
        '${accountStateReason(_r)} ${AppStrings.t('deleted_no_actions')}',
        style: TextStyle(color: context.textSecondary, fontSize: 12),
      );
    }
    final canDelete = _r.user.role != UserRole.admin;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        state == AccountState.active
            ? AccountActionButton(
                label: AppStrings.t('deactivate_action'),
                color: AppTheme.warning,
                icon: Icons.pause_circle_rounded,
                onTap: _busy ? null : _deactivate,
              )
            : AccountActionButton(
                label: AppStrings.t('activate_action'),
                color: AppTheme.success,
                icon: Icons.check_circle_rounded,
                onTap: _busy ? null : _activate,
              ),
        if (canDelete) ...[
          const SizedBox(height: 8),
          AccountActionButton(
            label: AppStrings.t('delete_permanently_action'),
            color: AppTheme.error,
            icon: Icons.delete_forever_rounded,
            onTap: _busy ? null : _delete,
          ),
        ],
        if (_busy) ...[
          const SizedBox(height: 8),
          const LinearProgressIndicator(minHeight: 2),
        ],
      ],
    );
  }
}

/// Confirmation for an account action. [lines] are separate paragraphs;
/// with [requireAcknowledgement] the confirm button stays disabled until
/// that checkbox is ticked (used for the irreversible delete).
Future<bool> showAccountConfirmDialog(
  BuildContext context, {
  required String title,
  required List<String> lines,
  required String confirmLabel,
  required Color color,
  String? requireAcknowledgement,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => _AccountConfirmDialog(
      title: title,
      lines: lines,
      confirmLabel: confirmLabel,
      color: color,
      acknowledgement: requireAcknowledgement,
    ),
  );
  return result ?? false;
}

class _AccountConfirmDialog extends StatefulWidget {
  final String title;
  final List<String> lines;
  final String confirmLabel;
  final Color color;
  final String? acknowledgement;
  const _AccountConfirmDialog({
    required this.title,
    required this.lines,
    required this.confirmLabel,
    required this.color,
    this.acknowledgement,
  });

  @override
  State<_AccountConfirmDialog> createState() => _AccountConfirmDialogState();
}

class _AccountConfirmDialogState extends State<_AccountConfirmDialog> {
  bool _ack = false;

  @override
  Widget build(BuildContext context) {
    final needsAck = widget.acknowledgement != null;
    return AlertDialog(
      title: Text(widget.title),
      content: ConstrainedBox(
        constraints: kDialogConstraints,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final line in widget.lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(line),
                ),
              if (needsAck)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _ack,
                  onChanged: (v) => setState(() => _ack = v ?? false),
                  title: Text(
                    widget.acknowledgement!,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(AppStrings.t('cancel_action')),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: widget.color),
          onPressed: needsAck && !_ack
              ? null
              : () => Navigator.of(context).pop(true),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

/// The detail screens' tinted action button, shared so the account
/// controls look like the buttons beside them.
class AccountActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;
  const AccountActionButton({
    super.key,
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
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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

/// The account's state badge plus, when it isn't Active, why — the block
/// every detail screen shows under the name.
class AccountStateNote extends StatelessWidget {
  final AccountRecord record;
  const AccountStateNote({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final reason = accountStateReason(record);
    if (reason.isEmpty) return const SizedBox.shrink();
    final color = accountStateColor(record.state);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        reason,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
