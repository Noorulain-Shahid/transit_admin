import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../app/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  /// The account this build expects. Printed on screen, so there is nothing
  /// secret about it — and the setup panel below needs the same two values,
  /// which is why they are not typed out twice.
  static const _adminEmail = 'admin@transitpro.com';
  static const _adminPassword = 'TransitAdmin@2026';

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _showPass = false;
  String _error = '';

  /// Set when sign-in finds no `users/{uid}` record, which is what a
  /// cleared database looks like. Switches the panel below from "here are
  /// your credentials" to "here is how to put the account back".
  bool _recordMissing = false;

  /// The uid the admin document has to be filed under, once the repair has
  /// run. Null until then.
  String? _preparedUid;
  bool _preparing = false;

  Future<void> _login() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    setState(() {
      _error = '';
      _recordMissing = false;
      _loading = true;
    });
    try {
      await AuthService.instance.signInWithEmail(
        _emailCtrl.text.trim(),
        _passCtrl.text,
      );
      if (!mounted) return;
      await AuthService.instance.saveRole('admin');
      if (!mounted) return;
      context.go('/admin');
    } on AdminRecordMissingException catch (e) {
      if (mounted) {
        setState(() {
          _recordMissing = true;
          _preparedUid = e.uid;
          _error =
              'The password is right, but this account has no admin record '
              'in the database. Use the panel below to put it back.';
        });
      }
    } on NotAnAdminException {
      if (mounted) {
        setState(
          () => _error =
              'That account exists but is not an admin. Sign in with the '
              'admin address, or promote this one in the console.',
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _error = _friendlyAuthError(e);
          // No such account at all is the other shape a cleared backend
          // takes, so the repair panel belongs here too — the message
          // points at it, and without this it would not be on screen.
          // Modern Firebase Auth reports this as 'invalid-credential'
          // rather than 'user-not-found', to avoid confirming which part
          // was wrong — so a missing account looks identical to a bad
          // password unless both codes open the panel.
          if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
            _recordMissing = true;
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Sign-in failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Translates raw Firebase Auth error codes into user-friendly messages.
  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
        // Firebase uses this single code for both "wrong password" and "no
        // such account", so the message has to cover both — the panel
        // below is what actually resolves the second case.
        return 'Incorrect email or password. If the database was cleared, '
            'use the setup panel below instead.';
      case 'invalid-email':
      case 'wrong-password':
        return 'Incorrect email or password. Please try again.';
      case 'user-not-found':
        // Distinct from a wrong password: there is no such account at all,
        // which after a database wipe is the likely state.
        return 'No account exists for that address. If the database was '
            'cleared, use the setup panel below.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return 'Sign-in failed. Please check your details and try again.';
    }
  }

  /// Rebuilds the Auth user and the `users/{uid}` document, then shows the
  /// uid so the role can be set where the rules insist it is set.
  Future<void> _prepareAccount() async {
    setState(() {
      _preparing = true;
      _error = '';
    });
    try {
      final uid = await AuthService.instance.prepareAdminAccount(
        _adminEmail,
        _adminPassword,
      );
      if (!mounted) return;
      setState(() {
        _preparedUid = uid;
        _recordMissing = true;
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(
        () => _error = e.code == 'email-already-in-use'
            ? 'That address already has an account under a different '
                  'password. Reset it from the Firebase console.'
            : 'Could not prepare the account: ${e.code}',
      );
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not prepare the account: $e');
    } finally {
      if (mounted) setState(() => _preparing = false);
    }
  }

  void _copyToClipboard(BuildContext context, String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Remove this panel once you no longer need it on screen — the admin
  // account itself lives in Firebase, not in this code, so deleting this
  // widget doesn't affect the account, only its visibility here.
  Widget _buildAdminCredentials(BuildContext context) {
    if (_recordMissing) return _buildRepairPanel(context);

    const email = _adminEmail;
    const password = _adminPassword;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.isDark
            ? AppTheme.driverCyan.withValues(alpha: 0.08)
            : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.driverCyan.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🔑 Your Admin Account',
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _CredentialRow(
            label: 'Email',
            value: email,
            onCopy: () => _copyToClipboard(context, 'Email', email),
          ),
          const SizedBox(height: 6),
          _CredentialRow(
            label: 'Password',
            value: password,
            onCopy: () => _copyToClipboard(context, 'Password', password),
          ),
        ],
      ),
    );
  }

  /// What to do when the account's database record is gone.
  ///
  /// Two steps, because exactly one of them is something a client is
  /// allowed to do. The app can create the login and the user document;
  /// it cannot set `role: 'admin'`, and the rule that stops it is the same
  /// rule that stops anyone else's installed copy from doing so.
  Widget _buildRepairPanel(BuildContext context) {
    final uid = _preparedUid;
    final hasUid = uid != null && uid.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.isDark
            ? const Color(0xFFF59E0B).withValues(alpha: 0.10)
            : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\u{1F6E0} Put the admin account back',
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'An admin account is two records: a sign-in, and a user document '
            'carrying the admin role. Clearing the database removed the '
            'second one.',
            style: TextStyle(
              color: context.textSecondary,
              fontSize: 11.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          if (!hasUid)
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _preparing ? null : _prepareAccount,
                child: Text(
                  _preparing ? 'Working\u2026' : 'Step 1 \u2014 rebuild what I can',
                ),
              ),
            )
          else ...[
            Text(
              'Step 1 done. The sign-in and the user document exist.',
              style: TextStyle(
                color: const Color(0xFF16A34A),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Step 2 \u2014 in the Firebase console, open Firestore \u2192 '
              'users \u2192 this document and change its "role" field from '
              '"parent" to "admin". The app is not allowed to do this, and '
              'that rule is what stops any installed copy from granting '
              'itself your data.',
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            _CredentialRow(
              label: 'Document',
              value: 'users/$uid',
              onCopy: () => _copyToClipboard(context, 'Path', 'users/$uid'),
            ),
            const SizedBox(height: 10),
            Text(
              'Then come back and sign in with the address above.',
              style: TextStyle(color: context.textTertiary, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: context.scaffoldBg,
        child: Stack(
          children: [
            // Glow blob
            Positioned(
              top: -100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.adminEmerald.withValues(alpha: 0.4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // Back button for non-nav screens
                    if (Navigator.of(context).canPop()) ...[
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: context.cardBgElevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: context.inputBorder),
                          ),
                          child: Text(
                            '← Back',
                            style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                    ] else ...[
                      const SizedBox(height: 44),
                    ],

                    // Role icon
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              gradient: AppTheme.adminGradient,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.adminEmerald.withValues(
                                    alpha: 0.45,
                                  ),
                                  blurRadius: 28,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Image.asset(
                                'assets/images/splash_screen/bus_splash_icon.png',
                                width: 40,
                                height: 40,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          Text(
                            'Admin Login',
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Manage your fleet & operations',
                            style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 28),
                        ],
                      ),
                    ),

                    // Form card
                    GlassCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Email
                          _FieldLabel('EMAIL ADDRESS'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 15,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Enter your email',
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Password
                          _FieldLabel('PASSWORD'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passCtrl,
                            obscureText: !_showPass,
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 15,
                            ),
                            onSubmitted: (_) => _login(),
                            decoration: InputDecoration(
                              hintText: 'Enter your password',
                              suffixIcon: GestureDetector(
                                onTap: () =>
                                    setState(() => _showPass = !_showPass),
                                child: Icon(
                                  _showPass
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: context.textTertiary,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Forgot password
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () => context.push('/forgot-password'),
                              child: Text(
                                'Forgot password?',
                                style: TextStyle(
                                  color: AppTheme.adminAccent,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),

                          // Error
                          if (_error.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppTheme.error.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '⚠️  ',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                  Expanded(
                                    child: Text(
                                      _error,
                                      style: const TextStyle(
                                        color: Color(0xFFFCA5A5),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),

                          // Login button
                          GradientButton(
                            label: 'Sign In as Admin →',
                            gradient: AppTheme.adminGradient,
                            glowColor: AppTheme.adminEmerald,
                            isLoading: _loading,
                            onTap: _login,
                          ),
                          const SizedBox(height: 16),

                          // Sign up prompt
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: TextStyle(
                                  color: context.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.push('/signup'),
                                child: const Text(
                                  'Sign up',
                                  style: TextStyle(
                                    color: AppTheme.adminEmerald,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildAdminCredentials(context),
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        '🔒  256-bit encrypted · GDPR compliant',
                        style: TextStyle(color: context.textHint, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CredentialRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onCopy;

  const _CredentialRow({
    required this.label,
    required this.value,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 68,
          child: Text(
            label,
            style: TextStyle(color: context.textSecondary, fontSize: 12),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy_rounded, size: 16),
          color: AppTheme.driverCyan,
          tooltip: 'Copy $label',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          onPressed: onCopy,
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: context.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }
}
