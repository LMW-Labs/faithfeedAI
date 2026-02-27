import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

/// A floating button that inserts hashtags and shows autocomplete
class HashtagButton extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onHashtagInserted;

  const HashtagButton({
    super.key,
    required this.controller,
    required this.onHashtagInserted,
  });

  // Popular faith-based hashtags for autocomplete
  static const List<String> _popularHashtags = [
    // Core Faith
    'prayer',
    'blessed',
    'faith',
    'testimony',
    'praise',
    'grateful',
    'godisgood',
    'amen',
    'worship',
    'bibleverse',
    'scripture',
    'devotional',
    'christian',
    'jesus',
    'grace',
    'hope',
    'love',
    'mercy',
    'trust',
    'salvation',
    'bible',
    'church',
    'community',
    'fellowship',
    'praisereport',
    'prayerrequest',
    'godisfaithful',
    'thankful',
    'godsplan',
    'faithjourney',
    // Spiritual Growth
    'discipleship',
    'transformation',
    'renewal',
    'spiritualgrowth',
    'dailybread',
    'quiettime',
    'meditation',
    'reflect',
    'godspromise',
    'biblestudy',
    // Worship & Praise
    'glorytogod',
    'hallelujah',
    'praisejesus',
    'worshipmusic',
    'gospelmusic',
    'sundayservice',
    'churchfamily',
    'praisehim',
    // Life Events
    'newbeliever',
    'baptism',
    'bornagain',
    'breakthrough',
    'victory',
    'healing',
    'deliverance',
    'restoration',
    'forgiven',
    'redeemed',
    // Encouragement
    'staystrong',
    'keepthefaith',
    'gotwins',
    'nevergiveup',
    'trustgod',
    'godisable',
    'godsprovision',
    'divineprotection',
    'encouragement',
    'inspire',
    // Community
    'prayergroup',
    'smallgroup',
    'youthgroup',
    'womenoffaith',
    'menoffaith',
    'familyfaith',
    'marriagegoals',
    'christianparenting',
    // Scripture Focus
    'verseoftheday',
    'psalm',
    'proverbs',
    'gospel',
    'newtestatment',
    'oldtestament',
    'revelation',
    'genesis',
    'john316',
    'romans828',
    'philippians413',
    'jeremiah2911',
    'isaiah4031',
    // Seasonal
    'easter',
    'christmas',
    'advent',
    'lent',
    'goodfriday',
    'resurrection',
    // General
    'ministry',
    'mission',
    'serve',
    'volunteer',
    'outreach',
    'evangelize',
    'witness',
    'testimony',
    'sharing',
  ];

  void _insertHashtag() {
    final text = controller.text;
    final selection = controller.selection;

    // Handle case where there's no valid selection (cursor not in text field)
    final int insertPosition;
    if (selection.start < 0 || selection.end < 0) {
      // No valid selection, append to end of text
      insertPosition = text.length;
    } else {
      insertPosition = selection.start;
    }

    // Insert # at cursor position or end of text
    final newText = '${text.substring(0, insertPosition)}#${text.substring(selection.end >= 0 ? selection.end : text.length)}';

    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: insertPosition + 1),
    );

    onHashtagInserted();
  }

  /// Get hashtag suggestions based on current text
  static List<String> getSuggestions(String text, int cursorPosition) {
    // Find if we're currently typing a hashtag
    final beforeCursor = text.substring(0, cursorPosition);
    final hashIndex = beforeCursor.lastIndexOf('#');

    if (hashIndex == -1) return [];

    // Get the text after the last #
    final hashtagText = beforeCursor.substring(hashIndex + 1).toLowerCase();

    // Check if there's a space after # (means we're done with that hashtag)
    if (hashtagText.contains(' ')) return [];

    // Filter suggestions
    return _popularHashtags
        .where((tag) => tag.toLowerCase().startsWith(hashtagText))
        .take(5)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _insertHashtag,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: const Center(
          child: Text(
            '#',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryTeal,
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget to display hashtag autocomplete suggestions
class HashtagSuggestions extends StatelessWidget {
  final List<String> suggestions;
  final Function(String) onSuggestionTap;

  const HashtagSuggestions({
    super.key,
    required this.suggestions,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.onSurfaceVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: suggestions.map((tag) {
          return InkWell(
            onTap: () => onSuggestionTap(tag),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              width: double.infinity,
              child: Row(
                children: [
                  const Icon(
                    Icons.tag,
                    size: 16,
                    color: AppTheme.primaryTeal,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '#$tag',
                    style: const TextStyle(
                      color: AppTheme.onSurface,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
