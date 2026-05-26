import 'dart:async';
import '../core/enums/enterprise_enums.dart';
import '../models/incident_model.dart';
import 'audit_service.dart';

class EmergencyService {
  final AuditService _auditService;
  final StreamController<IncidentModel> _liveIncidentStream = StreamController.broadcast();

  EmergencyService(this._auditService);

  Stream<IncidentModel> get liveIncidents => _liveIncidentStream.stream;

  /// Triggered from the Driver App via backend
  Future<void> handleIncomingSOS(IncidentModel incident) async {
    // 1. Broadcast the incident to the admin dashboard instantly
    _liveIncidentStream.add(incident);
    
    // 2. Log the critical event locally/audit trail
    await _auditService.logAction(
      adminId: 'SYSTEM',
      actionType: AuditActionType.emergencyTrigger,
      targetEntityId: incident.associatedRouteId ?? 'UNKNOWN',
      description: 'SOS Triggered: ${incident.title}',
    );

    // TODO: Trigger backend push notifications to critical staff
  }

  /// Admin acknowledges the emergency, updating its state
  Future<void> acknowledgeIncident(String adminId, IncidentModel incident) async {
    // Update local state handling
    incident.resolvedByAdminId = adminId;
    // Note: Usually we would update the backend database here
    
    await _auditService.logAction(
      adminId: adminId,
      actionType: AuditActionType.update,
      targetEntityId: incident.id,
      description: 'Acknowledged SOS Incident: ${incident.title}',
    );
  }

  /// Admin resolves the event
  Future<void> resolveIncident(String adminId, IncidentModel incident, String notes) async {
    incident.isResolved = true;
    incident.resolutionTimestamp = DateTime.now();
    incident.resolutionNotes = notes;

    await _auditService.logAction(
      adminId: adminId,
      actionType: AuditActionType.statusChange,
      targetEntityId: incident.id,
      description: 'Resolved SOS Incident: ${incident.title}. Notes: $notes',
    );
  }

  void dispose() {
    _liveIncidentStream.close();
  }
}
