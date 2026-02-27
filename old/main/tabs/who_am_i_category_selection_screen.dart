import 'package:flutter/material.dart';
import '../../../models/question_category_model.dart';
import '../../../services/categorized_questions_service.dart';
import '../../../theme/app_theme.dart';
// import 'who_am_i_screen.dart'; // TODO: Re-enable when WhoAmIScreen is created

class WhoAmICategorySelectionScreen extends StatefulWidget {
  const WhoAmICategorySelectionScreen({super.key});

  @override
  State<WhoAmICategorySelectionScreen> createState() => _WhoAmICategorySelectionScreenState();
}

class _WhoAmICategorySelectionScreenState extends State<WhoAmICategorySelectionScreen> {
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
    final categories = await _service.getWhoAmICategories();
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
      case 'person':
        return Icons.person;
      case 'record_voice_over':
        return Icons.record_voice_over;
      case 'castle':
        return Icons.castle;
      case 'groups':
        return Icons.groups;
      case 'theater_comedy':
        return Icons.theater_comedy;
      case 'help_outline':
        return Icons.help_outline;
      default:
        return Icons.person_search;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text('Who Am I? Categories'),
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
                      'Guess biblical figures from AI-generated clues',
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
          // TODO: Re-enable this when WhoAmIScreen is created
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => WhoAmIScreen(
          //       categoryId: category.id,
          //       categoryName: category.name,
          //     ),
          //   ),
          // );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("'Who Am I?' feature is coming soon!"),
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
                      '${category.questionCount} challenges',
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
