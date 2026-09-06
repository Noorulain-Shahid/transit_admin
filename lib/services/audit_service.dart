import 'package:flutter/foundation.dart';
import 'package:transit_core/transit_core.dart';

enum AuditActionType {
  create,
  update,
  delete,
  override,
  statusChange,
  broadcast,
  emergencyTrigger,
}

class AuditLogEntry {
  final String id;
  final DateTime timestamp;
  final String adminId;
  final AuditActionType actionType;
  final String targetEntityId; // e.g., DriverId, RouteId
  final String description;
  final String ipAddress;

  AuditLogEntry({
    required this.id,
    required this.timestamp,
    required this.adminId,
    required this.actionType,
    required this.targetEntityId,
    required this.description,
    this.ipAddress = 'Unknown',
  });
}

/// Service responsible for logging all critical administrative actions.
/// Writes append-only to the `auditLogs` Firestore collection — admin-only,
/// so it lives here rather than in the shared `transit_core` package.
class AuditService {
  AuditService._();
  static final AuditService instance = AuditService._();

  final List<AuditLogEntry> _localLogs = [];

  Future<void> logAction({
    required String adminId,
    required AuditActionType actionType,
    required String targetEntityId,
    required String description,
  }) async {
    final entry = AuditLogEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      adminId: adminId,
      actionType: actionType,
      targetEntityId: targetEntityId,
      description: description,
    );

    _localLogs.add(entry);

    if (kDebugMode) {
      debugPrint(
        '[AUDIT] ${entry.timestamp} | ${entry.adminId} | ${entry.actionType.name} | ${entry.description}',
      );
    }

    try {
      await Db.fs.collection('auditLogs').add({
        'adminId': entry.adminId,
        'actionType': entry.actionType.name,
        'targetEntityId': entry.targetEntityId,
        'description': entry.description,
        'ipAddress': entry.ipAddress,
        'createdAt': Db.now,
      });
    } catch (e) {
      // Firestore write is best-effort — a failed audit write must never
      // block the admin action it's logging.
      if (kDebugMode) debugPrint('[AUDIT] Firestore sync failed: $e');
    }
  }

  List<AuditLogEntry> getRecentLogs(int count) {
    return _localLogs.reversed.take(count).toList();
  }
}
