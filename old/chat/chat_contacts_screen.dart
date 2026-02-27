import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:faithfeed/services/logger_service.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../services/chat_service.dart';
import '../../services/auth_service.dart';
import '../../services/user_profile_service.dart';
import '../../services/marketplace_service.dart';
import '../../models/marketplace_conversation_model.dart';
import '../marketplace/marketplace_conversation_screen.dart';
import 'chat_screen.dart';

class ChatContactsScreen extends StatefulWidget {
  const ChatContactsScreen({super.key});

  @override
  State<ChatContactsScreen> createState() => _ChatContactsScreenState();
}

class _ChatContactsScreenState extends State<ChatContactsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final MarketplaceService _marketplaceService = MarketplaceService();

  String _searchQuery = '';
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final lowercaseQuery = query.toLowerCase();

      // Search by first name
      final firstNameSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('profile.firstName_lowercase',
              isGreaterThanOrEqualTo: lowercaseQuery)
          .where('profile.firstName_lowercase',
              isLessThanOrEqualTo: '$lowercaseQuery\uf8ff')
          .limit(10)
          .get();

      // Search by last name
      final lastNameSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('profile.lastName_lowercase',
              isGreaterThanOrEqualTo: lowercaseQuery)
          .where('profile.lastName_lowercase',
              isLessThanOrEqualTo: '$lowercaseQuery\uf8ff')
          .limit(10)
          .get();

      // Search by username
      final usernameSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('profile.username_lowercase',
              isGreaterThanOrEqualTo: lowercaseQuery)
          .where('profile.username_lowercase',
              isLessThanOrEqualTo: '$lowercaseQuery\uf8ff')
          .limit(10)
          .get();

      // Combine results and remove duplicates
      final allResults = <String, Map<String, dynamic>>{};

      for (final doc in [
        ...firstNameSnapshot.docs,
        ...lastNameSnapshot.docs,
        ...usernameSnapshot.docs
      ]) {
        if (!allResults.containsKey(doc.id)) {
          final data = doc.data();
          final profile = data['profile'] as Map<String, dynamic>? ?? {};

          allResults[doc.id] = {
            'id': doc.id,
            'firstName': profile['firstName'] ?? '',
            'lastName': profile['lastName'] ?? '',
            'username': profile['username'],
            'displayName': profile['displayName'] ?? '',
            'profileImage': profile['profileImage'] ?? '',
            'city': profile['city'] ?? '',
            'state': profile['state'] ?? '',
          };
        }
      }

      setState(() {
        _searchResults = allResults.values.toList();
        _isSearching = false;
      });
    } catch (e) {
      Log.d('Error searching users: $e');
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _startConversation(Map<String, dynamic> user) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final chatService = ChatService();
    final profileService =
        Provider.of<UserProfileService>(context, listen: false);

    if (authService.user == null) return;

    // Get current user profile
    await profileService.fetchUserProfile();
    final currentProfile = profileService.currentProfile;

    if (currentProfile == null) return;

    // Create or get conversation
    final conversationId = await chatService.createOrGetConversation(
      currentUserId: authService.user!.uid,
      otherUserId: user['id'],
      currentUserName: currentProfile.displayName,
      currentUserPhotoUrl: currentProfile.profileImageUrl,
      otherUserName: user['displayName'],
      otherUserPhotoUrl: user['profileImage'] ?? '',
    );

    if (conversationId != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            conversationId: conversationId,
            otherUserName: user['displayName'],
            otherUserPhotoUrl: user['profileImage'] ?? '',
          ),
        ),
      );
    }
  }

  void _showNewMessageSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.lightOnSurfaceMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'New Message',
                    style: TextStyle(
                      color: AppTheme.lightOnSurface,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: AppTheme.lightOnSurfaceVariant),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Search bar
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                autofocus: true,
                style: TextStyle(color: AppTheme.lightOnSurface),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                  _searchUsers(value);
                },
                decoration: InputDecoration(
                  hintText: 'Search people...',
                  hintStyle: TextStyle(color: AppTheme.lightOnSurfaceVariant),
                  prefixIcon:
                      const Icon(Icons.search, color: AppTheme.primaryTeal),
                  filled: true,
                  fillColor: AppTheme.lightSurfaceHighlight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Divider(color: AppTheme.lightOnSurfaceMuted.withValues(alpha: 0.3)),
            // Search results
            Expanded(
              child: _isSearching
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppTheme.primaryTeal),
                    )
                  : _searchResults.isEmpty && _searchQuery.isNotEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off,
                                  size: 64, color: AppTheme.lightOnSurfaceVariant),
                              const SizedBox(height: 16),
                              Text(
                                'No users found',
                                style: TextStyle(
                                    color: AppTheme.lightOnSurfaceVariant,
                                    fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : _searchResults.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.people_outline,
                                      size: 64,
                                      color: AppTheme.lightOnSurfaceVariant),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Search for people to message',
                                    style: TextStyle(
                                        color: AppTheme.lightOnSurfaceVariant,
                                        fontSize: 16),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: _searchResults.length,
                              itemBuilder: (context, index) {
                                final user = _searchResults[index];
                                return _buildUserTileInSheet(user);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTileInSheet(Map<String, dynamic> user) {
    final location = user['city'] != null && user['state'] != null
        ? '${user['city']}, ${user['state']}'
        : '';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.lightSurfaceHighlight,
        backgroundImage: user['profileImage']?.isNotEmpty == true
            ? NetworkImage(user['profileImage'])
            : null,
        child: user['profileImage']?.isEmpty ?? true
            ? Text(
                user['displayName']?.isNotEmpty == true
                    ? user['displayName'][0].toUpperCase()
                    : '?',
                style: TextStyle(color: AppTheme.lightOnSurfaceVariant),
              )
            : null,
      ),
      title: Text(
        user['displayName'] ?? 'Unknown User',
        style: TextStyle(color: AppTheme.lightOnSurface),
      ),
      subtitle: Text(
        location.isNotEmpty ? location : (user['username'] ?? ''),
        style: TextStyle(color: AppTheme.lightOnSurfaceVariant, fontSize: 12),
      ),
      onTap: () async {
        Navigator.pop(context); // Close the sheet
        await _startConversation(user);
      },
    );
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
            'Messages',
            style: TextStyle(color: AppTheme.lightOnSurface),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_square, color: AppTheme.primaryTeal),
              onPressed: _showNewMessageSheet,
              tooltip: 'New Message',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.primaryTeal,
            labelColor: AppTheme.primaryTeal,
            unselectedLabelColor: AppTheme.lightOnSurfaceVariant,
            tabs: const [
              Tab(text: 'Messages'),
              Tab(text: 'FaithFinds'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildMessagesTab(),
            _buildFaithFindsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesTab() {
    final authService = Provider.of<AuthService>(context);
    final chatService = ChatService();

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: TextField(
            controller: _searchController,
            style: TextStyle(color: AppTheme.lightOnSurface),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _searchUsers(value);
            },
            decoration: InputDecoration(
              hintText: 'Search conversations...',
              hintStyle: TextStyle(color: AppTheme.lightOnSurfaceVariant),
              prefixIcon:
                  const Icon(Icons.search, color: AppTheme.primaryTeal),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear,
                          color: AppTheme.lightOnSurfaceVariant),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _searchResults = [];
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppTheme.glassWhite,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.glassBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.glassBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryTeal),
              ),
            ),
          ),
        ),
        // Content
        Expanded(
          child: _searchQuery.isNotEmpty
              ? _buildSearchResults()
              : _buildConversationsList(authService, chatService),
        ),
      ],
    );
  }

  Widget _buildFaithFindsTab() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<List<MarketplaceConversation>>(
      stream: _marketplaceService.getConversations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryTeal),
          );
        }

        final conversations = snapshot.data ?? [];

        if (conversations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.storefront_outlined,
                  size: 64,
                  color: AppTheme.lightOnSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'No conversations yet',
                  style: TextStyle(
                    color: AppTheme.lightOnSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Contact a seller in FaithFinds to start a conversation',
                  style: TextStyle(color: AppTheme.lightOnSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            return _buildFaithFindsConversationCard(conversations[index], currentUserId);
          },
        );
      },
    );
  }

  Widget _buildFaithFindsConversationCard(MarketplaceConversation conversation, String? currentUserId) {
    final isBuyer = conversation.buyerId == currentUserId;
    final otherUserName = isBuyer ? conversation.sellerName : conversation.buyerName;
    final otherUserImage = isBuyer ? conversation.sellerProfileImage : conversation.buyerProfileImage;
    final unreadCount = isBuyer ? conversation.unreadCountBuyer : conversation.unreadCountSeller;

    return _buildFrostedCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MarketplaceConversationScreen(
                conversationId: conversation.id,
                itemTitle: conversation.itemTitle,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // User avatar
              CircleAvatar(
                radius: 25,
                backgroundColor: AppTheme.lightSurfaceHighlight,
                backgroundImage: otherUserImage.isNotEmpty
                    ? NetworkImage(otherUserImage)
                    : null,
                child: otherUserImage.isEmpty
                    ? Icon(Icons.person, color: AppTheme.lightOnSurfaceVariant)
                    : null,
              ),
              const SizedBox(width: 12),

              // Conversation info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            otherUserName,
                            style: TextStyle(
                              color: AppTheme.lightOnSurface,
                              fontSize: 15,
                              fontWeight: unreadCount > 0
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryTeal,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Re: ${conversation.itemTitle}',
                      style: const TextStyle(
                        color: AppTheme.primaryTeal,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (conversation.lastMessage.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        conversation.lastMessage,
                        style: TextStyle(
                          color: unreadCount > 0
                              ? AppTheme.lightOnSurface
                              : AppTheme.lightOnSurfaceVariant,
                          fontSize: 13,
                          fontWeight: unreadCount > 0
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryTeal),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: AppTheme.lightOnSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(color: AppTheme.lightOnSurfaceVariant, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return _buildUserTile(user);
      },
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    final location = user['city'] != null && user['state'] != null
        ? '${user['city']}, ${user['state']}'
        : '';

    return _buildFrostedCard(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppTheme.lightSurfaceHighlight,
          backgroundImage: user['profileImage']?.isNotEmpty == true
              ? NetworkImage(user['profileImage'])
              : null,
          child: user['profileImage']?.isEmpty ?? true
              ? Text(
                  user['displayName']?.isNotEmpty == true
                      ? user['displayName'][0].toUpperCase()
                      : '?',
                  style: TextStyle(color: AppTheme.lightOnSurfaceVariant),
                )
              : null,
        ),
        title: Text(
          user['displayName'] ?? 'Unknown User',
          style: TextStyle(
            color: AppTheme.lightOnSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          location.isNotEmpty ? location : (user['username'] ?? ''),
          style: TextStyle(color: AppTheme.lightOnSurfaceVariant, fontSize: 12),
        ),
        trailing: const Icon(Icons.message, color: AppTheme.primaryTeal),
        onTap: () => _startConversation(user),
      ),
    );
  }

  Widget _buildConversationsList(
      AuthService authService, ChatService chatService) {
    if (authService.user == null) {
      return Center(
        child: Text(
          'Please sign in to view messages',
          style: TextStyle(color: AppTheme.lightOnSurfaceVariant),
        ),
      );
    }

    return StreamBuilder<List<Conversation>>(
      stream: chatService.getUserConversations(authService.user!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryTeal),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline,
                    size: 64, color: AppTheme.lightOnSurfaceVariant),
                const SizedBox(height: 16),
                Text(
                  'No conversations yet',
                  style:
                      TextStyle(color: AppTheme.lightOnSurfaceVariant, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start a conversation with someone',
                  style:
                      TextStyle(color: AppTheme.lightOnSurfaceVariant, fontSize: 14),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _showNewMessageSheet,
                  icon: const Icon(Icons.edit),
                  label: const Text('New Message'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final conversations = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            final conversation = conversations[index];
            final currentUserId = authService.user!.uid;

            // Get other participant info
            String otherUserName = '';
            String otherUserPhotoUrl = '';

            if (conversation.isGroup) {
              otherUserName = conversation.groupName ?? 'Group Chat';
              otherUserPhotoUrl = conversation.groupPhotoUrl ?? '';
            } else {
              final otherUserId = conversation.participantIds.firstWhere(
                (id) => id != currentUserId,
                orElse: () => '',
              );

              if (otherUserId.isNotEmpty &&
                  conversation.participants.containsKey(otherUserId)) {
                final otherUser = conversation.participants[otherUserId];
                otherUserName = otherUser['name'] ?? 'Unknown';
                otherUserPhotoUrl = otherUser['photoUrl'] ?? '';
              }
            }

            final unreadCount = conversation.unreadCount[currentUserId] ?? 0;

            return _buildFrostedCard(
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: AppTheme.lightSurfaceHighlight,
                  backgroundImage: otherUserPhotoUrl.isNotEmpty
                      ? NetworkImage(otherUserPhotoUrl)
                      : null,
                  child: otherUserPhotoUrl.isEmpty
                      ? Text(
                          otherUserName.isNotEmpty
                              ? otherUserName[0].toUpperCase()
                              : '?',
                          style:
                              TextStyle(color: AppTheme.lightOnSurfaceVariant),
                        )
                      : null,
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        otherUserName,
                        style: TextStyle(
                          color: AppTheme.lightOnSurface,
                          fontWeight: unreadCount > 0
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryTeal,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          unreadCount.toString(),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ),
                  ],
                ),
                subtitle: Text(
                  conversation.lastMessage ?? 'No messages yet',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.lightOnSurfaceVariant,
                    fontWeight:
                        unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        conversationId: conversation.id,
                        otherUserName: otherUserName,
                        otherUserPhotoUrl: otherUserPhotoUrl,
                      ),
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
