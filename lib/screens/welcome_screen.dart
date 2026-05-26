import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _bounceController;
  late AnimationController _progressController;
  late Animation<double> _fadeAnim;
  late Animation<double> _bounceAnim;

  Timer? _navTimer;
  final _random = Random();
  late List<_FloatingDot> _dots;

  @override
  void initState() {
    super.initState();

    // Fade-in for content
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();

    // Bus bounce
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _bounceAnim = Tween<double>(begin: 0, end: -12).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    // Progress bar
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..forward();

    // Auto navigate after 4 seconds
    _navTimer = Timer(const Duration(milliseconds: 4000), () {
      if (mounted) context.go('/login');
    });

    // Generate floating dots
    _dots = List.generate(
      12,
      (i) => _FloatingDot(
        color: [
          AppTheme.adminEmerald,
          AppTheme.info,
          AppTheme.adminAccent,
          AppTheme.purple,
        ][i % 4],
        size: 3 + _random.nextDouble() * 4,
        left: 0.05 + _random.nextDouble() * 0.90,
        top: 0.10 + _random.nextDouble() * 0.80,
      ),
    );
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _fadeController.dispose();
    _bounceController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: context.scaffoldBg,
        child: Stack(
          children: [
            // Pulsing rings
            ...List.generate(6, (i) {
              final ringSize = 80.0 + i * 60;
              return Center(
                child: AnimatedBuilder(
                  animation: _bounceController,
                  builder: (_, __) {
                    final scale = 0.95 + (_bounceController.value * 0.10);
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: ringSize,
                        height: ringSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(
                              max(0.0, 0.15 - i * 0.02),
                            ),
                            width: 1,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }),

            // Floating dots
            ..._dots.map(
              (dot) => Positioned(
                left: dot.left * size.width,
                top: dot.top * size.height,
                child: AnimatedBuilder(
                  animation: _bounceController,
                  builder: (_, __) => Transform.translate(
                    offset: Offset(0, -_bounceController.value * 20),
                    child: Container(
                      width: dot.size,
                      height: dot.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dot.color.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Main content
            Center(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Shield icon with bounce
                      AnimatedBuilder(
                        animation: _bounceAnim,
                        builder: (_, __) => Transform.translate(
                          offset: Offset(0, _bounceAnim.value),
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              gradient: AppTheme.adminGradient,
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.adminEmerald.withValues(
                                    alpha: 0.5,
                                  ),
                                  blurRadius: 40,
                                  offset: const Offset(0, 20),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                '🛡️',
                                style: TextStyle(fontSize: 60),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // App name
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Colors.white,
                            Color(0xFF6EE7B7),
                            Color(0xFF34D399),
                          ],
                        ).createShader(bounds),
                        child: Text(
                          'Transit Admin',
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            color: context.textPrimary,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),
                      const SizedBox(height: 14),

                      // Progress bar
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: SizedBox(
                              width: 70,
                              height: 3,
                              child: AnimatedBuilder(
                                animation: _progressController,
                                builder: (_, __) => LinearProgressIndicator(
                                  value: _progressController.value,
                                  backgroundColor: Colors.white.withOpacity(
                                    0.15,
                                  ),
                                  valueColor: const AlwaysStoppedAnimation(
                                    AppTheme.adminEmerald,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingDot {
  final Color color;
  final double size;
  final double left;
  final double top;
  _FloatingDot({
    required this.color,
    required this.size,
    required this.left,
    required this.top,
  });
}
