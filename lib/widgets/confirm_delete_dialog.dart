import 'package:flutter/material.dart';
import '../app/locale_provider.dart';
import '../theme/app_theme.dart';

/// Shared confirmation dialog for every "Delete" (soft-delete/archive)
/// action in the admin app — Parent/Student/Driver Detail all show the same
/// dialog rather than each screen reimplementing its own, so the wording
/// and warning stay consistent no matter which entity is being removed.
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
