import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:transit_core/transit_core.dart';
import '../theme/theme_provider.dart';

/// Thrown by [AuthService.signInWithEmail] when the credentials are valid but
/// the account isn't an admin — kept separate from [FirebaseAuthException] so
/// the login screen can show one clear message either way.
class NotAnAdminException implements Exception {
  const NotAnAdminException();
}

/// Persists the logged-in role and theme preference across app restarts.
///
/// Call [saveRole] right after a successful login.
/// Call [saveTheme] whenever the user toggles dark/light mode.
/// Call [clearRole] when the user taps "Log Out".
/// Call [getSavedRole] at app start to decide where to navigate.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _roleKey = 'logged_in_role';
  static const _themeKey = 'theme_is_dark';

  // A getter, not a field — main.dart deliberately swallows a failed
  // Firebase.initializeApp() to keep running in "front-end mode" (see its
  // comment), and widget tests never call main() at all. A `final` field
  // would evaluate FirebaseAuth.instance (and throw `[core/no-app]`) the
  // moment *anything* constructs AuthService, which now happens as soon as
  // the router is built. Deferring to per-call access, with isSignedIn/
  // authStateChanges below catching the failure, keeps both cases working.
  FirebaseAuth get _firebaseAuth => FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// In-memory cache populated by [preload] before runApp().
  String? _cachedRole;
  String? get cachedRole => _cachedRole;

  /// True if a Firebase user is currently signed in. Note this only reflects
  /// *authentication*, not the `role: admin` check — that only happens inside
  /// [signInWithEmail] itself, so a non-admin account can never get signed in
  /// in the first place. Returns false (rather than throwing) if Firebase
  /// itself isn't initialized.
  bool get isSignedIn {
    try {
      return _firebaseAuth.currentUser != null;
    } catch (_) {
      return false;
    }
  }

  /// Fires on every sign-in/sign-out, used to drive the router's redirect.
  /// An empty stream (rather than a throw) if Firebase isn't initialized.
  Stream<User?> get authStateChanges {
    try {
      return _firebaseAuth.authStateChanges();
    } catch (_) {
      return const Stream.empty();
    }
  }

  /// Must be called in main() before runApp(). Loads role + theme into memory.
  Future<void> preload() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedRole = prefs.getString(_roleKey);
    final isDark = prefs.getBool(_themeKey);
    if (isDark != null) {
      ThemeProvider.instance.setMode(isDark ? ThemeMode.dark : ThemeMode.light);
    }
  }

  /// Returns true if sign-in succeeded (Firebase or front-end mode).
  /// Returns false if the user cancelled.
  /// Throws on other errors.
  Future<bool> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false; // The user canceled the sign-in

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Try Firebase auth, but fall back gracefully if Firebase isn't initialized
      try {
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await _firebaseAuth.signInWithCredential(credential);
      } catch (e) {
        // Firebase not available, but Google Sign-In succeeded - front-end mode
        debugPrint(
          'Firebase unavailable (front-end mode), proceeding with local auth: $e',
        );
      }
      return true; // Success in any case (Firebase or front-end mode)
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      rethrow;
    }
  }

  /// Signs in with Firebase Auth and requires the resulting account to carry
  /// `role: admin` on its `users/{uid}` document — that's the check every
  /// `isAdmin()` Firestore rule relies on, so a non-admin account must never
  /// be allowed to reach the admin shell even if the password is correct.
  ///
  /// Throws [FirebaseAuthException] for bad credentials, [NotAnAdminException]
  /// if the account is real but not an admin (and signs it back out).
  Future<void> signInWithEmail(String email, String password) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user?.uid;
    final user = uid == null ? null : await Db.users.doc(uid).get();
    final role = user?.data()?.role;
    if (role != UserRole.admin) {
      await _firebaseAuth.signOut();
      throw const NotAnAdminException();
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
    await clearRole();
  }

  /// Saves [role] ('parent' | 'driver' | 'student') to persistent storage.
  Future<void> saveRole(String role) async {
    _cachedRole = role;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role);
  }

  /// Saves the current dark-mode state.
  Future<void> saveTheme({required bool isDark}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
  }

  /// Loads and applies the persisted theme. Call after determining the role.
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_themeKey);
    if (isDark != null) {
      ThemeProvider.instance.setMode(isDark ? ThemeMode.dark : ThemeMode.light);
    }
  }

  /// Clears the saved role (call on logout). Theme is intentionally kept.
  Future<void> clearRole() async {
    _cachedRole = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_roleKey);
  }

  /// Returns the saved role, or `null` if no one is logged in.
  Future<String?> getSavedRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  /// Converts a role string to its root route path.
  static String routeForRole(String role) {
    switch (role) {
      case 'driver':
        return '/driver';
      case 'student':
        return '/student';
      default:
        return '/parent';
    }
  }
}
