import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final Border? border;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 20,
    this.blur = 12,
    this.border,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBody = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkCard.withOpacity(0.7)
            : AppColors.lightCard.withOpacity(0.8),
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ??
            Border.all(
              color: isDark ? AppColors.darkBorder.withOpacity(0.6) : AppColors.lightBorder.withOpacity(0.8),
              width: 1,
            ),
      ),
      child: child,
    );

    final container = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      clipBehavior: Clip.antiAlias,
      child: blur > 0
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: cardBody,
            )
          : cardBody,
    );

    Widget content = container;

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: AppColors.champagne.withOpacity(0.12),
          highlightColor: Colors.transparent,
          child: container,
        ),
      );
    }

    if (margin != null) {
      return Padding(
        padding: margin!,
        child: content,
      );
    }

    return content;
  }
}
