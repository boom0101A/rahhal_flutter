# ملف كود Dart: lib\shared\widgets\gradient_button.dart

```dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

/// Primary amber gradient CTA button with optional loading state.
class GradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final EdgeInsetsGeometry? padding;

  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.width,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      child: GestureDetector(
        onTap: isLoading ? null : onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 56,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            gradient: onPressed == null && !isLoading
                ? null
                : AppColors.amberGradient,
            color: onPressed == null && !isLoading
                ? AppColors.textSecondary.withValues(alpha: 0.2)
                : null,
            borderRadius: BorderRadius.circular(50),
            boxShadow:
                isLoading || onPressed == null ? null : AppColors.amberGlow,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading) ...[
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ] else ...[
                Text(
                  label,
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.bgPrimary,
                  ),
                ),
                if (icon != null) ...[
                  const SizedBox(width: 8),
                  Icon(icon, size: 20, color: AppColors.bgPrimary),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

```
