import 'package:flutter/foundation.dart';
import '../core/enums/enterprise_enums.dart';

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
/// In an enterprise system, this feeds to a secure write-only database.
class AuditService {
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

    // TODO: Sync to backend (e.g., Firebase Firestore 'audit_logs' collection)
    if (kDebugMode) {
      print(
        '[AUDIT] ${entry.timestamp} | ${entry.adminId} | ${entry.actionType.name} | ${entry.description}',
      );
    }
  }

  List<AuditLogEntry> getRecentLogs(int count) {
    return _localLogs.reversed.take(count).toList();
  }
}
