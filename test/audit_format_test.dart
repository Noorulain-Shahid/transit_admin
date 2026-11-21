import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:transit_admin/app/audit_format.dart';
import 'package:transit_admin/data/account_admin_client.dart';
import 'package:transit_admin/services/audit_service.dart';

AuditLogEntry _entry(Map<String, dynamic> m) => AuditLogEntry.fromMap('e1', {
  'adminId': 'admin-1',
  'actionType': 'statusChange',
  'targetEntityId': 'u1',
  'createdAt': DateTime(2026, 11, 15, 21, 42),
  ...m,
});

void main() {
  group('a detailed entry', () {
    final e = _entry({
      'action': AuditActions.accountDeactivate,
      'adminEmail': 'boss@transit.pk',
      'targetType': 'parent',
      'targetName': 'Sara Khan',
      'targetRole': 'Parent',
      'description': 'Deactivated parent Sara Khan',
      'changes': [
        {'label': 'Account status', 'from': 'Active', 'to': 'Deactivated'},
        {'label': 'Sign-in', 'from': 'Allowed', 'to': 'Blocked'},
      ],
      'details': [
        {'label': 'Email', 'value': 'sara@x.pk'},
      ],
    });

    test('reads back what was written, in order', () {
      expect(e.isLegacy, isFalse);
      expect(e.changes.map((c) => c.label), ['Account status', 'Sign-in']);
      expect(e.details.single.value, 'sara@x.pk');
      expect(e.timestamp, DateTime(2026, 11, 15, 21, 42));
    });

    test('title, target, admin and before → after lines', () {
      expect(auditActionTitle(e), 'Deactivated account');
      expect(auditTargetLine(e), 'Sara Khan · Parent · ID u1');
      expect(auditAdminLine(e, resolvedName: 'Ali'), 'Ali (boss@transit.pk)');
      expect(auditDetailLines(e), [
        'Account status: Active → Deactivated',
        'Sign-in: Allowed → Blocked',
        'Email: sara@x.pk',
      ]);
    });

    test('every new account action has a title', () {
      for (final a in [
        AuditActions.accountActivate,
        AuditActions.accountDeletePermanently,
        AuditActions.documentReject,
        AuditActions.documentVerify,
        AuditActions.driverApprove,
        AuditActions.driverSuspend,
        AuditActions.studentArchive,
        AuditActions.studentTransport,
      ]) {
        expect(auditActionTitle(_entry({'action': a})), isNot(contains('.')));
      }
      expect(
        auditActionTitle(
          _entry({'action': AuditActions.accountDeletePermanently}),
        ),
        'Permanently deleted account',
      );
    });

    test('a rejection keeps its reason', () {
      final r = _entry({
        'action': AuditActions.documentReject,
        'targetType': 'document',
        'targetName': 'Driving License of Ali',
        'changes': [
          {
            'label': 'Document status',
            'from': 'Pending review',
            'to': 'Rejected',
          },
        ],
        'details': [
          {'label': 'Reason', 'value': 'Photo is blurry'},
        ],
      });
      expect(
        auditDetailLines(r),
        containsAll([
          'Document status: Pending review → Rejected',
          'Reason: Photo is blurry',
        ]),
      );
    });
  });

  group('an older entry without details', () {
    final old = _entry({
      'actionType': 'delete',
      'description': 'Archived driver Ali',
    });

    test('falls back to its sentence and says nothing more was kept', () {
      expect(old.isLegacy, isTrue);
      expect(auditActionTitle(old), 'Archived driver Ali');
      final lines = auditDetailLines(old);
      expect(lines, hasLength(1));
      expect(lines.single, startsWith('Logged before detailed records'));
    });

    test('names the target from the looked-up account, else by id', () {
      expect(
        auditTargetLine(old, resolvedName: 'Ali Raza'),
        'Ali Raza · ID u1',
      );
      expect(auditTargetLine(old), 'ID u1');
      expect(
        auditTargetLine(_entry({'targetEntityId': ''})),
        'No target recorded',
      );
    });

    test('the admin falls back to email, then id', () {
      expect(auditAdminLine(old), 'Admin admin-1');
      expect(auditAdminLine(_entry({'adminId': 'unknown'})), 'Unknown admin');
    });

    test('an unknown category or a blank entry still has a title', () {
      final blank = _entry({'actionType': 'somethingNew'});
      expect(blank.actionType, AuditActionType.update);
      expect(auditActionTitle(blank), 'Update');
    });

    test('malformed change/detail rows are skipped, not thrown on', () {
      final e = _entry({
        'changes': [
          'oops',
          {'from': 'a'},
          null,
        ],
        'details': [42],
      });
      expect(e.changes, isEmpty);
      expect(e.details, isEmpty);
    });
  });

  test('categories: counts in enum order, readable names, route parsing', () {
    final entries = [
      _entry({'actionType': 'delete'}),
      _entry({'actionType': 'statusChange'}),
      _entry({'actionType': 'statusChange'}),
    ];
    final counts = auditCountsByCategory(entries);
    expect(counts.map((c) => c.key), [
      AuditActionType.delete,
      AuditActionType.statusChange,
    ]);
    expect(counts.last.value, 2);
    expect(auditCategoryLabel(AuditActionType.statusChange), 'Status change');
    expect(auditCategoryFromName('delete'), AuditActionType.delete);
    expect(auditCategoryFromName('nope'), isNull);
    expect(auditCategoryFromName(null), isNull);
  });

  group('permanent delete failures', () {
    test('every failure says nothing was deleted', () {
      expect(
        deleteFailureMessage(
          403,
          '{"error":"Admin accounts cannot be deleted."}',
        ),
        'Admin accounts cannot be deleted. Nothing was deleted.',
      );
      expect(
        deleteFailureMessage(401, '{"error":"ID token has expired."}'),
        startsWith('Your sign-in could not be verified.'),
      );
      expect(
        deleteFailureMessage(502, 'garbage'),
        'Server error (502). Nothing was deleted.',
      );
    });

    test('an old Worker without the route asks for a deploy', () {
      expect(
        deleteFailureMessage(404, '{"error":"Not found."}'),
        contains('deploy the Worker'),
      );
      expect(
        deleteFailureMessage(404, '{"error":"No such account."}'),
        'No such account. Nothing was deleted.',
      );
    });
  });

  group('removed profile options stay removed', () {
    String read(String path) => File(path).readAsStringSync();

    test('no Change Password, Security block or session history', () {
      final profile = read('lib/screens/admin/admin_profile.dart');
      expect(profile, isNot(contains('change_password')));
      expect(profile, isNot(contains('_buildSecurity')));
      expect(profile, isNot(contains('session-history')));
      expect(profile, contains("AppStrings.t('app_rating_feedback')"));
      expect(read('lib/app/router.dart'), isNot(contains('session-history')));
      expect(
        File('lib/screens/admin/admin_session_history.dart').existsSync(),
        isFalse,
      );
      expect(
        read('lib/services/audit_service.dart'),
        isNot(contains('loginSessions')),
      );
    });

    test('the feedback label is translated', () {
      final strings = read('lib/app/locale_provider.dart');
      expect(
        strings,
        contains("'app_rating_feedback': \"App Rating and Feedback\""),
      );
      expect(
        strings,
        contains("'app_rating_feedback': \"ایپ ریٹنگ اور فیڈ بیک\""),
      );
    });

    test('account screens use the shared account controls', () {
      for (final f in [
        'lib/screens/admin/admin_parent_detail.dart',
        'lib/screens/admin/admin_driver_detail.dart',
        'lib/screens/admin/admin_student_detail.dart',
      ]) {
        expect(read(f), contains('AccountControls('), reason: f);
      }
      final repo = read('lib/data/admin_repository.dart');
      expect(repo, isNot(contains('Future<void> deleteParent')));
      expect(repo, isNot(contains('Future<void> deleteDriver')));
    });
  });
}
