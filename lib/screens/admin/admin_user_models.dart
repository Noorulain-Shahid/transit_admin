import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Legacy model – kept for backward compatibility with existing detail page
// ─────────────────────────────────────────────────────────────────────────────
class AdminUserRecord {
  final String id;
  final String name;
  final String role;
  final String icon;
  final String detail;
  final Color color;
  final bool active;
  final String contact;
  final String address;
  final String extra;

  const AdminUserRecord({
    required this.id,
    required this.name,
    required this.role,
    required this.icon,
    required this.detail,
    required this.color,
    required this.active,
    required this.contact,
    required this.address,
    required this.extra,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  Student
// ─────────────────────────────────────────────────────────────────────────────
enum StudentStatus { onBus, missed, inactive }

enum SubscriptionStatus { active, expired, trial, suspended, blocked }

class StudentRecord {
  final String id;
  final String name;
  final String parentName;
  final String route;
  final String driver;
  final StudentStatus status;
  final SubscriptionStatus subscriptionStatus;
  final String grade;
  final String pickupTime;
  final String dropTime;
  final String pickupLocation;
  final String dropLocation;

  const StudentRecord({
    required this.id,
    required this.name,
    required this.parentName,
    required this.route,
    required this.driver,
    required this.status,
    required this.subscriptionStatus,
    required this.grade,
    required this.pickupTime,
    required this.dropTime,
    this.pickupLocation = '',
    this.dropLocation = '',
  });

  String get statusLabel {
    switch (status) {
      case StudentStatus.onBus:
        return 'On Bus';
      case StudentStatus.missed:
        return 'Missed';
      case StudentStatus.inactive:
        return 'Inactive';
    }
  }

  Color get statusColor {
    switch (status) {
      case StudentStatus.onBus:
        return const Color(0xFF10B981);
      case StudentStatus.missed:
        return const Color(0xFFF59E0B);
      case StudentStatus.inactive:
        return const Color(0xFF94A3B8);
    }
  }

  String get subscriptionLabel {
    switch (subscriptionStatus) {
      case SubscriptionStatus.active:
        return 'Active';
      case SubscriptionStatus.expired:
        return 'Expired';
      case SubscriptionStatus.trial:
        return 'Trial';
      case SubscriptionStatus.suspended:
        return 'Suspended';
      case SubscriptionStatus.blocked:
        return 'Blocked';
    }
  }

  Color get subscriptionColor {
    switch (subscriptionStatus) {
      case SubscriptionStatus.active:
        return const Color(0xFF10B981);
      case SubscriptionStatus.expired:
        return const Color(0xFFEF4444);
      case SubscriptionStatus.trial:
        return const Color(0xFF3B82F6);
      case SubscriptionStatus.suspended:
        return const Color(0xFFF59E0B);
      case SubscriptionStatus.blocked:
        return const Color(0xFFEF4444);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Parent
// ─────────────────────────────────────────────────────────────────────────────
enum ParentPlan { basic, standard, premium }

class ParentRecord {
  final String id;
  final String name;
  final int childrenCount;
  final List<String> childrenNames;
  final String contact;
  final String email;
  final ParentPlan plan;
  final SubscriptionStatus status;
  final String nextBillingDate;
  final double amountDue;
  final String address;

  const ParentRecord({
    required this.id,
    required this.name,
    required this.childrenCount,
    required this.childrenNames,
    required this.contact,
    required this.email,
    required this.plan,
    required this.status,
    required this.nextBillingDate,
    required this.amountDue,
    this.address = '',
  });

  String get planLabel {
    switch (plan) {
      case ParentPlan.basic:
        return 'Basic';
      case ParentPlan.standard:
        return 'Standard';
      case ParentPlan.premium:
        return 'Premium';
    }
  }

  Color get planColor {
    switch (plan) {
      case ParentPlan.basic:
        return const Color(0xFF94A3B8);
      case ParentPlan.standard:
        return const Color(0xFF3B82F6);
      case ParentPlan.premium:
        return const Color(0xFF8B5CF6);
    }
  }

  String get statusLabel {
    switch (status) {
      case SubscriptionStatus.active:
        return 'Active';
      case SubscriptionStatus.expired:
        return 'Expired';
      case SubscriptionStatus.trial:
        return 'Trial';
      case SubscriptionStatus.suspended:
        return 'Suspended';
      case SubscriptionStatus.blocked:
        return 'Blocked';
    }
  }

  Color get statusColor {
    switch (status) {
      case SubscriptionStatus.active:
        return const Color(0xFF10B981);
      case SubscriptionStatus.expired:
        return const Color(0xFFEF4444);
      case SubscriptionStatus.trial:
        return const Color(0xFF3B82F6);
      case SubscriptionStatus.suspended:
        return const Color(0xFFF59E0B);
      case SubscriptionStatus.blocked:
        return const Color(0xFFEF4444);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Driver
// ─────────────────────────────────────────────────────────────────────────────
enum DriverStatus { online, offline, onTrip }

class DriverRecord {
  final String id;
  final String name;
  final String vehicle;
  final String route;
  final DriverStatus status;
  final double rating;
  final int activeTrips;
  final String licenseNo;
  final String contact;
  final String photoUrl;
  final bool approved;
  final int totalTrips;

  const DriverRecord({
    required this.id,
    required this.name,
    required this.vehicle,
    required this.route,
    required this.status,
    required this.rating,
    required this.activeTrips,
    required this.licenseNo,
    required this.contact,
    this.photoUrl = '',
    this.approved = true,
    this.totalTrips = 0,
  });

  String get statusLabel {
    switch (status) {
      case DriverStatus.online:
        return 'Online';
      case DriverStatus.offline:
        return 'Offline';
      case DriverStatus.onTrip:
        return 'On Trip';
    }
  }

  Color get statusColor {
    switch (status) {
      case DriverStatus.online:
        return const Color(0xFF10B981);
      case DriverStatus.offline:
        return const Color(0xFF94A3B8);
      case DriverStatus.onTrip:
        return const Color(0xFF3B82F6);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Alert
// ─────────────────────────────────────────────────────────────────────────────
enum AlertSeverity { critical, warning, info }

enum AlertType { sos, missedBus, lateDriver, paymentFailure, subscriptionExpiry }

class AlertItem {
  final String id;
  final AlertType type;
  final String title;
  final String message;
  final AlertSeverity severity;
  final String timestamp;

  const AlertItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.severity,
    required this.timestamp,
  });

  Color get severityColor {
    switch (severity) {
      case AlertSeverity.critical:
        return const Color(0xFFEF4444);
      case AlertSeverity.warning:
        return const Color(0xFFF59E0B);
      case AlertSeverity.info:
        return const Color(0xFF3B82F6);
    }
  }

  IconData get typeIcon {
    switch (type) {
      case AlertType.sos:
        return Icons.emergency_rounded;
      case AlertType.missedBus:
        return Icons.no_transfer_rounded;
      case AlertType.lateDriver:
        return Icons.schedule_rounded;
      case AlertType.paymentFailure:
        return Icons.payment_rounded;
      case AlertType.subscriptionExpiry:
        return Icons.timer_off_rounded;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Subscription Plan Config
// ─────────────────────────────────────────────────────────────────────────────
class SubscriptionPlanConfig {
  final String name;
  final double price;
  final int childLimit; // -1 = unlimited
  final List<String> features;
  final Color color;

  const SubscriptionPlanConfig({
    required this.name,
    required this.price,
    required this.childLimit,
    required this.features,
    required this.color,
  });
}
