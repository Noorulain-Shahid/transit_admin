import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Mini Bar Chart — compact bar chart for dashboard analytics
// ─────────────────────────────────────────────────────────────────────────────
class MiniBarChart extends StatelessWidget {
  final List<double> values;
  final List<String>? labels;
  final Color barColor;
  final Color? barActiveColor;
  final double height;
  final double barWidth;
  final double barSpacing;

  const MiniBarChart({
    super.key,
    required this.values,
    this.labels,
    this.barColor = const Color(0xFF3B82F6),
    this.barActiveColor,
    this.height = 80,
    this.barWidth = 12,
    this.barSpacing = 6,
  });

  @override
  Widget build(BuildContext context) {
    final maxVal = values.reduce(math.max);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: height + (labels != null ? 20 : 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(values.length, (i) {
          final fraction = maxVal > 0 ? values[i] / maxVal : 0.0;
          final isHighest = values[i] == maxVal;
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: fraction),
                duration: Duration(milliseconds: 600 + i * 80),
                curve: Curves.easeOutCubic,
                builder: (context, val, _) {
                  return Container(
                    width: barWidth,
                    height: (height * val).clamp(4, height),
                    decoration: BoxDecoration(
                      color: isHighest
                          ? (barActiveColor ?? barColor)
                          : barColor.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(barWidth / 2),
                    ),
                  );
                },
              ),
              if (labels != null) ...[
                const SizedBox(height: 4),
                Text(
                  labels![i],
                  style: TextStyle(
                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Mini Line Chart — compact trend line for growth metrics
// ─────────────────────────────────────────────────────────────────────────────
class MiniLineChart extends StatelessWidget {
  final List<double> values;
  final Color lineColor;
  final double height;
  final double strokeWidth;
  final bool showGradient;

  const MiniLineChart({
    super.key,
    required this.values,
    this.lineColor = const Color(0xFF10B981),
    this.height = 50,
    this.strokeWidth = 2.0,
    this.showGradient = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, progress, _) {
          return CustomPaint(
            size: Size(double.infinity, height),
            painter: _LineChartPainter(
              values: values,
              color: lineColor,
              strokeWidth: strokeWidth,
              progress: progress,
              showGradient: showGradient,
            ),
          );
        },
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final double strokeWidth;
  final double progress;
  final bool showGradient;

  _LineChartPainter({
    required this.values,
    required this.color,
    required this.strokeWidth,
    required this.progress,
    required this.showGradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final maxVal = values.reduce(math.max);
    final minVal = values.reduce(math.min);
    final range = maxVal - minVal;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final gradientPath = Path();

    for (int i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width * progress;
      final normalized = range > 0 ? (values[i] - minVal) / range : 0.5;
      final y = size.height - (normalized * size.height * 0.85) - size.height * 0.05;

      if (i == 0) {
        path.moveTo(x, y);
        gradientPath.moveTo(x, y);
      } else {
        final prevX = ((i - 1) / (values.length - 1)) * size.width * progress;
        final prevNorm = range > 0 ? (values[i - 1] - minVal) / range : 0.5;
        final prevY = size.height - (prevNorm * size.height * 0.85) - size.height * 0.05;
        final cpX = (prevX + x) / 2;
        path.cubicTo(cpX, prevY, cpX, y, x, y);
        gradientPath.cubicTo(cpX, prevY, cpX, y, x, y);
      }
    }

    if (showGradient) {
      final lastX = size.width * progress;
      gradientPath.lineTo(lastX, size.height);
      gradientPath.lineTo(0, size.height);
      gradientPath.close();

      final gradientPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.25),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawPath(gradientPath, gradientPaint);
    }

    canvas.drawPath(path, paint);

    // Draw endpoint dot
    if (values.isNotEmpty && progress > 0.9) {
      final lastI = values.length - 1;
      final lx = (lastI / (values.length - 1)) * size.width * progress;
      final lNorm = range > 0 ? (values[lastI] - minVal) / range : 0.5;
      final ly = size.height - (lNorm * size.height * 0.85) - size.height * 0.05;

      canvas.drawCircle(
        Offset(lx, ly),
        4,
        Paint()..color = color,
      );
      canvas.drawCircle(
        Offset(lx, ly),
        2,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) =>
      old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Ring Indicator — donut chart for success/failure rates
// ─────────────────────────────────────────────────────────────────────────────
class RingIndicator extends StatelessWidget {
  final double percentage;
  final Color color;
  final Color? bgColor;
  final double size;
  final double strokeWidth;
  final Widget? center;

  const RingIndicator({
    super.key,
    required this.percentage,
    required this.color,
    this.bgColor,
    this.size = 64,
    this.strokeWidth = 6,
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: percentage / 100),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, val, child) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: _RingPainter(
                  progress: val,
                  color: color,
                  bgColor: bgColor ??
                      (isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFE2E8F0)),
                  strokeWidth: strokeWidth,
                ),
              ),
              ?center,
            ],
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bgColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.bgColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = bgColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Animated Counter — counting-up animation for stat values
// ─────────────────────────────────────────────────────────────────────────────
class AnimatedCounter extends StatelessWidget {
  final int value;
  final String? prefix;
  final String? suffix;
  final TextStyle? style;
  final Duration duration;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.prefix,
    this.suffix,
    this.style,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, val, _) {
        return Text(
          '${prefix ?? ''}${val.toInt()}${suffix ?? ''}',
          style: style,
        );
      },
    );
  }
}
