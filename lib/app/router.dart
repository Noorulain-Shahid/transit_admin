import 'package:go_router/go_router.dart';
import '../screens/welcome_screen.dart';
import '../screens/login_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/admin/admin_layout.dart';

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
  ],
);
