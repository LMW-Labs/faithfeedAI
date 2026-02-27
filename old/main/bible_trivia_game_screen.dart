import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:faithfeed/services/trivia_service.dart';
import 'package:faithfeed/services/premium_gate_service.dart';
import 'package:faithfeed/models/trivia_question_model.dart';
import 'package:faithfeed/theme/app_theme.dart';
import 'package:faithfeed/services/game_leaderboard_service.dart';
import 'package:faithfeed/services/game_instructions_service.dart';
import 'package:faithfeed/widgets/premium_badge.dart';
import 'package:faithfeed/widgets/premium_paywall.dart';
import 'package:provider/provider.dart';

class BibleTriviaGameScreen extends StatefulWidget {
  const BibleTriviaGameScreen({super.key});

  @override
  State<BibleTriviaGameScreen> createState() => _BibleTriviaGameScreenState();
}

class _BibleTriviaGameScreenState extends State<BibleTriviaGameScreen> {
  final TriviaService _triviaService = TriviaService();
  final ScrollController _scrollController = ScrollController();

  List<TriviaQuestion> _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  String? _selectedAnswer;
  bool _isLoading = false;
  bool _hasAnswered = false;
  bool _gameStarted = false;
  bool _gameFinished = false;

  @override
  void initState() {
    super.initState();
    // Show first-time instructions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showFirstTimeInstructions();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _showFirstTimeInstructions() async {
    await GameInstructionsService.showFirstTimeInstructions(
      context: context,
      gameId: 'bible_trivia',
      gameTitle: 'Bible Trivia Challenge',
      gameIcon: Icons.quiz,
      themeColor: AppTheme.primaryTeal,
      instructions: GameInstructions.bibleTriviaInstructions,
      footerText: 'Test your knowledge of Scripture!',
    );
  }

  Future<void> _startGame() async {
    // Check premium gate for trivia
    final gateService = Provider.of<PremiumGateService>(context, listen: false);
    final gateResult = await gateService.canAccess(PremiumGateService.bibleTrivia);

    if (!gateResult.allowed) {
      if (mounted) {
        showPremiumPaywall(
          context: context,
          featureName: 'Bible Trivia',
          featureDescription: 'Play unlimited trivia games and compete on the leaderboard.',
          featureIcon: Icons.quiz,
        );
      }
      return;
    }

    // Consume the use
    await gateService.consumeUse(PremiumGateService.bibleTrivia);

    setState(() {
      _isLoading = true;
      _gameStarted = true;
      _gameFinished = false;
      _currentQuestionIndex = 0;
      _score = 0;
      _selectedAnswer = null;
      _hasAnswered = false;
    });

    try {
      final questions = await _triviaService.getTriviaQuestions(count: 10);
      setState(() {
        _questions = questions;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _gameStarted = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load trivia: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _selectAnswer(String answer) {
    if (_hasAnswered) return;

    setState(() {
      _selectedAnswer = answer;
      _hasAnswered = true;

      if (answer == _questions[_currentQuestionIndex].correctAnswer) {
        _score++;
      }
    });

    // Auto-scroll to show the "Next Question" button
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = null;
        _hasAnswered = false;
      });
    } else {
      setState(() {
        _gameFinished = true;
      });
      // Record game result for leaderboard
      final percentage = (_score / _questions.length * 100).round();
      GameLeaderboardService().recordGameResult(
        gameType: 'bible_trivia',
        won: percentage >= 60, // Win if 60% or higher
        score: _score,
        guesses: _questions.length,
        metadata: {
          'percentage': percentage,
          'perfect': percentage == 100,
        },
      );
    }
  }

  Color _getAnswerColor(String answer) {
    if (!_hasAnswered) {
      return AppTheme.surface;
    }

    if (answer == _questions[_currentQuestionIndex].correctAnswer) {
      return AppTheme.mintGreen.withValues(alpha: 0.3);
    }

    if (answer == _selectedAnswer && answer != _questions[_currentQuestionIndex].correctAnswer) {
      return AppTheme.primaryCoral.withValues(alpha: 0.3);
    }

    return AppTheme.surface;
  }

  Color _getAnswerBorderColor(String answer) {
    if (!_hasAnswered) {
      return AppTheme.primaryTeal.withValues(alpha: 0.3);
    }

    if (answer == _questions[_currentQuestionIndex].correctAnswer) {
      return AppTheme.mintGreen;
    }

    if (answer == _selectedAnswer && answer != _questions[_currentQuestionIndex].correctAnswer) {
      return AppTheme.primaryCoral;
    }

    return AppTheme.primaryTeal.withValues(alpha: 0.3);
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
            'Bible Trivia Challenge',
            style: TextStyle(color: AppTheme.lightOnSurface),
          ),
          iconTheme: const IconThemeData(color: AppTheme.lightOnSurface),
          actions: [
          if (_gameStarted && !_gameFinished)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Score: $_score/${_questions.length}',
                    style: const TextStyle(
                      color: AppTheme.primaryTeal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (!_gameStarted) {
      return _buildWelcomeScreen();
    }

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryTeal),
            SizedBox(height: 16),
            Text(
              'Loading trivia questions...',
              style: TextStyle(color: AppTheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    if (_gameFinished) {
      return _buildResultsScreen();
    }

    if (_questions.isEmpty) {
      return const Center(
        child: Text(
          'No questions available',
          style: TextStyle(color: AppTheme.onSurfaceVariant),
        ),
      );
    }

    return _buildQuestionScreen();
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
              decoration: BoxDecoration(
                gradient: AppTheme.logoGradient,
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(
                'assets/bibletrivia.svg',
                width: 80,
                height: 80,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Test your knowledge of scripture with 10 questions',
              style: TextStyle(
                color: AppTheme.lightOnSurface,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Usage limit indicator for free users
            Consumer<PremiumGateService>(
              builder: (context, gateService, _) {
                if (gateService.isPremium) {
                  return const SizedBox.shrink();
                }
                return FutureBuilder<GateCheckResult>(
                  future: gateService.canAccess(PremiumGateService.bibleTrivia),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox.shrink();
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return const SizedBox.shrink();
                    }
                    final result = snapshot.data!;
                    return UsageLimitIndicator(
                      remaining: result.remainingUses ?? 0,
                      total: result.maxUses ?? 5,
                      label: '${result.remainingUses ?? 0}/${result.maxUses ?? 5} games today',
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _startGame,
                icon: const Icon(Icons.play_arrow),
                label: const Text(
                  'Start Game',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryTeal,
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

  Widget _buildQuestionScreen() {
    final question = _questions[_currentQuestionIndex];

    return Column(
      children: [
        // Progress bar
        LinearProgressIndicator(
          value: (_currentQuestionIndex + 1) / _questions.length,
          backgroundColor: AppTheme.surface,
          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryTeal),
          minHeight: 4,
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: 24 + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Question number
                Text(
                  'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                  style: TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Question card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryTeal.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    question.question,
                    style: const TextStyle(
                      color: AppTheme.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                // Answer options
                ...question.options.map((answer) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => _selectAnswer(answer),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _getAnswerColor(answer),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getAnswerBorderColor(answer),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  answer,
                                  style: const TextStyle(
                                    color: AppTheme.onSurface,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              if (_hasAnswered && answer == question.correctAnswer)
                                const Icon(
                                  Icons.check_circle,
                                  color: AppTheme.mintGreen,
                                ),
                              if (_hasAnswered &&
                                  answer == _selectedAnswer &&
                                  answer != question.correctAnswer)
                                const Icon(
                                  Icons.cancel,
                                  color: AppTheme.primaryCoral,
                                ),
                            ],
                          ),
                        ),
                      ),
                    )),
                if (_hasAnswered) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _nextQuestion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryTeal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _currentQuestionIndex < _questions.length - 1
                            ? 'Next Question'
                            : 'See Results',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsScreen() {
    final percentage = (_score / _questions.length * 100).round();
    String message;
    IconData icon;
    Color color;

    if (percentage >= 80) {
      message = 'Excellent! You really know your Bible!';
      icon = Icons.emoji_events;
      color = AppTheme.holyGold;
    } else if (percentage >= 60) {
      message = 'Great job! Keep studying the Word!';
      icon = Icons.thumb_up;
      color = AppTheme.primaryTeal;
    } else if (percentage >= 40) {
      message = 'Good effort! Keep learning!';
      icon = Icons.school;
      color = AppTheme.mintGreen;
    } else {
      message = 'Keep reading your Bible!';
      icon = Icons.menu_book;
      color = AppTheme.primaryCoral;
    }

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
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 80,
                color: color,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Game Complete!',
              style: TextStyle(
                color: AppTheme.onSurface,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your Score: $_score out of ${_questions.length}',
              style: const TextStyle(
                color: AppTheme.primaryTeal,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$percentage%',
              style: TextStyle(
                color: color,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                color: AppTheme.onSurfaceVariant,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _startGame,
                icon: const Icon(Icons.refresh),
                label: const Text(
                  'Play Again',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.home),
                label: const Text(
                  'Back to Games',
                  style: TextStyle(fontSize: 18),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryTeal,
                  side: const BorderSide(color: AppTheme.primaryTeal),
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
}
