import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/bible_verse_model.dart';
import '../../services/bookmark_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/verse_actions_modal.dart';

// UX ENHANCEMENTS
import '../../utils/ui_helpers.dart';
import '../../widgets/skeleton_loading.dart';
import '../../widgets/empty_states.dart';
import '../../widgets/swipeable_card.dart';
import 'package:share_plus/share_plus.dart';

class SavedVersesScreen extends StatelessWidget {
  const SavedVersesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookmarkService = BookmarkService();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Saved Verses'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<BibleVerseModel>>(
        stream: bookmarkService.getBookmarkedVerses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: 6,
              itemBuilder: (context, index) => const SkeletonVerseCard(),
            );
          }

          if (snapshot.hasError) {
            return EmptyState(
              icon: Icons.error_outline,
              title: 'Error Loading Verses',
              message: 'Something went wrong. Please try again.',
              actionLabel: 'Try Again',
              onAction: () {
                // Trigger rebuild
                (context as Element).markNeedsBuild();
              },
              iconColor: AppTheme.primaryCoral.withValues(alpha: 0.5),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const EmptySavedVerses();
          }

          final verses = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: verses.length,
            itemBuilder: (context, index) {
              final verse = verses[index];
              return _SwipeableVerseCard(
                verse: verse,
                onTap: () {
                  HapticHelper.light();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    barrierColor: Colors.black.withOpacity(0.6),
                    builder: (context) => VerseActionsModal(verse: verse),
                  );
                },
                onShare: () async {
                  HapticHelper.light();
                  final shareText = '${verse.reference}\n\n"${verse.text}"\n\nShared from FaithFeed';
                  await Share.share(shareText);
                },
                onDelete: () async {
                  HapticHelper.medium();
                  final shouldDelete = await ConfirmationDialog.showDeleteConfirmation(
                    context,
                    title: 'Remove ${verse.reference}?',
                    message: 'Remove this verse from your saved collection?',
                    confirmText: 'Remove',
                  );

                  if (shouldDelete && context.mounted) {
                    final success = await bookmarkService.removeVerse(verse);
                    if (context.mounted) {
                      if (success) {
                        SnackbarHelper.showSuccess(context, 'Verse removed');
                      } else {
                        SnackbarHelper.showError(context, 'Failed to remove verse');
                      }
                    }
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _SwipeableVerseCard extends StatelessWidget {
  final BibleVerseModel verse;
  final VoidCallback onTap;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const _SwipeableVerseCard({
    required this.verse,
    required this.onTap,
    required this.onShare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SwipeableCard(
      leftAction: SwipeAction.delete(onTap: onDelete),
      rightAction: SwipeAction.share(onTap: onShare),
      child: Card(
        color: AppTheme.surface,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Reference and copy button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        verse.reference,
                        style: const TextStyle(
                          color: AppTheme.primaryTeal,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    // Copy button
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      color: AppTheme.onSurfaceVariant,
                      onPressed: () async {
                        HapticHelper.light();
                        await Clipboard.setData(ClipboardData(
                          text: '${verse.reference} - ${verse.text}',
                        ));
                        if (context.mounted) {
                          SnackbarHelper.showSuccess(context, 'Verse copied');
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Verse text
                Text(
                  verse.text,
                  style: const TextStyle(
                    color: AppTheme.onSurface,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 8),
                // Swipe hint
                Center(
                  child: Text(
                    'Swipe left to delete • Swipe right to share',
                    style: TextStyle(
                      color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
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
