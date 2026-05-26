import '../core/enums/enterprise_enums.dart';

class Guardian {
  final String id;
  final String name;
  final String relationship;
  final String contactNumber;
  final String photoUrl; // For driver verification
  final bool isAuthorizedPickup;

  Guardian({
    required this.id,
    required this.name,
    required this.relationship,
    required this.contactNumber,
    required this.photoUrl,
    this.isAuthorizedPickup = false,
  });
}

class StudentModel {
  final String id;
  final String name;
  final String grade;
  final String assignedRouteId;
  final String assignedStopId;
  final List<Guardian> guardians;
  final SubscriptionStatus subscriptionStatus;
  final Map<String, dynamic> emergencyMedicalNotes;
  final bool isTransportSuspended;

  // Track behavior/attendance anomalies
  final int consecutiveAbsences;
  final List<String> missedBusHistory;

  StudentModel({
    required this.id,
    required this.name,
    required this.grade,
    required this.assignedRouteId,
    required this.assignedStopId,
    required this.guardians,
    this.subscriptionStatus = SubscriptionStatus.active,
    this.emergencyMedicalNotes = const {},
    this.isTransportSuspended = false,
    this.consecutiveAbsences = 0,
    this.missedBusHistory = const [],
  });

  bool get canBoardBus =>
      !isTransportSuspended &&
      (subscriptionStatus == SubscriptionStatus.active ||
          subscriptionStatus == SubscriptionStatus.gracePeriod);
}
