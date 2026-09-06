import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import '../screens/welcome_screen.dart';
import '../screens/login_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/admin/admin_layout.dart';
import '../screens/admin/admin_notifications.dart';
import '../screens/admin/admin_subscription.dart';
import '../screens/admin/admin_fees.dart';
import '../screens/admin/admin_routes.dart';
import '../screens/admin/admin_vehicles.dart';
import '../screens/admin/admin_student_detail.dart';
import '../screens/admin/admin_parent_detail.dart';
import '../screens/admin/admin_driver_detail.dart';
import 'auth_service.dart';

/// Notifies GoRouter to re-run [_guard] whenever Firebase auth state changes,
/// so signing in/out immediately redirects instead of waiting for the next
/// manual navigation. Mirrors the mobile app's `_AuthRefresh`.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

const _publicRoutes = {'/', '/login', '/forgot-password'};

/// Blocks reaching any `/admin*` route without a verified admin session.
///
/// Deliberately checks [AuthService.cachedRole], not just [AuthService.
/// isSignedIn] — `authStateChanges` (which drives [refreshListenable] below)
/// fires the instant the raw Firebase sign-in succeeds, which is *before*
/// [AuthService.signInWithEmail] has read the account's Firestore role and
/// possibly signed it back out for not being an admin. Guarding on
/// `isSignedIn` alone let that race auto-redirect a not-yet-verified (or
/// outright non-admin) session into `/admin` for the brief window before the
/// role check completed and signed it back out — the exact "logs in, then
/// kicks back out a second later" symptom this was written to fix.
/// `cachedRole` is only ever set to `'admin'` by [AuthService.saveRole],
/// which login_screen.dart calls *after* `signInWithEmail` has already
/// confirmed the role — so it can't go true during that race window.
String? _guard(BuildContext context, GoRouterState state) {
  final isVerifiedAdmin =
      AuthService.instance.isSignedIn && AuthService.instance.cachedRole == 'admin';
  final isPublic = _publicRoutes.contains(state.matchedLocation);

  if (!isVerifiedAdmin && !isPublic) return '/login';
  if (isVerifiedAdmin && state.matchedLocation == '/login') return '/admin';
  return null;
}

final appRouter = GoRouter(
  initialLocation: '/',
  redirect: _guard,
  refreshListenable: _AuthRefresh(AuthService.instance.authStateChanges),
  routes: [
    GoRoute(path: '/', builder: (context, state) => const WelcomeScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(path: '/admin', builder: (context, state) => const AdminLayout()),
    GoRoute(
      path: '/admin/notifications',
      builder: (context, state) => const AdminNotifications(),
    ),
    GoRoute(
      path: '/admin/subscription',
      builder: (context, state) => const AdminSubscription(),
    ),
    GoRoute(
      path: '/admin/fees',
      builder: (context, state) => const AdminFees(),
    ),
    GoRoute(
      path: '/admin/routes',
      builder: (context, state) => const AdminRoutes(),
    ),
    GoRoute(
      path: '/admin/vehicles',
      builder: (context, state) => const AdminVehicles(),
    ),
    // Entity detail pages — keyed by Firestore id, the screen loads its
    // own live data rather than being handed a snapshot object.
    GoRoute(
      path: '/admin/student-detail',
      builder: (context, state) {
        final studentId = state.extra as String;
        return AdminStudentDetail(studentId: studentId);
      },
    ),
    GoRoute(
      path: '/admin/parent-detail',
      builder: (context, state) {
        final parentId = state.extra as String;
        return AdminParentDetail(parentId: parentId);
      },
    ),
    GoRoute(
      path: '/admin/driver-detail',
      builder: (context, state) {
        final driverId = state.extra as String;
        return AdminDriverDetail(driverId: driverId);
      },
    ),
  ],
);
