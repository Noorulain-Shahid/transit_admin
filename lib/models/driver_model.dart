import '../core/enums/enterprise_enums.dart';

class ComplianceDocument {
  final String documentType; // e.g., 'License', 'BackgroundCheck'
  final DateTime expiryDate;
  final String fileUrl;
  final bool isVerified;

  ComplianceDocument({
    required this.documentType,
    required this.expiryDate,
    required this.fileUrl,
    this.isVerified = false,
  });

  bool get isExpired => DateTime.now().isAfter(expiryDate);
  bool get expiresSoon => DateTime.now().add(const Duration(days: 30)).isAfter(expiryDate);
}

class DriverModel {
  final String id;
  final String name;
  final String contactNumber;
  final DriverStatus status;
  
  // Scorecard constraints
  final double reliabilityScore; // 0.0 to 100.0
  final int harshBrakingEvents;
  final int overSpeedEvents;
  
  // Compliance
  final List<ComplianceDocument> documents;
  
  // Incident & Penalty History
  final List<String> incidentIds;
  final List<String> warnings;

  DriverModel({
    required this.id,
    required this.name,
    required this.contactNumber,
    this.status = DriverStatus.pendingVerification,
    this.reliabilityScore = 100.0,
    this.harshBrakingEvents = 0,
    this.overSpeedEvents = 0,
    this.documents = const [],
    this.incidentIds = const [],
    this.warnings = const [],
  });
  
  bool get hasExpiredDocuments => documents.any((doc) => doc.isExpired);
}
