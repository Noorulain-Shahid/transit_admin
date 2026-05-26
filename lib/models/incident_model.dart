import '../core/enums/enterprise_enums.dart';

class IncidentModel {
  final String id;
  final IncidentSeverity severity;
  final String title;
  final String description;
  final DateTime timestamp;
  final String? reportedByDriverId;
  final String? associatedRouteId;
  final String? associatedVehicleId;
  
  // Resolution workflow
  bool isResolved;
  String? resolvedByAdminId;
  DateTime? resolutionTimestamp;
  String? resolutionNotes;

  IncidentModel({
    required this.id,
    required this.severity,
    required this.title,
    required this.description,
    required this.timestamp,
    this.reportedByDriverId,
    this.associatedRouteId,
    this.associatedVehicleId,
    this.isResolved = false,
    this.resolvedByAdminId,
    this.resolutionTimestamp,
    this.resolutionNotes,
  });
}
