import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/accomplishments_service.dart';
import '../../models/accomplishment_model.dart';

class AccomplishmentsScreen extends StatefulWidget {
  const AccomplishmentsScreen({super.key});

  @override
  State<AccomplishmentsScreen> createState() => _AccomplishmentsScreenState();
}

class _AccomplishmentsScreenState extends State<AccomplishmentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Load accomplishments when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final service = Provider.of<AccomplishmentsService>(context, listen: false);
      service.loadAccomplishments();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<AccomplishmentsService>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Accomplishments'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryTeal,
          labelColor: AppTheme.primaryTeal,
          unselectedLabelColor: AppTheme.onSurfaceVariant,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Completed'),
            Tab(text: 'In Progress'),
            Tab(text: 'Not Started'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Tokens display
          _buildTokensHeader(service.totalTokens),

          // Accomplishments tabs
          Expanded(
            child: service.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryTeal),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAccomplishmentsList(service.accomplishments),
                      _buildAccomplishmentsList(service.completedAccomplishments),
                      _buildAccomplishmentsList(service.inProgressAccomplishments),
                      _buildAccomplishmentsList(service.notStartedAccomplishments),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTokensHeader(int tokens) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.logoGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryTeal.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.stars, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Tokens',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                tokens.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccomplishmentsList(List<Accomplishment> accomplishments) {
    if (accomplishments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 80,
              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No accomplishments here yet',
              style: TextStyle(
                color: AppTheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    // Group by category
    final groupedByCategory = <String, List<Accomplishment>>{};
    for (var accomplishment in accomplishments) {
      groupedByCategory.putIfAbsent(accomplishment.category, () => []).add(accomplishment);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: groupedByCategory.entries.map((entry) {
        return _buildCategorySection(entry.key, entry.value);
      }).toList(),
    );
  }

  Widget _buildCategorySection(String category, List<Accomplishment> accomplishments) {
    final categoryIcon = _getCategoryIcon(category);
    final categoryName = _getCategoryName(category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(categoryIcon, color: AppTheme.primaryTeal, size: 20),
              const SizedBox(width: 8),
              Text(
                categoryName,
                style: const TextStyle(
                  color: AppTheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        ...accomplishments.map((accomplishment) => _buildAccomplishmentCard(accomplishment)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAccomplishmentCard(Accomplishment accomplishment) {
    return Card(
      color: AppTheme.surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: accomplishment.isCompleted
            ? const BorderSide(color: AppTheme.holyGold, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accomplishment.isCompleted
                        ? AppTheme.holyGold.withValues(alpha: 0.2)
                        : AppTheme.primaryTeal.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIconData(accomplishment.icon),
                    color: accomplishment.isCompleted ? AppTheme.holyGold : AppTheme.primaryTeal,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        accomplishment.title,
                        style: TextStyle(
                          color: AppTheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          decoration: accomplishment.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        accomplishment.description,
                        style: const TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (accomplishment.isCompleted)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.holyGold.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: AppTheme.holyGold,
                      size: 20,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress bar
            if (!accomplishment.isCompleted) ...[
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: accomplishment.progress.clamp(0.0, 1.0),
                        backgroundColor: AppTheme.darkGrey,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryTeal),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${accomplishment.currentCount}/${accomplishment.targetCount}',
                    style: const TextStyle(
                      color: AppTheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: AppTheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    'Completed ${_formatDate(accomplishment.completedAt!)}',
                    style: const TextStyle(
                      color: AppTheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 8),

            // Reward tokens
            Row(
              children: [
                const Icon(Icons.stars, color: AppTheme.holyGold, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${accomplishment.rewardTokens} tokens',
                  style: const TextStyle(
                    color: AppTheme.holyGold,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'prayer':
        return Icons.volunteer_activism;
      case 'reading':
        return Icons.menu_book;
      case 'sharing':
        return Icons.share;
      case 'community':
        return Icons.people;
      case 'study':
        return Icons.school;
      case 'streak':
        return Icons.local_fire_department;
      default:
        return Icons.emoji_events;
    }
  }

  String _getCategoryName(String category) {
    switch (category) {
      case 'prayer':
        return 'Prayer';
      case 'reading':
        return 'Reading';
      case 'sharing':
        return 'Sharing';
      case 'community':
        return 'Community';
      case 'study':
        return 'Study';
      case 'streak':
        return 'Streaks';
      default:
        return category.toUpperCase();
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'volunteer_activism':
        return Icons.volunteer_activism;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'military_tech':
        return Icons.military_tech;
      case 'menu_book':
        return Icons.menu_book;
      case 'auto_stories':
        return Icons.auto_stories;
      case 'school':
        return Icons.school;
      case 'share':
        return Icons.share;
      case 'campaign':
        return Icons.campaign;
      case 'person_add':
        return Icons.person_add;
      case 'people':
        return Icons.people;
      case 'post_add':
        return Icons.post_add;
      case 'bookmark':
        return Icons.bookmark;
      case 'library_books':
        return Icons.library_books;
      case 'workspace_premium':
        return Icons.workspace_premium;
      case 'calendar_today':
        return Icons.calendar_today;
      case 'event_available':
        return Icons.event_available;
      default:
        return Icons.emoji_events;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    }
  }
}
