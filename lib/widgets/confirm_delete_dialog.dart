import 'package:flutter/material.dart';
import '../app/locale_provider.dart';
import '../theme/app_theme.dart';

/// Confirmation for removing (archiving) a parent's child from Student
/// Detail. Accounts — parents, drivers, self-registered students — use the
/// Deactivate / Activate / Delete permanently dialogs in
/// `account_controls.dart` instead.
///
/// Returns `true` only if the admin tapped the destructive confirm button;
/// `false`/`null` (dismissed) otherwise. Callers should only act on `true`.
Future<bool> showConfirmDeleteDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(AppStrings.t('delete_confirm_title')),
      content: Text(AppStrings.t('delete_confirm_body')),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(AppStrings.t('cancel_action')),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(AppStrings.t('delete_confirm_action')),
        ),
      ],
    ),
  );
  return result ?? false;
}
