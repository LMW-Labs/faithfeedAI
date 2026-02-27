import 'package:flutter/material.dart';
import '../../../models/question_category_model.dart';
import '../../../services/categorized_questions_service.dart';
import '../../../theme/app_theme.dart';

class TriviaCategorySelectionScreen extends StatefulWidget {
  const TriviaCategorySelectionScreen({super.key});

  @override
  State<TriviaCategorySelectionScreen> createState() => _TriviaCategorySelectionScreenState();
}

class _TriviaCategorySelectionScreenState extends State<TriviaCategorySelectionScreen> {
  final CategorizedQuestionsService _service = CategorizedQuestionsService();
  List<QuestionCategory> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _loading = true);
    final categories = await _service.getTriviaCategories();
    setState(() {
      _categories = categories;
      _loading = false;
    });
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return AppTheme.mintGreen;
      case 'medium':
        return AppTheme.holyGold;
      case 'hard':
        return AppTheme.primaryCoral;
      default:
        return AppTheme.primaryTeal;
    }
  }

  IconData _getCategoryIcon(String? iconName) {
    switch (iconName) {
      case 'book':
        return Icons.menu_book;
      case 'stars':
        return Icons.auto_awesome;
      case 'library_books':
        return Icons.library_books;
      case 'castle':
        return Icons.castle;
      case 'groups':
        return Icons.groups;
      case 'person':
        return Icons.person;
      case 'map':
        return Icons.map;
      case 'timeline':
        return Icons.timeline;
      case 'emoji_events':
        return Icons.emoji_events;
      default:
        return Icons.quiz;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text('Bible Trivia Categories'),
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryTeal),
            )
          : _categories.isEmpty
              ? const Center(
                  child: Text(
                    'No categories available',
                    style: TextStyle(color: AppTheme.onSurfaceVariant),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'Select a Category',
                      style: TextStyle(
                        color: AppTheme.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Choose a topic to test your Bible knowledge',
                      style: TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ..._categories.map((category) => _buildCategoryCard(category)),
                  ],
                ),
    );
  }

  Widget _buildCategoryCard(QuestionCategory category) {
    final difficultyColor = _getDifficultyColor(category.difficulty);
    final icon = _getCategoryIcon(category.icon);

    return Card(
      color: AppTheme.surface,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // TODO: Re-enable this when BibleTriviaScreen is created
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => BibleTriviaScreen(
          //       categoryId: category.id,
          //       categoryName: category.name,
          //     ),
          //   ),
          // );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Trivia feature is coming soon!'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: difficultyColor.withValues(alpha:0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: difficultyColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            category.name,
                            style: const TextStyle(
                              color: AppTheme.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Difficulty badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: difficultyColor.withValues(alpha:0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            category.difficulty.toUpperCase(),
                            style: TextStyle(
                              color: difficultyColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category.description,
                      style: const TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${category.questionCount} questions',
                      style: TextStyle(
                        color: AppTheme.primaryTeal.withValues(alpha:0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Arrow
              const Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.onSurfaceVariant,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
