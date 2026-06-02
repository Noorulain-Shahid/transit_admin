import 'package:go_router/go_router.dart';
import '../screens/welcome_screen.dart';
import '../screens/login_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/admin/admin_layout.dart';
import '../screens/admin/admin_notifications.dart';
import '../screens/admin/admin_subscription.dart';
import '../screens/admin/admin_user_detail.dart';
import '../screens/admin/admin_user_models.dart';
import '../screens/admin/admin_student_detail.dart';
import '../screens/admin/admin_parent_detail.dart';
import '../screens/admin/admin_driver_detail.dart';

final appRouter = GoRouter(
  initialLocation: '/',
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
    // Legacy user detail (kept for backward compat)
    GoRoute(
      path: '/admin/user-detail',
      builder: (context, state) {
        final user = state.extra as AdminUserRecord;
        return AdminUserDetailPage(user: user);
      },
    ),
    // New entity detail pages
    GoRoute(
      path: '/admin/student-detail',
      builder: (context, state) {
        final student = state.extra as StudentRecord;
        return AdminStudentDetail(student: student);
      },
    ),
    GoRoute(
      path: '/admin/parent-detail',
      builder: (context, state) {
        final parent = state.extra as ParentRecord;
        return AdminParentDetail(parent: parent);
      },
    ),
    GoRoute(
      path: '/admin/driver-detail',
      builder: (context, state) {
        final driver = state.extra as DriverRecord;
        return AdminDriverDetail(driver: driver);
      },
    ),
  ],
);
