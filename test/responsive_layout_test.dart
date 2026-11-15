// Layout tests at the sizes the admin panel has to work at: a phone, a
// tablet, two desktop monitors and a narrow desktop window. Firebase isn't
// available in widget tests, so these pump the screens and pieces that
// render without it (the sign-in flow, and the shared building blocks every
// list and detail screen is made of) and fail on any overflow or layout
// exception.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transit_admin/app/auth_service.dart';
import 'package:transit_admin/app/router.dart';
import 'package:transit_admin/main.dart';
import 'package:transit_admin/screens/admin/admin_feedback.dart';
import 'package:transit_admin/theme/app_theme.dart';
import 'package:transit_admin/widgets/entity_widgets.dart';
import 'package:transit_admin/widgets/glass_card.dart';
import 'package:transit_admin/widgets/mini_stat.dart';
import 'package:transit_admin/widgets/responsive.dart';
import 'package:transit_core/transit_core.dart';

const _sizes = <String, Size>{
  'phone 360x740': Size(360, 740),
  'tablet 800x1000': Size(800, 1000),
  'desktop 1366x768': Size(1366, 768),
  'desktop 1920x1080': Size(1920, 1080),
  'narrow desktop 800x600': Size(800, 600),
};

void _setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// A representative detail/list screen built from the shared pieces: a
/// two-pane body, a card grid, stat tiles, badges, locations, history rows
/// and a feedback tile.
Widget _sampleScreen() {
  final user = AppUser(
    uid: 'u1',
    role: UserRole.parent,
    name: 'Sara Ahmed with a fairly long family name',
    email: 'sara.ahmed.long.address@example.com',
    phone: '+92 300 1234567',
    isOnline: true,
    lastSeenAt: DateTime.now(),
  );
  final card = GlassCard(
    padding: const EdgeInsets.all(14),
    onTap: () {},
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const EntityAvatar(
              photoUrl: null,
              color: AppTheme.driverCyan,
              fallbackEmoji: '🚐',
              topRated: true,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                user.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            AccountStatusBadge(user: user),
            PresenceBadge(user: user, prefix: 'Parent'),
            const TopRatedBadge(),
            const RatingStars(value: 4.5),
          ],
        ),
        const SizedBox(height: 8),
        LastSeenLine(user: user),
      ],
    ),
  );
  return Scaffold(
    body: SingleChildScrollView(
      child: ResponsiveBody(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const Row(
                children: [
                  MiniStat(
                    icon: Icons.people_rounded,
                    label: 'Total',
                    value: '128',
                    color: AppTheme.parentPurple,
                  ),
                  SizedBox(width: 8),
                  MiniStat(
                    icon: Icons.check_circle_rounded,
                    label: 'Active',
                    value: '120',
                    color: AppTheme.success,
                  ),
                  SizedBox(width: 8),
                  MiniStat(
                    icon: Icons.pause_circle_rounded,
                    label: 'Deactivated',
                    value: '8',
                    color: AppTheme.error,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ResponsiveGrid(children: [card, card, card, card, card]),
              const SizedBox(height: 12),
              TwoPane(
                primary: [
                  SectionCard(
                    title: 'Contact & home',
                    icon: Icons.contact_phone_rounded,
                    color: AppTheme.parentPurple,
                    trailing: const StatusBadge(
                      label: '3 active',
                      color: AppTheme.error,
                    ),
                    child: Column(
                      children: [
                        InfoLine(
                          icon: Icons.email_rounded,
                          label: 'Email',
                          value: user.email,
                          color: AppTheme.driverCyan,
                          onTap: () {},
                        ),
                        const LocationBlock(
                          title: 'Institute — drop-off point',
                          name: 'Beaconhouse School System, Garden Town Campus',
                          coord: GeoCoord(31.520412, 74.358749),
                          icon: Icons.school_rounded,
                          color: AppTheme.studentAmber,
                          note: 'Stop 3 of 9 · ETA 7:42 AM · 1.2 km away',
                        ),
                        const EmergencyContactsBlock(
                          title: 'Emergency contacts',
                          contacts: [
                            EmergencyContact(
                              name: 'Bilal Ahmed',
                              relation: 'Uncle',
                              phone: '+92 321 7654321',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                secondary: [
                  const HistoryRow(
                    color: AppTheme.success,
                    title: '14 Nov 2026 · Morning trip · Round 1 (early run)',
                    subtitle:
                        'Completed · 6:31 AM – 7:40 AM · 1 h 9 m · On time · 9 stops',
                    trailing: 'Completed',
                  ),
                  const EmptyHint(text: 'No missed-bus requests on record.'),
                  FeedbackTile(
                    feedback: AppFeedback(
                      id: 'f1',
                      userId: 'u1',
                      rating: 4,
                      comment:
                          'The live tracking is great, but the app '
                          'sometimes takes a while to show the van.',
                      timestamp: DateTime(2026, 11, 14, 21, 42),
                      userName: 'Sara Ahmed',
                      userRole: 'parent',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('breakpoints', () {
    test('window classes', () {
      expect(windowClassFor(360), WindowClass.compact);
      expect(windowClassFor(599), WindowClass.compact);
      expect(windowClassFor(600), WindowClass.medium);
      expect(windowClassFor(1023), WindowClass.medium);
      expect(windowClassFor(1024), WindowClass.expanded);
      expect(windowClassFor(1920), WindowClass.expanded);
    });

    test('card grids use one column on a phone, more on desktop', () {
      expect(columnsFor(328, minItemWidth: 340), 1);
      expect(columnsFor(720, minItemWidth: 340), 2);
      expect(columnsFor(1248, minItemWidth: 340), 3);
      expect(columnsFor(5000, minItemWidth: 340), 4);
    });
  });

  test('Google sign-in is never touched on Windows', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    expect(AuthService.googleSignInSupported, isFalse);
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(AuthService.googleSignInSupported, isTrue);
  });

  for (final entry in _sizes.entries) {
    testWidgets('shared list/detail pieces lay out at ${entry.key}', (
      tester,
    ) async {
      _setSize(tester, entry.value);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          scrollBehavior: const AdminScrollBehavior(),
          home: _sampleScreen(),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      // Unmount so the presence clock's timer is cancelled.
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('welcome and login lay out at ${entry.key}', (tester) async {
      _setSize(tester, entry.value);
      await tester.pumpWidget(const TransitAdminApp());
      // The router is app-global; start each size from the splash.
      appRouter.go('/');
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull, reason: 'welcome screen');
      // Past the splash's auto-navigate timer, onto the login screen.
      await tester.pump(const Duration(milliseconds: 4100));
      await tester.pumpAndSettle();
      expect(find.text('Admin Login'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'login screen');

      appRouter.go('/forgot-password');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'forgot password');
      appRouter.go('/login');
      await tester.pumpAndSettle();
    });
  }

  testWidgets('Enter in the email field moves on to the password', (
    tester,
  ) async {
    _setSize(tester, const Size(1366, 768));
    await tester.pumpWidget(MaterialApp.router(routerConfig: appRouter));
    appRouter.go('/login');
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.tap(fields.first);
    await tester.enterText(fields.first, 'admin@example.com');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    expect(_focused(tester, fields.at(1)), isTrue);
  });
}

bool _focused(WidgetTester tester, Finder field) {
  final editable = find.descendant(
    of: field,
    matching: find.byType(EditableText),
  );
  return tester.widget<EditableText>(editable).focusNode.hasFocus;
}
