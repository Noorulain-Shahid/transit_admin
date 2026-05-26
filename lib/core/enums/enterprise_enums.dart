/// Enterprise Enums for Transit Pro Admin operations

enum TripState {
  scheduled,
  driverEnRoute,
  startingRoute,
  nearingStop,
  boarding,
  inTransit,
  delayed,
  emergencyActive,
  completed,
  cancelled
}

enum DriverStatus {
  pendingVerification,
  underReview,
  approved,
  activeEnRoute,
  offDuty,
  suspended,
  onLeave
}

enum IncidentSeverity {
  low,       // e.g., minor delay
  medium,    // e.g., vehicle maintenance required
  high,      // e.g., vehicle breakdown
  critical,  // e.g., accident, medical emergency, student missing
}

enum SubscriptionStatus {
  active,
  pendingPayment,
  overdue,
  suspended,
  cancelled,
  gracePeriod
}

enum VehicleStatus {
  active,
  inTransit,
  idle,
  scheduledForMaintenance,
  inShop,
  decommissioned
}

enum AuditActionType {
  create,
  update,
  delete,
  override,
  statusChange,
  broadcast,
  emergencyTrigger
}
