# ملف كود Dart: lib\shared\widgets\glass_card.dart

```dart
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

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.border,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.glass,
        borderRadius:
            borderRadius ?? BorderRadius.circular(16),
        border: border ??
            Border.all(
              color: AppColors.glassBorder,
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
        color: AppColors.glassStrong,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder, width: 1),
      ),
      child: child,
    );
  }
}

```
