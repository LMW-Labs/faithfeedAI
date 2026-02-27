import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart' as share_plus;
import '../../models/ai_content_model.dart';
import '../../models/bible_verse_model.dart';
import '../../services/ai_library_service.dart';
import '../../services/bookmark_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/verse_actions_modal.dart';
import 'study_verses_screen.dart';

class AILibraryScreen extends StatefulWidget {
  const AILibraryScreen({super.key});

  @override
  State<AILibraryScreen> createState() => _AILibraryScreenState();
}

class _AILibraryScreenState extends State<AILibraryScreen> {
  final AILibraryService _aiLibraryService = AILibraryService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground, // Set base background
      appBar: AppBar(
        backgroundColor: AppTheme.surface, // Frosted theme AppBar background
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light, // Ensure light status bar icons
        title: const Text(
          'Your Study Library',
          style: TextStyle(color: AppTheme.onSurface), // Readable title text color
        ),
        iconTheme: const IconThemeData(color: AppTheme.onSurface), // Readable icon color
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome header
            Text(
              'Browse your saved content',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.onSurfaceVariant, // Ensure readable
              ),
            ),
            const SizedBox(height: 20),

            // Category gallery grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [ // Added children list
                _buildCategoryCard(
                  context: context,
                  icon: Icons.menu_book,
                  title: 'Devotionals',
                  color: Colors.blue,
                  onTap: () => _navigateToCategory('devotionals'),
                ),
                _buildCategoryCard(
                  context: context,
                  icon: Icons.school,
                  title: 'Study Plans',
                  color: Colors.green,
                  onTap: () => _navigateToCategory('studyPlans'),
                ),
                _buildCategoryCard(
                  context: context,
                  icon: Icons.auto_stories,
                  title: 'Summaries',
                  color: Colors.orange,
                  onTap: () => _navigateToCategory('summaries'),
                ),
                _buildCategoryCard(
                  context: context,
                  icon: Icons.edit_note,
                  title: 'Notes',
                  color: Colors.purple,
                  onTap: () => _navigateToCategory('notes'),
                ),
                _buildCategoryCard(
                  context: context,
                  icon: Icons.bookmark,
                  title: 'Saved Verses',
                  color: Colors.pink,
                  onTap: () => _navigateToCategory('savedVerses'),
                ),
                _buildCategoryCard(
                  context: context,
                  icon: Icons.format_quote,
                  title: 'Study Verses',
                  color: Colors.teal,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StudyVersesScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      color: AppTheme.surface, // Use AppTheme.surface for card background
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.onSurface, // Readable text color
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToCategory(String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _CategoryDetailScreen(
          category: category,
          aiLibraryService: _aiLibraryService,
        ),
      ),
    );
  }

  Widget _buildAllContentTab() {
    return StreamBuilder<List<AIContentItem>>(
      stream: _aiLibraryService.streamAllContent(),
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
                Text(
                  'Error loading content',
                  style: TextStyle(color: AppTheme.onSurface),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final allContent = snapshot.data ?? [];

        if (allContent.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_stories_outlined,
                  size: 64,
                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No saved content yet',
                  style: TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Generate devotionals and sermons to see them here',
                  style: TextStyle(
                    color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: allContent.length,
          itemBuilder: (context, index) {
            final item = allContent[index];
            return _buildContentCard(item);
          },
        );
      },
    );
  }

  Widget _buildDevotionalsTab() {
    return FutureBuilder<List<AIContentItem>>(
      future: _aiLibraryService.getContentByType(AIContentType.devotional),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryTeal),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final devotionals = snapshot.data ?? [];

        if (devotionals.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.menu_book_outlined,
                  size: 64,
                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No saved devotionals',
                  style: TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: devotionals.length,
          itemBuilder: (context, index) {
            final item = devotionals[index];
            return _buildContentCard(item);
          },
        );
      },
    );
  }

  Widget _buildStudyPlansTab() {
    return FutureBuilder<List<AIContentItem>>(
      future: _aiLibraryService.getContentByType(AIContentType.studyPlan),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryTeal),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final studyPlans = snapshot.data ?? [];

        if (studyPlans.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 64,
                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No saved study plans',
                  style: TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create custom study plans to see them here',
                  style: TextStyle(
                    color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: studyPlans.length,
          itemBuilder: (context, index) {
            final item = studyPlans[index];
            return _buildContentCard(item);
          },
        );
      },
    );
  }

  Widget _buildContentCard(AIContentItem item) {
    IconData icon;
    Color iconColor;

    switch (item.type) {
      case AIContentType.devotional:
        icon = Icons.menu_book;
        iconColor = Colors.blue;
        break;
      case AIContentType.sermonOutline:
        icon = Icons.mic;
        iconColor = Colors.purple;
        break;
      case AIContentType.studyPlan:
        icon = Icons.school;
        iconColor = Colors.green;
        break;
      case AIContentType.chapterSummary:
        icon = Icons.auto_stories;
        iconColor = Colors.orange;
        break;
    }

    return Card(
      color: AppTheme.surface,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _viewContent(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            color: AppTheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(item.createdAt),
                          style: TextStyle(
                            color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: AppTheme.onSurfaceVariant),
                    onPressed: () => _showOptionsMenu(item),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item.content,
                style: const TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 14,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewContent(AIContentItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ContentViewModal(item: item),
    );
  }

  void _showOptionsMenu(AIContentItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share, color: AppTheme.primaryTeal),
              title: const Text('Share', style: TextStyle(color: AppTheme.onSurface)),
              onTap: () {
                Navigator.pop(context);
                share_plus.SharePlus.instance.share(share_plus.ShareParams(text: '${item.title}\n\n${item.content}'));
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: AppTheme.primaryTeal),
              title: const Text('Copy', style: TextStyle(color: AppTheme.onSurface)),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: '${item.title}\n\n${item.content}'));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(item);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(AIContentItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Delete Content?', style: TextStyle(color: AppTheme.onSurface)),
        content: Text(
          'Are you sure you want to delete "${item.title}"? This action cannot be undone.',
          style: const TextStyle(color: AppTheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              navigator.pop();
              try {
                await _aiLibraryService.deleteContent(item.id!);
                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Content deleted')),
                  );
                  setState(() {}); // Refresh the list
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      final period = date.hour >= 12 ? 'PM' : 'AM';
      return 'Today • $hour:${date.minute.toString().padLeft(2, '0')} $period';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }
}

// Category detail screen showing filtered content
class _CategoryDetailScreen extends StatefulWidget {
  final String category;
  final AILibraryService aiLibraryService;

  const _CategoryDetailScreen({
    required this.category,
    required this.aiLibraryService,
  });

  @override
  State<_CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<_CategoryDetailScreen> {
  String get category => widget.category;
  AILibraryService get aiLibraryService => widget.aiLibraryService;

  bool _isSelectionMode = false;
  final Set<String> _selectedItemIds = {};
  List<AIContentItem> _currentContent = []; // New state variable to hold content

  String get _categoryTitle {
    switch (category) {
      case 'all':
        return 'All Content';
      case 'devotionals':
        return 'Devotionals';
      case 'studyPlans':
        return 'Study Plans';
      case 'summaries':
        return 'Summaries';
      case 'notes':
        return 'Notes';
      case 'savedVerses':
        return 'Saved Verses';
      default:
        return 'Library';
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedItemIds.clear(); // Clear selection when exiting selection mode
      }
    });
  }

  void _toggleItemSelection(String itemId, bool? isChecked) {
    setState(() {
      if (isChecked == true) {
        _selectedItemIds.add(itemId);
      } else {
        _selectedItemIds.remove(itemId);
      }
    });
  }

  void _toggleSelectAll(bool? isChecked) {
    setState(() {
      _selectedItemIds.clear();
      if (isChecked == true) {
        for (var item in _currentContent) {
          if (item.id != null) {
            _selectedItemIds.add(item.id!);
          }
        }
      }
    });
  }

  void _deleteSelectedContent(List<AIContentItem> allContent) async {
    if (_selectedItemIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No items selected for deletion')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Delete Selected Content?', style: TextStyle(color: AppTheme.onSurface)),
        content: Text(
          'Are you sure you want to delete ${_selectedItemIds.length} selected items? This action cannot be undone.',
          style: const TextStyle(color: AppTheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final messenger = ScaffoldMessenger.of(context);
      try {
        // Collect IDs before async gap
        final itemsToDelete = _selectedItemIds.toList();
        _selectedItemIds.clear(); // Clear immediately for UI responsiveness
        setState(() {
          _isSelectionMode = false; // Exit selection mode
        });

        for (final id in itemsToDelete) {
          await aiLibraryService.deleteContent(id);
        }

        if (mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text('${itemsToDelete.length} items deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text('Error deleting content: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground, // Frosted theme background
      appBar: AppBar(
        backgroundColor: AppTheme.surface, // Frosted theme AppBar background
        title: Text(
          _categoryTitle,
          style: const TextStyle(color: AppTheme.onSurface), // Readable title text color
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.onSurface), // Readable icon color
        actions: [
          if (widget.category != 'savedVerses') // Saved Verses has its own delete mechanism
            if (_isSelectionMode)
              Row(
                children: [
                  TextButton(
                    onPressed: _toggleSelectionMode,
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: AppTheme.primaryTeal),
                    ),
                  ),
                  Checkbox(
                    value: _selectedItemIds.length == _currentContent.length && _currentContent.isNotEmpty,
                    onChanged: _toggleSelectAll,
                    activeColor: AppTheme.primaryTeal,
                  ),
                  const Text('Select All', style: TextStyle(color: AppTheme.primaryTeal)),
                  if (_selectedItemIds.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteSelectedContent(_currentContent),
                    ),
                ],
              )
            else
              TextButton(
                onPressed: _toggleSelectionMode,
                child: const Text(
                  'Select',
                  style: TextStyle(color: AppTheme.primaryTeal),
                ),
              ),
        ],
      ),
      body: _buildCategoryContent(),
    );
  }

  Widget _buildCategoryContent() {
    if (category == 'all') {
      return StreamBuilder<List<AIContentItem>>(
        stream: aiLibraryService.streamAllContent(),
        builder: (context, snapshot) => _buildContentList(context, snapshot),
      );
    } else if (category == 'devotionals') {
      return FutureBuilder<List<AIContentItem>>(
        future: aiLibraryService.getContentByType(AIContentType.devotional),
        builder: (context, snapshot) => _buildContentList(context, snapshot),
      );
    } else if (category == 'studyPlans') {
      return FutureBuilder<List<AIContentItem>>(
        future: aiLibraryService.getContentByType(AIContentType.studyPlan),
        builder: (context, snapshot) => _buildContentList(context, snapshot),
      );
    } else if (category == 'summaries') {
      return FutureBuilder<List<AIContentItem>>(
        future: aiLibraryService.getContentByType(AIContentType.chapterSummary),
        builder: (context, snapshot) => _buildContentList(context, snapshot),
      );
    } else if (category == 'notes') {
      return const Center(
        child: Text(
          'Notes coming soon!',
          style: TextStyle(color: AppTheme.onSurfaceVariant),
        ),
      );
    } else if (category == 'savedVerses') {
      return _SavedVersesContent();
    }
    return const SizedBox.shrink();
  }

  Widget _buildContentList(
    BuildContext context,
    AsyncSnapshot<List<AIContentItem>> snapshot,
  ) {
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
            Text(
              'Error loading content',
              style: const TextStyle(color: AppTheme.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              snapshot.error.toString(),
              style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final content = snapshot.data ?? [];

    // Update _currentContent here
    _currentContent = content;

    if (content.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_stories_outlined,
              size: 64,
              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No ${_categoryTitle.toLowerCase()} yet',
              style: const TextStyle(
                color: AppTheme.onSurfaceVariant,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: content.length,
      itemBuilder: (context, index) {
        final item = content[index];
        return _buildContentCard(
          item,
          _isSelectionMode,
          _selectedItemIds.contains(item.id!),
          _toggleItemSelection,
        );
      },
    );
  }

  Widget _buildContentCard(
    AIContentItem item,
    bool isSelectionMode,
    bool isSelected,
    Function(String itemId, bool? isChecked) onToggleSelection,
  ) {
    IconData icon;
    Color iconColor;

    switch (item.type) {
      case AIContentType.devotional:
        icon = Icons.menu_book;
        iconColor = Colors.blue;
        break;
      case AIContentType.sermonOutline:
        icon = Icons.mic;
        iconColor = Colors.purple;
        break;
      case AIContentType.studyPlan:
        icon = Icons.school;
        iconColor = Colors.green;
        break;
      case AIContentType.chapterSummary:
        icon = Icons.auto_stories;
        iconColor = Colors.orange;
        break;
    }

    return Card(
      color: isSelected ? AppTheme.primaryTeal.withValues(alpha: 0.2) : AppTheme.surface, // Highlight selected card
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          if (isSelectionMode && item.id != null) {
            onToggleSelection(item.id!, !isSelected);
          } else {
            _viewContent(item);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isSelectionMode && item.id != null)
                    Checkbox(
                      value: isSelected,
                      onChanged: (bool? value) {
                        onToggleSelection(item.id!, value);
                      },
                      activeColor: AppTheme.primaryTeal,
                    ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            color: AppTheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(item.createdAt),
                          style: TextStyle(
                            color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isSelectionMode) // Only show options menu when not in selection mode
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: AppTheme.onSurfaceVariant),
                      onPressed: () => _showOptionsMenu(item),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item.content,
                style: const TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 14,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewContent(AIContentItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ContentViewModal(item: item),
    );
  }

  void _showOptionsMenu(AIContentItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share, color: AppTheme.primaryTeal),
              title: const Text('Share', style: TextStyle(color: AppTheme.onSurface)),
              onTap: () {
                Navigator.pop(context);
                share_plus.SharePlus.instance.share(share_plus.ShareParams(text: '${item.title}\n\n${item.content}'));
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: AppTheme.primaryTeal),
              title: const Text('Copy', style: TextStyle(color: AppTheme.onSurface)),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: '${item.title}\n\n${item.content}'));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(item);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(AIContentItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Delete Content?', style: TextStyle(color: AppTheme.onSurface)),
        content: Text(
          'Are you sure you want to delete "${item.title}"? This action cannot be undone.',
          style: const TextStyle(color: AppTheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              navigator.pop();
              try {
                await aiLibraryService.deleteContent(item.id!);
                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Content deleted')),
                  );
                  setState(() {}); // Refresh the list
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      final period = date.hour >= 12 ? 'PM' : 'AM';
      return 'Today • $hour:${date.minute.toString().padLeft(2, '0')} $period';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }
}

class _ContentViewModal extends StatelessWidget {
  final AIContentItem item;

  const _ContentViewModal({required this.item});

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      final period = date.hour >= 12 ? 'PM' : 'AM';
      return 'Today • $hour:${date.minute.toString().padLeft(2, '0')} $period';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppTheme.surface, // Frosted theme modal background
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: AppTheme.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.typeLabel} • ${_formatDate(item.createdAt)}',
                        style: TextStyle(
                          color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.onSurfaceVariant),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: AppTheme.onSurfaceVariant, height: 1),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Text(
                item.content,
                style: const TextStyle(
                  color: AppTheme.onSurface,
                  fontSize: 16,
                  height: 1.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Saved Verses content widget
class _SavedVersesContent extends StatelessWidget {
  final BookmarkService _bookmarkService = BookmarkService();

  _SavedVersesContent();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BibleVerseModel>>(
      stream: _bookmarkService.getStudyVerses(),
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
                  'Error loading saved verses',
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
                  Icons.bookmark_outline,
                  size: 80,
                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No saved verses yet',
                  style: TextStyle(
                    color: AppTheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap the Study icon when reading verses\nto save them here',
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
            return _SavedVerseCard(
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
                final success = await _bookmarkService.removeFromStudy(verse);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Removed from saved verses'
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
    );
  }
}

class _SavedVerseCard extends StatelessWidget {
  final BibleVerseModel verse;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SavedVerseCard({
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
        onDelete();
        return false; // Let the callback handle the actual removal
      },
      child: Card(
        color: AppTheme.surface,
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.pink.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.bookmark, color: Colors.pink, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        verse.reference,
                        style: const TextStyle(
                          color: AppTheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  verse.text,
                  style: const TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 14,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}