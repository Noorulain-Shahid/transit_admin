import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Soft, elevated card (two opposing shadows, `context.isDark`-aware) used
/// across several admin screens (Fee/Route/Vehicle Management, detail-screen
/// empty states) — previously copy-pasted as an identical or near-identical
/// private `_NeumorphicCard` in each file. [borderRadius]/[shadowOffset]/
/// [blurRadius] default to the shape most screens already used; Fee
/// Management's slightly larger variant is reproduced by passing its own
/// values rather than forcing every caller into one fixed size.
class NeumorphicCard extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final Widget child;
  final double borderRadius;
  final double shadowOffset;
  final double blurRadius;

  const NeumorphicCard({
    super.key,
    required this.padding,
    required this.child,
    this.borderRadius = 16,
    this.shadowOffset = 5,
    this.blurRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.45)
                : const Color(0xFFB8BEC8).withValues(alpha: 0.6),
            offset: Offset(shadowOffset, shadowOffset),
            blurRadius: blurRadius,
          ),
          BoxShadow(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.white.withValues(alpha: 0.9),
            offset: Offset(-shadowOffset, -shadowOffset),
            blurRadius: blurRadius,
          ),
        ],
      ),
      child: child,
    );
  }
}
