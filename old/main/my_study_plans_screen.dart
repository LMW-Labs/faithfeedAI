import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/study_plan_service.dart';
import '../../theme/app_theme.dart';
import 'study_plan_detail_screen.dart';

class MyStudyPlansScreen extends StatelessWidget {
  const MyStudyPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Study Plans'),
          backgroundColor: AppTheme.surface,
        ),
        body: const Center(
          child: Text('Please log in to view your study plans.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Study Plans'),
        backgroundColor: AppTheme.surface,
      ),
      backgroundColor: Colors.transparent,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('studyPlans')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading plans: ${snapshot.error}',
                    style: const TextStyle(color: AppTheme.onSurface),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.book_outlined,
                    size: 64,
                    color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No study plans yet',
                    style: TextStyle(
                      color: AppTheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Create your first personalized study plan from the AI Tools screen',
                      style: TextStyle(color: AppTheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }

          final plans = snapshot.data!.docs
              .map((doc) => StudyPlan.fromFirestore(doc))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
              return _buildPlanCard(context, plan);
            },
          );
        },
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, StudyPlan plan) {
    final progressPercent = (plan.progress * 100).toInt();
    final completedDays = plan.days.where((day) => day.isCompleted).length;
    final totalDays = plan.days.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppTheme.surface,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudyPlanDetailScreen(plan: plan),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      plan.title,
                      style: const TextStyle(
                        color: AppTheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (plan.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          color: AppTheme.primaryTeal,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                plan.description,
                style: const TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppTheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    plan.duration,
                    style: const TextStyle(
                      color: AppTheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: AppTheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$completedDays/$totalDays days',
                    style: const TextStyle(
                      color: AppTheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$progressPercent% Complete',
                        style: const TextStyle(
                          color: AppTheme.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: plan.progress.toDouble() / 100,
                      backgroundColor: AppTheme.darkGrey,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryTeal,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
