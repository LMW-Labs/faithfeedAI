import 'package:faithfeed/services/study_plan_service.dart';
import 'package:faithfeed/theme/app_theme.dart';
import 'package:faithfeed/screens/main/my_study_plans_screen.dart';
import 'package:faithfeed/screens/main/ai_library_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;

class CustomStudyPlanScreen extends StatefulWidget {
  const CustomStudyPlanScreen({super.key});

  @override
  State<CustomStudyPlanScreen> createState() => _CustomStudyPlanScreenState();
}

class _CustomStudyPlanScreenState extends State<CustomStudyPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _goalController = TextEditingController();
  final _focusAreaController = TextEditingController();
  final StudyPlanService _studyPlanService = StudyPlanService();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _planKey = GlobalKey();

  final List<String> _durationOptions = ['7 days', '14 days', '30 days'];
  final List<String> _experienceLevels = ['beginner', 'intermediate', 'advanced'];
  final List<String> _availableTopics = [
    'Prayer',
    'Faith',
    'Discipleship',
    'Leadership',
    'Family',
    'Relationships',
    'Service',
    'Spiritual Growth',
    'Healing',
    'Worship',
  ];

  // Quick goal suggestions for users new to faith
  final List<String> _goalSuggestions = [
    'Grow in prayer',
    'Understand the Gospels',
    'Strengthen faith in trials',
    'Study Paul\'s letters',
    'Learn about grace',
    'Build a prayer life',
    'Discover God\'s purpose',
    'Deepen my relationship with Jesus',
  ];

  // Focus area suggestions
  final List<String> _focusAreaSuggestions = [
    'Healing',
    'Evangelism',
    'Worship',
    'Mentoring',
    'Forgiveness',
    'Leadership',
  ];

  String _selectedDuration = '7 days';
  String _selectedExperience = 'beginner';
  final Set<String> _selectedTopics = {'Spiritual Growth'};

  StudyPlan? _generatedPlan;
  bool _isLoading = false;

  @override
  void dispose() {
    _goalController.dispose();
    _focusAreaController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.primaryTeal, size: 28),
            const SizedBox(width: 12),
            const Text(
              'Plan Created!',
              style: TextStyle(color: AppTheme.onSurface),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your personalized study plan has been created and saved to your library.',
              style: TextStyle(color: AppTheme.onSurface),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.library_books, color: AppTheme.primaryTeal, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: const Text(
                      'Access your saved plans anytime from My Library → Study Plans',
                      style: TextStyle(
                        color: AppTheme.onSurface,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // Reset form to create another
              _resetForm();
            },
            child: const Text(
              'Create Another',
              style: TextStyle(color: AppTheme.primaryTeal),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // Scroll to the plan
              _scrollToPlan();
            },
            child: const Text(
              'View Here',
              style: TextStyle(color: AppTheme.primaryTeal),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // Navigate to AI Library
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AILibraryScreen(),
                ),
              );
            },
            child: const Text('Go to Library'),
          ),
        ],
      ),
    );
  }

  void _scrollToPlan() {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _planKey.currentContext != null) {
        Scrollable.ensureVisible(
          _planKey.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _resetForm() {
    if (!mounted) return;

    setState(() {
      _goalController.clear();
      _focusAreaController.clear();
      _generatedPlan = null;
      _selectedDuration = '7 days';
      _selectedExperience = 'beginner';
      _selectedTopics.clear();
      _selectedTopics.add('Spiritual Growth');
    });
  }

  Future<void> _generateStudyPlan() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedTopics.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one topic.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _generatedPlan = null;
    });

    // Scroll down to show the loading indicator
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });

    try {
      final plan = await _studyPlanService.generateStudyPlan(
        goal: _goalController.text.trim(),
        duration: _selectedDuration,
        topics: _selectedTopics.toList(),
        experienceLevel: _selectedExperience,
        focusArea: _focusAreaController.text.trim().isEmpty ? null : _focusAreaController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _generatedPlan = plan;
        });

        // Scroll to show the generated plan
        _scrollToPlan();

        // Show success dialog
        if (plan != null) {
          _showSuccessDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Plan generated but could not be saved. Please try again.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate study plan: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildTopicsSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _availableTopics.map((topic) {
        final isSelected = _selectedTopics.contains(topic);
        return FilterChip(
          label: Text(topic),
          selected: isSelected,
          backgroundColor: isSelected ? AppTheme.primaryTeal : AppTheme.surface, // Frosted theme background
          selectedColor: AppTheme.primaryTeal,
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppTheme.onSurface, // Readable text
          ),
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedTopics.add(topic);
              } else {
                _selectedTopics.remove(topic);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildPlanOverview(StudyPlan plan) {
    return Card(
      key: _planKey,
      color: AppTheme.surface,
      margin: const EdgeInsets.only(top: 20),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              plan.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.primaryTeal,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              plan.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.onSurfaceVariant, // Readable text
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _buildInfoChip(Icons.flag, 'Goal: ${plan.goal}'),
                _buildInfoChip(Icons.schedule, 'Duration: ${plan.duration}'),
                _buildInfoChip(Icons.school, 'Level: ${plan.experienceLevel}'),
                if (plan.focusArea != null && plan.focusArea!.isNotEmpty)
                  _buildInfoChip(Icons.center_focus_strong, 'Focus: ${plan.focusArea}'),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: AppTheme.onSurfaceVariant), // Consistent divider
            ...plan.days.map(_buildDayTile),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Chip(
      avatar: Icon(icon, size: 18, color: AppTheme.primaryTeal),
      label: Text(text),
      backgroundColor: AppTheme.surface, // Consistent background
      labelStyle: const TextStyle(color: AppTheme.onSurface),
    );
  }

  Widget _buildDayTile(StudyDay day) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(left: 16, right: 8, bottom: 12),
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryTeal.withOpacity(0.2),
        child: Text(
          day.day.toString(),
          style: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(
        day.title,
        style: const TextStyle(
          color: AppTheme.onSurface, // Readable text
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '${day.estimatedMinutes} min • ${day.description}',
        style: const TextStyle(color: AppTheme.onSurfaceVariant), // Readable text
      ),
      children: [
        if (day.scriptures.isNotEmpty) ...[
          const Text(
            'Scripture Readings',
            style: TextStyle(
              color: AppTheme.primaryTeal,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...day.scriptures.map(
            (scripture) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '${scripture['reference']}: ${scripture['passage']}',
                style: const TextStyle(color: AppTheme.onSurface), // Readable text
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        _buildSectionText('Reflection', day.reflection),
        _buildSectionText('Prayer Focus', day.prayer),
        _buildSectionText('Action Step', day.actionItem),
      ],
    );
  }

  Widget _buildSectionText(String label, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.primaryTeal,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(color: AppTheme.onSurface), // Readable text
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground, // Base background for frosted theme
      appBar: AppBar(
        backgroundColor: AppTheme.surface, // Frosted theme AppBar background
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light, // Ensure light status bar icons
        title: const Text(
          'Custom Study Plan',
          style: TextStyle(color: AppTheme.onSurface), // Readable title text color
        ),
        iconTheme: const IconThemeData(color: AppTheme.onSurface), // Readable icon color
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.library_books, size: 20),
            label: const Text('My Plans'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryTeal,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyStudyPlansScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Add top margin to prevent text field from being hidden behind app bar
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _goalController,
                        style: const TextStyle(color: AppTheme.onSurface), // Readable input text
                        decoration: InputDecoration(
                          labelText: 'What is your primary study goal?',
                          helperMaxLines: 3,
                          hintText: 'Or tap a suggestion below',
                          labelStyle: TextStyle(color: AppTheme.onSurfaceVariant), // Readable label
                          hintStyle: TextStyle(color: AppTheme.onSurfaceVariant.withOpacity(0.7)), // Readable hint
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.onSurfaceVariant.withOpacity(0.3))),
                          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryTeal)),
                        ),
                        maxLines: 1,
                        scrollPhysics: const ClampingScrollPhysics(),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please describe your goal.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      // Horizontal scrollable chips to save vertical space
                      SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _goalSuggestions.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final suggestion = _goalSuggestions[index];
                            return ActionChip(
                              label: Text(suggestion),
                              labelStyle: const TextStyle(fontSize: 12, color: AppTheme.onSurface), // Readable text
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              visualDensity: VisualDensity.compact,
                              backgroundColor: AppTheme.surface, // Consistent background
                              side: BorderSide(
                                color: AppTheme.primaryTeal.withOpacity(0.3),
                              ),
                              onPressed: () {
                                setState(() {
                                  _goalController.text = suggestion;
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedDuration,
                    style: const TextStyle(color: AppTheme.onSurface), // Readable selected value
                    dropdownColor: AppTheme.surface, // Frosted dropdown background
                    decoration: InputDecoration(
                      labelText: 'Plan duration',
                      labelStyle: TextStyle(color: AppTheme.onSurfaceVariant), // Readable label
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.onSurfaceVariant.withOpacity(0.3))),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryTeal)),
                    ),
                    items: _durationOptions
                        .map((option) => DropdownMenuItem(
                              value: option,
                              child: Text(
                                option,
                                style: const TextStyle(color: AppTheme.onSurface), // Readable option text
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedDuration = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedExperience,
                    style: const TextStyle(color: AppTheme.onSurface), // Readable selected value
                    dropdownColor: AppTheme.surface, // Frosted dropdown background
                    decoration: InputDecoration(
                      labelText: 'Experience level',
                      labelStyle: TextStyle(color: AppTheme.onSurfaceVariant), // Readable label
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.onSurfaceVariant.withOpacity(0.3))),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryTeal)),
                    ),
                    items: _experienceLevels
                        .map((level) => DropdownMenuItem(
                              value: level,
                              child: Text(
                                level[0].toUpperCase() + level.substring(1),
                                style: const TextStyle(color: AppTheme.onSurface), // Readable option text
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedExperience = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _focusAreaController,
                        style: const TextStyle(color: AppTheme.onSurface), // Readable input text
                        decoration: InputDecoration(
                          labelText: 'Focus area (optional)',
                          hintText: 'Or select from suggestions',
                          labelStyle: TextStyle(color: AppTheme.onSurfaceVariant), // Readable label
                          hintStyle: TextStyle(color: AppTheme.onSurfaceVariant.withOpacity(0.7)), // Readable hint
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.onSurfaceVariant.withOpacity(0.3))),
                          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryTeal)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Horizontal scrollable chips
                      SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _focusAreaSuggestions.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final suggestion = _focusAreaSuggestions[index];
                            return ActionChip(
                              label: Text(suggestion),
                              labelStyle: const TextStyle(fontSize: 12, color: AppTheme.onSurface), // Readable text
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              visualDensity: VisualDensity.compact,
                              backgroundColor: AppTheme.surface, // Consistent background
                              side: BorderSide(
                                color: AppTheme.primaryTeal.withOpacity(0.3),
                              ),
                              onPressed: () {
                                setState(() {
                                  _focusAreaController.text = suggestion;
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Select topics to include',
                    style: TextStyle(
                      color: AppTheme.onSurface, // Readable text
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildTopicsSelector(),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _generateStudyPlan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryTeal, // Consistent button color
                        foregroundColor: AppTheme.onPrimary, // Text color for button
                      ),
                      child: const Text('Generate Study Plan'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _isLoading
                        ? Container(
                            key: const ValueKey('loading'),
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: AppTheme.surface, // Consistent background
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 12),
                                const Text(
                                  'Asking the AI to prepare your plan…',
                                  style: TextStyle(color: AppTheme.onSurfaceVariant), // Readable text
                                ),
                              ],
                            ),
                          )
                        : _generatedPlan != null
                            ? _buildPlanOverview(_generatedPlan!)
                            : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}