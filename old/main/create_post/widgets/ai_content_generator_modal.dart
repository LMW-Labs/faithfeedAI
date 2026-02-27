import 'package:flutter/material.dart';
import 'package:faithfeed/services/logger_service.dart';
import '../../../../theme/app_theme.dart';
import '../../../../services/ai_content_service.dart';
import '../../../../models/ai_content_idea.dart';

/// Post preset types for AI content generation
enum PostPreset {
  encourage,
  devotion,
  verseShare,
  testimony,
}

extension PostPresetX on PostPreset {
  String get label {
    switch (this) {
      case PostPreset.encourage:
        return 'Encourage';
      case PostPreset.devotion:
        return 'Devotion';
      case PostPreset.verseShare:
        return 'Verse Share';
      case PostPreset.testimony:
        return 'Testimony';
    }
  }

  String get emoji {
    switch (this) {
      case PostPreset.encourage:
        return '💪';
      case PostPreset.devotion:
        return '🙏';
      case PostPreset.verseShare:
        return '📖';
      case PostPreset.testimony:
        return '✝️';
    }
  }

  String get description {
    switch (this) {
      case PostPreset.encourage:
        return 'Uplifting, hopeful';
      case PostPreset.devotion:
        return 'Reflective, peaceful';
      case PostPreset.verseShare:
        return 'Scripture-focused';
      case PostPreset.testimony:
        return 'Personal story';
    }
  }

  // Maps preset to backend parameters
  Map<String, dynamic> get backendParams {
    switch (this) {
      case PostPreset.encourage:
        return {
          'tone': 'encouraging',
          'length': 'medium',
          'includeScripture': true,
          'includePrayer': false,
          'includeCallToAction': true,
        };
      case PostPreset.devotion:
        return {
          'tone': 'pastoral',
          'length': 'medium',
          'includeScripture': true,
          'includePrayer': true,
          'includeCallToAction': false,
        };
      case PostPreset.verseShare:
        return {
          'tone': 'educational',
          'length': 'short',
          'includeScripture': true,
          'includePrayer': false,
          'includeCallToAction': false,
        };
      case PostPreset.testimony:
        return {
          'tone': 'testimonial',
          'length': 'long',
          'includeScripture': true,
          'includePrayer': false,
          'includeCallToAction': true,
        };
    }
  }
}

/// Modal for generating AI content ideas
/// Uses a simplified preset-based approach
class AIContentGeneratorModal extends StatefulWidget {
  final String? initialScriptureReference;
  final Function(String content, String? scripture, bool aiGenerated) onIdeaSelected;

  const AIContentGeneratorModal({
    super.key,
    this.initialScriptureReference,
    required this.onIdeaSelected,
  });

  static Future<void> show(
    BuildContext context, {
    String? initialScriptureReference,
    required Function(String content, String? scripture, bool aiGenerated) onIdeaSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => AIContentGeneratorModal(
        initialScriptureReference: initialScriptureReference,
        onIdeaSelected: onIdeaSelected,
      ),
    );
  }

  @override
  State<AIContentGeneratorModal> createState() => _AIContentGeneratorModalState();
}

class _AIContentGeneratorModalState extends State<AIContentGeneratorModal> {
  final AIContentService _aiContentService = AIContentService();
  final TextEditingController _topicController = TextEditingController();

  PostPreset _selectedPreset = PostPreset.encourage;
  List<AIContentIdea> _ideas = [];
  bool _isGenerating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Pre-fill with scripture reference if provided
    if (widget.initialScriptureReference != null &&
        widget.initialScriptureReference!.isNotEmpty) {
      _topicController.text = 'A post about ${widget.initialScriptureReference}';
    }
  }

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _handleGenerate() async {
    final topic = _topicController.text.trim();
    if (topic.length < 3) {
      setState(() {
        _errorMessage = 'Please share what\'s on your heart (at least 3 characters).';
      });
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _ideas = [];
    });

    try {
      final params = _selectedPreset.backendParams;

      final results = await _aiContentService.generatePostIdeas(
        topic: topic,
        tone: params['tone'],
        audience: 'faithfeed community',
        includeScripture: params['includeScripture'],
        scriptureFocus: '',
        includePrayer: params['includePrayer'],
        includeCallToAction: params['includeCallToAction'],
        length: params['length'],
      );

      setState(() {
        _ideas = results;
      });
    } catch (e) {
      String userFriendlyError;
      final errorString = e.toString().toLowerCase();

      Log.d('AI Content Generation Error: $e');

      if (errorString.contains('unauthenticated')) {
        userFriendlyError = 'Authentication error. Please sign out and sign back in.';
      } else if (errorString.contains('permission') || errorString.contains('denied')) {
        userFriendlyError = 'AI service not configured. Please contact support.';
      } else if (errorString.contains('network') || errorString.contains('timeout')) {
        userFriendlyError = 'Network error. Please check your connection and try again.';
      } else if (errorString.contains('quota') || errorString.contains('limit')) {
        userFriendlyError = 'Service temporarily unavailable. Please try again in a moment.';
      } else if (errorString.contains('invalid-argument')) {
        userFriendlyError = 'Invalid input. Please check your topic and try again.';
      } else if (errorString.contains('internal')) {
        userFriendlyError = 'Server error. The AI service may be temporarily unavailable.';
      } else {
        userFriendlyError = 'Failed to generate content ideas. Please try again.';
      }

      setState(() {
        _errorMessage = userFriendlyError;
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  void _selectIdea(AIContentIdea idea) {
    final buffer = StringBuffer(idea.body);
    if (idea.hasCallToAction) {
      buffer.write('\n\n${idea.callToAction}');
    }
    if (idea.hasPrayer) {
      buffer.write('\n\n${idea.prayer}');
    }

    final scripture = idea.hasScripture ? idea.scripture : null;

    widget.onIdeaSelected(buffer.toString(), scripture, true);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: AppTheme.primaryTeal),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'AI Content Generator',
                          style: TextStyle(
                            color: AppTheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: AppTheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Topic input
                  TextField(
                    controller: _topicController,
                    maxLines: 3,
                    style: const TextStyle(color: AppTheme.onSurface),
                    decoration: InputDecoration(
                      labelText: "What's on your heart?",
                      labelStyle: const TextStyle(color: AppTheme.onSurfaceVariant),
                      hintText: 'e.g., Encouragement for those struggling with anxiety',
                      hintStyle: TextStyle(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7)),
                      filled: true,
                      fillColor: AppTheme.surfaceElevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primaryTeal, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Preset selector label
                  const Text(
                    'Choose a style',
                    style: TextStyle(
                      color: AppTheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2x2 preset grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.2,
                    children: PostPreset.values.map((preset) {
                      final isSelected = _selectedPreset == preset;
                      return _buildPresetButton(preset, isSelected);
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Generate button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isGenerating ? null : _handleGenerate,
                      icon: _isGenerating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(_isGenerating ? 'Generating...' : 'Generate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  // Error message
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryCoral.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.primaryCoral.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppTheme.primaryCoral, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: AppTheme.primaryCoral, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Loading indicator
                  if (_isGenerating) ...[
                    const SizedBox(height: 24),
                    Center(
                      child: Column(
                        children: [
                          const CircularProgressIndicator(color: AppTheme.primaryTeal),
                          const SizedBox(height: 12),
                          Text(
                            'Creating ${_selectedPreset.label.toLowerCase()} content...',
                            style: const TextStyle(
                              color: AppTheme.onSurfaceVariant,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Ideas list
                  if (_ideas.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Choose an idea',
                      style: TextStyle(
                        color: AppTheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._ideas.map((idea) => _buildIdeaCard(idea)),
                  ],

                  // Extra padding at bottom
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPresetButton(PostPreset preset, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPreset = preset;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryTeal.withValues(alpha: 0.15)
              : AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryTeal
                : AppTheme.onSurfaceVariant.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Text(
                preset.emoji,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      preset.label,
                      style: TextStyle(
                        color: isSelected ? AppTheme.primaryTeal : AppTheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      preset.description,
                      style: TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: AppTheme.primaryTeal,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdeaCard(AIContentIdea idea) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppTheme.darkBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              idea.title,
              style: const TextStyle(
                color: AppTheme.primaryTeal,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              idea.body,
              style: const TextStyle(
                color: AppTheme.onSurface,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            if (idea.hasScripture) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.menu_book, size: 16, color: AppTheme.primaryTeal),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        idea.scripture,
                        style: const TextStyle(
                          color: AppTheme.onSurface,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (idea.hasPrayer) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.self_improvement, size: 16, color: AppTheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      idea.prayer,
                      style: const TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (idea.hasCallToAction) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.campaign, size: 16, color: AppTheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      idea.callToAction,
                      style: const TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _selectIdea(idea),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Use this idea'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
