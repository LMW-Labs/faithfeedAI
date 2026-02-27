import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for SystemUiOverlayStyle
import '../../models/bible_verse_model.dart';
import '../../services/bookmark_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/verse_actions_modal.dart';

/// Study Verses Screen - Shows only the user's study verses collection
/// The Study Plans functionality has been moved to the Library
class StudyVersesScreen extends StatelessWidget {
  const StudyVersesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookmarkService = BookmarkService();

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text(
          'Study Verses',
          style: TextStyle(color: AppTheme.onSurface), // Ensure title is readable
        ),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.onSurface), // Ensure back button is readable
        systemOverlayStyle: SystemUiOverlayStyle.light, // Ensure status bar icons are light
      ),
      body: StreamBuilder<List<BibleVerseModel>>(
        stream: bookmarkService.getStudyVerses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryTeal),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Error loading study verses',
                    style: TextStyle(color: AppTheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 80,
                    color: AppTheme.onSurfaceVariant.withAlpha(127),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No study verses yet',
                    style: TextStyle(
                      color: AppTheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap the Study icon when reading verses\nto add them to your study collection',
                    style: TextStyle(color: AppTheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final verses = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: verses.length,
            itemBuilder: (context, index) {
              final verse = verses[index];
              return _VerseCard(
                verse: verse,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => VerseActionsModal(verse: verse),
                  );
                },
                onDelete: () async {
                  final success = await bookmarkService.removeFromStudy(verse);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Removed from study collection'
                              : 'Failed to remove verse',
                        ),
                        backgroundColor: success ? AppTheme.primaryTeal : Colors.red,
                      ),
                    );
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

class _VerseCard extends StatelessWidget {
  final BibleVerseModel verse;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _VerseCard({
    required this.verse,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(verse.reference),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text(
              'Remove',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.surface,
            title: const Text(
              'Remove from Study',
              style: TextStyle(color: AppTheme.onSurface),
            ),
            content: Text(
              'Remove ${verse.reference} from your study collection?',
              style: const TextStyle(color: AppTheme.onSurfaceVariant),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppTheme.onSurface), // Readable button text
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Remove'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        onDelete();
      },
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
                // Reference and badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal.withAlpha(51),
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.holyGold.withAlpha(51),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.school,
                                size: 14,
                                color: AppTheme.holyGold,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Study',
                                style: TextStyle(
                                  color: AppTheme.holyGold,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            onDelete();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red.withAlpha(25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}