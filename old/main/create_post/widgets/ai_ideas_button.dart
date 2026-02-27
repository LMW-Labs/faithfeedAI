import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

/// A floating button that opens the AI content generator
class AIIdeasButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isActive;

  const AIIdeasButton({
    super.key,
    required this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: isActive ? AppTheme.aiGradient : null,
          color: isActive ? null : AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? AppTheme.primaryTeal
                : AppTheme.onSurfaceVariant.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Icon(
          Icons.auto_awesome,
          color: isActive ? Colors.white : AppTheme.primaryTeal,
          size: 24,
        ),
      ),
    );
  }
}
