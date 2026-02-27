import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

/// Text input area that adapts based on whether gradient background is active
/// - Enlarges text when gradient is active (Facebook-style)
/// - Removes borders when gradient is active
/// - Scrolls when no gradient, limits lines when gradient is active
class PostTextInput extends StatelessWidget {
  final TextEditingController controller;
  final bool hasGradientBackground;
  final Gradient? backgroundGradient;
  final Color backgroundColor;
  final Color textColor;
  final bool isBold;
  final bool isItalic;
  final double fontSize;
  final TextAlign textAlignment;
  final String? hintText;

  const PostTextInput({
    super.key,
    required this.controller,
    required this.hasGradientBackground,
    this.backgroundGradient,
    required this.backgroundColor,
    required this.textColor,
    this.isBold = false,
    this.isItalic = false,
    this.fontSize = 16.0,
    this.textAlignment = TextAlign.left,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate font size based on gradient background
    // When gradient is active, text should be larger (Facebook-style)
    final effectiveFontSize = hasGradientBackground
        ? fontSize * 1.5  // 50% larger when gradient is active
        : fontSize;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        // Narrower height - more compact
        minHeight: hasGradientBackground ? 200 : 180,
        maxHeight: hasGradientBackground ? 200 : 180,
      ),
      decoration: BoxDecoration(
        color: backgroundGradient == null ? backgroundColor : null,
        gradient: backgroundGradient,
        // Remove border radius when gradient is active (full-width like feed images)
        borderRadius: hasGradientBackground ? null : BorderRadius.circular(12),
        // Only show border when NO gradient is active
        border: hasGradientBackground
            ? null
            : Border.all(
                color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3),
                width: 1,
              ),
      ),
      child: Stack(
        children: [
          // Text input with scrolling behavior
          Padding(
            padding: EdgeInsets.all(hasGradientBackground ? 20 : 12),
            child: SingleChildScrollView(
              child: TextField(
                controller: controller,
                // When gradient is active, limit max lines to fit in box
                // When no gradient, allow unlimited scrolling
                maxLines: hasGradientBackground ? 6 : null,
                minLines: hasGradientBackground ? 6 : 8,
                textAlign: textAlignment,
                style: TextStyle(
                  color: textColor,
                  fontSize: effectiveFontSize,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
                  height: 1.4,
                ),
                decoration: InputDecoration(
                  hintText: hintText ?? "What's on your heart?",
                  hintStyle: TextStyle(
                    color: textColor.withValues(alpha: 0.5),
                    fontSize: effectiveFontSize,
                  ),
                  filled: false,
                  fillColor: Colors.transparent,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),

          // Clear background button (X) - only show when gradient is active
          if (hasGradientBackground)
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    // This will be handled by parent widget
                    // Parent should clear the gradient when this is tapped
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
