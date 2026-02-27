import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../theme/app_theme.dart';
import '../ai_tools/custom_study_plan_screen.dart';
import '../ai_tools/thematic_guidance_screen.dart';
import '../ai_tools/devotional_generator_screen.dart';
import '../ai_tools/ai_study_partner_screen.dart';
import '../ai_tools/chapter_summarizer_screen.dart';
import '../ai_tools/topical_studies_screen.dart';
import '../ai_tools/manual_study_plan_screen.dart';
import '../ai_library_screen.dart';
import '../../games/bible_connections_screen.dart';
import '../../games/the_walk_start_screen.dart';
import '../../games/weekly_leaderboard_screen.dart';
import '../bible_trivia_game_screen.dart';
import '../../notes/notes_feed_screen.dart';

class ExploreTab extends StatefulWidget {
  const ExploreTab({super.key});

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Text(
              'AI Study Tools',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.lightOnSurface, // Dark text on frosted background
              ),
            ),
            const SizedBox(height: 12),

            // Tools Grid - 3 columns of small squares
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.1,
              children: [
                // Your Library - First and distinguishable
                _buildLibrarySquareCard(context),
                _buildSquareToolCard(
                  context: context,
                  svgAsset: 'assets/bytheme.svg',
                  title: 'By Theme',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFB347), Color(0xFFFFCC80)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ThematicGuidanceScreen()),
                  ),
                ),
                _buildSquareToolCard(
                  context: context,
                  svgAsset: 'assets/studyplan.svg',
                  title: 'Study Plan',
                  gradient: AppTheme.primaryGradient,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CustomStudyPlanScreen()),
                  ),
                ),
                _buildSquareToolCard(
                  context: context,
                  svgAsset: 'assets/devotional.svg',
                  title: 'Devotional',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DevotionalGeneratorScreen()),
                  ),
                ),
                _buildSquareToolCard(
                  context: context,
                  svgAsset: 'assets/studypartner.svg',
                  title: 'Study Partner',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AIStudyPartnerScreen()),
                  ),
                ),
                _buildSquareToolCard(
                  context: context,
                  svgAsset: 'assets/summarizer.svg',
                  title: 'Summarizer',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF26A69A), Color(0xFF4DB6AC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChapterSummarizerScreen()),
                  ),
                ),
                _buildSquareToolCard(
                  context: context,
                  svgAsset: 'assets/mynotes.svg',
                  title: 'My Notes',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5C6BC0), Color(0xFF7986CB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotesFeedScreen()),
                  ),
                ),
                _buildSquareToolCard(
                  context: context,
                  svgAsset: 'assets/topical.svg',
                  title: 'Topical',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7B1FA2), Color(0xFFAB47BC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TopicalStudiesScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Games Section Header
            Text(
              'Games & Trivia',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.lightOnSurface, // Dark text on frosted background
              ),
            ),
            const SizedBox(height: 12),

            // Games Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.1,
              children: [
                _buildSquareToolCard(
                  context: context,
                  svgAsset: 'assets/bibletrivia.svg',
                  title: 'Bible Trivia',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BibleTriviaGameScreen()),
                  ),
                ),
                _buildSquareToolCard(
                  context: context,
                  svgAsset: 'assets/bibleconnections.svg',
                  title: 'Bible\nConnections',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0088A8), Color(0xFF006080)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BibleConnectionsScreen()),
                  ),
                ),
                _buildSquareToolCard(
                  context: context,
                  svgAsset: 'assets/thewalk.svg',
                  title: 'The Walk',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF80CBC4), Color(0xFFA7FFEB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TheWalkStartScreen()),
                  ),
                ),
                _buildSquareToolCard(
                  context: context,
                  svgAsset: 'assets/trophy.svg',
                  title: 'Leaderboard',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF64B5F6), Color(0xFF90CAF9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WeeklyLeaderboardScreen()),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Advanced Section Header
            Row(
              children: [
                Text(
                  'Advanced',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.lightOnSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Power Users',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryTeal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Advanced Tools - Single item for now
            _buildSquareToolCard(
              context: context,
              svgAsset: 'assets/manual study.svg',
              title: 'Manual Plan',
              gradient: const LinearGradient(
                colors: [Color(0xFFFF8F00), Color(0xFFFFB300)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManualStudyPlanScreen()),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // Your Library - Square card with distinct styling
  Widget _buildLibrarySquareCard(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AILibraryScreen()),
      ),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.mainBlue, AppTheme.lightBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.mainBlue.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/library.svg',
                  width: 40,
                  height: 40,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Your Library',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Small square tool card for grid - supports both icons and SVG assets
  Widget _buildSquareToolCard({
    required BuildContext context,
    IconData? icon,
    String? svgAsset,
    required String title,
    required Gradient gradient,
    required VoidCallback onTap,
    bool isPremium = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Premium badge
            if (isPremium)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.softPeach,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'PRO',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            // Content
            Center(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (svgAsset != null)
                      SvgPicture.asset(
                        svgAsset,
                        width: 40,
                        height: 40,
                        // No colorFilter - these SVGs contain embedded images
                      )
                    else if (icon != null)
                      Icon(icon, size: 32, color: Colors.white),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
