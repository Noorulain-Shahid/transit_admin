import 'dart:async';
import '../core/enums/enterprise_enums.dart';
import '../models/route_model.dart';
import '../models/vehicle_model.dart';

class SmartAlert {
  final String id;
  final IncidentSeverity severity;
  final String title;
  final String message;
  final DateTime timestamp;
  final String? actionRoute;

  SmartAlert({
    required this.id,
    required this.severity,
    required this.title,
    required this.message,
    required this.timestamp,
    this.actionRoute,
  });
}

/// Service that analyzes realtime streams and yields system intelligence insights.
class SmartAlertService {
  final StreamController<SmartAlert> _alertStreamController = StreamController.broadcast();

  Stream<SmartAlert> get alertStream => _alertStreamController.stream;

  /// Checks if a route assignment is valid. Emits an alert if capacity is exceeded.
  void checkRouteCapacity(RouteModel route, VehicleModel vehicle, int assignedStudentsCount) {
    if (assignedStudentsCount > vehicle.capacity) {
      _emitAlert(
        severity: IncidentSeverity.medium,
        title: 'Capacity Overload Detected',
        message: 'Route ${route.routeName} has $assignedStudentsCount students, but Vehicle ${vehicle.licensePlate} holds only ${vehicle.capacity}.',
      );
    }
  }

  /// Evaluates vehicle compliance rules and emits warnings.
  void evaluateFleetHealth(VehicleModel vehicle) {
    if (vehicle.needsMaintenance) {
      _emitAlert(
        severity: IncidentSeverity.high,
        title: 'Maintenance Overdue',
        message: 'Vehicle ${vehicle.licensePlate} has missed its scheduled maintenance.',
      );
    }

    if (vehicle.needsInsuranceRenewal) {
      _emitAlert(
        severity: IncidentSeverity.critical,
        title: 'Compliance Violation',
        message: 'Vehicle ${vehicle.licensePlate} has expired insurance. Do not dispatch.',
      );
    }
  }

  /// Detects driver behavioral anomalies and telemetry triggers.
  void analyzeDriverTelemetry(String driverId, int overSpeedEvents, int harshBrakes) {
    if (overSpeedEvents > 3) {
      _emitAlert(
        severity: IncidentSeverity.high,
        title: 'Safety Warning',
        message: 'Driver $driverId exceeded speed limit $overSpeedEvents times. Action required.',
      );
    }
  }

  void _emitAlert({
    required IncidentSeverity severity,
    required String title,
    required String message,
  }) {
    final alert = SmartAlert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      severity: severity,
      title: title,
      message: message,
      timestamp: DateTime.now(),
    );
    _alertStreamController.add(alert);
  }

  void dispose() {
    _alertStreamController.close();
  }
}
