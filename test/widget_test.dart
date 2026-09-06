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
