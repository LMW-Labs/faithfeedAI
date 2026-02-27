import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:faithfeed/services/logger_service.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/post_service.dart';
import '../../services/friends_service.dart';
import '../../models/post_model.dart';
import '../../widgets/enhanced_post_card.dart';
import 'user_friends_list_screen.dart';

class UserProfileViewScreen extends StatefulWidget {
  final String userId;

  const UserProfileViewScreen({
    super.key,
    required this.userId,
  });

  @override
  State<UserProfileViewScreen> createState() => _UserProfileViewScreenState();
}

class _UserProfileViewScreenState extends State<UserProfileViewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PostService _postService = PostService();
  final FriendsService _friendsService = FriendsService();

  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isFriend = false;
  String? _requestStatus; // 'sent', 'received', or null
  int _friendsCount = 0;
  int _mutualFriendsCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUserId = authService.user?.uid;

      // Add timeout to prevent infinite loading
      final doc = await _firestore
          .collection('users')
          .doc(widget.userId)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Request timed out. Please check your connection.');
            },
          );

      if (!mounted) return;

      if (doc.exists && doc.data() != null) {
        // Load relationship status and counts in parallel
        final friendsCountFuture = _friendsService.getFriendsCount(widget.userId);
        final mutualFriendsFuture = _friendsService.getMutualFriends(widget.userId);
        
        Future<bool>? isFriendFuture;
        Future<String?>? requestStatusFuture;

        if (currentUserId != null && currentUserId != widget.userId) {
          isFriendFuture = _friendsService.areFriends(currentUserId, widget.userId);
          requestStatusFuture = _friendsService.getFriendRequestStatus(widget.userId);
        }

        final results = await Future.wait([
          friendsCountFuture, 
          mutualFriendsFuture,
          if (isFriendFuture != null) isFriendFuture else Future.value(false),
          if (requestStatusFuture != null) requestStatusFuture else Future.value(null),
        ]);

        if (!mounted) return;

        setState(() {
          _userData = doc.data();
          _friendsCount = results[0] as int;
          _mutualFriendsCount = (results[1] as List).length;
          _isFriend = results[2] as bool;
          _requestStatus = results[3] as String?;
          _isLoading = false;
        });
      } else {
        // User document doesn't exist
        setState(() {
          _userData = null;
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User profile not found'),
              backgroundColor: AppTheme.primaryCoral,
            ),
          );
        }
      }
    } catch (e) {
      Log.d('❌ Error loading user profile: $e');
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile: ${e.toString()}'),
            backgroundColor: AppTheme.primaryCoral,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadUserProfile,
            ),
          ),
        );
      }
    }
  }

  String _getDisplayName() {
    return _userData?['profile']?['displayName'] ?? 'User';
  }

  String _getBio() {
    return _userData?['profile']?['bio'] ?? '';
  }

  String _getUsername() {
    return _userData?['profile']?['username'] ?? '';
  }

  String _getAboutMe() {
    return _userData?['profile']?['aboutMe'] ?? '';
  }

  String _getProfileImage() {
    // Check both possible field names for profile image
    return _userData?['profile']?['profileImageUrl'] ??
           _userData?['profile']?['profileImage'] ?? '';
  }

  String? _getBannerImage() {
    return _userData?['profile']?['bannerImageUrl'] as String?;
  }

  String _getDenomination() {
    final showDenomination = _userData?['privacy']?['showDenomination'] ?? true;
    if (!showDenomination) return '';
    return _userData?['profile']?['denomination'] ?? '';
  }

  String _getLocation() {
    final showLocation = _userData?['privacy']?['showLocation'] ?? true;
    if (!showLocation) return '';
    return _userData?['profile']?['location'] ?? '';
  }

  String _getChurch() {
    final showChurch = _userData?['privacy']?['showChurch'] ?? true;
    if (!showChurch) return '';
    return _userData?['profile']?['church'] ?? '';
  }

  String? _getTestimony() {
    return _userData?['profile']?['testimony'] as String?;
  }

  int _getPrayersOffered() {
    return _userData?['stats']?['prayersOffered'] ?? 0;
  }

  int _getVerseShares() {
    return _userData?['stats']?['verseShares'] ?? 0;
  }

  int _getPrayersReceived() {
    return _userData?['stats']?['prayersReceived'] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final isOwnProfile = authService.user?.uid == widget.userId;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.darkBackground,
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: AppTheme.surface,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryTeal),
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
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    size: 32,
                    weight: 700,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildProfileHeader(isOwnProfile),
                ),
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
                      Tab(text: 'About'),
                      Tab(text: 'Stats'),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildPostsTab(),
              _buildAboutTab(),
              _buildStatsTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(bool isOwnProfile) {
    final hasAvatar = _getProfileImage().isNotEmpty;
    final bannerImage = _getBannerImage();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate the midpoint where avatar center would be
        final splitPosition = 110.0;

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

            // BOTTOM HALF: Dark background with optional banner
            Positioned(
              top: splitPosition,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.darkBackground,
                  image: bannerImage != null && bannerImage.isNotEmpty
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(bannerImage),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withAlpha(77),
                            BlendMode.darken,
                          ),
                        )
                      : null,
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
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  const SizedBox(height: 8),

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
                              imageUrl: _getProfileImage(),
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
                              errorWidget: (context, url, error) => Container(
                                width: 100,
                                height: 100,
                                color: AppTheme.darkGrey,
                                child: const Icon(Icons.person, size: 50, color: AppTheme.onSurfaceVariant),
                              ),
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
                    _getDisplayName(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),

                  // Username
                  if (_getUsername().isNotEmpty)
                    Text(
                      '@${_getUsername()}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 6),

                  // Bio
                  if (_getBio().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        _getBio(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.onSurfaceVariant,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Action Buttons (Add Friend / Message)
                  if (!isOwnProfile) _buildActionButtons(),

                  const Spacer(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionButtons() {
    String label = 'Add Friend';
    IconData icon = Icons.person_add;
    Color bgColor = AppTheme.primaryTeal;
    Color fgColor = Colors.white;
    VoidCallback? onPressed;

    if (_isFriend) {
      label = 'Unfriend';
      icon = Icons.person_remove;
      bgColor = AppTheme.surface;
      fgColor = AppTheme.onSurface;
      onPressed = () => _handleUnfriend();
    } else if (_requestStatus == 'sent') {
      label = 'Request Sent';
      icon = Icons.hourglass_empty;
      bgColor = AppTheme.surface;
      fgColor = AppTheme.onSurfaceVariant;
      onPressed = null; 
    } else if (_requestStatus == 'received') {
      label = 'Accept Request';
      icon = Icons.person_add_alt_1;
      bgColor = AppTheme.successGreen;
      fgColor = Colors.white;
      onPressed = () => _handleAcceptRequest();
    } else {
      onPressed = () => _handleSendRequest();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: bgColor,
            foregroundColor: fgColor,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          icon: Icon(icon, size: 18),
          label: Text(label),
        ),
        const SizedBox(width: 12),
        // Message Button
        ElevatedButton.icon(
          onPressed: () {
            // TODO: Implement messaging
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Messaging coming soon!')),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.surface,
            foregroundColor: AppTheme.onSurface,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          icon: const Icon(Icons.message_outlined, size: 18),
          label: const Text('Message'),
        ),
      ],
    );
  }

  Future<void> _handleSendRequest() async {
    try {
      await _friendsService.sendFriendRequest(widget.userId);
      setState(() {
        _requestStatus = 'sent';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request sent!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send request: $e')),
        );
      }
    }
  }

  Future<void> _handleAcceptRequest() async {
    try {
      // Find the request ID first
      final requests = await _firestore
          .collection('friendRequests')
          .where('fromUserId', isEqualTo: widget.userId)
          .where('toUserId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .where('status', isEqualTo: 'pending')
          .get();

      if (requests.docs.isNotEmpty) {
        await _friendsService.acceptFriendRequest(requests.docs.first.id);
        setState(() {
          _isFriend = true;
          _requestStatus = null;
          _friendsCount++;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Friend request accepted!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept request: $e')),
        );
      }
    }
  }

  Future<void> _handleUnfriend() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unfriend?'),
        content: Text('Are you sure you want to remove ${_getDisplayName()} from your friends?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Unfriend', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _friendsService.unfriend(widget.userId);
        setState(() {
          _isFriend = false;
          _friendsCount--;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to unfriend: $e')),
          );
        }
      }
    }
  }

  Widget _buildPostsTab() {
    return StreamBuilder<List<Post>>(
      stream: _postService.getUserPosts(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryTeal),
          );
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Error loading posts',
              style: TextStyle(color: AppTheme.onSurfaceVariant),
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
                  Icons.post_add_outlined,
                  size: 64,
                  color: AppTheme.onSurfaceVariant.withAlpha(128),
                ),
                const SizedBox(height: 16),
                Text(
                  'No posts yet',
                  style: TextStyle(
                    color: AppTheme.onSurfaceVariant.withAlpha(179),
                    fontSize: 16,
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

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // About Me section (extended bio)
          if (_getAboutMe().isNotEmpty) ...[
            const Text(
              'About Me',
              style: TextStyle(
                color: AppTheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryTeal.withAlpha(51),
                ),
              ),
              child: Text(
                _getAboutMe(),
                style: const TextStyle(
                  color: AppTheme.onSurface,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          const Text(
            'Details',
            style: TextStyle(
              color: AppTheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_getDenomination().isNotEmpty)
            _buildInfoRow(Icons.church_outlined, 'Denomination', _getDenomination()),
          if (_getChurch().isNotEmpty)
            _buildInfoRow(Icons.home_outlined, 'Church', _getChurch()),
          if (_getLocation().isNotEmpty)
            _buildInfoRow(Icons.location_on_outlined, 'Location', _getLocation()),
          const SizedBox(height: 24),

          // Contact Section
          if (_userData?['privacy']?['showPhone'] == true &&
              (_userData?['profile']?['phoneNumber'] != null ||
                  _userData?['business']?['phoneNumber'] != null)) ...[
            const Text(
              'Contact Info',
              style: TextStyle(
                color: AppTheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
                Icons.phone_outlined,
                'Phone',
                (_userData?['profile']?['phoneNumber'] ??
                    _userData?['business']?['phoneNumber']) as String),
            const SizedBox(height: 24),
          ],

          const Text(
            'Spiritual Info',
            style: TextStyle(
              color: AppTheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSpiritualInfo(),
          const SizedBox(height: 24),

          // Testimony Button
          if (_getTestimony() != null && _getTestimony()!.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showTestimonyDialog(context, _getTestimony()!);
                },
                icon: const Icon(Icons.auto_stories),
                label: Text('Read ${_getDisplayName()}\'s Testimony'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
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
        title: Row(
          children: [
            const Icon(Icons.auto_stories, color: AppTheme.primaryTeal),
            const SizedBox(width: 12),
            Text(
              '${_getDisplayName()}\'s Testimony',
              style: const TextStyle(color: AppTheme.onSurface),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryTeal, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: AppTheme.onSurface,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpiritualInfo() {
    final baptized = _userData?['spiritual']?['baptized'] ?? false;
    final prayerStyle = _userData?['spiritual']?['prayerStyle'] ?? '';
    final currentReadingPlan = _userData?['spiritual']?['currentReadingPlan'] ?? '';
    final faithJourneyStart = _userData?['spiritual']?['faithJourneyStart'] ?? '';
    final favoriteVerses = _userData?['spiritual']?['favoriteVerses'] as List? ?? [];

    // Privacy checks
    final showBaptismStatus = _userData?['privacy']?['showBaptismStatus'] ?? true;
    final showPrayerStyle = _userData?['privacy']?['showPrayerStyle'] ?? true;
    final showReadingPlan = _userData?['privacy']?['showReadingPlan'] ?? true;
    final showFaithJourneyDate = _userData?['privacy']?['showFaithJourneyDate'] ?? true;
    final showFavoriteVerses = _userData?['privacy']?['showFavoriteVerses'] ?? true;

    return Column(
      children: [
        if (baptized && showBaptismStatus)
          _buildInfoRow(Icons.water_drop_outlined, 'Baptized', 'Yes'),
        if (faithJourneyStart.isNotEmpty && showFaithJourneyDate)
          _buildInfoRow(Icons.timeline, 'Faith Journey Started', faithJourneyStart),
        if (prayerStyle.isNotEmpty && showPrayerStyle)
          _buildInfoRow(Icons.favorite_outline, 'Prayer Style', prayerStyle),
        if (currentReadingPlan.isNotEmpty && showReadingPlan)
          _buildInfoRow(Icons.menu_book_outlined, 'Reading Plan', currentReadingPlan),
        if (favoriteVerses.isNotEmpty && showFavoriteVerses)
          _buildInfoRow(Icons.bookmark, 'Favorite Verses', favoriteVerses.join(', ')),
        if (!baptized && prayerStyle.isEmpty && currentReadingPlan.isEmpty && favoriteVerses.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'No spiritual information shared',
                style: TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatsTab() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final isOwnProfile = authService.user?.uid == widget.userId;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            'Community Stats',
            style: TextStyle(
              color: AppTheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                icon: Icons.volunteer_activism,
                label: 'Prayers Offered',
                value: _getPrayersOffered().toString(),
              ),
              _buildStatCard(
                icon: Icons.favorite,
                label: 'Prayers Received',
                value: _getPrayersReceived().toString(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                icon: Icons.share,
                label: 'Verse Shares',
                value: _getVerseShares().toString(),
              ),
              _buildTappableStatCard(
                icon: Icons.people,
                label: 'Friends',
                value: _friendsCount.toString(),
                subtitle: !isOwnProfile && _mutualFriendsCount > 0
                    ? '$_mutualFriendsCount mutual'
                    : null,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserFriendsListScreen(
                        userId: widget.userId,
                        userName: _getDisplayName(),
                        isOwnProfile: isOwnProfile,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryTeal, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTappableStatCard({
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryTeal.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryTeal, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.onSurface,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.primaryTeal,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'View',
                  style: TextStyle(
                    color: AppTheme.primaryTeal,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.chevron_right,
                  color: AppTheme.primaryTeal,
                  size: 14,
                ),
              ],
            ),
          ],
        ),
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
