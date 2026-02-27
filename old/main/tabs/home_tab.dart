// In lib/screens/main/tabs/home_tab.dart

import 'package:flutter/material.dart';
import 'package:faithfeed/services/logger_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/post_model.dart';
import '../../../models/story_model.dart';
import '../../../services/post_service.dart';
import '../../../services/daily_verse_service.dart';
import '../../../services/story_service.dart';
import '../../../services/mock_data_service.dart';
import '../../../services/user_profile_service.dart';
import '../../../widgets/enhanced_post_card.dart';
import '../../../widgets/daily_verse_card.dart';
import '../../../theme/app_theme.dart';
import '../create_post_modal.dart';
import '../../stories/create_story_screen.dart';
import '../../stories/story_viewer_screen.dart';

// NEW UX ENHANCEMENTS
import '../../../utils/ui_helpers.dart';
import '../../../widgets/skeleton_loading.dart';
import '../../../widgets/empty_states.dart';
import '../../../widgets/optimized_image.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final PostService _postService = PostService();
  final DailyVerseService _dailyVerseService = DailyVerseService();
  final StoryService _storyService = StoryService();
  List<Post>? _lfsPosts;
  bool _isLoadingPosts = false;

  @override
  void initState() {
    super.initState();
    // Load daily verse when tab loads
    _dailyVerseService.fetchDailyVerse();
    // Load LFS-ranked posts
    _loadLFSFeed();
  }

  Future<void> _loadLFSFeed() async {
    if (_isLoadingPosts) return;

    setState(() {
      _isLoadingPosts = true;
    });

    try {
      final posts = await _postService.getLFSFeedPosts(limit: 20);
      if (mounted) {
        setState(() {
          _lfsPosts = posts.isNotEmpty ? posts : MockDataService.getFeedPosts();
          _isLoadingPosts = false;
        });
      }
    } catch (e) {
      Log.e('loading LFS feed: $e');
      if (mounted) {
        setState(() {
          _lfsPosts = MockDataService.getFeedPosts();
          _isLoadingPosts = false;
        });
      }
    }
  }

  void _openCreatePostModal() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreatePostModal(),
    );

    // Refresh feed if a post was created
    if (result == true && mounted) {
      _loadLFSFeed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PullToRefreshWrapper(
        onRefresh: _loadLFSFeed,
        child: _isLoadingPosts && _lfsPosts == null
            ? ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                itemBuilder: (context, index) => const SkeletonPostCard(),
              )
            : CustomScrollView(
            slivers: [
              // Top spacing to prevent overlap with AppBar
              const SliverToBoxAdapter(
                child: SizedBox(height: 4),
              ),
              // Stories section
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 110,
                  child: StreamBuilder<List<Story>>(
                    stream: _storyService.getActiveStories(),
                    builder: (context, storySnapshot) {
                      if (storySnapshot.hasError) {
                        Log.d('## Reflection Stream Error: ${storySnapshot.error}');
                        return const Center(
                          child: Text(
                            'Could not load reflections.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      if (storySnapshot.connectionState == ConnectionState.waiting) {
                        // Show a loading indicator for reflections
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      final stories = (storySnapshot.data != null && storySnapshot.data!.isNotEmpty)
                          ? storySnapshot.data!
                          : MockDataService.getReflections();

                      return ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        children: [
                          _buildAddStory(user),
                          ...stories.map((story) => _buildStoryCircle(story, stories)),
                        ],
                      );
                    },
                  ),
                ),
              ),

              // Create post input section
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: AppTheme.primaryTeal.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryTeal.withValues(alpha: 0.15),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticHelper.light();
                            _openCreatePostModal();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.darkBackground,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTheme.primaryTeal.withValues(alpha: 0.6), // Light blue border
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: const Text(
                              'What\'s on your mind?',
                              style: TextStyle(
                                color: AppTheme.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.image_outlined, size: 22),
                        color: AppTheme.primaryBlue,
                        onPressed: () {
                          HapticHelper.light();
                          _openCreatePostModal();
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Add photo',
                      ),
                    ],
                  ),
                ),
              ),

              // Verse of the Day - Dynamic with actions
              SliverToBoxAdapter(
                child: ListenableBuilder(
                  listenable: _dailyVerseService,
                  builder: (context, child) {
                    return _dailyVerseService.currentVerse != null
                        ? DailyVerseCard(verse: _dailyVerseService.currentVerse!)
                        : const SizedBox.shrink();
                  },
                ),
              ),

              // Posts list (LFS-ranked)
              if (_lfsPosts == null || _lfsPosts!.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: EmptyPostsFeed(
                      onCreatePost: _openCreatePostModal,
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final post = _lfsPosts![index];
                      return EnhancedPostCard(post: post);
                    },
                    childCount: _lfsPosts!.length,
                  ),
                ),
            ],
          ),
      ),
    );
  }

  Widget _buildAddStory(User? user) {
    final profileService = Provider.of<UserProfileService>(context);
    final profileImageUrl = profileService.currentProfile?.profileImageUrl;
    final displayName = user?.displayName ?? '';
    final initial = displayName.isNotEmpty
        ? displayName.substring(0, 1).toUpperCase()
        : 'U';

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CreateStoryScreen(),
          ),
        );
        // Refresh reflections if a reflection was created
        if (result == true && mounted) {
          setState(() {});
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Container(
                  width: 70,
                  height: 75,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppTheme.surface,
                    border: Border.all(
                      color: AppTheme.primaryTeal.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: profileImageUrl != null && profileImageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: profileImageUrl,
                            cacheKey: profileImageUrl,
                            fit: BoxFit.cover,
                            width: 70,
                            height: 75,
                            placeholder: (context, url) => Center(
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  color: AppTheme.primaryTeal,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Center(
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  color: AppTheme.primaryTeal,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: AppTheme.primaryTeal,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                          ),
                  ),
                ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTeal,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            const Text(
              'Add Reflection',
              style: TextStyle(
                color: AppTheme.lightOnSurface,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryCircle(Story story, List<Story> allStories) {
    return GestureDetector(
      onTap: () {
        // Find the index of this reflection in the list
        final index = allStories.indexOf(story);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoryViewerScreen(
              stories: allStories,
              initialIndex: index,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryTeal,
                  width: 2.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: OptimizedImage(
                  imageUrl: story.imageUrl,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 3),
            SizedBox(
              width: 70,
              child: Text(
                story.userName,
                style: const TextStyle(
                  color: AppTheme.lightOnSurface,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
