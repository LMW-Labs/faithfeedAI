import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_theme.dart';
import '../../services/friends_service.dart';
import '../../models/friend_model.dart';
import 'user_profile_view_screen.dart';

/// Screen to display a user's friends list with mutual friends highlighted
class UserFriendsListScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final bool isOwnProfile;

  const UserFriendsListScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.isOwnProfile = false,
  });

  @override
  State<UserFriendsListScreen> createState() => _UserFriendsListScreenState();
}

class _UserFriendsListScreenState extends State<UserFriendsListScreen> {
  final FriendsService _friendsService = FriendsService();

  List<Friend> _friends = [];
  List<Friend> _mutualFriends = [];
  Set<String> _mutualFriendIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    setState(() => _isLoading = true);

    try {
      // Load the user's friends
      final friends = await _friendsService.getUserFriends(widget.userId);

      // If viewing someone else's profile, also get mutual friends
      List<Friend> mutualFriends = [];
      if (!widget.isOwnProfile) {
        mutualFriends = await _friendsService.getMutualFriends(widget.userId);
      }

      if (mounted) {
        setState(() {
          _friends = friends;
          _mutualFriends = mutualFriends;
          _mutualFriendIds = mutualFriends.map((f) => f.id).toSet();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load friends: $e'),
            backgroundColor: AppTheme.primaryCoral,
          ),
        );
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
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          title: Text(
            widget.isOwnProfile ? 'My Friends' : "${widget.userName}'s Friends",
            style: const TextStyle(color: AppTheme.lightOnSurface),
          ),
          iconTheme: const IconThemeData(color: AppTheme.lightOnSurface),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryTeal),
              )
            : _friends.isEmpty
                ? _buildEmptyState()
                : _buildFriendsList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: AppTheme.lightOnSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            widget.isOwnProfile
                ? 'You have no friends yet'
                : '${widget.userName} has no friends yet',
            style: TextStyle(
              color: AppTheme.lightOnSurfaceVariant,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsList() {
    // Sort: mutual friends first, then alphabetically
    final sortedFriends = List<Friend>.from(_friends)
      ..sort((a, b) {
        final aIsMutual = _mutualFriendIds.contains(a.id);
        final bIsMutual = _mutualFriendIds.contains(b.id);
        if (aIsMutual && !bIsMutual) return -1;
        if (!aIsMutual && bIsMutual) return 1;
        return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mutual friends summary (if viewing someone else's profile)
        if (!widget.isOwnProfile && _mutualFriends.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: _buildMutualFriendsSummary(),
          ),

        // Friends count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '${_friends.length} ${_friends.length == 1 ? 'Friend' : 'Friends'}',
            style: TextStyle(
              color: AppTheme.lightOnSurfaceVariant,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Friends list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: sortedFriends.length,
            itemBuilder: (context, index) {
              final friend = sortedFriends[index];
              final isMutual = _mutualFriendIds.contains(friend.id);
              return _buildFriendTile(friend, isMutual);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMutualFriendsSummary() {
    return _buildFrostedCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Stacked avatars (up to 3)
            SizedBox(
              width: 60,
              height: 36,
              child: Stack(
                children: [
                  for (int i = 0; i < _mutualFriends.length.clamp(0, 3); i++)
                    Positioned(
                      left: i * 18.0,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.lightSurface,
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: AppTheme.lightSurfaceHighlight,
                          backgroundImage: _mutualFriends[i].profileImageUrl.isNotEmpty
                              ? CachedNetworkImageProvider(_mutualFriends[i].profileImageUrl)
                              : null,
                          child: _mutualFriends[i].profileImageUrl.isEmpty
                              ? Text(
                                  _mutualFriends[i].displayName.isNotEmpty
                                      ? _mutualFriends[i].displayName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: AppTheme.lightOnSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _getMutualFriendsText(),
                style: TextStyle(
                  color: AppTheme.lightOnSurface,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(
              Icons.people,
              color: AppTheme.primaryTeal,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  String _getMutualFriendsText() {
    if (_mutualFriends.isEmpty) return '';
    if (_mutualFriends.length == 1) {
      return '${_mutualFriends[0].displayName} is a mutual friend';
    }
    if (_mutualFriends.length == 2) {
      return '${_mutualFriends[0].displayName} and ${_mutualFriends[1].displayName} are mutual friends';
    }
    return '${_mutualFriends[0].displayName}, ${_mutualFriends[1].displayName} and ${_mutualFriends.length - 2} more mutual friends';
  }

  Widget _buildFriendTile(Friend friend, bool isMutual) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _buildFrostedCard(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.lightSurfaceHighlight,
                backgroundImage: friend.profileImageUrl.isNotEmpty
                    ? CachedNetworkImageProvider(friend.profileImageUrl)
                    : null,
                child: friend.profileImageUrl.isEmpty
                    ? Text(
                        friend.displayName.isNotEmpty
                            ? friend.displayName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: AppTheme.lightOnSurfaceVariant,
                          fontSize: 18,
                        ),
                      )
                    : null,
              ),
              // Mutual friend indicator
              if (isMutual && !widget.isOwnProfile)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTeal,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.lightSurface,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.people,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
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
                    color: AppTheme.lightOnSurfaceVariant,
                    fontSize: 12,
                  ),
                )
              : null,
          trailing: isMutual && !widget.isOwnProfile
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Mutual',
                    style: TextStyle(
                      color: AppTheme.primaryTeal,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : const Icon(
                  Icons.chevron_right,
                  color: AppTheme.lightOnSurfaceVariant,
                ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserProfileViewScreen(userId: friend.id),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFrostedCard({required Widget child}) {
    return ClipRRect(
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
    );
  }
}
