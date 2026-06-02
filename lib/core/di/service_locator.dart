import '../../services/audit_service.dart';
import '../../services/smart_alert_service.dart';
import '../../services/emergency_service.dart';

/// Simple Service Locator for Enterprise Transit Pro
class ServiceLocator {
  static final ServiceLocator instance = ServiceLocator._internal();

  ServiceLocator._internal();

  late final AuditService auditService;
  late final SmartAlertService smartAlertService;
  late final EmergencyService emergencyService;

  void initialize() {
    auditService = AuditService();
    smartAlertService = SmartAlertService();
    emergencyService = EmergencyService(auditService);
  }
}
