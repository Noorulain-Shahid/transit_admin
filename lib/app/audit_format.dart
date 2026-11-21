import '../services/audit_service.dart';
import 'admin_format.dart';

/// Pure wording for the audit log (Activity Tracking and Audit History),
/// kept out of the widgets so the fallbacks for older, detail-less entries
/// are unit-tested.

/// "Status change", not the enum's `statusChange`.
String auditCategoryLabel(AuditActionType type) => switch (type) {
  AuditActionType.create => 'Create',
  AuditActionType.update => 'Update',
  AuditActionType.delete => 'Delete',
  AuditActionType.override => 'Override',
  AuditActionType.statusChange => 'Status change',
  AuditActionType.broadcast => 'Broadcast',
  AuditActionType.emergencyTrigger => 'Emergency trigger',
};

/// A one-line explanation of what each category holds.
String auditCategoryHint(AuditActionType type) => switch (type) {
  AuditActionType.create => 'Records an admin created',
  AuditActionType.update => 'Profile and record edits',
  AuditActionType.delete =>
    'Accounts deleted permanently, students and records removed',
  AuditActionType.override => 'Manual overrides',
  AuditActionType.statusChange =>
    'Activations, deactivations, approvals, suspensions, document checks',
  AuditActionType.broadcast => 'Messages sent to many users',
  AuditActionType.emergencyTrigger => 'Emergency alerts raised',
};

/// The record's headline: what was done.
String auditActionTitle(AuditLogEntry e) {
  final known = switch (e.action) {
    AuditActions.accountDeactivate => 'Deactivated account',
    AuditActions.accountActivate => 'Activated account',
    AuditActions.accountDeletePermanently => 'Permanently deleted account',
    AuditActions.accountEdit => 'Edited account details',
    AuditActions.driverApprove => 'Approved driver',
    AuditActions.driverSuspend => 'Suspended driver',
    AuditActions.documentVerify => 'Verified document',
    AuditActions.documentReject => 'Rejected document',
    AuditActions.studentArchive => 'Removed student',
    AuditActions.studentEdit => 'Edited student details',
    AuditActions.studentTransport => 'Changed student transport',
    _ => null,
  };
  if (known != null) return known;
  final description = e.description.trim();
  if (description.isNotEmpty) return description;
  return auditCategoryLabel(e.actionType);
}

String _roleWord(String type) => switch (type) {
  'parent' => 'Parent',
  'driver' => 'Driver',
  'student' => 'Student',
  'document' => 'Document',
  'admin' => 'Admin',
  '' => '',
  _ => '${type[0].toUpperCase()}${type.substring(1)}',
};

/// "Sara Khan · Parent · ID u123". [resolvedName] is the name looked up
/// from `users/{id}` (or the student record) for entries that never stored
/// one; without either, the line still names the record by its id.
String auditTargetLine(AuditLogEntry e, {String? resolvedName}) {
  final name = e.targetName.isNotEmpty
      ? e.targetName
      : (resolvedName ?? '').trim();
  final role = e.targetRole.isNotEmpty ? e.targetRole : _roleWord(e.targetType);
  final id = e.targetEntityId.trim();
  final parts = [
    if (name.isNotEmpty) name,
    if (role.isNotEmpty) role,
    if (id.isNotEmpty) 'ID $id',
  ];
  return parts.isEmpty ? 'No target recorded' : parts.join(' · ');
}

/// "Status: Active → Deactivated", then "Reason: …" — every specific the
/// entry carries, in the order it was written. An older entry that kept
/// only a sentence has that sentence as its title, and says plainly that
/// nothing more was recorded.
List<String> auditDetailLines(AuditLogEntry e) {
  final lines = <String>[
    for (final c in e.changes)
      '${c.label}: ${c.from.isEmpty ? '—' : c.from} → ${c.to.isEmpty ? '—' : c.to}',
    for (final d in e.details)
      d.label.isEmpty
          ? d.value
          : '${d.label}: ${d.value.isEmpty ? '—' : d.value}',
  ];
  if (e.isLegacy) {
    lines.add(
      'Logged before detailed records were kept — no before/after values '
      'were saved for this entry.',
    );
  }
  return lines;
}

/// "Ali Admin (ali@example.com)", falling back to whichever of the two is
/// known, then to the uid.
String auditAdminLine(AuditLogEntry e, {String? resolvedName}) {
  final name = (resolvedName ?? '').trim();
  final email = e.adminEmail.trim();
  if (name.isNotEmpty && email.isNotEmpty) return '$name ($email)';
  if (name.isNotEmpty) return name;
  if (email.isNotEmpty) return email;
  return e.adminId.isEmpty || e.adminId == 'unknown'
      ? 'Unknown admin'
      : 'Admin ${e.adminId}';
}

/// "14 Nov, 9:42 PM".
String auditWhen(AuditLogEntry e, {DateTime? now}) =>
    formatExactTime(e.timestamp, now: now);

/// Counts per category, in enum order, leaving out empty categories.
List<MapEntry<AuditActionType, int>> auditCountsByCategory(
  Iterable<AuditLogEntry> entries,
) {
  final counts = <AuditActionType, int>{};
  for (final e in entries) {
    counts[e.actionType] = (counts[e.actionType] ?? 0) + 1;
  }
  return [
    for (final t in AuditActionType.values)
      if ((counts[t] ?? 0) > 0) MapEntry(t, counts[t]!),
  ];
}

/// Parses a category name handed over in a route's `extra`.
AuditActionType? auditCategoryFromName(Object? name) {
  if (name is! String) return null;
  for (final t in AuditActionType.values) {
    if (t.name == name) return t;
  }
  return null;
}
