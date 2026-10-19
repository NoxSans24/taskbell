import 'package:flutter/material.dart';
import 'package:taskbell_app/core/theme/app_theme.dart';

class ComicCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final double shadowOffset;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const ComicCard({
    super.key,
    required this.child,
    this.color,
    this.shadowOffset = 3.0,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color ?? palette.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: palette.shadow,
              offset: Offset(shadowOffset, shadowOffset),
              blurRadius: 0,
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class ComicButton extends StatelessWidget {
  final String text;
  final Widget? icon;
  final Color? color;
  final VoidCallback onPressed;
  final bool isFullWidth;

  const ComicButton({
    super.key,
    required this.text,
    this.icon,
    this.color,
    required this.onPressed,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? palette.secondary,
            foregroundColor: palette.onAccent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: palette.border, width: 2),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ).copyWith(
            overlayColor: WidgetStateProperty.all(
              palette.onAccent.withValues(alpha: 0.08),
            ),
            shadowColor: WidgetStateProperty.all(Colors.transparent),
          ),
          child: Ink(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: palette.shadow,
                  offset: const Offset(3, 3),
                  blurRadius: 0,
                ),
              ],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  icon!,
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
