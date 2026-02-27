import 'package:flutter/material.dart';
import 'package:faithfeed/services/logger_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../services/marketplace_service.dart';
import '../../models/marketplace_conversation_model.dart';

/// Marketplace Conversation Screen
/// Secure messaging between buyer and seller
class MarketplaceConversationScreen extends StatefulWidget {
  final String conversationId;
  final String itemTitle;

  const MarketplaceConversationScreen({
    super.key,
    required this.conversationId,
    required this.itemTitle,
  });

  @override
  State<MarketplaceConversationScreen> createState() =>
      _MarketplaceConversationScreenState();
}

class _MarketplaceConversationScreenState
    extends State<MarketplaceConversationScreen> {
  final MarketplaceService _marketplaceService = MarketplaceService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? _currentUserId;
  String? _currentUserName;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _markAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      // Get profile data directly from Firestore
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final data = doc.data();
          final profile = data?['profile'] as Map<String, dynamic>?;
          if (profile != null) {
            setState(() {
              final firstName = profile['firstName'] as String? ?? '';
              final lastName = profile['lastName'] as String? ?? '';
              _currentUserName = '$firstName $lastName'.trim();
              if (_currentUserName!.isEmpty) {
                _currentUserName = user.email?.split('@').first ?? 'User';
              }
            });
          }
        }
      } catch (e) {
        Log.e('loading user profile: $e');
      }
    }
  }

  Future<void> _markAsRead() async {
    await _marketplaceService.markConversationAsRead(widget.conversationId);
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _currentUserName == null) return;

    final success = await _marketplaceService.sendMessage(
      conversationId: widget.conversationId,
      message: message,
      senderName: _currentUserName!,
    );

    if (success) {
      _messageController.clear();
      // Scroll to bottom after sending
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'FaithFinds Message',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              widget.itemTitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Safety notice banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: AppTheme.primaryTeal.withValues(alpha:0.1),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_user,
                  size: 16,
                  color: AppTheme.primaryTeal,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'All conversations are monitored for community safety',
                    style: const TextStyle(
                      color: AppTheme.primaryTeal,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Messages list
          Expanded(
            child: StreamBuilder<List<MarketplaceMessage>>(
              stream: _marketplaceService.getMessages(widget.conversationId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading messages',
                      style: const TextStyle(color: AppTheme.onSurfaceVariant),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
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
                          'No messages yet',
                          style: TextStyle(
                            color: AppTheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Start the conversation',
                          style: TextStyle(color: AppTheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data!;
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // Start from bottom
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessageBubble(messages[index]);
                  },
                );
              },
            ),
          ),

          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: Border(
                top: BorderSide(
                  color: AppTheme.onSurfaceVariant.withValues(alpha:0.1),
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: AppTheme.onSurface),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: const TextStyle(
                          color: AppTheme.onSurfaceVariant,
                        ),
                        filled: true,
                        fillColor: AppTheme.darkBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(width: 12),
                  FloatingActionButton(
                    onPressed: _sendMessage,
                    backgroundColor: AppTheme.softPeach,
                    mini: true,
                    child: const Icon(Icons.send, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MarketplaceMessage message) {
    final isMe = message.senderId == _currentUserId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.darkGrey,
              child: Icon(Icons.person, size: 16, color: AppTheme.onSurface),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? AppTheme.softPeach : AppTheme.darkGrey,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isMe)
                        Text(
                          message.senderName,
                          style: TextStyle(
                            color: AppTheme.primaryTeal,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (!isMe) const SizedBox(height: 4),
                      Text(
                        message.message,
                        style: TextStyle(
                          color: isMe ? Colors.white : AppTheme.onSurface,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTimestamp(message.timestamp),
                  style: const TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.softPeach,
              child: Icon(Icons.person, size: 16, color: Colors.white),
            ),
          ],
        ],
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
