import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import 'hashtag_button.dart';
import 'ai_ideas_button.dart';

/// Floating action buttons that appear in bottom-right corner of text input
/// Contains: Attach media button, Hashtag button, AI ideas button
class FloatingActionButtons extends StatelessWidget {
  final Gradient? selectedGradient;
  final Color? selectedColor;
  final Function(Gradient gradient, Color textColor) onGradientSelected;
  final Function(Color color, Color textColor) onColorSelected;
  final VoidCallback onClearBackground;
  final TextEditingController textController;
  final VoidCallback onHashtagInserted;
  final VoidCallback onAIIdeasPressed;
  final bool isAIActive;
  final VoidCallback? onAttachMediaPressed;

  const FloatingActionButtons({
    super.key,
    required this.selectedGradient,
    required this.selectedColor,
    required this.onGradientSelected,
    required this.onColorSelected,
    required this.onClearBackground,
    required this.textController,
    required this.onHashtagInserted,
    required this.onAIIdeasPressed,
    this.isAIActive = false,
    this.onAttachMediaPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      right: 16,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Attach media button (paperclip icon)
          if (onAttachMediaPressed != null)
            _buildAttachMediaButton(),
          if (onAttachMediaPressed != null)
            const SizedBox(width: 8),

          // Hashtag button
          HashtagButton(
            controller: textController,
            onHashtagInserted: onHashtagInserted,
          ),
          const SizedBox(width: 8),

          // AI ideas button
          AIIdeasButton(
            onPressed: onAIIdeasPressed,
            isActive: isAIActive,
          ),
        ],
      ),
    );
  }

  Widget _buildAttachMediaButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onAttachMediaPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primaryBlue.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.attach_file,
            color: AppTheme.primaryBlue,
            size: 20,
          ),
        ),
      ),
    );
  }
}
