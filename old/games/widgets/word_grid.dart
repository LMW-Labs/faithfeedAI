import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class WordGrid extends StatelessWidget {
  final List<String> words;
  final List<bool> revealedWords;
  final Function(int) onWordTap;
  final bool canReveal;

  const WordGrid({
    super.key,
    required this.words,
    required this.revealedWords,
    required this.onWordTap,
    required this.canReveal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryTeal.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: words.asMap().entries.map((entry) {
          final index = entry.key;
          final word = entry.value;
          final isRevealed = revealedWords[index];

          return _WordChip(
            word: word,
            isRevealed: isRevealed,
            canReveal: canReveal,
            onTap: () => onWordTap(index),
          );
        }).toList(),
      ),
    );
  }
}

class _WordChip extends StatefulWidget {
  final String word;
  final bool isRevealed;
  final bool canReveal;
  final VoidCallback onTap;

  const _WordChip({
    required this.word,
    required this.isRevealed,
    required this.canReveal,
    required this.onTap,
  });

  @override
  State<_WordChip> createState() => _WordChipState();
}

class _WordChipState extends State<_WordChip> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Animate in when revealed
    if (widget.isRevealed) {
      _controller.forward();
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _controller.reverse();
      });
    }
  }

  @override
  void didUpdateWidget(_WordChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isRevealed && widget.isRevealed) {
      _controller.forward();
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _controller.reverse();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: widget.isRevealed || !widget.canReveal ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: widget.isRevealed
                ? LinearGradient(
                    colors: [
                      AppTheme.primaryTeal,
                      AppTheme.primaryTeal.withValues(alpha: 0.8),
                    ],
                  )
                : LinearGradient(
                    colors: [
                      AppTheme.darkGrey,
                      AppTheme.darkGrey.withValues(alpha: 0.8),
                    ],
                  ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.isRevealed
                  ? AppTheme.primaryTeal
                  : AppTheme.onSurfaceVariant.withValues(alpha: 0.3),
              width: widget.isRevealed ? 2 : 1,
            ),
            boxShadow: widget.isRevealed
                ? [
                    BoxShadow(
                      color: AppTheme.primaryTeal.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Text(
            widget.isRevealed ? widget.word : '___',
            style: TextStyle(
              color: widget.isRevealed ? Colors.white : AppTheme.onSurfaceVariant,
              fontSize: 16,
              fontWeight: widget.isRevealed ? FontWeight.bold : FontWeight.normal,
              fontStyle: widget.isRevealed ? FontStyle.normal : FontStyle.italic,
            ),
          ),
        ),
      ),
    );
  }
}
