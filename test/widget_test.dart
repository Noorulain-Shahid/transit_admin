import 'dart:io';
// Basic smoke + behavior tests for the admin app's entry flow.
//
// These intentionally avoid touching Firestore/FirebaseAuth data (no test
// double is wired up for either), so they cover client-side flow and the
// router guard rather than any live-data screen.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:transit_admin/main.dart';
import 'package:transit_admin/app/router.dart';

void main() {
  _accountRepairTests();

  testWidgets('Welcome screen navigates to Admin Login after splash', (
    tester,
  ) async {
    await tester.pumpWidget(const TransitAdminApp());
    // The splash screen runs looping animations, so pumpAndSettle would
    // never settle — advance past its 4s auto-navigate timer explicitly.
    await tester.pump(const Duration(milliseconds: 4100));
    await tester.pump();
    expect(find.text('Admin Login'), findsOneWidget);
  });

  testWidgets(
    'Router guard redirects an unauthenticated deep link to /admin back to /login',
    (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: appRouter));
      await tester.pumpAndSettle();

      appRouter.go('/admin');
      await tester.pumpAndSettle();

      // No signed-in FirebaseAuth user exists in this test environment, so
      // the guard in app/router.dart must have sent us back to /login
      // instead of rendering the admin shell.
      expect(find.text('Admin Login'), findsOneWidget);
      expect(find.text('Command Center'), findsNothing);
    },
  );

  testWidgets('Login form shows a validation error on empty submit', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: appRouter));
    appRouter.go('/login');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign In as Admin →'));
    await tester.pump();

    expect(find.text('Please fill in all fields.'), findsOneWidget);
  });
}

/// Source-level guards for the admin-account repair.
///
/// A cleared database leaves the Auth user and destroys the `users/{uid}`
/// document behind it. Both failures used to read "incorrect email or
/// password", on a screen that prints the password two inches below.
void _accountRepairTests() {
  String read(String path) => File(path).readAsStringSync();

  group('a missing admin record is told apart from a wrong password', () {
    test('sign-in distinguishes no record from the wrong role', () {
      final src = read('lib/app/auth_service.dart');
      expect(src, contains('class AdminRecordMissingException'));
      expect(src, contains('throw AdminRecordMissingException('));
      // The other branch must survive: a real account with role 'parent'
      // is a different problem with a different fix.
      expect(src, contains('throw const NotAnAdminException()'));
    });

    test('the login screen offers the repair for both shapes', () {
      final src = read('lib/screens/login_screen.dart');
      expect(src, contains('on AdminRecordMissingException'));
      expect(
        src,
        contains("e.code == 'user-not-found') _recordMissing = true"),
        reason: 'no account at all is the other shape a cleared backend takes',
      );
      expect(src, contains('_buildRepairPanel'));
    });

    test('the client never grants itself the admin role', () {
      // The whole point of leaving step two in the console: a client that
      // could write role 'admin' would make every isAdmin() rule decorative.
      final src = read('lib/app/auth_service.dart');
      final start = src.indexOf('Future<String> prepareAdminAccount');
      expect(start, greaterThan(-1));
      final body = src.substring(start, src.indexOf('\n  Future<void> signOut', start));
      expect(body, contains('role: UserRole.parent'));
      expect(
        body.contains('UserRole.admin'),
        isFalse,
        reason: 'the rules refuse it, and they are right to',
      );
      expect(
        body.contains('signOut()'),
        isTrue,
        reason: 'this is a repair, not a login',
      );
    });
  });
}
