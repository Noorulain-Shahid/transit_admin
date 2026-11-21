import 'package:transit_core/transit_core.dart';

import '../app/admin_format.dart';
import '../services/audit_service.dart';
import 'account_admin_client.dart';
import 'admin_repository.dart';

export 'account_admin_client.dart' show AccountActionException;

/// "Parent", "Driver", "Student" — the role as an audit record names it.
String accountRoleLabel(UserRole role) => switch (role) {
  UserRole.parent => 'Parent',
  UserRole.driver => 'Driver',
  UserRole.student => 'Student',
  UserRole.admin => 'Admin',
};

/// Deactivate, Activate and Delete permanently for parent, driver and
/// self-registered student accounts — the writes, then the audit record
/// with who, what and the before/after state. Every screen goes through
/// here so the three detail screens can't drift apart.
class AccountActions {
  AccountActions._();
  static final AccountActions instance = AccountActions._();

  final _repo = AdminRepository.instance;
  final _audit = AuditService.instance;

  String _name(AccountRecord r) =>
      r.user.name.trim().isEmpty ? 'Unnamed account' : r.user.name.trim();

  List<AuditDetail> _contact(AccountRecord r, {bool former = false}) => [
    if (r.user.email.isNotEmpty)
      AuditDetail(former ? 'Email (erased)' : 'Email', r.user.email),
    if (r.user.phone.isNotEmpty)
      AuditDetail(former ? 'Phone (erased)' : 'Phone', r.user.phone),
  ];

  Future<void> deactivate(AccountRecord r) async {
    if (r.state != AccountState.active) {
      throw const AccountActionException('This account is not active.');
    }
    final role = accountRoleLabel(r.user.role);
    await _repo.deactivateAccount(r.uid);
    await _audit.logAction(
      actionType: AuditActionType.statusChange,
      action: AuditActions.accountDeactivate,
      targetEntityId: r.uid,
      targetType: r.user.role.name,
      targetName: _name(r),
      targetRole: role,
      description: 'Deactivated ${role.toLowerCase()} ${_name(r)}',
      changes: const [
        AuditChange('Account status', 'Active', 'Deactivated'),
        AuditChange('Sign-in', 'Allowed', 'Blocked'),
      ],
      details: _contact(r),
    );
  }

  Future<AccountRestoreResult> activate(AccountRecord r) async {
    if (r.state != AccountState.deactivated) {
      throw const AccountActionException(
        'Only a deactivated account can be activated.',
      );
    }
    final role = accountRoleLabel(r.user.role);
    final before = r.isLegacyArchive ? 'Deactivated (archived)' : 'Deactivated';
    final result = await _repo.activateAccount(r);
    await _audit.logAction(
      actionType: AuditActionType.statusChange,
      action: AuditActions.accountActivate,
      targetEntityId: r.uid,
      targetType: r.user.role.name,
      targetName: _name(r),
      targetRole: role,
      description: 'Activated ${role.toLowerCase()} ${_name(r)}',
      changes: [
        AuditChange('Account status', before, 'Active'),
        const AuditChange('Sign-in', 'Blocked', 'Allowed'),
      ],
      details: [
        ..._contact(r),
        if (result.profileRestored)
          AuditDetail(
            r.user.role == UserRole.driver
                ? 'Driver profile'
                : 'Student record',
            'Restored from the archive',
          ),
        if (result.restoredChildren.isNotEmpty)
          AuditDetail('Children restored', result.restoredChildren.join(', ')),
      ],
    );
    return result;
  }

  /// Deletes the Firebase sign-in through the Worker, then — only once that
  /// succeeded — writes the tombstone and archives the account's records.
  /// A Worker failure throws [AccountActionException] and changes nothing.
  Future<AccountDeletionResult> deletePermanently(AccountRecord r) async {
    if (r.user.role == UserRole.admin) {
      throw const AccountActionException(
        'Admin accounts cannot be deleted from the admin panel.',
      );
    }
    if (r.state == AccountState.deleted) {
      throw const AccountActionException('This account is already deleted.');
    }
    final role = accountRoleLabel(r.user.role);
    final before = accountStateLabel(r.state);

    await AccountAdminClient.instance.deleteSignIn(r.uid);

    final AccountDeletionResult result;
    try {
      result = await _repo.tombstoneDeletedAccount(r);
    } catch (_) {
      // The sign-in is gone but Firestore still shows a live account. The
      // Worker treats a missing sign-in as success, so running the delete
      // again finishes the job.
      throw const AccountActionException(
        'The sign-in was deleted, but the account records could not be '
        'updated. Run "Delete permanently" again to finish.',
      );
    }

    await _audit.logAction(
      actionType: AuditActionType.delete,
      action: AuditActions.accountDeletePermanently,
      targetEntityId: r.uid,
      targetType: r.user.role.name,
      targetName: _name(r),
      targetRole: role,
      description: 'Permanently deleted ${role.toLowerCase()} ${_name(r)}',
      changes: [
        AuditChange('Account status', before, 'Deleted (permanent)'),
        const AuditChange('Sign-in', 'Exists', 'Removed'),
      ],
      details: [
        ..._contact(r, former: true),
        const AuditDetail(
          'Email reuse',
          'The email can now be used to register a new account',
        ),
        if (result.profileArchived)
          AuditDetail(
            r.user.role == UserRole.driver
                ? 'Driver profile'
                : 'Student record',
            'Archived',
          ),
        if (result.archivedChildren.isNotEmpty)
          AuditDetail('Children archived', result.archivedChildren.join(', ')),
        if (result.studentsReassigned > 0)
          AuditDetail(
            'Students unassigned from this driver',
            '${result.studentsReassigned}',
          ),
      ],
    );
    return result;
  }
}
