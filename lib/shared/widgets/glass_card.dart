import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Frosted glass card matching the Next.js design prototype's `.glass` class.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Border? border;
  final List<BoxShadow>? boxShadow;

  /// Overrides [backgroundColor] with a gradient fill — for callers that need
  /// a tinted glass look (e.g. the weather banner's sky gradient) while still
  /// sharing this card's padding/border/radius defaults.
  final Gradient? gradient;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.border,
    this.boxShadow,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null
            ? (backgroundColor ?? AppColors.adaptiveGlass(context))
            : null,
        gradient: gradient,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        border: border ??
            Border.all(
              color: AppColors.adaptiveGlassBorder(context),
              width: 1,
            ),
        boxShadow: boxShadow,
      ),
      child: child,
    );
  }
}

/// A stronger glass card with 70% opacity background.
class GlassCardStrong extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const GlassCardStrong({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.adaptiveGlassStrong(context),
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.adaptiveGlassBorder(context),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}
