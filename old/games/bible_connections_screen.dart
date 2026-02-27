import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'dart:math';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/app_theme.dart';
import '../../services/game_leaderboard_service.dart';
import '../../services/game_instructions_service.dart';
import '../../services/premium_gate_service.dart';
import '../../widgets/premium_badge.dart';
import '../../widgets/premium_paywall.dart';

/// Bible Connections - A word grouping game inspired by NYT Connections
/// Players must find 4 groups of 4 related biblical items
class BibleConnectionsScreen extends StatefulWidget {
  const BibleConnectionsScreen({super.key});

  @override
  State<BibleConnectionsScreen> createState() => _BibleConnectionsScreenState();
}

class _BibleConnectionsScreenState extends State<BibleConnectionsScreen>
    with TickerProviderStateMixin {
  late List<ConnectionGroup> _groups;
  late List<String> _shuffledWords;
  final Set<String> _selectedWords = {};
  final List<ConnectionGroup> _solvedGroups = [];
  int _mistakes = 0;
  bool _isChecking = false;
  bool _gameStarted = false;
  bool _gameComplete = false;
  int _currentPuzzleIndex = 0;
  bool _isLoading = true;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _successController;

  static const String _puzzleIndexKey = 'bible_connections_puzzle_index';

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _successController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Don't load the game immediately, wait for user to start
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _startGame() async {
    // Show first-time instructions
    await GameInstructionsService.showFirstTimeInstructions(
      context: context,
      gameId: 'bible_connections',
      gameTitle: 'Bible Connections',
      gameIcon: Icons.grid_view,
      themeColor: const Color(0xFF9C27B0),
      instructions: GameInstructions.bibleConnectionsInstructions,
      footerText: 'Look for what 4 items have in common!',
      buttonText: 'Start Playing',
    );
    _loadSavedProgress();
  }

  Future<void> _loadSavedProgress() async {
    setState(() => _isLoading = true);

    // Check premium gate for bible connections
    final gateService = Provider.of<PremiumGateService>(context, listen: false);
    final gateResult = await gateService.canAccess(PremiumGateService.bibleConnections);

    if (!gateResult.allowed) {
      if (mounted) {
        showPremiumPaywall(
          context: context,
          featureName: 'Bible Connections',
          featureDescription: 'Play unlimited connection puzzles and compete on the leaderboard.',
          featureIcon: Icons.grid_view,
        );
        Navigator.pop(context);
      }
      return;
    }

    // Consume the use
    await gateService.consumeUse(PremiumGateService.bibleConnections);

    final prefs = await SharedPreferences.getInstance();
    final savedIndex = prefs.getInt(_puzzleIndexKey) ?? 0;
    setState(() {
      _currentPuzzleIndex = savedIndex;
      _gameStarted = true;
      _isLoading = false;
    });
    _loadPuzzle();
  }

  Future<void> _savePuzzleIndex() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_puzzleIndexKey, _currentPuzzleIndex);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _successController.dispose();
    super.dispose();
  }

  void _loadPuzzle() {
    final puzzles = _getAllPuzzles();
    _groups = puzzles[_currentPuzzleIndex % puzzles.length];
    _shuffledWords = _groups.expand((g) => g.words).toList()..shuffle(Random());
    _selectedWords.clear();
    _solvedGroups.clear();
    _mistakes = 0;
    _gameComplete = false;
  }

  List<List<ConnectionGroup>> _getAllPuzzles() {
    return [
      // Puzzle 1: Biblical themes
      [
        ConnectionGroup(
          category: 'Jesus\' 12 Disciples',
          words: ['Peter', 'James', 'John', 'Matthew'],
          difficulty: 1,
          color: const Color(0xFFFFC107), // Yellow
        ),
        ConnectionGroup(
          category: 'Books of the Pentateuch',
          words: ['Genesis', 'Exodus', 'Leviticus', 'Numbers'],
          difficulty: 2,
          color: const Color(0xFF4CAF50), // Green
        ),
        ConnectionGroup(
          category: 'Fruits of the Spirit',
          words: ['Love', 'Joy', 'Peace', 'Patience'],
          difficulty: 3,
          color: const Color(0xFF2196F3), // Blue
        ),
        ConnectionGroup(
          category: 'Plagues of Egypt',
          words: ['Locusts', 'Darkness', 'Frogs', 'Boils'],
          difficulty: 4,
          color: const Color(0xFF9C27B0), // Purple
        ),
      ],
      // Puzzle 2: People and places
      [
        ConnectionGroup(
          category: 'Women of the Bible',
          words: ['Ruth', 'Esther', 'Mary', 'Sarah'],
          difficulty: 1,
          color: const Color(0xFFFFC107),
        ),
        ConnectionGroup(
          category: 'Kings of Israel',
          words: ['David', 'Solomon', 'Saul', 'Rehoboam'],
          difficulty: 2,
          color: const Color(0xFF4CAF50),
        ),
        ConnectionGroup(
          category: 'Cities Visited by Paul',
          words: ['Corinth', 'Ephesus', 'Philippi', 'Thessalonica'],
          difficulty: 3,
          color: const Color(0xFF2196F3),
        ),
        ConnectionGroup(
          category: 'Old Testament Prophets',
          words: ['Isaiah', 'Jeremiah', 'Ezekiel', 'Daniel'],
          difficulty: 4,
          color: const Color(0xFF9C27B0),
        ),
      ],
      // Puzzle 3: Events and symbols
      [
        ConnectionGroup(
          category: 'Jesus\' Miracles',
          words: ['Water to Wine', 'Feeding 5000', 'Walking on Water', 'Raising Lazarus'],
          difficulty: 1,
          color: const Color(0xFFFFC107),
        ),
        ConnectionGroup(
          category: 'Parables of Jesus',
          words: ['Prodigal Son', 'Good Samaritan', 'Mustard Seed', 'Lost Sheep'],
          difficulty: 2,
          color: const Color(0xFF4CAF50),
        ),
        ConnectionGroup(
          category: 'Items in the Tabernacle',
          words: ['Ark of Covenant', 'Menorah', 'Altar of Incense', 'Table of Showbread'],
          difficulty: 3,
          color: const Color(0xFF2196F3),
        ),
        ConnectionGroup(
          category: 'Armor of God (Eph 6)',
          words: ['Belt of Truth', 'Shield of Faith', 'Helmet of Salvation', 'Sword of Spirit'],
          difficulty: 4,
          color: const Color(0xFF9C27B0),
        ),
      ],
      // Puzzle 4: Numbers and more
      [
        ConnectionGroup(
          category: 'Sons of Jacob',
          words: ['Reuben', 'Judah', 'Benjamin', 'Joseph'],
          difficulty: 1,
          color: const Color(0xFFFFC107),
        ),
        ConnectionGroup(
          category: 'Gospel Writers',
          words: ['Matthew', 'Mark', 'Luke', 'John'],
          difficulty: 2,
          color: const Color(0xFF4CAF50),
        ),
        ConnectionGroup(
          category: 'Mountains in the Bible',
          words: ['Sinai', 'Ararat', 'Carmel', 'Zion'],
          difficulty: 3,
          color: const Color(0xFF2196F3),
        ),
        ConnectionGroup(
          category: 'Rivers in the Bible',
          words: ['Jordan', 'Euphrates', 'Nile', 'Tigris'],
          difficulty: 4,
          color: const Color(0xFF9C27B0),
        ),
      ],
    ];
  }

  void _toggleWord(String word) {
    if (_isChecking || _solvedGroups.any((g) => g.words.contains(word))) return;

    setState(() {
      if (_selectedWords.contains(word)) {
        _selectedWords.remove(word);
      } else if (_selectedWords.length < 4) {
        _selectedWords.add(word);
      }
    });
  }

  Future<void> _checkSelection() async {
    if (_selectedWords.length != 4 || _isChecking) return;

    setState(() => _isChecking = true);

    // Check if selected words match any unsolved group
    ConnectionGroup? matchedGroup;
    for (final group in _groups) {
      if (_solvedGroups.contains(group)) continue;

      final groupWords = group.words.toSet();
      if (groupWords.containsAll(_selectedWords) &&
          _selectedWords.containsAll(groupWords)) {
        matchedGroup = group;
        break;
      }
    }

    if (matchedGroup != null) {
      // Correct!
      await _successController.forward(from: 0);
      setState(() {
        _solvedGroups.add(matchedGroup!);
        _selectedWords.clear();

        if (_solvedGroups.length == 4) {
          _gameComplete = true;
          // Record game result for leaderboard
          GameLeaderboardService().recordGameResult(
            gameType: 'bible_connections',
            won: true,
            guesses: _mistakes + 4, // Total attempts = mistakes + 4 correct
            metadata: {'perfect': _mistakes == 0},
          );
        }
      });
    } else {
      // Wrong - check for "one away"
      int maxMatching = 0;
      for (final group in _groups) {
        if (_solvedGroups.contains(group)) continue;
        final matching = group.words.where((w) => _selectedWords.contains(w)).length;
        maxMatching = max(maxMatching, matching);
      }

      if (maxMatching == 3) {
        _showOneAwayMessage();
      }

      await _shakeController.forward(from: 0);
      setState(() {
        _mistakes++;
        _selectedWords.clear();

        // If 4 mistakes, record as loss
        if (_mistakes >= 4) {
          GameLeaderboardService().recordGameResult(
            gameType: 'bible_connections',
            won: false,
            guesses: _mistakes,
          );
        }
      });
    }

    setState(() => _isChecking = false);
  }

  void _showOneAwayMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.white),
            SizedBox(width: 8),
            Text('One away!'),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shuffleWords() {
    setState(() {
      final unsolvedWords = _shuffledWords
          .where((w) => !_solvedGroups.any((g) => g.words.contains(w)))
          .toList()
        ..shuffle(Random());

      final solvedWords = _shuffledWords
          .where((w) => _solvedGroups.any((g) => g.words.contains(w)))
          .toList();

      _shuffledWords = [...solvedWords, ...unsolvedWords];
    });
  }

  void _nextPuzzle() {
    setState(() {
      _currentPuzzleIndex++;
      _loadPuzzle();
    });
    _savePuzzleIndex();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.lightBackgroundGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          title: const Text(
            'Bible Connections',
            style: TextStyle(color: AppTheme.lightOnSurface),
          ),
          iconTheme: const IconThemeData(color: AppTheme.lightOnSurface),
          actions: [
            if (_gameStarted)
              IconButton(
                icon: const Icon(Icons.help_outline),
                onPressed: _showHelpDialog,
              ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF9C27B0)),
      );
    }

    if (!_gameStarted) {
      return _buildWelcomeScreen();
    }

    return _buildGameScreen();
  }

  Widget _buildWelcomeScreen() {
    return Center(
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: 24 + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(
                'assets/bibleconnections.svg',
                color: Colors.white,
                width: 80,
                height: 80,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Find groups of 4 items that share something in common.',
              style: TextStyle(
                color: AppTheme.onSurfaceVariant,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _startGame,
                icon: const Icon(Icons.play_arrow),
                label: const Text(
                  'Start Playing',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9C27B0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameScreen() {
    return Column(
      children: [
        // Mistakes indicator
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Mistakes: ',
                style: TextStyle(color: AppTheme.onSurfaceVariant),
              ),
              ...List.generate(4, (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < _mistakes
                        ? Colors.red
                        : AppTheme.surface,
                    border: Border.all(
                      color: i < _mistakes
                          ? Colors.red
                          : AppTheme.onSurfaceVariant,
                    ),
                  ),
                  child: i < _mistakes
                      ? const Icon(Icons.close, size: 16, color: Colors.white)
                      : null,
                ),
              )),
            ],
          ),
        ),

        // Solved groups
        ..._solvedGroups.map((group) => _buildSolvedGroup(group)),

        // Word grid
        Expanded(
          child: AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  sin(_shakeAnimation.value * pi * 4) * _shakeAnimation.value,
                  0,
                ),
                child: child,
              );
            },
            child: _buildWordGrid(),
          ),
        ),

        // Action buttons - fixed at bottom with safe area
        if (!_gameComplete)
          SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: BoxDecoration(
                color: AppTheme.darkBackground,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Theme(
                data: AppTheme.darkTheme.copyWith(
                  outlinedButtonTheme: OutlinedButtonThemeData(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _shuffleWords,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF9C27B0)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Shuffle'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _selectedWords.isEmpty
                            ? null
                            : () => setState(() => _selectedWords.clear()),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: _selectedWords.isEmpty
                                ? Colors.grey.shade700
                                : const Color(0xFF9C27B0),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Deselect'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _selectedWords.length == 4 ? _checkSelection : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedWords.length == 4
                              ? const Color(0xFF9C27B0)
                              : Colors.grey.shade800,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Submit'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Game complete
        if (_gameComplete) _buildGameComplete(),
      ],
    );
  }

  Widget _buildSolvedGroup(ConnectionGroup group) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: group.color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            group.category.toUpperCase(),
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            group.words.join(', '),
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWordGrid() {
    final unsolvedWords = _shuffledWords
        .where((w) => !_solvedGroups.any((g) => g.words.contains(w)))
        .toList();

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 1.5,
      ),
      itemCount: unsolvedWords.length,
      itemBuilder: (context, index) {
        final word = unsolvedWords[index];
        final isSelected = _selectedWords.contains(word);

        return GestureDetector(
          onTap: () => _toggleWord(word),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF2D2D3A), Color(0xFF3D3D4A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFFFD700)
                    : Colors.grey.shade700,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF9C27B0).withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Text(
                  word,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontSize: word.length > 10 ? 10 : 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGameComplete() {
    final score = 4 - _mistakes;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.celebration,
              size: 48,
              color: Color(0xFF9C27B0),
            ),
            const SizedBox(height: 16),
            const Text(
              'Puzzle Complete!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Score: $score/4 ⭐',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _nextPuzzle,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Next Puzzle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9C27B0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => Theme(
        data: AppTheme.lightTheme,
        child: AlertDialog(
          backgroundColor: AppTheme.lightSurface,
          title: const Text('How to Play'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Find groups of 4 items that share something in common.'),
              SizedBox(height: 12),
              Text('• Select 4 items and tap Submit'),
              Text('• You get 4 mistakes before the game ends'),
              Text('• Categories are color-coded by difficulty:'),
              SizedBox(height: 8),
              Row(children: [
                CircleAvatar(backgroundColor: Color(0xFFFFC107), radius: 8),
                SizedBox(width: 8),
                Text('Yellow - Easiest'),
              ]),
              Row(children: [
                CircleAvatar(backgroundColor: Color(0xFF4CAF50), radius: 8),
                SizedBox(width: 8),
                Text('Green - Easy'),
              ]),
              Row(children: [
                CircleAvatar(backgroundColor: Color(0xFF2196F3), radius: 8),
                SizedBox(width: 8),
                Text('Blue - Medium'),
              ]),
              Row(children: [
                CircleAvatar(backgroundColor: Color(0xFF9C27B0), radius: 8),
                SizedBox(width: 8),
                Text('Purple - Hardest'),
              ]),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it!'),
            ),
          ],
        ),
      ),
    );
  }
}

class ConnectionGroup {
  final String category;
  final List<String> words;
  final int difficulty; // 1-4
  final Color color;

  const ConnectionGroup({
    required this.category,
    required this.words,
    required this.difficulty,
    required this.color,
  });
}
