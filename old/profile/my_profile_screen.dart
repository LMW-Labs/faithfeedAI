import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/user_profile_service.dart';
import '../../services/post_service.dart';
import '../../services/friends_service.dart';
import '../../services/prayer_service.dart';
import '../../models/post_model.dart';
import '../../widgets/enhanced_post_card.dart';
import '../../utils/date_formatter.dart';
import '../main/edit_profile_screen.dart';
import '../main/account_settings_screen.dart';
import 'user_friends_list_screen.dart';

/// My Profile Screen
///
/// Displays the current user's personal profile in a nice visual format
/// Similar to UserProfileViewScreen but for viewing your own profile
class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PostService _postService = PostService();
  final FriendsService _friendsService = FriendsService();
  final PrayerService _prayerService = PrayerService();

  // Profile stats
  int _postCount = 0;
  int _friendsCount = 0;
  int _prayersCount = 0;

  // Activity stats
  int _prayersOfferedCount = 0;
  int _verseSharesCount = 0;
  int _commentsCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load profile data and stats
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileService = Provider.of<UserProfileService>(context, listen: false);
      profileService.fetchUserProfile();
      _loadProfileStats();
    });
  }

  Future<void> _loadProfileStats() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.user?.uid;
    if (userId == null) return;

    final results = await Future.wait([
      _postService.getUserPostCount(userId),
      _friendsService.getFriendsCount(userId),
      _prayerService.getUserPrayerRequestCount(userId),
      _prayerService.getUserPrayersOfferedCount(userId),
      _postService.getUserVerseShareCount(userId),
      _postService.getUserCommentCount(userId),
    ]);

    if (mounted) {
      setState(() {
        _postCount = results[0];
        _friendsCount = results[1];
        _prayersCount = results[2];
        _prayersOfferedCount = results[3];
        _verseSharesCount = results[4];
        _commentsCount = results[5];
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final profileService = Provider.of<UserProfileService>(context);
    final profile = profileService.currentProfile;
    final userId = authService.user?.uid;

    // Only show loading if we don't have a profile yet and are actively loading
    if (profile == null && profileService.isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.darkBackground,
        appBar: AppBar(
          title: const Text('My Profile'),
          backgroundColor: AppTheme.surface,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryTeal),
        ),
      );
    }

    if (profile == null) {
      return Scaffold(
        backgroundColor: AppTheme.darkBackground,
        appBar: AppBar(
          title: const Text('My Profile'),
          backgroundColor: AppTheme.surface,
        ),
        body: const Center(
          child: Text(
            'Unable to load profile',
            style: TextStyle(color: AppTheme.onSurfaceVariant),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE8E8E8), // Heavenly white at top
              Color(0xFF0A0A0A), // Dark black at bottom
            ],
            stops: [0.0, 0.5],
          ),
        ),
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 360,
                floating: false,
                pinned: true,
                backgroundColor: AppTheme.surface,
                foregroundColor: Colors.black,
                forceElevated: innerBoxIsScrolled,
                elevation: innerBoxIsScrolled ? 4 : 0,
                centerTitle: true,
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    size: 32,
                    weight: 700,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildProfileHeader(profile),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(
                      Icons.settings,
                      size: 32,
                      weight: 700,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AccountSettingsScreen(),
                        ),
                      );
                    },
                    tooltip: 'Account Settings',
                  ),
                ],
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    labelColor: AppTheme.primaryTeal,
                    unselectedLabelColor: AppTheme.onSurfaceVariant,
                    indicatorColor: AppTheme.primaryTeal,
                    tabs: const [
                      Tab(text: 'Posts'),
                      Tab(text: 'Activity'),
                      Tab(text: 'About'),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildPostsTab(userId),
              _buildActivityTab(profile),
              _buildAboutTab(profile),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openEditProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EditProfileScreen(),
      ),
    );
    if (!mounted) return;
    final profileService = Provider.of<UserProfileService>(context, listen: false);
    await profileService.fetchUserProfile();
    _loadProfileStats();
  }

  Widget _buildProfileHeader(UserProfileData profile) {
    final hasAvatar = profile.profileImageUrl.isNotEmpty;
    debugPrint('🔍 [MyProfileScreen] Building header with profileImageUrl: ${profile.profileImageUrl}');
    debugPrint('🔍 [MyProfileScreen] hasAvatar: $hasAvatar');

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate the midpoint where avatar center would be
        // Avatar is 100px, positioned after SafeArea + 8px gap
        // We want the split line at roughly the center of the avatar
        final splitPosition = 110.0; // Approximately where avatar center is

        return Stack(
          children: [
            // TOP HALF: Swirled 3-color gradient with frosted glass
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: splitPosition,
              child: ClipRect(
                child: Stack(
                  children: [
                    // Base swirled gradient with 3 colors
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(-1.0, -1.0),
                          end: Alignment(1.0, 1.0),
                          colors: [
                            Color(0xFF6366F1), // Indigo/Purple
                            Color(0xFF3B82F6), // Blue
                            Color(0xFF14B8A6), // Teal
                          ],
                          stops: [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                    // Secondary swirl overlay for more depth
                    Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(-0.5, -0.3),
                          radius: 1.5,
                          colors: [
                            const Color(0xFF8B5CF6).withAlpha(150), // Violet
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    // Third color swirl
                    Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0.7, 0.2),
                          radius: 1.2,
                          colors: [
                            const Color(0xFF06B6D4).withAlpha(120), // Cyan
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    // Frosted glass overlay
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(40),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withAlpha(60),
                              Colors.white.withAlpha(20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // BOTTOM HALF: Current dark color with user banner option
            Positioned(
              top: splitPosition,
              left: 0,
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: () => _showBannerOptions(profile),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.darkBackground,
                    image: profile.bannerImageUrl != null && profile.bannerImageUrl!.isNotEmpty
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(profile.bannerImageUrl!),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                              Colors.black.withAlpha(77),
                              BlendMode.darken,
                            ),
                          )
                        : null,
                  ),
                  child: null, // No placeholder icon - keep area clean
                ),
              ),
            ),

            // Soft blend between top and bottom sections
            Positioned(
              top: splitPosition - 30,
              left: 0,
              right: 0,
              height: 60,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppTheme.darkBackground.withAlpha(200),
                    ],
                  ),
                ),
              ),
            ),

            // Main content - positioned at top just under app bar
            Positioned.fill(
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    const SizedBox(height: 8), // Small gap under app bar

                    // Profile Image - centered on the split line
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.darkBackground,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(80),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: hasAvatar
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: profile.profileImageUrl,
                                cacheKey: profile.profileImageUrl,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: 100,
                                  height: 100,
                                  color: AppTheme.darkGrey,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: AppTheme.primaryTeal,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) {
                                  debugPrint('🔍 [MyProfileScreen] CachedNetworkImage ERROR for url: $url');
                                  debugPrint('🔍 [MyProfileScreen] Error: $error');
                                  return Container(
                                    width: 100,
                                    height: 100,
                                    color: AppTheme.darkGrey,
                                    child: const Icon(Icons.person, size: 50, color: AppTheme.onSurfaceVariant),
                                  );
                                },
                              ),
                            )
                          : CircleAvatar(
                              radius: 50,
                              backgroundColor: AppTheme.darkGrey,
                              child: const Icon(Icons.person, size: 50, color: AppTheme.onSurfaceVariant),
                            ),
                    ),
                    const SizedBox(height: 10),

                    // Display Name
                    Text(
                      profile.displayName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Edit Profile Button (below headline)
                    ElevatedButton.icon(
                      onPressed: _openEditProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit Profile'),
                    ),
                    const SizedBox(height: 6),

                    // Username
                    if (profile.username != null && profile.username!.isNotEmpty)
                      Text(
                        '@${profile.username}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    const SizedBox(height: 6),

                    // Bio with expand/collapse (headline)
                    if (profile.bio.isNotEmpty)
                      _ExpandableBio(bio: profile.bio),

                    const Spacer(),

                    // Stats Row at bottom - tappable stats
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: _buildTappableStatItem(
                              'Posts',
                              '$_postCount',
                              onTap: () {
                                // Switch to Posts tab
                                _tabController.animateTo(0);
                              },
                            ),
                          ),
                          Expanded(
                            child: _buildTappableStatItem(
                              'Friends',
                              '$_friendsCount',
                              onTap: () {
                                final authService = Provider.of<AuthService>(context, listen: false);
                                final profileService = Provider.of<UserProfileService>(context, listen: false);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UserFriendsListScreen(
                                      userId: authService.user?.uid ?? '',
                                      userName: profileService.currentProfile?.displayName ?? 'My',
                                      isOwnProfile: true,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          Expanded(
                            child: _buildTappableStatItem(
                              'Prayer Requests',
                              '$_prayersCount',
                              onTap: () {
                                // Switch to Activity tab which shows prayer stats
                                _tabController.animateTo(1);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showBannerOptions(UserProfileData profile) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.onSurfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.primaryTeal),
              title: const Text(
                'Choose from gallery',
                style: TextStyle(color: AppTheme.onSurface),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickBannerImage();
              },
            ),
            if (profile.bannerImageUrl != null && profile.bannerImageUrl!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppTheme.primaryCoral),
                title: const Text(
                  'Remove backdrop',
                  style: TextStyle(color: AppTheme.primaryCoral),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _removeBannerImage();
                },
              ),
            ListTile(
              leading: const Icon(Icons.close, color: AppTheme.onSurfaceVariant),
              title: const Text(
                'Cancel',
                style: TextStyle(color: AppTheme.onSurfaceVariant),
              ),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _pickBannerImage() async {
    final profileService = Provider.of<UserProfileService>(context, listen: false);

    try {
      // Pick image from gallery
      final image = await profileService.pickImageFromGallery();
      if (image == null) return;

      // Upload the selected image
      final imageUrl = await profileService.uploadBannerImage(image);
      if (imageUrl != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backdrop updated!'),
            backgroundColor: AppTheme.primaryTeal,
          ),
        );
        profileService.fetchUserProfile();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload backdrop: $e'),
            backgroundColor: AppTheme.primaryCoral,
          ),
        );
      }
    }
  }

  Future<void> _removeBannerImage() async {
    final profileService = Provider.of<UserProfileService>(context, listen: false);

    try {
      await profileService.deleteBannerImage();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backdrop removed'),
            backgroundColor: AppTheme.primaryTeal,
          ),
        );
        profileService.fetchUserProfile();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove backdrop: $e'),
            backgroundColor: AppTheme.primaryCoral,
          ),
        );
      }
    }
  }

  Widget _buildTappableStatItem(String label, String value, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsTab(String? userId) {
    if (userId == null) {
      return const Center(
        child: Text(
          'Not logged in',
          style: TextStyle(color: AppTheme.onSurfaceVariant),
        ),
      );
    }

    return StreamBuilder<List<Post>>(
      stream: _postService.getUserPosts(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryTeal),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading posts',
              style: const TextStyle(color: AppTheme.onSurfaceVariant),
            ),
          );
        }

        final posts = snapshot.data ?? [];

        if (posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.post_add,
                  size: 64,
                  color: AppTheme.onSurfaceVariant.withAlpha(128),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No posts yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Share your first post with the community',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            return EnhancedPostCard(post: posts[index]);
          },
        );
      },
    );
  }

  /// Format date string to "October 1, 2025" format
  String _formatDateString(String dateStr) {
    // Use centralized date formatter for app-wide consistency
    // Format: "Oct 1, 2025" (short month name)
    return DateFormatter.formatDateString(dateStr);
  }

  Widget _buildActivityTab(UserProfileData profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildActivitySection(
            'Spiritual Journey',
            [
              if (profile.baptized)
                _buildActivityItem(Icons.water_drop, 'Baptized', 'Yes'),
              if (profile.faithJourneyStart != null && profile.faithJourneyStart!.isNotEmpty)
                _buildActivityItem(Icons.calendar_today, 'Faith Journey Started', _formatDateString(profile.faithJourneyStart!)),
              if (profile.currentReadingPlan.isNotEmpty)
                _buildActivityItem(Icons.menu_book, 'Current Reading Plan', profile.currentReadingPlan),
              if (profile.prayerStyle.isNotEmpty)
                _buildActivityItem(Icons.self_improvement, 'Prayer Style', profile.prayerStyle),
            ],
          ),
          const SizedBox(height: 24),

          _buildActivitySection(
            'Favorite Verses',
            profile.favoriteVerses.map((verse) {
              return _buildActivityItem(Icons.favorite, 'Favorite', verse);
            }).toList(),
          ),

          const SizedBox(height: 24),

          _buildActivitySection(
            'Statistics',
            [
              _buildActivityItem(Icons.volunteer_activism, 'Prayer Requests', '$_prayersCount'),
              _buildActivityItem(Icons.church, 'Prayers Offered', '$_prayersOfferedCount'),
              _buildActivityItem(Icons.share, 'Verses Shared', '$_verseSharesCount'),
              _buildActivityItem(Icons.comment, 'Comments', '$_commentsCount'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySection(String title, List<Widget> items) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surface.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.surface.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: items,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryTeal),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurface,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutTab(UserProfileData profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personal Information
          _buildAboutSection(
            'Personal Information',
            [
              if (profile.showFullName && profile.firstName.isNotEmpty)
                _buildInfoRow(Icons.person, 'Name', '${profile.firstName} ${profile.lastName}'),
              if (profile.email.isNotEmpty)
                _buildInfoRow(Icons.email, 'Email', profile.email),
              if (profile.username != null && profile.username!.isNotEmpty)
                _buildInfoRow(Icons.alternate_email, 'Username', '@${profile.username}'),
            ],
          ),
          const SizedBox(height: 24),

          // Location
          if (profile.showLocation && (profile.city.isNotEmpty || profile.state.isNotEmpty))
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAboutSection(
                  'Location',
                  [
                    if (profile.city.isNotEmpty || profile.state.isNotEmpty)
                      _buildInfoRow(Icons.location_on, 'Location', profile.location),
                    if (profile.showAddress && profile.address != null && profile.address!.isNotEmpty)
                      _buildInfoRow(Icons.home, 'Address', profile.address!),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),

          // Faith & Community
          _buildAboutSection(
            'Faith & Community',
            [
              if (profile.denomination.isNotEmpty)
                _buildInfoRow(Icons.church, 'Denomination', profile.denomination),
              if (profile.church.isNotEmpty)
                _buildInfoRow(Icons.location_city, 'Church', profile.church),
              if (profile.baptized)
                _buildInfoRow(Icons.water_drop, 'Baptized', 'Yes'),
            ],
          ),
          const SizedBox(height: 24),

          // My Testimony Button
          if (profile.testimony != null && profile.testimony!.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    _showTestimonyDialog(context, profile.testimony!);
                  },
                  icon: const Icon(Icons.auto_stories),
                  label: const Text('Read My Testimony'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),

          // Contact (if organization)
          if (profile.website != null && profile.website!.isNotEmpty ||
              profile.phoneNumber != null && profile.phoneNumber!.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAboutSection(
                  'Contact',
                  [
                    if (profile.website != null && profile.website!.isNotEmpty)
                      _buildInfoRow(Icons.language, 'Website', profile.website!),
                    if (profile.showPhone && profile.phoneNumber != null && profile.phoneNumber!.isNotEmpty)
                      _buildInfoRow(Icons.phone, 'Phone', profile.phoneNumber!),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),

          // Social Links
          if (profile.socialLinks.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAboutSection(
                  'Social Media',
                  profile.socialLinks.map((link) {
                    return _buildInfoRow(Icons.link, 'Link', link);
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(String title, List<Widget> items) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surface.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.surface.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: items,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryTeal),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.onSurface,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  void _showTestimonyDialog(BuildContext context, String testimony) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Row(
          children: [
            Icon(Icons.auto_stories, color: AppTheme.primaryTeal),
            SizedBox(width: 12),
            Text(
              'My Testimony',
              style: TextStyle(color: AppTheme.onSurface),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            testimony,
            style: const TextStyle(
              color: AppTheme.onSurface,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: AppTheme.primaryTeal),
            ),
          ),
        ],
      ),
    );
  }
}

// Tab bar delegate for sticky tabs
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppTheme.darkBackground,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}

// Expandable Bio Widget
class _ExpandableBio extends StatefulWidget {
  final String bio;

  const _ExpandableBio({required this.bio});

  @override
  State<_ExpandableBio> createState() => _ExpandableBioState();
}

class _ExpandableBioState extends State<_ExpandableBio> {
  bool _isExpanded = false;
  static const int _maxExpandedChars = 450;

  String get _displayBio {
    if (!_isExpanded || widget.bio.length <= _maxExpandedChars) {
      return widget.bio;
    }

    final truncated = widget.bio.substring(0, _maxExpandedChars);
    final lastSpace = truncated.lastIndexOf(' ');
    final safeCutoff = lastSpace > 0 ? truncated.substring(0, lastSpace) : truncated;
    return '${safeCutoff.trim()}…';
  }

  @override
  Widget build(BuildContext context) {
    final shouldShowMore = widget.bio.length > 100;
    final isTruncated = widget.bio.length > _maxExpandedChars;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Text(
            _displayBio,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.onSurfaceVariant,
            ),
            maxLines: _isExpanded ? 12 : 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (shouldShowMore)
            GestureDetector(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _isExpanded ? 'less' : 'more...',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.primaryTeal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (_isExpanded && isTruncated)
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Text(
                'Bio truncated for display',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
