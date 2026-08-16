import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

enum ButtonVariant { primary, secondary, outline, text, danger }

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final ButtonVariant variant;
  final double? width;
  final double height;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.variant = ButtonVariant.primary,
    this.width,
    this.height = 54,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget child;
    if (widget.isLoading) {
      child = SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            widget.variant == ButtonVariant.primary
                ? (isDark ? AppColors.darkBackground : Colors.white)
                : AppColors.champagne,
          ),
        ),
      );
    } else {
      child = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, size: 20),
            const SizedBox(width: 10),
          ],
          Text(
            widget.text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: _getTextColor(isDark),
            ),
          ),
        ],
      );
    }

    return AnimatedScale(
      scale: _isPressed ? 0.975 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOutCubic,
      child: Container(
        width: widget.width ?? double.infinity,
        height: widget.height,
        decoration: _getBoxDecoration(isDark),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTapDown: widget.isLoading || widget.onPressed == null
                ? null
                : (_) => setState(() => _isPressed = true),
            onTapUp: widget.isLoading || widget.onPressed == null
                ? null
                : (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: widget.isLoading || widget.onPressed == null
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    widget.onPressed!();
                  },
            borderRadius: BorderRadius.circular(16),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }

  BoxDecoration _getBoxDecoration(bool isDark) {
    if (widget.onPressed == null) {
      return BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(16),
      );
    }

    switch (widget.variant) {
      case ButtonVariant.primary:
        return BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.champagneDark.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        );
      case ButtonVariant.secondary:
        return BoxDecoration(
          color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
          borderRadius: BorderRadius.circular(16),
        );
      case ButtonVariant.outline:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.champagne : AppColors.champagneDark,
            width: 1.5,
          ),
        );
      case ButtonVariant.text:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        );
      case ButtonVariant.danger:
        return BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        );
    }
  }

  Color _getTextColor(bool isDark) {
    if (widget.onPressed == null) {
      return isDark ? AppColors.textTertiaryDark : Colors.grey.shade600;
    }
    switch (widget.variant) {
      case ButtonVariant.primary:
        return isDark ? AppColors.darkBackground : Colors.white;
      case ButtonVariant.secondary:
        return isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
      case ButtonVariant.outline:
        return isDark ? AppColors.champagne : AppColors.champagneDark;
      case ButtonVariant.text:
        return isDark ? AppColors.champagne : AppColors.champagneDark;
      case ButtonVariant.danger:
        return Colors.white;
    }
  }
}
