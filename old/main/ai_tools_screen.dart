import 'package:faithfeed/screens/main/ai_tools/devotional_generator_screen.dart';
import 'package:faithfeed/screens/main/ai_tools/ai_study_partner_screen.dart';
import 'package:faithfeed/screens/main/ai_tools/chapter_summarizer_screen.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AIToolsScreen extends StatelessWidget {
  const AIToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Tools'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Sermon Recorder - Hidden (doesn't work well)
          // _buildToolCard(
          //   context,
          //   icon: FontAwesomeIcons.microphone,
          //   title: 'Sermon Recorder',
          //   subtitle: 'Record a sermon and get an outline.',
          //   gradient: const LinearGradient(
          //     colors: [Color(0xFF6A5AE0), Color(0xFF9B8CE8)],
          //     begin: Alignment.topLeft,
          //     end: Alignment.bottomRight,
          //   ),
          //   isFontAwesome: true,
          //   onTap: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (context) => const SermonRecorderScreen(),
          //       ),
          //     );
          //   },
          //   isPremium: false, // Made FREE
          // ),
          _buildToolCard(
            context,
            icon: FontAwesomeIcons.bookBible,
            title: 'Devotional Generator',
            subtitle: 'Create a devotional from a theme or verses.',
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B9D), Color(0xFFFFA06B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            isFontAwesome: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DevotionalGeneratorScreen(),
                ),
              );
            },
            isPremium: false, // Made FREE
          ),
          _buildToolCard(
            context,
            icon: FontAwesomeIcons.compass,
            title: 'AI Study Partner',
            subtitle: 'Interactive Bible study with AI assistance.',
            gradient: const LinearGradient(
              colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            isFontAwesome: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AIStudyPartnerScreen(),
                ),
              );
            },
            isPremium: false,
          ),
          _buildToolCard(
            context,
            icon: Icons.auto_stories,
            title: 'Chapter Summarizer',
            subtitle: 'Get comprehensive summaries with key verses and themes.',
            gradient: const LinearGradient(
              colors: [Color(0xFFF9A826), Color(0xFFFF7B54)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            isFontAwesome: false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChapterSummarizerScreen(),
                ),
              );
            },
            isPremium: false,
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
    bool isPremium = false,
    bool isFontAwesome = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isFontAwesome
                      ? FaIcon(icon, size: 32, color: Colors.white)
                      : Icon(icon, size: 32, color: Colors.white),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isPremium)
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    width: 1,
                                  ),
                                ),
                                child: const Text(
                                  'Premium',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6.0),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
