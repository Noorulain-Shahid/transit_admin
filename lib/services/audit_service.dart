import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:transit_core/transit_core.dart';

/// The category an action is counted under on Admin Activity Tracking.
enum AuditActionType {
  create,
  update,
  delete,
  override,
  statusChange,
  broadcast,
  emergencyTrigger,
}

/// Machine keys for the specific action inside a category — what the
/// Audit History screen turns into a title ("Deactivated account"). Stored
/// as `auditLogs/{id}.action`; entries written before this existed have
/// none and fall back to their `description`.
abstract final class AuditActions {
  static const accountDeactivate = 'account.deactivate';
  static const accountActivate = 'account.activate';
  static const accountDeletePermanently = 'account.deletePermanently';
  static const accountEdit = 'account.edit';
  static const driverApprove = 'driver.approve';
  static const driverSuspend = 'driver.suspend';
  static const documentVerify = 'document.verify';
  static const documentReject = 'document.reject';
  static const studentArchive = 'student.archive';
  static const studentEdit = 'student.edit';
  static const studentTransport = 'student.transport';
}

/// One field an action changed: `Status: Active → Deactivated`.
class AuditChange {
  final String label;
  final String from;
  final String to;
  const AuditChange(this.label, this.from, this.to);

  Map<String, String> toMap() => {'label': label, 'from': from, 'to': to};

  static AuditChange? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final label = asString(raw['label']);
    if (label.isEmpty) return null;
    return AuditChange(label, asString(raw['from']), asString(raw['to']));
  }
}

/// One extra fact about an action: `Reason: Photo is blurry`.
class AuditDetail {
  final String label;
  final String value;
  const AuditDetail(this.label, this.value);

  Map<String, String> toMap() => {'label': label, 'value': value};

  static AuditDetail? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final label = asString(raw['label']);
    final value = asString(raw['value']);
    if (label.isEmpty && value.isEmpty) return null;
    return AuditDetail(label, value);
  }
}

class AuditLogEntry {
  final String id;
  final DateTime timestamp;
  final String adminId;

  /// The admin's sign-in email when the action was taken (empty on older
  /// entries — the screen then resolves the name from `users/{adminId}`).
  final String adminEmail;
  final AuditActionType actionType;

  /// See [AuditActions]; empty on older entries.
  final String action;
  final String targetEntityId; // e.g. a uid, a student id, a document id

  /// `parent` / `driver` / `student` / `document` — empty on older entries.
  final String targetType;
  final String targetName;

  /// Human role line, e.g. "Parent", "Driver", "Student (child of Sara)".
  final String targetRole;
  final String description;

  /// Ordered — stored as lists, not maps, so they read back in the order
  /// they were written.
  final List<AuditChange> changes;
  final List<AuditDetail> details;
  final String ipAddress;

  AuditLogEntry({
    required this.id,
    required this.timestamp,
    required this.adminId,
    required this.actionType,
    required this.targetEntityId,
    required this.description,
    this.adminEmail = '',
    this.action = '',
    this.targetType = '',
    this.targetName = '',
    this.targetRole = '',
    this.changes = const [],
    this.details = const [],
    this.ipAddress = 'Unknown',
  });

  /// Written before targets, changes and details were recorded.
  bool get isLegacy =>
      action.isEmpty &&
      targetName.isEmpty &&
      changes.isEmpty &&
      details.isEmpty;

  factory AuditLogEntry.fromMap(String id, Map<String, dynamic> m) {
    final created = m['createdAt'];
    return AuditLogEntry(
      id: id,
      timestamp: created is Timestamp
          ? created.toDate()
          : (asDateOrNull(created) ?? DateTime.now()),
      adminId: asString(m['adminId'], 'unknown'),
      adminEmail: asString(m['adminEmail']),
      actionType: AuditActionType.values.firstWhere(
        (t) => t.name == m['actionType'],
        orElse: () => AuditActionType.update,
      ),
      action: asString(m['action']),
      targetEntityId: asString(m['targetEntityId']),
      targetType: asString(m['targetType']),
      targetName: asString(m['targetName']),
      targetRole: asString(m['targetRole']),
      description: asString(m['description']),
      changes: [
        if (m['changes'] is List)
          for (final c in m['changes'] as List) ?AuditChange.fromMap(c),
      ],
      details: [
        if (m['details'] is List)
          for (final d in m['details'] as List) ?AuditDetail.fromMap(d),
      ],
      ipAddress: asString(m['ipAddress'], 'Unknown'),
    );
  }
}

/// Service responsible for logging all critical administrative actions.
/// Writes append-only to the `auditLogs` Firestore collection — admin-only,
/// so it lives here rather than in the shared `transit_core` package.
class AuditService {
  AuditService._();
  static final AuditService instance = AuditService._();

  /// Records one admin action. [adminId] defaults to the signed-in admin.
  ///
  /// Everything beyond [description] is what the Audit History screen shows
  /// as the record's detail: who the target was ([targetName],
  /// [targetRole], [targetType]), what changed ([changes]) and anything
  /// else worth keeping ([details] — a rejection reason, the children
  /// restored with a parent, ...).
  Future<void> logAction({
    String? adminId,
    required AuditActionType actionType,
    required String targetEntityId,
    required String description,
    String action = '',
    String targetType = '',
    String targetName = '',
    String targetRole = '',
    List<AuditChange> changes = const [],
    List<AuditDetail> details = const [],
  }) async {
    final current = FirebaseAuth.instance.currentUser;
    final by = adminId ?? current?.uid ?? 'unknown';

    if (kDebugMode) {
      debugPrint('[AUDIT] $by | ${actionType.name} | $action | $description');
    }

    try {
      await Db.fs.collection('auditLogs').add({
        'adminId': by,
        'adminEmail': current?.email ?? '',
        'actionType': actionType.name,
        'action': action,
        'targetEntityId': targetEntityId,
        'targetType': targetType,
        'targetName': targetName,
        'targetRole': targetRole,
        'description': description,
        'changes': [for (final c in changes) c.toMap()],
        'details': [for (final d in details) d.toMap()],
        'ipAddress': 'Unknown',
        'createdAt': Db.now,
      });
    } catch (e) {
      // Firestore write is best-effort — a failed audit write must never
      // block the admin action it's logging.
      if (kDebugMode) debugPrint('[AUDIT] Firestore sync failed: $e');
    }
  }

  /// The newest [limit] entries of the `auditLogs` collection. One query
  /// ordered by `createdAt` only (a single-field index, always present);
  /// Activity Tracking's per-category view filters these in memory rather
  /// than adding an `actionType + createdAt` composite index. A one-time
  /// fetch rather than a live stream: a history log is read-only and
  /// doesn't need to update under the admin's finger while they scroll.
  Future<List<AuditLogEntry>> fetchRecentLogs({int limit = 300}) async {
    final snap = await Db.fs
        .collection('auditLogs')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((doc) => AuditLogEntry.fromMap(doc.id, doc.data()))
        .toList();
  }
}
