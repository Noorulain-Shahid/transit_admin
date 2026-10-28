import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app/router.dart';
import 'app/auth_service.dart';
import 'app/locale_provider.dart';
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

      // DIAGNOSTIC ONLY — ruling out a corrupted local Firestore cache as the
      // cause of every `.snapshots()` stream silently hanging (no data, no
      // error, just a timeout). Must run before any other Firestore call —
      // it throws `failed-precondition` if a listener is already attached,
      // which is exactly why it's placed immediately after
      // `Firebase.initializeApp()` and before anything else touches
      // Firestore. `kDebugMode`-gated so a release build never pays the cost
      // of wiping offline persistence (and its resulting slower first
      // reads/no offline support) on every single cold start — remove this
      // block entirely once the hang is confirmed fixed or ruled out.
      if (kDebugMode) {
        try {
          await FirebaseFirestore.instance.clearPersistence();
          debugPrint('[main] Firestore persistence cleared.');
        } catch (e) {
          debugPrint('[main] clearPersistence failed (non-fatal): $e');
        }
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
    LocaleProvider.instance.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    ThemeProvider.instance.removeListener(_onThemeChanged);
    LocaleProvider.instance.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() => setState(() {});

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
      // `locale` bound to LocaleProvider is what actually flips the app to
      // RTL when Urdu is picked — 'ur' is on Flutter's built-in RTL language
      // list, so once this locale is active, `Directionality.of(context)`
      // switches automatically everywhere in the tree; nothing else needs
      // to opt in.
      locale: LocaleProvider.instance.locale,
      supportedLocales: LocaleProvider.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: appRouter,
    );
  }
}
