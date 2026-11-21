import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transit_admin/app/admin_format.dart';
import 'package:transit_admin/widgets/account_controls.dart';
import 'package:transit_core/transit_core.dart';

AppUser _user({
  bool isActive = true,
  bool isDeleted = false,
  String email = 'sara@example.com',
  String phone = '0300',
  UserRole role = UserRole.parent,
}) => AppUser(
  uid: 'u1',
  role: role,
  name: 'Sara',
  email: email,
  phone: phone,
  isActive: isActive,
  isDeleted: isDeleted,
);

Widget _host(AccountRecord record) => MaterialApp(
  home: Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: AccountControls(record: record),
    ),
  ),
);

void main() {
  testWidgets('an Active account offers Deactivate and Delete permanently', (
    tester,
  ) async {
    await tester.pumpWidget(_host(AccountRecord(_user())));
    expect(find.text('Deactivate'), findsOneWidget);
    expect(find.text('Delete permanently'), findsOneWidget);
    expect(find.text('Activate'), findsNothing);
  });

  testWidgets('a Deactivated or legacy-archived account offers Activate', (
    tester,
  ) async {
    await tester.pumpWidget(_host(AccountRecord(_user(isActive: false))));
    expect(find.text('Activate'), findsOneWidget);
    expect(find.text('Deactivate'), findsNothing);

    await tester.pumpWidget(_host(AccountRecord(_user(isDeleted: true))));
    expect(find.text('Activate'), findsOneWidget);
    expect(find.text('Delete permanently'), findsOneWidget);
  });

  testWidgets('a Deleted account offers nothing', (tester) async {
    final selfDeleted = AccountRecord(
      _user(isDeleted: true, isActive: false, email: '', phone: ''),
      deletedBy: 'u1',
    );
    await tester.pumpWidget(_host(selfDeleted));
    expect(find.text('Activate'), findsNothing);
    expect(find.text('Delete permanently'), findsNothing);
    expect(find.textContaining('Deleted by the user'), findsOneWidget);

    final removed = AccountRecord(
      _user(isDeleted: true, isActive: false),
      deletedBy: 'admin',
      authDeleted: true,
    );
    await tester.pumpWidget(_host(removed));
    expect(find.text('Activate'), findsNothing);
    expect(find.textContaining('Permanently deleted'), findsOneWidget);
  });

  testWidgets('an admin account cannot be deleted from here', (tester) async {
    await tester.pumpWidget(_host(AccountRecord(_user(role: UserRole.admin))));
    expect(find.text('Delete permanently'), findsNothing);
  });

  testWidgets(
    'permanent delete needs the checkbox; cancelling changes nothing',
    (tester) async {
      await tester.pumpWidget(_host(AccountRecord(_user())));
      await tester.tap(find.text('Delete permanently'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Sara permanently?'), findsOneWidget);
      expect(find.textContaining('sara@example.com'), findsOneWidget);
      final confirm = find.widgetWithText(FilledButton, 'Delete permanently');
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Delete Sara permanently?'), findsNothing);
      // Still offered: nothing ran.
      expect(find.text('Deactivate'), findsOneWidget);
    },
  );

  testWidgets('deactivate asks first', (tester) async {
    await tester.pumpWidget(_host(AccountRecord(_user())));
    await tester.tap(find.text('Deactivate'));
    await tester.pumpAndSettle();
    expect(find.text('Deactivate Sara?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Deactivate Sara?'), findsNothing);
  });
}
