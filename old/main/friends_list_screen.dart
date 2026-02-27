import 'dart:ui' show ImageFilter;
import 'package:faithfeed/models/friend_model.dart';
import 'package:faithfeed/models/friend_request_model.dart';
import 'package:faithfeed/services/friends_service.dart';
import 'package:faithfeed/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../profile/user_profile_view_screen.dart';
import '../friends/find_friends_screen.dart';

// UX ENHANCEMENTS
import '../../utils/ui_helpers.dart';
import '../../widgets/skeleton_loading.dart';
import '../../widgets/empty_states.dart';
import '../../widgets/optimized_image.dart';

class FriendsListScreen extends StatefulWidget {
  const FriendsListScreen({super.key});

  @override
  State<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FriendsService _friendsService = FriendsService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showUnfriendDialog(Friend friend) async {
    final confirmed = await ConfirmationDialog.showDeleteConfirmation(
      context,
      title: 'Unfriend ${friend.displayName}?',
      message: 'You can always send a new friend request later.',
      confirmText: 'Unfriend',
    );
    if (confirmed && mounted) {
      _unfriendFriend(friend.id);
    }
  }

  void _unfriendFriend(String friendId) async {
    try {
      await _friendsService.unfriend(friendId);
      if (mounted) {
        SnackbarHelper.showSuccess(context, 'Friend removed');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(
          context,
          'Failed to unfriend. Please try again.',
        );
      }
    }
  }

  Future<void> _acceptRequest(String requestId) async {
    try {
      await _friendsService.acceptFriendRequest(requestId);
      if (mounted) {
        SnackbarHelper.showSuccess(context, 'Friend request accepted');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Failed to accept request');
      }
    }
  }

  Future<void> _declineRequest(String requestId) async {
    try {
      await _friendsService.declineFriendRequest(requestId);
      if (mounted) {
        SnackbarHelper.showSuccess(context, 'Friend request declined');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Failed to decline request');
      }
    }
  }

  Future<void> _cancelRequest(String requestId) async {
    try {
      await _friendsService.cancelFriendRequest(requestId);
      if (mounted) {
        SnackbarHelper.showSuccess(context, 'Friend request cancelled');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Failed to cancel request');
      }
    }
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
          iconTheme: const IconThemeData(color: AppTheme.lightOnSurface),
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          title: Text(
            'Friends',
            style: TextStyle(color: AppTheme.lightOnSurface),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add, color: AppTheme.primaryTeal),
              tooltip: 'Find Friends',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FindFriendsScreen(),
                  ),
                );
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.primaryTeal,
            labelColor: AppTheme.primaryTeal,
            unselectedLabelColor: AppTheme.lightOnSurfaceVariant,
            tabs: [
              const Tab(text: 'Friends'),
              StreamBuilder<List<FriendRequest>>(
                stream: _friendsService.getPendingRequests(),
                builder: (context, snapshot) {
                  final count = snapshot.data?.length ?? 0;
                  return Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Requests'),
                        if (count > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryCoral,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              count.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildFriendsTab(),
            _buildRequestsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsTab() {
    return StreamBuilder<List<Friend>>(
      stream: _friendsService.getFriendsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 8,
            itemBuilder: (context, index) => const SkeletonUserTile(),
          );
        }
        if (snapshot.hasError) {
          return EmptyState(
            icon: Icons.error_outline,
            title: 'Error Loading Friends',
            message: 'Something went wrong. Please try again.',
            actionLabel: 'Try Again',
            onAction: () => setState(() {}),
            iconColor: AppTheme.primaryCoral.withValues(alpha: 0.5),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return EmptyFriendsList(
            onFindFriends: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FindFriendsScreen(),
                ),
              );
            },
          );
        }

        final friends = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friend = friends[index];
            return _buildFrostedCard(
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                leading: OptimizedAvatar(
                  imageUrl: friend.profileImageUrl.isNotEmpty
                      ? friend.profileImageUrl
                      : null,
                  size: 50,
                  fallbackIcon: Icons.person,
                ),
                title: Text(
                  friend.displayName,
                  style: TextStyle(
                    color: AppTheme.lightOnSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: friend.username.isNotEmpty
                    ? Text(
                        '@${friend.username}',
                        style: TextStyle(
                            color: AppTheme.lightOnSurfaceVariant),
                      )
                    : null,
                trailing: IconButton(
                  icon: Icon(Icons.more_vert,
                      color: AppTheme.lightOnSurfaceVariant),
                  onPressed: () {
                    HapticHelper.light();
                    _showUnfriendDialog(friend);
                  },
                ),
                onTap: () {
                  HapticHelper.light();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          UserProfileViewScreen(userId: friend.id),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRequestsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Received Requests Section
          Text(
            'Received',
            style: TextStyle(
              color: AppTheme.lightOnSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildReceivedRequests(),
          const SizedBox(height: 24),

          // Sent Requests Section
          Text(
            'Sent',
            style: TextStyle(
              color: AppTheme.lightOnSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildSentRequests(),
        ],
      ),
    );
  }

  Widget _buildReceivedRequests() {
    return StreamBuilder<List<FriendRequest>>(
      stream: _friendsService.getPendingRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: AppTheme.primaryTeal),
            ),
          );
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return _buildFrostedCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No pending friend requests',
                  style: TextStyle(
                    color: AppTheme.lightOnSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }

        return Column(
          children: requests.map((request) {
            return _buildFrostedCard(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundImage: request.fromUserImageUrl.isNotEmpty
                          ? CachedNetworkImageProvider(request.fromUserImageUrl)
                          : null,
                      backgroundColor: AppTheme.lightSurfaceHighlight,
                      child: request.fromUserImageUrl.isEmpty
                          ? Icon(Icons.person,
                              color: AppTheme.lightOnSurfaceVariant)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.fromUserName,
                            style: TextStyle(
                              color: AppTheme.lightOnSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            timeago.format(request.createdAt),
                            style: TextStyle(
                              color: AppTheme.lightOnSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check_circle,
                              color: AppTheme.primaryTeal, size: 28),
                          onPressed: () => _acceptRequest(request.id),
                          tooltip: 'Accept',
                        ),
                        IconButton(
                          icon: Icon(Icons.cancel,
                              color: AppTheme.lightOnSurfaceVariant,
                              size: 28),
                          onPressed: () => _declineRequest(request.id),
                          tooltip: 'Decline',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSentRequests() {
    return StreamBuilder<List<FriendRequest>>(
      stream: _friendsService.getSentRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: AppTheme.primaryTeal),
            ),
          );
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return _buildFrostedCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No sent friend requests',
                  style: TextStyle(
                    color: AppTheme.lightOnSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }

        return Column(
          children: requests.map((request) {
            return _buildFrostedCard(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundImage: request.toUserImageUrl.isNotEmpty
                          ? CachedNetworkImageProvider(request.toUserImageUrl)
                          : null,
                      backgroundColor: AppTheme.lightSurfaceHighlight,
                      child: request.toUserImageUrl.isEmpty
                          ? Icon(Icons.person,
                              color: AppTheme.lightOnSurfaceVariant)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.toUserName,
                            style: TextStyle(
                              color: AppTheme.lightOnSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryTeal.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'Pending',
                                  style: TextStyle(
                                    color: AppTheme.primaryTeal,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                timeago.format(request.createdAt),
                                style: TextStyle(
                                  color: AppTheme.lightOnSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _cancelRequest(request.id),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryCoral,
                      ),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildFrostedCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.glassWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.glassBorder,
                width: 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
