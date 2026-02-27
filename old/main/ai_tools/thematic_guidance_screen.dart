import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:faithfeed/services/logger_service.dart';
import '../../../models/bible_verse_model.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/verse_actions_modal.dart';
import '../../../services/thematic_guidance_service.dart';

class ThematicGuidanceScreen extends StatefulWidget {
  const ThematicGuidanceScreen({super.key});

  @override
  State<ThematicGuidanceScreen> createState() => _ThematicGuidanceScreenState();
}

class _ThematicGuidanceScreenState extends State<ThematicGuidanceScreen> {
  final ThematicGuidanceService _guidanceService = ThematicGuidanceService();

  List<BibleVerseModel> _verses = [];
  bool _loading = false;
  String? _selectedTheme;
  String? _themeSummary;

  final List<String> _themes = [
    'Comfort', 'Anxiety', 'Forgiveness', 'Grace', 'Purpose', 'Doubt', 'Strength',
    'Weakness', 'Patience', 'Perseverance', 'Guidance', 'Wisdom', 'Hope', 'Future',
    'Love', 'Marriage', 'Parenting', 'Friendship', 'Loyalty', 'Conflict',
    'Serving Others', 'Community', 'Fellowship', 'Nature', 'Miracles', 'Role',
    'Power of Prayer', 'Faith', 'Financial Stewardship', 'Justice', 'Righteousness',
    'Honesty', 'Integrity', 'Temptation', 'Addiction', 'Redemption', 'Holy Spirit',
    'Mountains', 'Cities', 'Anger', 'Dragons', 'Advent', 'Covenants', 'Gospel', 'Witness',
  ];

  Future<void> _searchByTheme(String theme) async {
    setState(() {
      _loading = true;
      _selectedTheme = theme;
      _verses = [];
      _themeSummary = null;
    });

    try {
      final result = await _guidanceService.getThemeVerses(theme);
      setState(() {
        _verses = result.verses;
        _themeSummary = result.summary;
        _loading = false;
      });
    } catch (e) {
      Log.d('❌ Search error: $e');
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }


  Widget _buildThemeGrid() {
    // Modern gradient colors matching Explore tab
    final tileGradients = [
      const [Color(0xFF667eea), Color(0xFF764ba2)], // Purple/Blue
      const [Color(0xFFf093fb), Color(0xFFF5576C)], // Pink gradient
      const [Color(0xFF11998e), Color(0xFF38ef7d)], // Teal/Green
      const [Color(0xFF9C27B0), Color(0xFFBA68C8)], // Purple
      const [Color(0xFF4CAF50), Color(0xFF81C784)], // Green
      const [Color(0xFF5C6BC0), Color(0xFF7986CB)], // Indigo
      const [Color(0xFFFF8F00), Color(0xFFFFB300)], // Orange
      const [Color(0xFF7B1FA2), Color(0xFFAB47BC)], // Deep Purple
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemCount: _themes.length,
      itemBuilder: (context, index) {
        final theme = _themes[index];
        final isSelected = _selectedTheme == theme;
        final gradient = tileGradients[index % tileGradients.length];

        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _searchByTheme(theme),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isSelected ? 0.2 : 0.12),
                  blurRadius: isSelected ? 8 : 6,
                  offset: Offset(0, isSelected ? 4 : 3),
                ),
              ],
              border: isSelected
                  ? Border.all(color: Colors.white.withOpacity(0.3), width: 2)
                  : null,
            ),
            padding: const EdgeInsets.all(10),
            child: Center(
              child: Text(
                theme,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  height: 1.2,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showVerseActions(BibleVerseModel verse) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VerseActionsModal(verse: verse),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = _selectedTheme != null;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground, // Base background for frosted theme
      appBar: AppBar(
        backgroundColor: AppTheme.surface, // Frosted theme AppBar background
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light, // Ensure light status bar icons
        title: Text(
          hasSelection ? _selectedTheme! : 'Thematic Guidance',
          style: const TextStyle(color: AppTheme.onSurface), // Readable title text color
        ),
        iconTheme: const IconThemeData(color: AppTheme.onSurface), // Readable icon color
        leading: hasSelection
            ? IconButton(
                icon: const Icon(Icons.arrow_back), // Uses iconTheme color
                onPressed: () {
                  setState(() {
                    _selectedTheme = null;
                    _verses = [];
                    _themeSummary = null;
                  });
                },
              )
            : null,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Collapsible header - shrinks when theme is selected
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: hasSelection ? 0 : null,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: hasSelection ? 0 : 1,
              child: Column(
                children: [
                  // Hero header
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Row(
                          children: [
                            Icon(
                              Icons.explore_outlined,
                              color: Colors.white,
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Thematic Guidance',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Choose a theme below to discover biblical teachings about it.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Theme buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Card(
                      color: AppTheme.surface, // Use AppTheme.surface
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: AppTheme.onSurfaceVariant.withOpacity(0.1)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: SizedBox(
                          height: 500,
                          child: SingleChildScrollView(
                            child: _buildThemeGrid(),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Results section (summary + verses)
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryTeal),
                  )
                : _verses.isEmpty
                    ? const SizedBox.shrink()
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            // Theme Summary Card
                            if (_themeSummary != null && _themeSummary!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                child: Card(
                                  color: AppTheme.surface, // Use AppTheme.surface
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(color: AppTheme.primaryTeal.withOpacity(0.2)),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: const [
                                            Icon(Icons.auto_awesome, color: AppTheme.primaryTeal),
                                            SizedBox(width: 8),
                                            Text(
                                              'Theme Snapshot',
                                              style: TextStyle(
                                                color: AppTheme.onSurface, // Readable text color
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _themeSummary!,
                                          style: const TextStyle(
                                            color: AppTheme.onSurfaceVariant, // Readable text color
                                            height: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                            // Verses List
                            Padding(
                              padding: const EdgeInsets.only(bottom: 40),
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                itemCount: _verses.length,
                                itemBuilder: (context, index) {
                                  final verse = _verses[index];
                                  return _buildVerseCard(verse);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerseCard(BibleVerseModel verse) {
    return Card(
      color: AppTheme.surface, // Use AppTheme.surface
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.onSurfaceVariant.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: () => _showVerseActions(verse),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reference
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryTeal.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  verse.reference,
                  style: const TextStyle(
                    color: AppTheme.primaryTeal,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Verse text
              Text(
                verse.text,
                style: const TextStyle(
                  color: AppTheme.onSurfaceVariant, // Readable text color
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}