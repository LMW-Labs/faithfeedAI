import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/app_theme.dart';
import '../../services/game_leaderboard_service.dart';
import '../../utils/lfs_utils.dart';

/// Weekly Game Leaderboard - Shows current week's top players
class WeeklyLeaderboardScreen extends StatefulWidget {
  const WeeklyLeaderboardScreen({super.key});

  @override
  State<WeeklyLeaderboardScreen> createState() => _WeeklyLeaderboardScreenState();
}

class _WeeklyLeaderboardScreenState extends State<WeeklyLeaderboardScreen>
    with SingleTickerProviderStateMixin {
  final GameLeaderboardService _leaderboardService = GameLeaderboardService();

  LeaderboardData? _leaderboardData;
  MyGameStats? _myStats;
  bool _isLoading = true;
  String? _error;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _leaderboardService.getWeeklyLeaderboard(limit: 50),
        _leaderboardService.getMyStats(),
      ]);

      setState(() {
        _leaderboardData = results[0] as LeaderboardData?;
        _myStats = results[1] as MyGameStats?;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load leaderboard: $e';
        _isLoading = false;
      });
    }
  }

  void _shareMyStats() {
    if (_myStats == null) return;

    final rank = _myStats!.rank;
    final stats = _myStats!.weeklyStats;
    final points = stats?.totalPoints ?? 0;
    final gamesPlayed = stats?.gamesPlayed ?? 0;

    String shareText;
    if (rank != null) {
      shareText = 'I\'m rank #$rank on the FaithFeed weekly leaderboard with $points points from $gamesPlayed games! Can you beat me? 🏆';
    } else {
      shareText = 'I\'m playing games on FaithFeed and climbing the leaderboard! Join me! 🏆';
    }

    Share.share(shareText);
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
            'Weekly Leaderboard',
            style: TextStyle(color: AppTheme.lightOnSurface),
          ),
          iconTheme: const IconThemeData(color: AppTheme.lightOnSurface),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.primaryTeal,
            labelColor: AppTheme.primaryTeal,
            unselectedLabelColor: AppTheme.lightOnSurfaceVariant,
            tabs: const [
              Tab(text: 'Rankings', icon: Icon(Icons.leaderboard)),
              Tab(text: 'My Stats', icon: Icon(Icons.person)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareMyStats,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
            ),
          ],
        ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRankingsTab(),
                    _buildMyStatsTab(),
                  ],
                ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppTheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: AppTheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingsTab() {
    if (_leaderboardData == null || _leaderboardData!.leaderboard.isEmpty) {
      return _buildEmptyLeaderboard();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: Column(
        children: [
          // Week info header
          _buildWeekHeader(),

          // Leaderboard list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _leaderboardData!.leaderboard.length,
              itemBuilder: (context, index) {
                final entry = _leaderboardData!.leaderboard[index];
                return _buildLeaderboardEntry(entry, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyLeaderboard() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_outlined, size: 80, color: AppTheme.onSurfaceVariant.withOpacity(0.5)),
          const SizedBox(height: 24),
          const Text(
            'No games played this week yet!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Be the first to get on the leaderboard.',
            style: TextStyle(color: AppTheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.videogame_asset),
            label: const Text('Play a Game'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryTeal,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekHeader() {
    final daysRemaining = _leaderboardData?.daysRemaining ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1a237e), Color(0xFF283593)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: Colors.amber, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This Week\'s Competition',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  daysRemaining == 1
                      ? 'Final day! Ends tomorrow'
                      : '$daysRemaining days remaining',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_leaderboardData?.leaderboard.length ?? 0} players',
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardEntry(LeaderboardEntry entry, int index) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isCurrentUser = entry.oderId == currentUserId;

    // Medal colors for top 3
    Color? medalColor;
    IconData? medalIcon;
    if (entry.rank == 1) {
      medalColor = Colors.amber;
      medalIcon = Icons.emoji_events;
    } else if (entry.rank == 2) {
      medalColor = Colors.grey[400];
      medalIcon = Icons.emoji_events;
    } else if (entry.rank == 3) {
      medalColor = Colors.brown[400];
      medalIcon = Icons.emoji_events;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppTheme.primaryTeal.withOpacity(0.2)
            : AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? Border.all(color: AppTheme.primaryTeal, width: 2)
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rank indicator
            SizedBox(
              width: 36,
              child: medalIcon != null
                  ? Icon(medalIcon, color: medalColor, size: 28)
                  : Text(
                      '#${entry.rank}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
            ),
            const SizedBox(width: 8),
            // Avatar
            CircleAvatar(
              radius: 22,
              backgroundColor: AppTheme.primaryTeal.withOpacity(0.3),
              backgroundImage: entry.photoURL != null
                  ? NetworkImage(entry.photoURL!)
                  : null,
              child: entry.photoURL == null
                  ? Text(
                      entry.displayName.isNotEmpty
                          ? entry.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: AppTheme.primaryTeal,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                entry.displayName,
                style: TextStyle(
                  fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w500,
                  color: AppTheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (entry.currentStreak >= 3)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department,
                        color: Colors.orange, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      '${entry.currentStreak}',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        subtitle: Text(
          '${entry.gamesWon}W / ${entry.gamesPlayed} games',
          style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${entry.totalPoints}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryTeal,
              ),
            ),
            const Text(
              'pts',
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyStatsTab() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return _buildSignInPrompt();
    }

    if (_myStats?.weeklyStats == null) {
      return _buildNoStatsYet();
    }

    final stats = _myStats!.weeklyStats!;
    final rank = _myStats!.rank;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Rank card
            _buildRankCard(rank, stats.totalPoints),
            const SizedBox(height: 16),

            // Stats grid
            Row(
              children: [
                Expanded(child: _buildStatCard('Games', '${stats.gamesPlayed}', Icons.videogame_asset)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Wins', '${stats.gamesWon}', Icons.check_circle)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildStatCard('Streak', '${stats.currentStreak}', Icons.local_fire_department)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Best', '${stats.bestStreak}', Icons.emoji_events)),
              ],
            ),

            const SizedBox(height: 24),

            // Game breakdown
            if (stats.gameBreakdown.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Game Breakdown',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...stats.gameBreakdown.entries.map((e) =>
                _buildGameBreakdownItem(e.key, e.value as Map<String, dynamic>)),
            ],

            const SizedBox(height: 24),

            // How points work
            _buildPointsExplainer(),
          ],
        ),
      ),
    );
  }

  Widget _buildSignInPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.account_circle, size: 80, color: AppTheme.onSurfaceVariant),
          const SizedBox(height: 16),
          const Text(
            'Sign in to track your stats',
            style: TextStyle(fontSize: 18, color: AppTheme.onSurface),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your game results will be saved\nand you can compete on the leaderboard!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildNoStatsYet() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports_esports, size: 80, color: AppTheme.onSurfaceVariant.withOpacity(0.5)),
          const SizedBox(height: 24),
          const Text(
            'No games played this week',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Play games to start earning points!',
            style: TextStyle(color: AppTheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Play Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryTeal,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankCard(int? rank, int points) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: rank != null && rank <= 3
              ? [Colors.amber.shade800, Colors.amber.shade600]
              : [AppTheme.primaryTeal.withOpacity(0.8), AppTheme.primaryTeal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (rank != null && rank <= 3 ? Colors.amber : AppTheme.primaryTeal)
                .withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Rank',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Text(
                rank != null ? '#$rank' : '--',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Total Points',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Text(
                '$points',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryTeal, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.onSurface,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameBreakdownItem(String gameType, Map<String, dynamic> data) {
    final gameNames = {
      'bible_connections': 'Bible Connections',
      'the_walk': 'The Walk',
      'bible_trivia': 'Bible Trivia',
      'disappearing_verse': 'Disappearing Verse',
      'daily_bread': 'Daily Bread',
    };

    final gameIcons = {
      'bible_connections': Icons.grid_view_rounded,
      'the_walk': Icons.directions_walk_rounded,
      'bible_trivia': Icons.quiz,
      'disappearing_verse': Icons.auto_stories,
      'daily_bread': Icons.breakfast_dining,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            gameIcons[gameType] ?? Icons.videogame_asset,
            color: AppTheme.primaryTeal,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gameNames[gameType] ?? gameType,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.onSurface,
                  ),
                ),
                Text(
                  '${data['won'] ?? 0}W / ${data['played'] ?? 0} played',
                  style: const TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${data['points'] ?? 0} pts',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryTeal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsExplainer() {
    return GestureDetector(
      onTap: () => LFSUtils.launchLFSPage(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.onSurfaceVariant.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: AppTheme.primaryTeal, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'How Points Work',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onSurface,
                  ),
                ),
                const Spacer(),
                const Text(
                  'Learn More',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primaryTeal,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildPointRule('Winning a game', '+10 pts'),
            _buildPointRule('Quick solve (< 30s)', '+3 pts'),
            _buildPointRule('Fewer guesses (1-2)', '+5 pts'),
            _buildPointRule('Perfect game', '+5 pts'),
            _buildPointRule('3-day streak', '+2 pts'),
            _buildPointRule('7-day streak', '+10 pts'),
            _buildPointRule('Playing (even losing)', '+2 pts'),
          ],
        ),
      ),
    );
  }

  Widget _buildPointRule(String description, String points) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13),
            ),
          ),
          Text(
            points,
            style: const TextStyle(
              color: AppTheme.primaryTeal,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
