import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app/router.dart';
import 'app/auth_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';

void main() {
  // A live Firestore permission error (e.g. a session whose admin role was
  // revoked after login) was observed to terminate the whole app process on
  // a real device instead of just failing the one screen — each screen's own
  // stream `onError` handler should already catch this, but this is the last
  // line of defense so a gap in any one of them can never take the app down.
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Initialize Firebase with graceful fallback for front-end-only mode
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } catch (e) {
        debugPrint('Firebase initialization skipped (front-end mode): $e');
      }

      // Preload auth and theme settings
      await AuthService.instance.preload();

      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      runApp(const TransitAdminApp());
    },
    (error, stack) {
      debugPrint('[UNCAUGHT] $error\n$stack');
    },
  );
}

class TransitAdminApp extends StatefulWidget {
  const TransitAdminApp({super.key});

  @override
  State<TransitAdminApp> createState() => _TransitAdminAppState();
}

class _TransitAdminAppState extends State<TransitAdminApp> {
  @override
  void initState() {
    super.initState();
    ThemeProvider.instance.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    ThemeProvider.instance.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() => setState(() {
    final isDark = ThemeProvider.instance.isDark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: isDark
            ? const Color(0xFF0C0120)
            : const Color(0xFFF0FDF4),
      ),
    );
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TransitPro Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeProvider.instance.mode,
      routerConfig: appRouter,
    );
  }
}
