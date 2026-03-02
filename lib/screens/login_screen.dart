import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

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

  void _fillDemo() {
    _emailCtrl.text = 'admin@transit.com';
    _passCtrl.text = 'admin123';
    setState(() => _error = '');
  }

  void _login() {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    setState(() {
      _error = '';
      _loading = true;
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _loading = false);
        context.go('/admin');
      }
    });
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
                        AppTheme.adminEmerald.withOpacity(0.4),
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
                    const SizedBox(height: 44),

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
                                  color: AppTheme.adminEmerald.withOpacity(
                                    0.45,
                                  ),
                                  blurRadius: 28,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                '🛡️',
                                style: TextStyle(fontSize: 36),
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
                          // Demo hint
                          GestureDetector(
                            onTap: _fillDemo,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.adminEmerald.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.adminEmerald.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '📋  USE DEMO ACCOUNT',
                                    style: TextStyle(
                                      color: AppTheme.adminAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'admin@transit.com  ·  admin123',
                                    style: TextStyle(
                                      color: context.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),

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
                                color: AppTheme.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppTheme.error.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Text(
                                    '⚠️  ',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                  Text(
                                    _error,
                                    style: const TextStyle(
                                      color: Color(0xFFFCA5A5),
                                      fontSize: 13,
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        '🔒  256-bit encrypted · GDPR compliant',
                        style: TextStyle(
                          color: context.textHint,
                          fontSize: 12,
                        ),
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

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withOpacity(0.6),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }
}
