import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:transit_admin/app/admin_format.dart';
import 'package:transit_core/transit_core.dart';

AppUser _user({
  String uid = 'u1',
  bool isActive = true,
  bool isDeleted = false,
  bool isOnline = false,
  DateTime? lastSeenAt,
  String subscriptionStatus = 'trial',
  String email = 'a@b.c',
  String phone = '0300',
  DateTime? deletedAt,
}) => AppUser(
  uid: uid,
  role: UserRole.parent,
  name: 'Sara',
  email: email,
  phone: phone,
  isActive: isActive,
  isDeleted: isDeleted,
  isOnline: isOnline,
  lastSeenAt: lastSeenAt,
  subscriptionStatus: subscriptionStatus,
  deletedAt: deletedAt,
);

void main() {
  final now = DateTime(2026, 11, 15, 21, 42);

  group('account state is binary: Active or Deactivated', () {
    test('a normal account is Active', () {
      expect(isAccountDeactivated(_user()), isFalse);
      expect(accountStatusLabel(_user()), 'Active');
    });

    test('an admin-switched-off account is Deactivated', () {
      expect(accountStatusLabel(_user(isActive: false)), 'Deactivated');
    });

    test('a deleted (tombstone) account is Deactivated even if isActive', () {
      expect(accountStatusLabel(_user(isDeleted: true)), 'Deactivated');
    });

    test('deletedBy tells a self-delete from an admin archive', () {
      final u = _user(isDeleted: true, deletedAt: now);
      expect(
        deactivationReason(u, deletedBy: 'u1'),
        startsWith('Deleted by the user'),
      );
      expect(
        deactivationReason(u, deletedBy: 'someone-else'),
        startsWith('Archived by an admin'),
      );
      // Without deletedBy, a blanked tombstone reads as a self-delete.
      expect(
        deactivationReason(_user(isDeleted: true, email: '', phone: '')),
        'Deleted by the user',
      );
    });
  });

  group('presence', () {
    test('online only while the heartbeat is fresh', () {
      final fresh = _user(
        isOnline: true,
        lastSeenAt: now.subtract(const Duration(minutes: 1)),
      );
      final stale = _user(
        isOnline: true,
        lastSeenAt: now.subtract(const Duration(minutes: 4)),
      );
      expect(presenceLabel(fresh, now), 'Online');
      expect(presenceLabel(stale, now), 'Offline');
      expect(
        presenceLabel(_user(isOnline: false, lastSeenAt: now), now),
        'Offline',
      );
      expect(presenceLabel(null, now), 'Offline');
    });

    test('a deleted account is never online', () {
      final u = _user(isDeleted: true, isOnline: true, lastSeenAt: now);
      expect(isUserOnline(u, now), isFalse);
    });

    test('last seen gives the elapsed time and the exact time', () {
      final u = _user(
        lastSeenAt: now.subtract(const Duration(hours: 2, minutes: 15)),
      );
      expect(
        lastSeenLabel(u, now),
        'Offline for 2 h 15 m · Last seen 15 Nov, 7:27 PM',
      );
      expect(
        lastSeenLabel(_user(isOnline: true, lastSeenAt: now), now),
        'Online now',
      );
      expect(lastSeenLabel(_user(), now), 'No app activity recorded yet');
    });

    test('durations use the two largest units', () {
      expect(formatDuration(const Duration(seconds: 40)), '40 s');
      expect(formatDuration(const Duration(minutes: 12)), '12 m');
      expect(formatDuration(const Duration(hours: 3)), '3 h');
      expect(formatDuration(const Duration(days: 3, hours: 4)), '3 d 4 h');
      expect(formatDuration(const Duration(seconds: -5)), '0 s');
    });

    test('exact time adds the year only when it differs', () {
      expect(
        formatExactTime(DateTime(2026, 11, 14, 9, 5), now: now),
        '14 Nov, 9:05 AM',
      );
      expect(
        formatExactTime(DateTime(2025, 1, 2, 0, 0), now: now),
        '2 Jan 2025, 12:00 AM',
      );
    });
  });

  group('student subscription chip', () {
    const child = Student(id: 's1', name: 'Ali', parentId: 'p1');
    const selfRegistered = Student(id: 's2', name: 'Zoya', parentId: '');

    test('reads the parent for a child, the student for a self-registered', () {
      expect(primaryAccountIdFor(child), 'p1');
      expect(primaryAccountIdFor(selfRegistered), 's2');
    });

    test('Active only for a purchased plan on a live account', () {
      expect(
        studentSubscriptionLabel(_user(subscriptionStatus: 'active')),
        'Active',
      );
      expect(
        studentSubscriptionLabel(_user(subscriptionStatus: 'trial')),
        'Inactive',
      );
      expect(
        studentSubscriptionLabel(
          _user(subscriptionStatus: 'active', isDeleted: true),
        ),
        'Inactive',
      );
      expect(
        studentSubscriptionLabel(
          _user(subscriptionStatus: 'active', isActive: false),
        ),
        'Inactive',
      );
      expect(studentSubscriptionLabel(null), 'Inactive');
    });
  });

  group('levels and fees', () {
    test('Academy is a level, and an empty level is School', () {
      expect(
        instituteLevels,
        containsAll(['School', 'College', 'University', 'Academy']),
      );
      expect(
        studentLevel(
          const Student(id: 'a', name: 'A', parentId: 'p', instituteType: ''),
        ),
        'School',
      );
      expect(
        studentLevel(
          const Student(
            id: 'a',
            name: 'A',
            parentId: 'p',
            instituteType: 'Academy',
          ),
        ),
        'Academy',
      );
    });

    test('agreed fee falls back to the accepted seat request', () {
      const s = Student(id: 's1', name: 'A', parentId: 'p');
      const req = RideRequest(
        id: 'd_s1',
        requesterId: 'p',
        studentId: 's1',
        driverId: 'd',
        scheduleId: 'r1',
        status: RideRequestStatus.accepted,
        feePaisa: 350000,
        feeStatus: FeeStatus.accepted,
      );
      expect(agreedFeePaisa(s, const [req]), 350000);
      expect(
        agreedFeePaisa(
          const Student(
            id: 's1',
            name: 'A',
            parentId: 'p',
            monthlyFeePaisa: 400000,
          ),
          const [req],
        ),
        400000,
      );
      expect(formatRupees(350000), 'Rs.3,500');
    });

    test('earnings are paid totals per month, newest first', () {
      Payment pay(String month, int amount, PaymentStatus status) => Payment(
        id: '$month$amount',
        studentId: 's',
        parentId: 'p',
        monthKey: month,
        amountPaisa: amount,
        status: status,
      );
      final totals = paidTotalsByMonth([
        pay('2026-10', 100000, PaymentStatus.paid),
        pay('2026-11', 200000, PaymentStatus.paid),
        pay('2026-11', 50000, PaymentStatus.paid),
        pay('2026-11', 999900, PaymentStatus.submitted),
      ]);
      expect(totals.map((e) => e.key).toList(), ['2026-11', '2026-10']);
      expect(totals.first.value, 250000);
    });
  });

  test('feedback average ignores out-of-range ratings', () {
    AppFeedback f(int r) =>
        AppFeedback(id: '$r', userId: 'u', rating: r, timestamp: now);
    expect(feedbackAverage([f(5), f(4), f(0)]), 4.5);
    expect(feedbackAverage(const []), 0);
  });

  test('a Google Maps link drops a pin on the coordinate', () {
    expect(
      googleMapsUri(const GeoCoord(31.5, 74.35)).toString(),
      'https://www.google.com/maps/search/?api=1&query=31.5,74.35',
    );
  });

  // Source-level guard for the "Child Detail loads forever" bug.
  group('list streams replay to every subscriber', () {
    String read(String path) => File(path).readAsStringSync();

    test('the repository hands out no shared broadcast stream', () {
      final code = read(
        'lib/data/admin_repository.dart',
      ).split('\n').where((l) => !l.trimLeft().startsWith('//')).join('\n');
      expect(
        code.contains('.asBroadcastStream()'),
        isFalse,
        reason:
            'a broadcast stream does not replay its last snapshot to a '
            'late subscriber, which is what left screens spinning',
      );
    });

    test('Parent Detail queries the parent\'s own children', () {
      final src = read('lib/screens/admin/admin_parent_detail.dart');
      expect(src, contains('watchStudentsOfParent('));
    });
  });
}
