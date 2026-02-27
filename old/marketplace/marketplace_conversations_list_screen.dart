import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../services/marketplace_service.dart';
import '../../services/mock_data_service.dart';
import '../../models/marketplace_conversation_model.dart';
import 'marketplace_conversation_screen.dart';

/// List all marketplace conversations for current user
class MarketplaceConversationsListScreen extends StatefulWidget {
  const MarketplaceConversationsListScreen({super.key});

  @override
  State<MarketplaceConversationsListScreen> createState() =>
      _MarketplaceConversationsListScreenState();
}

class _MarketplaceConversationsListScreenState
    extends State<MarketplaceConversationsListScreen> {
  final MarketplaceService _marketplaceService = MarketplaceService();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('FaithFinds Messages'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<MarketplaceConversation>>(
        stream: _marketplaceService.getConversations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Use mock data if error or empty (for screenshots)
          final conversations = (snapshot.hasData && snapshot.data!.isNotEmpty)
              ? snapshot.data!
              : (_currentUserId != null
                  ? MockDataService.getMarketplaceConversations(_currentUserId!)
                  : <MarketplaceConversation>[]);

          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: AppTheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No conversations yet',
                    style: TextStyle(
                      color: AppTheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Contact a seller to start a conversation',
                    style: TextStyle(color: AppTheme.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              return _buildConversationCard(conversations[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildConversationCard(MarketplaceConversation conversation) {
    final isBuyer = conversation.buyerId == _currentUserId;
    final otherUserName = isBuyer ? conversation.sellerName : conversation.buyerName;
    final otherUserImage = isBuyer ? conversation.sellerProfileImage : conversation.buyerProfileImage;
    final unreadCount = isBuyer ? conversation.unreadCountBuyer : conversation.unreadCountSeller;

    return Card(
      color: AppTheme.surface,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
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
                radius: 28,
                backgroundColor: AppTheme.darkGrey,
                backgroundImage: otherUserImage.isNotEmpty
                    ? NetworkImage(otherUserImage)
                    : null,
                child: otherUserImage.isEmpty
                    ? const Icon(Icons.person, color: AppTheme.onSurface)
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
                            style: const TextStyle(
                              color: AppTheme.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
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
                              color: AppTheme.primaryCoral,
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
                              ? AppTheme.onSurface
                              : AppTheme.onSurfaceVariant,
                          fontSize: 14,
                          fontWeight: unreadCount > 0
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      _formatTimestamp(conversation.lastMessageAt),
                      style: const TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow icon
              const Icon(
                Icons.chevron_right,
                color: AppTheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
    }
  }
}
