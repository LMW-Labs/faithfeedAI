import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/bible_verse_model.dart';
import '../../../models/verse_annotation_model.dart';
import '../../../services/verse_annotation_service.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/lfs_utils.dart';

class VerseCommunityTab extends StatefulWidget {
  final BibleVerseModel verse;

  const VerseCommunityTab({
    super.key,
    required this.verse,
  });

  @override
  State<VerseCommunityTab> createState() => _VerseCommunityTabState();
}

class _VerseCommunityTabState extends State<VerseCommunityTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryTeal,
          unselectedLabelColor: AppTheme.onSurfaceVariant,
          indicatorColor: AppTheme.primaryTeal,
          tabs: const [
            Tab(text: 'Comments'),
            Tab(text: 'Q&A'),
            Tab(text: 'Mine'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _CommentsView(verse: widget.verse),
              _QAView(verse: widget.verse),
              _MyContributionsView(verse: widget.verse),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// COMMENTS TAB
// ============================================================================

class _CommentsView extends StatelessWidget {
  final BibleVerseModel verse;

  const _CommentsView({required this.verse});

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<VerseAnnotationService>(context, listen: false);

    return Column(
      children: [
        // Add Comment Button
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _showAddCommentDialog(context, verse, service),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryTeal,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.add_comment),
            label: const Text('Add Comment (+5 LFS)'),
          ),
        ),

        // Comments List
        Expanded(
          child: StreamBuilder<List<VerseAnnotation>>(
            stream: service.streamAnnotations(
              verse.reference,
              filterType: AnnotationType.insight,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final comments = snapshot.data ?? [];

              if (comments.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No comments yet.\nBe the first to share your insight!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.onSurfaceVariant),
                    ),
                  ),
                );
              }

              return ListView.builder(
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  return _AnnotationCard(
                    annotation: comments[index],
                    verse: verse,
                    onReply: () => _showReplyDialog(
                      context,
                      verse,
                      comments[index],
                      service,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showAddCommentDialog(
    BuildContext context,
    BibleVerseModel verse,
    VerseAnnotationService service,
  ) async {
    final controller = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        scrollable: true,
        title: const Text('Add Comment', style: TextStyle(color: AppTheme.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              verse.reference,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryTeal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              verse.text,
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              style: const TextStyle(color: AppTheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Share your insight...',
                hintStyle: const TextStyle(color: AppTheme.onSurfaceVariant),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: AppTheme.darkBackground,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '✨ Contributions increase Living Faith Score',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.mintGreen,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => LFSUtils.launchLFSPage(context),
                  child: const Text(
                    'Learn More',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryTeal,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryTeal,
            ),
            child: const Text('Post Comment'),
          ),
        ],
      ),
    );

    if (result == true && controller.text.trim().isNotEmpty) {
      try {
        await service.submitInsight(
          reference: verse.reference,
          verseText: verse.text,
          content: controller.text.trim(),
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Comment posted! +5 LFS points earned'),
              backgroundColor: AppTheme.mintGreen,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }

    controller.dispose();
  }

  Future<void> _showReplyDialog(
    BuildContext context,
    BibleVerseModel verse,
    VerseAnnotation annotation,
    VerseAnnotationService service,
  ) async {
    final controller = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Reply to Comment', style: TextStyle(color: AppTheme.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.darkBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                annotation.content,
                style: const TextStyle(color: AppTheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              style: const TextStyle(color: AppTheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Your reply...',
                hintStyle: const TextStyle(color: AppTheme.onSurfaceVariant),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: AppTheme.darkBackground,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '✨ You\'ll earn +3 Living Faith Score points',
              style: TextStyle(fontSize: 12, color: AppTheme.mintGreen),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryTeal,
            ),
            child: const Text('Post Reply'),
          ),
        ],
      ),
    );

    if (result == true && controller.text.trim().isNotEmpty) {
      try {
        await service.submitReply(
          reference: verse.reference,
          verseText: verse.text,
          parentId: annotation.id,
          content: controller.text.trim(),
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reply posted! +3 LFS points earned'),
              backgroundColor: AppTheme.mintGreen,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }

    controller.dispose();
  }
}

// ============================================================================
// Q&A TAB
// ============================================================================

class _QAView extends StatefulWidget {
  final BibleVerseModel verse;

  const _QAView({required this.verse});

  @override
  State<_QAView> createState() => _QAViewState();
}

class _QAViewState extends State<_QAView> {
  String _filter = 'all'; // all, answered, unanswered

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<VerseAnnotationService>(context, listen: false);

    return Column(
      children: [
        // Top bar: Ask Question button + Filter
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showAskQuestionDialog(context, widget.verse, service),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryTeal,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.help_outline),
                  label: const Text('Ask Question (+5 LFS)'),
                ),
              ),
              const SizedBox(width: 12),
              PopupMenuButton<String>(
                initialValue: _filter,
                icon: const Icon(Icons.filter_list),
                onSelected: (value) {
                  setState(() => _filter = value);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'all', child: Text('All')),
                  const PopupMenuItem(value: 'answered', child: Text('Answered')),
                  const PopupMenuItem(value: 'unanswered', child: Text('Unanswered')),
                ],
              ),
            ],
          ),
        ),

        // Questions List
        Expanded(
          child: StreamBuilder<List<VerseAnnotation>>(
            stream: service.streamAnnotations(
              widget.verse.reference,
              filterType: AnnotationType.question,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              var questions = snapshot.data ?? [];

              // Apply filter
              if (_filter == 'unanswered') {
                // This is a simplified check - in production you'd check actual answer counts
                questions = questions.where((q) {
                  // For now, we'll fetch answer count synchronously
                  // In production, you might want to cache this or use a different approach
                  return true; // Placeholder - implement proper filtering
                }).toList();
              }

              if (questions.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No questions yet.\nBe the first to ask!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.onSurfaceVariant),
                    ),
                  ),
                );
              }

              return ListView.builder(
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  return _QuestionCard(
                    question: questions[index],
                    verse: widget.verse,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showAskQuestionDialog(
    BuildContext context,
    BibleVerseModel verse,
    VerseAnnotationService service,
  ) async {
    final controller = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Ask a Question', style: TextStyle(color: AppTheme.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              verse.reference,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryTeal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              verse.text,
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              style: const TextStyle(color: AppTheme.onSurface),
              decoration: InputDecoration(
                hintText: 'What would you like to know about this verse?',
                hintStyle: const TextStyle(color: AppTheme.onSurfaceVariant),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: AppTheme.darkBackground,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '✨ You\'ll earn +5 Living Faith Score points',
              style: TextStyle(fontSize: 12, color: AppTheme.mintGreen),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryTeal,
            ),
            child: const Text('Post Question'),
          ),
        ],
      ),
    );

    if (result == true && controller.text.trim().isNotEmpty) {
      try {
        await service.submitQuestion(
          reference: verse.reference,
          verseText: verse.text,
          content: controller.text.trim(),
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Question posted! +5 LFS points earned'),
              backgroundColor: AppTheme.mintGreen,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }

    controller.dispose();
  }
}

// ============================================================================
// MY CONTRIBUTIONS TAB
// ============================================================================

class _MyContributionsView extends StatelessWidget {
  final BibleVerseModel verse;

  const _MyContributionsView({required this.verse});

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<VerseAnnotationService>(context, listen: false);

    return FutureBuilder<List<VerseAnnotation>>(
      future: service.getUserAnnotations(verse.reference),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final myContributions = snapshot.data ?? [];

        if (myContributions.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.edit_note,
                    size: 64,
                    color: AppTheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No contributions yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Share a comment or ask a question\nto see your contributions here',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          );
        }

        // Calculate stats
        final comments = myContributions.where((a) => a.type == AnnotationType.insight).length;
        final questions = myContributions.where((a) => a.type == AnnotationType.question).length;
        final answers = myContributions.where((a) => a.type == AnnotationType.answer).length;
        final replies = myContributions.where((a) => a.type == AnnotationType.reply).length;
        final totalUpvotes = myContributions.fold<int>(0, (sum, a) => sum + a.upvotes);

        return Column(
          children: [
            // Stats Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryTeal.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Contributions to This Verse',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryTeal,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _StatChip(label: 'Comments', count: comments),
                      _StatChip(label: 'Questions', count: questions),
                      _StatChip(label: 'Answers', count: answers),
                      _StatChip(label: 'Replies', count: replies),
                      _StatChip(label: '👍 Upvotes', count: totalUpvotes, color: AppTheme.mintGreen),
                    ],
                  ),
                ],
              ),
            ),

            // Contributions List
            Expanded(
              child: ListView.builder(
                itemCount: myContributions.length,
                itemBuilder: (context, index) {
                  final contribution = myContributions[index];
                  return _MyContributionCard(
                    annotation: contribution,
                    verse: verse,
                    onDelete: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Contribution?'),
                          content: const Text(
                            'This will permanently remove your contribution. This cannot be undone.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true && context.mounted) {
                        try {
                          await service.deleteAnnotation(
                            contribution.verseId,
                            contribution.id,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Contribution deleted'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      }
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// SHARED WIDGETS
// ============================================================================

class _AnnotationCard extends StatefulWidget {
  final VerseAnnotation annotation;
  final BibleVerseModel verse;
  final VoidCallback onReply;

  const _AnnotationCard({
    required this.annotation,
    required this.verse,
    required this.onReply,
  });

  @override
  State<_AnnotationCard> createState() => _AnnotationCardState();
}

class _AnnotationCardState extends State<_AnnotationCard> {
  bool _showReplies = false;

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<VerseAnnotationService>(context, listen: false);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: widget.annotation.userPhotoUrl != null
                          ? NetworkImage(widget.annotation.userPhotoUrl!)
                          : null,
                      child: widget.annotation.userPhotoUrl == null
                          ? Text(widget.annotation.userName[0].toUpperCase())
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                widget.annotation.userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                              if (widget.annotation.isVerifiedScholar) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.verified,
                                  size: 16,
                                  color: AppTheme.primaryTeal,
                                ),
                              ],
                            ],
                          ),
                          Text(
                            _formatTimestamp(widget.annotation.createdAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Content
                Text(
                  widget.annotation.content,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),

                // Actions
                Row(
                  children: [
                    StreamBuilder<String?>(
                      stream: service.streamUserVote(widget.annotation.id),
                      builder: (context, voteSnapshot) {
                        final userVote = voteSnapshot.data;
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                userVote == 'up' ? Icons.thumb_up : Icons.thumb_up_outlined,
                                color: userVote == 'up' ? AppTheme.primaryTeal : null,
                                size: 20,
                              ),
                              onPressed: () => service.upvote(widget.annotation.verseId, widget.annotation.id),
                            ),
                            Text(
                              '${widget.annotation.upvotes}',
                              style: const TextStyle(color: AppTheme.onSurface),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(
                                userVote == 'down' ? Icons.thumb_down : Icons.thumb_down_outlined,
                                color: userVote == 'down' ? Colors.red : null,
                                size: 20,
                              ),
                              onPressed: () => service.downvote(widget.annotation.verseId, widget.annotation.id),
                            ),
                          ],
                        );
                      },
                    ),
                    const Spacer(),
                    StreamBuilder<List<VerseAnnotation>>(
                      stream: service.streamReplies(
                        widget.annotation.verseId,
                        widget.annotation.id,
                      ),
                      builder: (context, snapshot) {
                        final count = snapshot.data?.length ?? 0;
                        if (count == 0) return const SizedBox.shrink();
                        return TextButton.icon(
                          onPressed: () => setState(() => _showReplies = !_showReplies),
                          icon: Icon(_showReplies ? Icons.expand_less : Icons.expand_more, size: 18),
                          label: Text('$count ${count == 1 ? 'Reply' : 'Replies'}'),
                        );
                      },
                    ),
                    TextButton.icon(
                      onPressed: widget.onReply,
                      icon: const Icon(Icons.reply, size: 18),
                      label: const Text('Reply'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Replies (expanded)
          if (_showReplies)
            StreamBuilder<List<VerseAnnotation>>(
              stream: service.streamReplies(
                widget.annotation.verseId,
                widget.annotation.id,
              ),
              builder: (context, snapshot) {
                final replies = snapshot.data ?? [];
                if (replies.isEmpty) return const SizedBox.shrink();

                return Column(
                  children: replies.map((reply) => Container(
                    margin: const EdgeInsets.only(left: 32, right: 16, bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.darkBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              reply.userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppTheme.onSurface,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _formatTimestamp(reply.createdAt),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reply.content,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays > 7) {
      return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class _QuestionCard extends StatefulWidget {
  final VerseAnnotation question;
  final BibleVerseModel verse;

  const _QuestionCard({
    required this.question,
    required this.verse,
  });

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  bool _showAnswers = false;

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<VerseAnnotationService>(context, listen: false);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: widget.question.userPhotoUrl != null
                          ? NetworkImage(widget.question.userPhotoUrl!)
                          : null,
                      child: widget.question.userPhotoUrl == null
                          ? Text(widget.question.userName[0].toUpperCase())
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.question.userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.onSurface,
                            ),
                          ),
                          Text(
                            _formatTimestamp(widget.question.createdAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Question
                Text(
                  widget.question.content,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    StreamBuilder<List<VerseAnnotation>>(
                      stream: service.streamAnswers(
                        widget.question.verseId,
                        widget.question.id,
                      ),
                      builder: (context, snapshot) {
                        final count = snapshot.data?.length ?? 0;
                        return TextButton(
                          onPressed: () {
                            setState(() => _showAnswers = !_showAnswers);
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _showAnswers ? Icons.expand_less : Icons.expand_more,
                                size: 20,
                              ),
                              Text(
                                '$count ${count == 1 ? 'Answer' : 'Answers'}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    TextButton(
                      onPressed: () => _showAnswerDialog(context, service),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.question_answer, size: 20),
                          Text(
                            'Answer (+10 LFS)',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Answers (expanded)
          if (_showAnswers)
            StreamBuilder<List<VerseAnnotation>>(
              stream: service.streamAnswers(
                widget.question.verseId,
                widget.question.id,
              ),
              builder: (context, snapshot) {
                final answers = snapshot.data ?? [];
                
                if (answers.isEmpty) {
                  return Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.darkBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'No answers yet. Be the first to answer!',
                        style: TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: answers
                      .map((answer) => Container(
                            margin: const EdgeInsets.only(
                              left: 32,
                              right: 16,
                              bottom: 8,
                            ),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.darkBackground,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      answer.userName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: AppTheme.onSurface,
                                      ),
                                    ),
                                    if (answer.isVerifiedScholar)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 4),
                                        child: Icon(
                                          Icons.verified,
                                          size: 14,
                                          color: AppTheme.primaryTeal,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  answer.content,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                StreamBuilder<String?>(
                                  stream: service.streamUserVote(answer.id),
                                  builder: (context, voteSnapshot) {
                                    final userVote = voteSnapshot.data;
                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          iconSize: 18,
                                          icon: Icon(
                                            userVote == 'up'
                                                ? Icons.thumb_up
                                                : Icons.thumb_up_outlined,
                                            color: userVote == 'up'
                                                ? AppTheme.primaryTeal
                                                : null,
                                          ),
                                          onPressed: () => service.upvote(
                                            answer.verseId,
                                            answer.id,
                                          ),
                                        ),
                                        Text(
                                          '${answer.upvotes}',
                                          style: const TextStyle(color: AppTheme.onSurface),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays > 7) {
      return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _showAnswerDialog(
    BuildContext context,
    VerseAnnotationService service,
  ) async {
    final controller = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Answer Question', style: TextStyle(color: AppTheme.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.darkBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.question.content,
                style: const TextStyle(color: AppTheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              style: const TextStyle(color: AppTheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Your answer...',
                hintStyle: const TextStyle(color: AppTheme.onSurfaceVariant),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: AppTheme.darkBackground,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '✨ You\'ll earn +10 Living Faith Score points',
              style: TextStyle(fontSize: 12, color: AppTheme.mintGreen),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryTeal,
            ),
            child: const Text('Post Answer'),
          ),
        ],
      ),
    );

    if (result == true && controller.text.trim().isNotEmpty) {
      try {
        await service.submitAnswer(
          reference: widget.verse.reference,
          verseText: widget.verse.text,
          questionId: widget.question.id,
          content: controller.text.trim(),
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Answer posted! +10 LFS points earned'),
              backgroundColor: AppTheme.mintGreen,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }

    controller.dispose();
  }
}

class _MyContributionCard extends StatefulWidget {
  final VerseAnnotation annotation;
  final BibleVerseModel verse;
  final VoidCallback onDelete;

  const _MyContributionCard({
    required this.annotation,
    required this.verse,
    required this.onDelete,
  });

  @override
  State<_MyContributionCard> createState() => _MyContributionCardState();
}

class _MyContributionCardState extends State<_MyContributionCard> {
  bool _showReplies = false;

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<VerseAnnotationService>(context, listen: false);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getTypeColor(widget.annotation.type).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getTypeLabel(widget.annotation.type),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _getTypeColor(widget.annotation.type),
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: widget.onDelete,
                      color: Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Content
                Text(
                  widget.annotation.content,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),

                // Stats & Actions
                Row(
                  children: [
                    Icon(
                      Icons.thumb_up,
                      size: 16,
                      color: AppTheme.primaryTeal,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.annotation.upvotes} upvotes',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      _formatTimestamp(widget.annotation.createdAt),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    StreamBuilder<List<VerseAnnotation>>(
                      stream: service.streamReplies(
                        widget.annotation.verseId,
                        widget.annotation.id,
                      ),
                      builder: (context, snapshot) {
                        final count = snapshot.data?.length ?? 0;
                        if (count == 0) return const SizedBox.shrink();
                        return TextButton.icon(
                          onPressed: () => setState(() => _showReplies = !_showReplies),
                          icon: Icon(_showReplies ? Icons.expand_less : Icons.expand_more, size: 18),
                          label: Text('$count ${count == 1 ? 'Reply' : 'Replies'}'),
                        );
                      },
                    ),
                    if (widget.annotation.type == AnnotationType.insight || 
                        widget.annotation.type == AnnotationType.answer)
                      TextButton.icon(
                        onPressed: () => _showReplyDialog(context, service),
                        icon: const Icon(Icons.reply, size: 18),
                        label: const Text('Reply'),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Replies (expanded)
          if (_showReplies)
            StreamBuilder<List<VerseAnnotation>>(
              stream: service.streamReplies(
                widget.annotation.verseId,
                widget.annotation.id,
              ),
              builder: (context, snapshot) {
                final replies = snapshot.data ?? [];
                if (replies.isEmpty) return const SizedBox.shrink();

                return Column(
                  children: replies.map((reply) => Container(
                    margin: const EdgeInsets.only(left: 32, right: 16, bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.darkBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              reply.userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppTheme.onSurface,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _formatTimestamp(reply.createdAt),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reply.content,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _showReplyDialog(
    BuildContext context,
    VerseAnnotationService service,
  ) async {
    final controller = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Post a Reply', style: TextStyle(color: AppTheme.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.darkBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.annotation.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              style: const TextStyle(color: AppTheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Your reply...',
                hintStyle: const TextStyle(color: AppTheme.onSurfaceVariant),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: AppTheme.darkBackground,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '✨ You\'ll earn +3 Living Faith Score points',
              style: TextStyle(fontSize: 12, color: AppTheme.mintGreen),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryTeal,
            ),
            child: const Text('Post Reply'),
          ),
        ],
      ),
    );

    if (result == true && controller.text.trim().isNotEmpty) {
      try {
        await service.submitReply(
          reference: widget.verse.reference,
          verseText: widget.verse.text,
          parentId: widget.annotation.id,
          content: controller.text.trim(),
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reply posted! +3 LFS points earned'),
              backgroundColor: AppTheme.mintGreen,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }

    controller.dispose();
  }

  Color _getTypeColor(AnnotationType type) {
    switch (type) {
      case AnnotationType.insight:
        return AppTheme.primaryTeal;
      case AnnotationType.question:
        return Colors.orange;
      case AnnotationType.answer:
        return AppTheme.mintGreen;
      case AnnotationType.reply:
        return Colors.blue;
      default:
        return AppTheme.onSurfaceVariant;
    }
  }

  String _getTypeLabel(AnnotationType type) {
    switch (type) {
      case AnnotationType.insight:
        return 'Comment';
      case AnnotationType.question:
        return 'Question';
      case AnnotationType.answer:
        return 'Answer';
      case AnnotationType.reply:
        return 'Reply';
      default:
        return type.name;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays > 7) {
      return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color? color;

  const _StatChip({
    required this.label,
    required this.count,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? AppTheme.primaryTeal).withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color ?? AppTheme.primaryTeal,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color ?? AppTheme.primaryTeal,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
