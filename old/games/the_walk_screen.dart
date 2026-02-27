import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// The Walk - A narrative choice game where you play AS biblical characters
/// Making decisions that affect the story outcome and earn Faith Points
class TheWalkScreen extends StatefulWidget {
  const TheWalkScreen({super.key});

  @override
  State<TheWalkScreen> createState() => _TheWalkScreenState();
}

class _TheWalkScreenState extends State<TheWalkScreen>
    with TickerProviderStateMixin {
  String _currentScene = 'intro';
  int _faithPoints = 0;
  final List<Map<String, String>> _choices = [];
  bool _showVerse = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  late AnimationController _scrollIndicatorController;
  late Animation<double> _scrollIndicatorAnimation;
  final ScrollController _scrollController = ScrollController();
  bool _showScrollIndicator = true;

  // Story Data - Joseph and His Brothers
  late Map<String, StoryScene> _story;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _fadeController.forward();

    // Scroll indicator animation - bouncing effect
    _scrollIndicatorController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _scrollIndicatorAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(
        parent: _scrollIndicatorController,
        curve: Curves.easeInOut,
      ),
    );

    // Listen to scroll events to hide indicator
    _scrollController.addListener(_onScroll);

    _initializeStory();
  }

  void _onScroll() {
    if (_scrollController.offset > 50 && _showScrollIndicator) {
      setState(() {
        _showScrollIndicator = false;
      });
    } else if (_scrollController.offset <= 50 && !_showScrollIndicator) {
      setState(() {
        _showScrollIndicator = true;
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scrollIndicatorController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeStory() {
    _story = {
      'intro': StoryScene(
        title: "The Walk: Joseph's Test",
        image: '🌾',
        text: '''Twenty years have passed since your brothers sold you into slavery. Through God's grace, you rose from prisoner to governor of all Egypt.

Now, during the great famine, your brothers stand before you—not recognizing the brother they betrayed.

Simeon remains imprisoned as collateral. The others have returned with Benjamin, your youngest brother, just as you demanded.''',
        scripture: null,
        choices: [
          StoryChoice(text: 'Reveal yourself immediately', nextScene: 'reveal_early', faithPoints: 0),
          StoryChoice(text: 'Test their hearts first', nextScene: 'test_hearts', faithPoints: 10),
        ],
      ),
      
      'test_hearts': StoryScene(
        title: 'A Test of Character',
        image: '🏺',
        text: '''You order a feast for your brothers, giving Benjamin five times more than the others. You watch their faces carefully...

There is no jealousy. They seem genuinely happy for Benjamin.

But you must know if they have truly changed. You devise a final test: your silver cup will be hidden in Benjamin's sack.''',
        scripture: ScriptureReference(
          ref: 'Genesis 44:1-2',
          text: 'Then he commanded the steward of his house, saying, "Fill the men\'s sacks with food... and put my cup, the silver cup, in the mouth of the sack of the youngest."',
        ),
        choices: [
          StoryChoice(text: 'Proceed with the cup test', nextScene: 'cup_test', faithPoints: 5),
          StoryChoice(text: 'This is too cruel—reveal yourself now', nextScene: 'reveal_feast', faithPoints: 0),
        ],
      ),

      'cup_test': StoryScene(
        title: 'The Silver Cup',
        image: '🔍',
        text: '''Your steward catches them on the road. The cup is found in Benjamin's sack. Your brothers tear their clothes in grief and return to face you.

Judah—the very one who suggested selling you—steps forward. His words shake you to your core:

"How can we return without the boy? Let me remain as your slave instead of Benjamin, for if I return without him, I will kill my father with grief."''',
        scripture: ScriptureReference(
          ref: 'Genesis 44:33-34',
          text: 'Now therefore, please let your servant remain instead of the lad as a slave to my lord, and let the lad go up with his brothers.',
        ),
        choices: [
          StoryChoice(text: 'Accept Judah\'s offer as punishment', nextScene: 'accept_judah', faithPoints: -20),
          StoryChoice(text: 'Their repentance is genuine—reveal yourself', nextScene: 'reveal_full', faithPoints: 25),
        ],
      ),

      'reveal_early': StoryScene(
        title: 'Hasty Revelation',
        image: '😢',
        text: '''"I am Joseph!" you cry out. Your brothers stand frozen in terror, expecting vengeance.

But something feels incomplete. You've revealed yourself, but you don't truly know if their hearts have changed. The reconciliation feels hollow—built on their fear rather than genuine repentance.''',
        scripture: null,
        choices: [
          StoryChoice(text: 'Continue with reconciliation', nextScene: 'reconcile_early', faithPoints: 5),
        ],
      ),

      'reveal_feast': StoryScene(
        title: 'Mercy at the Feast',
        image: '💕',
        text: '''Watching them celebrate together, without jealousy, touches your heart. Perhaps this is enough.

"I am Joseph, your brother!" The words pour out before you can stop them. They stare in disbelief, then terror fills their eyes.

"Do not be afraid," you say quickly. "God sent me here to preserve life."''',
        scripture: ScriptureReference(
          ref: 'Genesis 45:5',
          text: 'Now, do not therefore be grieved or angry with yourselves because you sold me here; for God sent me before you to preserve life.',
        ),
        choices: [
          StoryChoice(text: 'Embrace your brothers', nextScene: 'ending_good', faithPoints: 15),
        ],
      ),

      'reveal_full': StoryScene(
        title: 'The Moment of Truth',
        image: '😭',
        text: '''Judah's willingness to sacrifice himself for Benjamin breaks you completely. Tears stream down your face as you clear the room of all Egyptians.

"I am Joseph!" you weep. "Is my father still alive?"

Your brothers cannot answer—they are terrified. But you see it now: they are not the same men who threw you in that pit. Twenty years of guilt have transformed them.''',
        scripture: ScriptureReference(
          ref: 'Genesis 45:3-4',
          text: 'Then Joseph said to his brothers, "I am Joseph; does my father still live?" But his brothers could not answer him, for they were dismayed in his presence.',
        ),
        choices: [
          StoryChoice(text: 'Comfort your brothers', nextScene: 'comfort', faithPoints: 20),
        ],
      ),

      'accept_judah': StoryScene(
        title: 'A Bitter Choice',
        image: '⛓️',
        text: '''You accept Judah's offer. He remains as your slave while the others return home.

But as you watch them leave, emptiness fills your heart. Revenge has not healed the wound—it has only deepened it. Your father will still lose a son. The cycle of pain continues.''',
        scripture: ScriptureReference(
          ref: 'Romans 12:19',
          text: 'Beloved, do not avenge yourselves, but rather give place to wrath; for it is written, "Vengeance is Mine, I will repay," says the Lord.',
        ),
        choices: [
          StoryChoice(text: 'Call them back', nextScene: 'reveal_full', faithPoints: 10),
          StoryChoice(text: 'Let them go', nextScene: 'ending_bitter', faithPoints: -10),
        ],
      ),

      'comfort': StoryScene(
        title: 'Reconciliation',
        image: '🤗',
        text: '''"Come close to me," you say gently. "I am Joseph, your brother, whom you sold into Egypt. Do not be distressed. Do not be angry with yourselves. It was not you who sent me here, but God."

You embrace Benjamin first, then Judah, then each brother in turn. Decades of pain dissolve in tears of forgiveness.''',
        scripture: ScriptureReference(
          ref: 'Genesis 45:14-15',
          text: 'Then he fell on his brother Benjamin\'s neck and wept, and Benjamin wept on his neck. Moreover he kissed all his brothers and wept over them, and after that his brothers talked with him.',
        ),
        choices: [
          StoryChoice(text: 'Complete your journey', nextScene: 'ending_perfect', faithPoints: 25),
        ],
      ),

      'reconcile_early': StoryScene(
        title: 'An Uneasy Peace',
        image: '🕊️',
        text: '''Your brothers accept your forgiveness, but uncertainty lingers. Without seeing their transformation firsthand, doubts remain on both sides.

Still, you send for your father, and the family is reunited. It is good—but it could have been greater.''',
        scripture: null,
        choices: [
          StoryChoice(text: 'See your results', nextScene: 'ending_okay', faithPoints: 5),
        ],
      ),

      // ENDINGS
      'ending_perfect': StoryScene(
        title: 'Perfect Ending',
        image: '✨',
        text: '''You bring your entire family to Egypt—70 souls in all. Your father Jacob, now 130 years old, finally holds his lost son again.

"It is enough," Israel says. "Joseph my son is still alive. I will go and see him before I die."

You have learned the deepest truth: what others meant for evil, God intended for good. Forgiveness has made you—and your family—whole.''',
        scripture: ScriptureReference(
          ref: 'Genesis 50:20',
          text: 'But as for you, you meant evil against me; but God meant it for good, in order to bring it about as it is this day, to save many people alive.',
        ),
        choices: [],
        isEnding: true,
        endingMessage: 'You have walked the path of wisdom and grace. Joseph\'s story teaches us that forgiveness, tested and proven, brings the deepest healing.',
      ),

      'ending_good': StoryScene(
        title: 'Good Ending',
        image: '🌅',
        text: '''Your family is reunited in Egypt. The famine passes, and your father lives out his remaining years in peace.

Though you wonder sometimes what might have been if you had tested your brothers' hearts more thoroughly, the joy of reconciliation overwhelms any doubts.''',
        scripture: ScriptureReference(
          ref: 'Colossians 3:13',
          text: 'Bearing with one another, and forgiving one another, if anyone has a complaint against another; even as Christ forgave you, so you also must do.',
        ),
        choices: [],
        isEnding: true,
        endingMessage: 'You showed mercy—perhaps hastily, but mercy nonetheless. God honors a forgiving heart.',
      ),

      'ending_okay': StoryScene(
        title: 'Bittersweet Ending',
        image: '🌤️',
        text: '''Your family reunites, but shadows remain. Your brothers always seem slightly on edge around you, never quite sure of your full forgiveness.

The reconciliation is real, but incomplete. Some wounds take longer to heal when we rush past the process.''',
        scripture: ScriptureReference(
          ref: 'James 1:4',
          text: 'But let patience have its perfect work, that you may be perfect and complete, lacking nothing.',
        ),
        choices: [],
        isEnding: true,
        endingMessage: 'Healing takes time. Sometimes the longer path leads to deeper restoration.',
      ),

      'ending_bitter': StoryScene(
        title: 'Tragic Ending',
        image: '🌑',
        text: '''Judah serves as your slave. Your brothers return home in shame. Your father dies of grief, never knowing his son Joseph still lives.

You have all the power in Egypt, but your heart is hollow. Revenge has cost you everything that truly mattered.''',
        scripture: ScriptureReference(
          ref: 'Hebrews 12:15',
          text: 'Looking carefully lest anyone fall short of the grace of God; lest any root of bitterness springing up cause trouble, and by this many become defiled.',
        ),
        choices: [],
        isEnding: true,
        endingMessage: 'Unforgiveness imprisons the one who holds it. Joseph\'s true power was not his position—it was his capacity to forgive.',
      ),
    };
  }

  void _handleChoice(StoryChoice choice) {
    setState(() {
      _faithPoints += choice.faithPoints;
      _choices.add({'scene': _currentScene, 'choice': choice.text});
      _showVerse = false;
    });

    _fadeController.reverse().then((_) {
      setState(() {
        _currentScene = choice.nextScene;
        _showScrollIndicator = true; // Reset indicator for new scene
      });
      _fadeController.forward();
      // Scroll to top of new scene
      _scrollController.jumpTo(0);
    });
  }

  void _resetGame() {
    setState(() {
      _currentScene = 'intro';
      _faithPoints = 0;
      _choices.clear();
      _showVerse = false;
      _showScrollIndicator = true; // Reset indicator
    });
    _fadeController.forward(from: 0);
    _scrollController.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final scene = _story[_currentScene]!;

    return Scaffold(
      backgroundColor: const Color(0xFF1a1510),
      appBar: AppBar(
        title: const Text('The Walk'),
        backgroundColor: const Color(0xFF2d2318),
        foregroundColor: const Color(0xFFD4B896),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF8B4513).withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF8B4513)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('✝️', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  '$_faithPoints FP',
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: Column(
            children: [
              // Scene Icon
              Text(
                scene.image,
                style: const TextStyle(fontSize: 64),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                scene.title,
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Story Text
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8D4A8).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF8B4513).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  scene.text,
                  style: const TextStyle(
                    color: Color(0xFFD4B896),
                    fontSize: 16,
                    height: 1.8,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Scripture Reference
              if (scene.scripture != null)
                GestureDetector(
                  onTap: () => setState(() => _showVerse = !_showVerse),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                      border: const Border(
                        left: BorderSide(color: Color(0xFFFFD700), width: 3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '📖 ${scene.scripture!.ref}',
                              style: const TextStyle(
                                color: Color(0xFFFFD700),
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              _showVerse ? 'tap to hide' : 'tap to read',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        if (_showVerse) ...[
                          const SizedBox(height: 12),
                          Text(
                            '"${scene.scripture!.text}"',
                            style: const TextStyle(
                              color: Color(0xFFE8D4A8),
                              fontSize: 15,
                              fontStyle: FontStyle.italic,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Ending Screen
              if (scene.isEnding) ...[
                _buildEndingScreen(scene),
              ] else ...[
                // Choice Buttons
                Text(
                  'WHAT DO YOU DO?',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                ...scene.choices.map((choice) => _buildChoiceButton(choice)),
              ],

              // Journey Progress
              if (!scene.isEnding && _choices.isNotEmpty) ...[
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.only(top: 20),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: const Color(0xFF8B4513).withOpacity(0.3),
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YOUR PATH',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _choices.asMap().entries.map((entry) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B4513).withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${entry.key + 1}. ${entry.value['choice']!.length > 20 ? '${entry.value['choice']!.substring(0, 20)}...' : entry.value['choice']}',
                              style: const TextStyle(
                                color: Color(0xFF8B7355),
                                fontSize: 11,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
              ),
            ),

            // Scroll indicator - modern bouncing chevron
            if (_showScrollIndicator && !scene.isEnding)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  opacity: _showScrollIndicator ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _scrollIndicatorAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _scrollIndicatorAnimation.value),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B4513).withOpacity(0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFD700).withOpacity(0.3),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFFFFD700),
                              size: 32,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceButton(StoryChoice choice) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleChoice(choice),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF8B4513).withOpacity(0.6),
                  const Color(0xFF5D3A1A).withOpacity(0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF8B4513)),
            ),
            child: Row(
              children: [
                Text(
                  '▸',
                  style: TextStyle(
                    color: const Color(0xFFE8D4A8).withOpacity(0.6),
                    fontSize: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    choice.text,
                    style: const TextStyle(
                      color: Color(0xFFE8D4A8),
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEndingScreen(StoryScene scene) {
    Color scoreColor;
    if (_faithPoints >= 50) {
      scoreColor = Colors.green;
    } else if (_faithPoints >= 20) {
      scoreColor = Colors.amber;
    } else {
      scoreColor = Colors.red;
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: scoreColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Text(
                'FINAL FAITH POINTS',
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$_faithPoints',
                style: TextStyle(
                  color: scoreColor,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          scene.endingMessage ?? '',
          style: const TextStyle(
            color: Color(0xFFD4B896),
            fontSize: 15,
            fontStyle: FontStyle.italic,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _resetGame,
              icon: const Icon(Icons.refresh),
              label: const Text('Walk Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B4513),
                foregroundColor: const Color(0xFFE8D4A8),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFFD4B896)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () {
                // Share functionality
                final text = '🚶 The Walk: Joseph\'s Test\n\n${scene.title}\nFaith Points: $_faithPoints\n\nPlay on FaithFeed!';
                // You can implement sharing here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Results copied to clipboard!')),
                );
              },
              icon: const Icon(Icons.share),
              label: const Text('Share'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF8B7355),
                side: const BorderSide(color: Color(0xFF5D3A1A)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Data Models
class StoryScene {
  final String title;
  final String image;
  final String text;
  final ScriptureReference? scripture;
  final List<StoryChoice> choices;
  final bool isEnding;
  final String? endingMessage;

  const StoryScene({
    required this.title,
    required this.image,
    required this.text,
    this.scripture,
    required this.choices,
    this.isEnding = false,
    this.endingMessage,
  });
}

class StoryChoice {
  final String text;
  final String nextScene;
  final int faithPoints;

  const StoryChoice({
    required this.text,
    required this.nextScene,
    required this.faithPoints,
  });
}

class ScriptureReference {
  final String ref;
  final String text;

  const ScriptureReference({
    required this.ref,
    required this.text,
  });
}
