import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_theme.dart';
import '../../models/friend_request_model.dart';
import '../../services/friends_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen>
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

  Future<void> _acceptRequest(String requestId) async {
    try {
      await _friendsService.acceptFriendRequest(requestId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Friend request accepted'),
            backgroundColor: AppTheme.primaryTeal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _declineRequest(String requestId) async {
    try {
      await _friendsService.declineFriendRequest(requestId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Friend request declined'),
            backgroundColor: AppTheme.onSurfaceVariant,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to decline request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelRequest(String requestId) async {
    try {
      await _friendsService.cancelFriendRequest(requestId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Friend request cancelled'),
            backgroundColor: AppTheme.onSurfaceVariant,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Friend Requests',
          style: TextStyle(color: AppTheme.onSurface),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.onSurfaceVariant),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryTeal,
          labelColor: AppTheme.primaryTeal,
          unselectedLabelColor: AppTheme.onSurfaceVariant,
          tabs: const [
            Tab(text: 'Received'),
            Tab(text: 'Sent'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReceivedTab(),
          _buildSentTab(),
        ],
      ),
    );
  }

  Widget _buildReceivedTab() {
    return StreamBuilder<List<FriendRequest>>(
      stream: _friendsService.getPendingRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryTeal),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading requests',
              style: const TextStyle(color: AppTheme.onSurfaceVariant),
            ),
          );
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No pending friend requests',
                  style: TextStyle(
                    color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return Card(
              color: AppTheme.surface,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: request.fromUserImageUrl.isNotEmpty
                          ? CachedNetworkImageProvider(request.fromUserImageUrl)
                          : null,
                      backgroundColor: AppTheme.darkGrey,
                      child: request.fromUserImageUrl.isEmpty
                          ? const Icon(Icons.person, color: AppTheme.onSurfaceVariant)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.fromUserName,
                            style: const TextStyle(
                              color: AppTheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            timeago.format(request.createdAt),
                            style: const TextStyle(
                              color: AppTheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        ElevatedButton(
                          onPressed: () => _acceptRequest(request.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryTeal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            minimumSize: const Size(80, 36),
                          ),
                          child: const Text('Accept'),
                        ),
                        const SizedBox(height: 4),
                        TextButton(
                          onPressed: () => _declineRequest(request.id),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.onSurfaceVariant,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            minimumSize: const Size(80, 36),
                          ),
                          child: const Text('Decline'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSentTab() {
    return StreamBuilder<List<FriendRequest>>(
      stream: _friendsService.getSentRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryTeal),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading requests',
              style: const TextStyle(color: AppTheme.onSurfaceVariant),
            ),
          );
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.send_outlined,
                  size: 64,
                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No sent friend requests',
                  style: TextStyle(
                    color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return Card(
              color: AppTheme.surface,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: request.toUserImageUrl.isNotEmpty
                          ? CachedNetworkImageProvider(request.toUserImageUrl)
                          : null,
                      backgroundColor: AppTheme.darkGrey,
                      child: request.toUserImageUrl.isEmpty
                          ? const Icon(Icons.person, color: AppTheme.onSurfaceVariant)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.toUserName,
                            style: const TextStyle(
                              color: AppTheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sent ${timeago.format(request.createdAt)}',
                            style: const TextStyle(
                              color: AppTheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _cancelRequest(request.id),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
