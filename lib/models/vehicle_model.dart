import '../core/enums/enterprise_enums.dart';

class VehicleModel {
  final String id;
  final String licensePlate;
  final VehicleStatus status;
  final int capacity;

  // Maintenance & Fleet compliance
  final DateTime nextMaintenanceDate;
  final DateTime insuranceExpiryDate;

  // Telemetry
  final double currentMileage;
  final bool isEngineIdle;

  VehicleModel({
    required this.id,
    required this.licensePlate,
    required this.capacity,
    this.status = VehicleStatus.idle,
    required this.nextMaintenanceDate,
    required this.insuranceExpiryDate,
    this.currentMileage = 0.0,
    this.isEngineIdle = false,
  });

  bool get needsMaintenance => DateTime.now().isAfter(nextMaintenanceDate);
  bool get needsInsuranceRenewal => DateTime.now().isAfter(insuranceExpiryDate);
}
