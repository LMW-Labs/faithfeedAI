import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/study_plan_service.dart';
import '../../theme/app_theme.dart';

class StudyPlanDetailScreen extends StatefulWidget {
  final StudyPlan plan;

  const StudyPlanDetailScreen({
    super.key,
    required this.plan,
  });

  @override
  State<StudyPlanDetailScreen> createState() => _StudyPlanDetailScreenState();
}

class _StudyPlanDetailScreenState extends State<StudyPlanDetailScreen> {
  late StudyPlan _plan;

  @override
  void initState() {
    super.initState();
    _plan = widget.plan;
  }

  Future<void> _toggleDayCompletion(int dayIndex) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final updatedDays = List<Map<String, dynamic>>.from(
        _plan.days.map((day) => day.toMap()),
      );

      // Toggle completion
      updatedDays[dayIndex]['isCompleted'] = !_plan.days[dayIndex].isCompleted;

      // Calculate progress
      final completedCount = updatedDays.where((day) => day['isCompleted'] == true).length;
      final progress = ((completedCount / updatedDays.length) * 100).round();

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('studyPlans')
          .doc(_plan.id)
          .update({
        'days': updatedDays,
        'progress': progress,
        'lastAccessedAt': FieldValue.serverTimestamp(),
      });

      // Update local state
      setState(() {
        _plan = StudyPlan(
          id: _plan.id,
          userId: _plan.userId,
          title: _plan.title,
          description: _plan.description,
          goal: _plan.goal,
          duration: _plan.duration,
          topics: _plan.topics,
          experienceLevel: _plan.experienceLevel,
          focusArea: _plan.focusArea,
          sessionsPerWeek: _plan.sessionsPerWeek,
          days: updatedDays
              .map((dayMap) => StudyDay.fromMap(dayMap))
              .toList(),
          createdAt: _plan.createdAt,
          isActive: _plan.isActive,
          progress: progress,
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updatedDays[dayIndex]['isCompleted'] == true
                  ? 'Day ${dayIndex + 1} marked as complete!'
                  : 'Day ${dayIndex + 1} marked as incomplete',
            ),
            backgroundColor: AppTheme.primaryTeal,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating progress: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deletePlan() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Delete Study Plan?',
          style: TextStyle(color: AppTheme.onSurface),
        ),
        content: const Text(
          'This will permanently delete this study plan. This action cannot be undone.',
          style: TextStyle(color: AppTheme.onSurfaceVariant),
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

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('studyPlans')
            .doc(_plan.id)
            .delete();

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Study plan deleted'),
              backgroundColor: AppTheme.primaryTeal,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting plan: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final completedDays = _plan.days.where((day) => day.isCompleted).length;
    final totalDays = _plan.days.length;
    final progressPercent = (_plan.progress).toInt();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Plan'),
        backgroundColor: AppTheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deletePlan,
            tooltip: 'Delete plan',
          ),
        ],
      ),
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Card(
                color: AppTheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _plan.title,
                              style: const TextStyle(
                                color: AppTheme.onSurface,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (_plan.isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryTeal.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text(
                                'Active',
                                style: TextStyle(
                                  color: AppTheme.primaryTeal,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _plan.description,
                        style: const TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildInfoChip(Icons.flag, 'Goal: ${_plan.goal}'),
                          _buildInfoChip(Icons.calendar_today, _plan.duration),
                          _buildInfoChip(Icons.school, _plan.experienceLevel.capitalize()),
                          if (_plan.focusArea != null && _plan.focusArea!.isNotEmpty)
                            _buildInfoChip(Icons.center_focus_strong, 'Focus: ${_plan.focusArea}'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(color: AppTheme.darkGrey),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress: $completedDays/$totalDays days',
                            style: const TextStyle(
                              color: AppTheme.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '$progressPercent%',
                            style: const TextStyle(
                              color: AppTheme.primaryTeal,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _plan.progress.toDouble() / 100,
                          backgroundColor: AppTheme.darkGrey,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryTeal,
                          ),
                          minHeight: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Study Days',
                style: TextStyle(
                  color: AppTheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              // Days List
              ..._plan.days.asMap().entries.map((entry) {
                final index = entry.key;
                final day = entry.value;
                return _buildDayCard(day, index);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Chip(
      avatar: Icon(icon, size: 18, color: AppTheme.primaryTeal),
      label: Text(text),
      backgroundColor: AppTheme.darkGrey.withValues(alpha: 0.4),
      labelStyle: const TextStyle(color: AppTheme.onSurface, fontSize: 13),
    );
  }

  Widget _buildDayCard(StudyDay day, int index) {
    return Card(
      color: AppTheme.surface,
      margin: const EdgeInsets.only(bottom: 12),
      child: Theme(
        data: ThemeData(
          dividerColor: Colors.transparent,
          expansionTileTheme: const ExpansionTileThemeData(
            textColor: AppTheme.onSurface,
            iconColor: AppTheme.onSurfaceVariant,
          ),
        ),
        child: ExpansionTile(
          leading: GestureDetector(
            onTap: () => _toggleDayCompletion(index),
            child: CircleAvatar(
              backgroundColor: day.isCompleted
                  ? AppTheme.primaryTeal
                  : AppTheme.darkGrey.withValues(alpha: 0.4),
              child: day.isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : Text(
                      day.day.toString(),
                      style: const TextStyle(
                        color: AppTheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          title: Text(
            day.title,
            style: TextStyle(
              color: AppTheme.onSurface,
              fontWeight: FontWeight.w600,
              decoration: day.isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Text(
            '${day.estimatedMinutes} min • ${day.description}',
            style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (day.scriptures.isNotEmpty) ...[
                    const Text(
                      'Scripture Readings',
                      style: TextStyle(
                        color: AppTheme.primaryTeal,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...day.scriptures.map(
                      (scripture) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.darkGrey.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                scripture['reference'] ?? '',
                                style: const TextStyle(
                                  color: AppTheme.primaryTeal,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              if (scripture['text']?.isNotEmpty == true) ...[
                                const SizedBox(height: 4),
                                Text(
                                  scripture['text'] ?? '',
                                  style: const TextStyle(
                                    color: AppTheme.onSurface,
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildSection('Reflection', day.reflection, Icons.psychology),
                  _buildSection('Prayer Focus', day.prayer, Icons.church),
                  _buildSection('Action Step', day.actionItem, Icons.check_circle_outline),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _toggleDayCompletion(index),
                      icon: Icon(
                        day.isCompleted ? Icons.undo : Icons.check,
                        size: 20,
                      ),
                      label: Text(
                        day.isCompleted ? 'Mark Incomplete' : 'Mark Complete',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: day.isCompleted
                            ? AppTheme.darkGrey
                            : AppTheme.primaryTeal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String label, String content, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.primaryTeal),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.primaryTeal,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(
              color: AppTheme.onSurface,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
