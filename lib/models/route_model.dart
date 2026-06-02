import '../core/enums/enterprise_enums.dart';

class RouteModel {
  final String id;
  final String routeName;
  final List<String> stopIds;

  // Realtime Operations
  final TripState currentState;
  final String? activeVehicleId;
  final String? activeDriverId;

  // Analytics & Intelligence
  final int averageDurationMinutes;
  final double routeEfficiencyScore; // A-F grade or 0-100 logic
  final double estimatedFuelUsageLiters;

  // Concurrency & overlap
  final List<String> overlappingRouteIds;

  RouteModel({
    required this.id,
    required this.routeName,
    required this.stopIds,
    this.currentState = TripState.scheduled,
    this.activeVehicleId,
    this.activeDriverId,
    this.averageDurationMinutes = 60,
    this.routeEfficiencyScore = 100.0,
    this.estimatedFuelUsageLiters = 0.0,
    this.overlappingRouteIds = const [],
  });
}
