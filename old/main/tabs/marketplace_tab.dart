import 'package:flutter/material.dart';
import 'package:faithfeed/services/logger_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../theme/app_theme.dart';
import '../../../services/marketplace_service.dart';
import '../../../models/marketplace_item_model.dart';
import '../../marketplace/create_marketplace_item_screen.dart';
import '../../marketplace/saved_items_screen.dart';
import '../../marketplace/marketplace_conversations_list_screen.dart';
import '../../marketplace/marketplace_conversation_screen.dart';
import '../../../services/mock_data_service.dart';

class MarketplaceTab extends StatefulWidget {
  const MarketplaceTab({super.key});

  @override
  State<MarketplaceTab> createState() => _MarketplaceTabState();
}

class _MarketplaceTabState extends State<MarketplaceTab> {
  final MarketplaceService _marketplaceService = MarketplaceService();
  MarketplaceCategory? _selectedCategory;
  String? _currentUserName;
  String? _currentUserProfileImage;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
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
              _currentUserProfileImage = profile['profileImage'] as String? ?? '';
            });
          }
        }
      } catch (e) {
        Log.e('loading user profile: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('FaithFinds'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Saved items button
          IconButton(
            icon: const Icon(Icons.bookmark, color: AppTheme.lightOnSurface),
            tooltip: 'Saved Items',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SavedItemsScreen(),
                ),
              );
            },
          ),
          // Messages button
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: AppTheme.lightOnSurface),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MarketplaceConversationsListScreen(),
                ),
              );
            },
          ),
          // Category filter
          PopupMenuButton<MarketplaceCategory?>(
            icon: const Icon(Icons.filter_list, color: AppTheme.lightOnSurface),
            color: AppTheme.surface,
            onSelected: (category) {
              setState(() {
                _selectedCategory = category;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('All Categories', style: TextStyle(color: AppTheme.onSurface)),
              ),
              ...MarketplaceCategory.values.map((category) {
                return PopupMenuItem(
                  value: category,
                  child: Text(
                    category.displayName,
                    style: const TextStyle(color: AppTheme.onSurface),
                  ),
                );
              }),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.lightOnSurface),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateMarketplaceItemScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<MarketplaceItemModel>>(
        stream: _marketplaceService.getMarketplaceItemsStream(
          category: _selectedCategory,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppTheme.primaryCoral),
                  const SizedBox(height: 16),
                  const Text(
                    'Error loading items',
                    style: TextStyle(color: AppTheme.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }

          final items = (snapshot.data != null && snapshot.data!.isNotEmpty)
              ? snapshot.data!
              : MockDataService.getMarketplaceItems();
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return _buildListingCard(items[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildListingCard(MarketplaceItemModel item) {
    final isMockItem = item.id.startsWith('mock-');

    return Card(
      color: AppTheme.surface,
      margin: const EdgeInsets.only(bottom: 16.0),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show image if available, otherwise show placeholder
          Stack(
            children: [
              if (item.imageUrls.isNotEmpty)
                Image.network(
                  item.imageUrls.first,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPlaceholderImage();
                  },
                )
              else
                _buildPlaceholderImage(),
              Positioned(
                top: 8,
                left: 8,
                child: _buildCategoryBadge(item.category),
              ),
              // Example badge for mock items
              if (isMockItem)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(180),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Example',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User info
                Row(
                  children: [
                    if (item.userProfileImageUrl.isNotEmpty)
                      CircleAvatar(
                        radius: 12,
                        backgroundImage: NetworkImage(item.userProfileImageUrl),
                      ),
                    if (item.userProfileImageUrl.isNotEmpty)
                      const SizedBox(width: 8),
                    Text(
                      item.userName,
                      style: const TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.title,
                  style: const TextStyle(
                    color: AppTheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: const TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.location != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 14, color: AppTheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        item.location!,
                        style: const TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.displayPrice,
                      style: TextStyle(
                        color: item.displayPrice == 'FREE'
                            ? AppTheme.mintGreen
                            : AppTheme.softPeach,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _showItemDetails(item);
                      },
                      child: const Text('View Details'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: 180,
      color: AppTheme.darkGrey,
      child: const Icon(
        Icons.storefront,
        size: 64,
        color: AppTheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildCategoryBadge(MarketplaceCategory category) {
    Color badgeColor;
    switch (category) {
      case MarketplaceCategory.free:
        badgeColor = AppTheme.mintGreen;
        break;
      case MarketplaceCategory.event:
        badgeColor = AppTheme.lightPurple;
        break;
      case MarketplaceCategory.service:
        badgeColor = AppTheme.lightBlue;
        break;
      case MarketplaceCategory.housing:
        badgeColor = AppTheme.lightPurple;
        break;
      case MarketplaceCategory.jobs:
        badgeColor = AppTheme.primaryCoral;
        break;
      default:
        badgeColor = AppTheme.primaryTeal;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        category.displayName,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  void _showItemDetails(MarketplaceItemModel item) {
    // Track view (only for real items, not mock data)
    final isMockItem = item.id.startsWith('mock-');
    if (!isMockItem) {
      _marketplaceService.trackItemView(item.id);
    }

    // Get current user ID directly from Firebase Auth to ensure accuracy
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isSaved = item.savedByUserIds.contains(currentUserId);
    // Only show as own item if we have a valid current user ID and it matches
    // Never treat mock items as owned (they can't be deleted from Firestore)
    final isOwnItem = !isMockItem && currentUserId != null && item.userId == currentUserId;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar with save and close buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () async {
                        if (isSaved) {
                          await _marketplaceService.unsaveItem(item.id);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Removed from saved items')),
                            );
                          }
                        } else {
                          await _marketplaceService.saveItem(item.id);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Saved for later')),
                            );
                          }
                        }
                        Navigator.pop(context);
                      },
                      icon: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_border,
                        color: AppTheme.softPeach,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: AppTheme.onSurfaceVariant),
                    ),
                  ],
                ),
                // Images carousel or single image
                if (item.imageUrls.isNotEmpty)
                  SizedBox(
                    height: 300,
                    child: PageView.builder(
                      itemCount: item.imageUrls.length,
                      itemBuilder: (context, index) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            item.imageUrls[index],
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),
                  )
                else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildPlaceholderImage(),
                  ),
                const SizedBox(height: 16),

                // Category badge and Example badge
                Row(
                  children: [
                    _buildCategoryBadge(item.category),
                    if (isMockItem) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.withAlpha(100),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.withAlpha(150)),
                        ),
                        child: const Text(
                          'Example Listing',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // Price
                Text(
                  item.displayPrice,
                  style: TextStyle(
                    color: item.displayPrice == 'FREE'
                        ? AppTheme.mintGreen
                        : AppTheme.softPeach,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Title
                Text(
                  item.title,
                  style: const TextStyle(
                    color: AppTheme.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // User info
                Row(
                  children: [
                    if (item.userProfileImageUrl.isNotEmpty)
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(item.userProfileImageUrl),
                      ),
                    if (item.userProfileImageUrl.isNotEmpty)
                      const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.userName,
                          style: const TextStyle(
                            color: AppTheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Posted ${_formatDate(item.createdAt)}',
                          style: const TextStyle(
                            color: AppTheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Description
                const Text(
                  'Description',
                  style: TextStyle(
                    color: AppTheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.description,
                  style: const TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),

                // Location
                if (item.location != null) ...[
                  const Text(
                    'Location',
                    style: TextStyle(
                      color: AppTheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: AppTheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text(
                        item.location!,
                        style: const TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Contact info
                if (item.contactInfo != null) ...[
                  const Text(
                    'Contact',
                    style: TextStyle(
                      color: AppTheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.contactInfo!,
                    style: const TextStyle(
                      color: AppTheme.softPeach,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Analytics
                if (isOwnItem) ...[
                  const Divider(color: AppTheme.onSurfaceVariant),
                  const Text(
                    'Item Stats',
                    style: TextStyle(
                      color: AppTheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildStatChip(Icons.visibility, '${item.views} views'),
                      const SizedBox(width: 12),
                      _buildStatChip(Icons.favorite, '${item.interests} interested'),
                      const SizedBox(width: 12),
                      _buildStatChip(Icons.bookmark, '${item.savedByUserIds.length} saved'),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Actions for non-owners
                if (!isOwnItem) ...[
                  // Show message for mock items
                  if (isMockItem) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(50),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withAlpha(100)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.info_outline, color: Colors.grey, size: 32),
                          SizedBox(height: 8),
                          Text(
                            'This is an example listing',
                            style: TextStyle(
                              color: AppTheme.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Create your own listing or browse real items from the community.',
                            style: TextStyle(
                              color: AppTheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Primary action: Buy Now (only show if item has a price)
                    if (item.displayPrice != 'FREE') ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _handleBuyNow(context, item),
                          icon: const Icon(Icons.shopping_cart),
                          label: const Text('Buy Now'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryTeal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Primary action: Contact Seller
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (_currentUserName == null || _currentUserProfileImage == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please complete your profile first')),
                            );
                            return;
                          }

                          // Start conversation
                          final conversationId = await _marketplaceService.startConversation(
                            itemId: item.id,
                            itemTitle: item.title,
                            sellerId: item.userId,
                            sellerName: item.userName,
                            sellerProfileImage: item.userProfileImageUrl,
                            buyerName: _currentUserName!,
                            buyerProfileImage: _currentUserProfileImage!,
                          );

                          if (conversationId != null && mounted) {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MarketplaceConversationScreen(
                                  conversationId: conversationId,
                                  itemTitle: item.title,
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.message),
                        label: const Text('Message Seller'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.softPeach,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Secondary actions: Interested and Save
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await _marketplaceService.trackItemInterest(item.id);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Marked as interested!'),
                                    backgroundColor: AppTheme.primaryTeal,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.favorite_border),
                            label: const Text('Interested'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryCoral,
                              side: const BorderSide(color: AppTheme.primaryCoral),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            if (isSaved) {
                              await _marketplaceService.unsaveItem(item.id);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Removed from saved items')),
                                );
                              }
                            } else {
                              await _marketplaceService.saveItem(item.id);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Saved for later!'),
                                    backgroundColor: AppTheme.primaryTeal,
                                  ),
                                );
                              }
                            }
                            Navigator.pop(context);
                          },
                          icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
                          label: Text(isSaved ? 'Saved' : 'Save'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.softPeach,
                            side: const BorderSide(color: AppTheme.softPeach),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  ],
                ],

                // Actions for owner
                if (isOwnItem)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: AppTheme.surface,
                            title: const Text(
                              'Delete Item',
                              style: TextStyle(color: AppTheme.onSurface),
                            ),
                            content: const Text(
                              'Are you sure you want to delete this item?',
                              style:
                                  TextStyle(color: AppTheme.onSurfaceVariant),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text(
                                  'Delete',
                                  style:
                                      TextStyle(color: AppTheme.primaryCoral),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          final success = await _marketplaceService
                              .deleteMarketplaceItem(item.id);
                          if (mounted && success) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Item deleted successfully')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.delete, color: Colors.white),
                      label: const Text('Delete Item'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryCoral,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                // Bottom padding to ensure content isn't cut off
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.darkGrey,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryTeal),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.onSurface,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  Future<void> _handleBuyNow(BuildContext context, MarketplaceItemModel item) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryTeal),
      ),
    );

    try {
      // Check if seller can receive payments
      final canReceive = await _marketplaceService.canSellerReceivePayments(item.userId);

      if (!canReceive) {
        if (mounted) {
          Navigator.pop(context); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This seller hasn\'t set up payments yet. Try messaging them instead.'),
              backgroundColor: AppTheme.primaryCoral,
            ),
          );
        }
        return;
      }

      // Parse price
      final price = double.tryParse(item.price.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;

      if (price <= 0) {
        if (mounted) {
          Navigator.pop(context); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid price for this item.'),
              backgroundColor: AppTheme.primaryCoral,
            ),
          );
        }
        return;
      }

      // Initiate purchase
      final result = await _marketplaceService.initiatePurchase(
        itemId: item.id,
        itemName: item.title,
        itemPrice: price,
        sellerId: item.userId,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading
      }

      if (result['success'] == true) {
        final sessionId = result['sessionId'] as String;
        // Open Stripe Checkout in browser
        final checkoutUrl = Uri.parse('https://checkout.stripe.com/c/pay/$sessionId');

        if (await canLaunchUrl(checkoutUrl)) {
          await launchUrl(checkoutUrl, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not open payment page. Please try again.'),
                backgroundColor: AppTheme.primaryCoral,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Failed to start checkout.'),
              backgroundColor: AppTheme.primaryCoral,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.primaryCoral,
          ),
        );
      }
    }
  }
}
