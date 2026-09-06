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
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _showPass = false;
  String _error = '';

  Future<void> _login() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    setState(() {
      _error = '';
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
    } on NotAnAdminException {
      if (mounted) {
        setState(() => _error = 'This account is not an admin account.');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _error = _friendlyAuthError(e));
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
      case 'invalid-email':
      case 'wrong-password':
      case 'user-not-found':
        return 'Incorrect email or password. Please try again.';
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
    const email = 'admin@transitpro.com';
    const password = 'TransitAdmin@2026';

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
