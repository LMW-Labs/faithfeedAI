import 'package:flutter/material.dart';
import 'package:faithfeed/services/logger_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart'; // Required for SystemUiOverlayStyle
import '../../../services/study_plan_service.dart';
import '../../../theme/app_theme.dart';

class TopicalStudiesScreen extends StatelessWidget {
  const TopicalStudiesScreen({super.key});

  static final List<TopicalStudy> _topicalStudies = [
    TopicalStudy(
      title: 'Prayer & Communion with God',
      description: 'Learn to deepen your prayer life and maintain constant fellowship with God',
      topic: 'Prayer',
      icon: Icons.back_hand,
      color: Colors.purple,
      duration: 7,
      verses: [
        {'reference': 'Matthew 6:5-15', 'day': 1, 'theme': 'The Lord\'s Prayer'},
        {'reference': '1 Thessalonians 5:16-18', 'day': 2, 'theme': 'Pray Continually'},
        {'reference': 'Philippians 4:6-7', 'day': 3, 'theme': 'Prayer and Peace'},
        {'reference': 'James 5:13-18', 'day': 4, 'theme': 'Power of Prayer'},
        {'reference': 'Luke 11:1-13', 'day': 5, 'theme': 'Ask, Seek, Knock'},
        {'reference': 'John 17:1-26', 'day': 6, 'theme': 'Jesus\' High Priestly Prayer'},
        {'reference': 'Ephesians 6:18-20', 'day': 7, 'theme': 'Prayer in the Spirit'},
      ],
    ),
    TopicalStudy(
      title: 'Faith & Trust in God',
      description: 'Build unwavering faith and learn to trust God in all circumstances',
      topic: 'Faith',
      icon: Icons.favorite,
      color: Colors.red,
      duration: 7,
      verses: [
        {'reference': 'Hebrews 11:1-6', 'day': 1, 'theme': 'Faith Defined'},
        {'reference': 'Romans 10:17', 'day': 2, 'theme': 'Faith Comes by Hearing'},
        {'reference': 'James 2:14-26', 'day': 3, 'theme': 'Faith and Works'},
        {'reference': 'Matthew 17:20', 'day': 4, 'theme': 'Faith Like a Mustard Seed'},
        {'reference': 'Proverbs 3:5-6', 'day': 5, 'theme': 'Trust in the Lord'},
        {'reference': 'Habakkuk 2:4', 'day': 6, 'theme': 'The Just Shall Live by Faith'},
        {'reference': 'Mark 11:22-24', 'day': 7, 'theme': 'Have Faith in God'},
      ],
    ),
    TopicalStudy(
      title: 'Love & Relationships',
      description: 'Understand God\'s love and how to love others authentically',
      topic: 'Relationships',
      icon: Icons.people,
      color: Colors.pink,
      duration: 7,
      verses: [
        {'reference': '1 Corinthians 13:1-13', 'day': 1, 'theme': 'Love Chapter'},
        {'reference': 'John 13:34-35', 'day': 2, 'theme': 'Love One Another'},
        {'reference': '1 John 4:7-21', 'day': 3, 'theme': 'God is Love'},
        {'reference': 'Romans 12:9-21', 'day': 4, 'theme': 'Love in Action'},
        {'reference': 'Ephesians 5:1-2', 'day': 5, 'theme': 'Walk in Love'},
        {'reference': 'Matthew 22:37-40', 'day': 6, 'theme': 'Greatest Commandments'},
        {'reference': 'John 15:12-17', 'day': 7, 'theme': 'Greater Love'},
      ],
    ),
    TopicalStudy(
      title: 'Spiritual Growth & Maturity',
      description: 'Develop spiritual disciplines and grow deeper in your walk with Christ',
      topic: 'Spiritual Growth',
      icon: Icons.trending_up,
      color: Colors.green,
      duration: 7,
      verses: [
        {'reference': '2 Peter 3:18', 'day': 1, 'theme': 'Grow in Grace'},
        {'reference': 'Hebrews 5:11-14', 'day': 2, 'theme': 'From Milk to Meat'},
        {'reference': 'Philippians 3:12-16', 'day': 3, 'theme': 'Press Toward the Goal'},
        {'reference': 'Colossians 3:1-17', 'day': 4, 'theme': 'Set Your Mind Above'},
        {'reference': 'Ephesians 4:11-16', 'day': 5, 'theme': 'Grow Up in Christ'},
        {'reference': 'James 1:2-8', 'day': 6, 'theme': 'Trials Build Maturity'},
        {'reference': '2 Corinthians 3:18', 'day': 7, 'theme': 'Transformed into His Image'},
      ],
    ),
    TopicalStudy(
      title: 'Worship & Praise',
      description: 'Learn to worship God in spirit and truth',
      topic: 'Worship',
      icon: Icons.music_note,
      color: Colors.orange,
      duration: 7,
      verses: [
        {'reference': 'Psalm 95:1-7', 'day': 1, 'theme': 'Come, Let Us Worship'},
        {'reference': 'John 4:23-24', 'day': 2, 'theme': 'Worship in Spirit and Truth'},
        {'reference': 'Psalm 100:1-5', 'day': 3, 'theme': 'Enter His Gates with Thanksgiving'},
        {'reference': 'Revelation 4:8-11', 'day': 4, 'theme': 'Heavenly Worship'},
        {'reference': 'Romans 12:1-2', 'day': 5, 'theme': 'Living Sacrifice'},
        {'reference': 'Psalm 150:1-6', 'day': 6, 'theme': 'Let Everything Praise the Lord'},
        {'reference': 'Hebrews 13:15', 'day': 7, 'theme': 'Sacrifice of Praise'},
      ],
    ),
    TopicalStudy(
      title: 'Serving & Ministry',
      description: 'Discover your calling and learn to serve others with excellence',
      topic: 'Service',
      icon: Icons.volunteer_activism,
      color: Colors.blue,
      duration: 7,
      verses: [
        {'reference': 'Mark 10:42-45', 'day': 1, 'theme': 'Servant Leadership'},
        {'reference': 'Galatians 5:13', 'day': 2, 'theme': 'Serve One Another in Love'},
        {'reference': 'Romans 12:3-8', 'day': 3, 'theme': 'Using Your Gifts'},
        {'reference': '1 Peter 4:10-11', 'day': 4, 'theme': 'Stewards of God\'s Grace'},
        {'reference': 'Matthew 25:31-46', 'day': 5, 'theme': 'Serving the Least'},
        {'reference': 'Ephesians 2:10', 'day': 6, 'theme': 'Created for Good Works'},
        {'reference': 'Colossians 3:23-24', 'day': 7, 'theme': 'Work as for the Lord'},
      ],
    ),
    TopicalStudy(
      title: 'Wisdom & Discernment',
      description: 'Seek God\'s wisdom and learn to make godly decisions',
      topic: 'Leadership',
      icon: Icons.lightbulb,
      color: Colors.amber,
      duration: 7,
      verses: [
        {'reference': 'James 1:5-8', 'day': 1, 'theme': 'Ask for Wisdom'},
        {'reference': 'Proverbs 2:1-11', 'day': 2, 'theme': 'The Value of Wisdom'},
        {'reference': 'Proverbs 3:13-18', 'day': 3, 'theme': 'Blessed are the Wise'},
        {'reference': '1 Corinthians 1:18-25', 'day': 4, 'theme': 'God\'s Wisdom vs World\'s Wisdom'},
        {'reference': 'Proverbs 9:10', 'day': 5, 'theme': 'Fear of the Lord'},
        {'reference': 'Ecclesiastes 7:11-12', 'day': 6, 'theme': 'Wisdom Preserves Life'},
        {'reference': 'Colossians 2:2-3', 'day': 7, 'theme': 'Treasures of Wisdom in Christ'},
      ],
    ),
    TopicalStudy(
      title: 'Family & Marriage',
      description: 'Build strong, godly families rooted in biblical principles',
      topic: 'Family',
      icon: Icons.family_restroom,
      color: Colors.teal,
      duration: 7,
      verses: [
        {'reference': 'Ephesians 5:22-33', 'day': 1, 'theme': 'Marriage Covenant'},
        {'reference': 'Proverbs 31:10-31', 'day': 2, 'theme': 'The Virtuous Wife'},
        {'reference': 'Ephesians 6:1-4', 'day': 3, 'theme': 'Parents and Children'},
        {'reference': '1 Peter 3:1-7', 'day': 4, 'theme': 'Husbands and Wives'},
        {'reference': 'Deuteronomy 6:4-9', 'day': 5, 'theme': 'Teaching Your Children'},
        {'reference': 'Colossians 3:18-21', 'day': 6, 'theme': 'Family Relationships'},
        {'reference': 'Joshua 24:15', 'day': 7, 'theme': 'As for Me and My House'},
      ],
    ),
    TopicalStudy(
      title: 'Overcoming Trials & Suffering',
      description: 'Find strength and hope in God during difficult times',
      topic: 'Healing',
      icon: Icons.healing,
      color: Colors.indigo,
      duration: 7,
      verses: [
        {'reference': 'Romans 8:18-28', 'day': 1, 'theme': 'All Things Work Together'},
        {'reference': 'James 1:2-4', 'day': 2, 'theme': 'Joy in Trials'},
        {'reference': '2 Corinthians 1:3-7', 'day': 3, 'theme': 'God of All Comfort'},
        {'reference': 'Psalm 23:1-6', 'day': 4, 'theme': 'The Lord is My Shepherd'},
        {'reference': '1 Peter 5:6-11', 'day': 5, 'theme': 'Cast Your Anxieties'},
        {'reference': 'Isaiah 41:10', 'day': 6, 'theme': 'Fear Not'},
        {'reference': 'Philippians 4:11-13', 'day': 7, 'theme': 'I Can Do All Things'},
      ],
    ),
    TopicalStudy(
      title: 'Discipleship & Following Jesus',
      description: 'Learn what it means to be a true disciple of Christ',
      topic: 'Discipleship',
      icon: Icons.directions_walk,
      color: Colors.brown,
      duration: 7,
      verses: [
        {'reference': 'Matthew 16:24-26', 'day': 1, 'theme': 'Take Up Your Cross'},
        {'reference': 'John 8:31-32', 'day': 2, 'theme': 'Continue in My Word'},
        {'reference': 'Luke 14:25-33', 'day': 3, 'theme': 'Counting the Cost'},
        {'reference': 'Matthew 28:18-20', 'day': 4, 'theme': 'The Great Commission'},
        {'reference': 'John 15:1-8', 'day': 5, 'theme': 'Abide in Me'},
        {'reference': '2 Timothy 2:1-7', 'day': 6, 'theme': 'Strong in Grace'},
        {'reference': 'Galatians 2:20', 'day': 7, 'theme': 'Christ Lives in Me'},
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground, // Consistent dark background
      appBar: AppBar(
        backgroundColor: AppTheme.surface, // Frosted theme AppBar background
        elevation: 0,
        title: const Text(
          'Topical Studies',
          style: TextStyle(color: AppTheme.onSurface), // Readable title text color
        ),
        iconTheme: const IconThemeData(color: AppTheme.onSurface), // Readable icon color
        systemOverlayStyle: SystemUiOverlayStyle.light, // Ensure light status bar icons
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Pre-built study plans on key biblical topics',
            style: TextStyle(
              color: AppTheme.onSurfaceVariant, // Ensure readable
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          ..._topicalStudies.map((study) => _TopicalStudyCard(study: study)),
        ],
      ),
    );
  }
}

class TopicalStudy {
  final String title;
  final String description;
  final String topic;
  final IconData icon;
  final Color color;
  final int duration;
  final List<Map<String, dynamic>> verses;

  TopicalStudy({
    required this.title,
    required this.description,
    required this.topic,
    required this.icon,
    required this.color,
    required this.duration,
    required this.verses,
  });
}

class _TopicalStudyCard extends StatelessWidget {
  final TopicalStudy study;

  const _TopicalStudyCard({required this.study});

  Future<void> _startStudy(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in to start a study plan'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show loading dialog
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryTeal),
        ),
      );

      // Create study days from the verses
      final studyDays = study.verses.map((verseData) {
        return StudyDay(
          day: verseData['day'] as int,
          title: verseData['theme'] as String,
          description: 'Study ${verseData['reference']} and reflect on ${verseData['theme']}',
          scriptures: [
            {
              'reference': verseData['reference'] as String,
              'text': 'Read and meditate on this passage',
            }
          ],
          reflection: 'Reflect on how ${verseData['theme']} applies to your life today.',
          prayer: 'Pray for God to reveal deeper truths about ${verseData['theme']} in your life.',
          actionItem: 'Apply one truth from this passage in your daily walk.',
          estimatedMinutes: 15,
          isCompleted: false,
        );
      }).toList();

      final studyPlan = StudyPlan(
        id: '',
        userId: user.uid,
        title: study.title,
        description: study.description,
        goal: 'Learn about ${study.topic}',
        duration: '${study.duration} days',
        topics: [study.topic],
        experienceLevel: 'beginner',
        focusArea: study.topic,
        sessionsPerWeek: study.duration >= 7 ? 7 : study.duration,
        days: studyDays,
        createdAt: DateTime.now(),
        isActive: true,
        progress: 0,
      );

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('studyPlans')
          .add(studyPlan.toFirestore());

      Log.d('✅ Topical study plan created: ${study.title}');

      if (!context.mounted) return;

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${study.title} added to your study plans!'),
          backgroundColor: AppTheme.primaryTeal,
        ),
      );

      // Navigate back
      Navigator.of(context).pop();
    } catch (e) {
      Log.d('❌ Error creating topical study: $e');

      if (!context.mounted) return;

      // Close loading dialog if open
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating study plan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.surface,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _startStudy(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: study.color.withOpacity(0.2), // Consistent opacity usage
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  study.icon,
                  color: study.color,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      study.title,
                      style: const TextStyle(
                        color: AppTheme.onSurface, // Readable text color
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      study.description,
                      style: const TextStyle(
                        color: AppTheme.onSurfaceVariant, // Readable text color
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal.withOpacity(0.2), // Consistent opacity usage
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${study.duration} days',
                        style: const TextStyle(
                          color: AppTheme.primaryTeal,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.onSurfaceVariant, // Readable icon color
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}