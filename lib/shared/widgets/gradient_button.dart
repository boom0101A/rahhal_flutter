import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

/// Primary amber gradient CTA button with optional loading state.
class GradientButton extends StatefulWidget {
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
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null && !widget.isLoading;
    return SizedBox(
      width: widget.width ?? double.infinity,
      child: GestureDetector(
        onTapDown: widget.isLoading || disabled ? null : (_) => _scaleCtrl.forward(),
        onTapUp: widget.isLoading || disabled ? null : (_) => _scaleCtrl.reverse(),
        onTapCancel: widget.isLoading || disabled ? null : () => _scaleCtrl.reverse(),
        onTap: widget.isLoading ? null : widget.onPressed,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 56,
            padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              gradient: disabled ? null : AppColors.amberGradient,
              color: disabled ? AppColors.adaptiveTextSecondary(context).withValues(alpha: 0.2) : null,
              borderRadius: BorderRadius.circular(50),
              boxShadow: widget.isLoading || disabled ? null : AppColors.amberGlow,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.isLoading) ...[
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
                    widget.label,
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.bgPrimary,
                    ),
                  ),
                  if (widget.icon != null) ...[
                    const SizedBox(width: 8),
                    Icon(widget.icon, size: 20, color: AppColors.bgPrimary),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
