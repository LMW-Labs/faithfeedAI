import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/marketplace_service.dart';
import '../../models/marketplace_item_model.dart';

/// Saved/Bookmarked Marketplace Items Screen
class SavedItemsScreen extends StatefulWidget {
  const SavedItemsScreen({super.key});

  @override
  State<SavedItemsScreen> createState() => _SavedItemsScreenState();
}

class _SavedItemsScreenState extends State<SavedItemsScreen> {
  final MarketplaceService _marketplaceService = MarketplaceService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Saved Items'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<MarketplaceItemModel>>(
        stream: _marketplaceService.getSavedItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppTheme.primaryCoral,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Error loading saved items',
                    style: TextStyle(color: AppTheme.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.bookmark_outline,
                    size: 64,
                    color: AppTheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No saved items',
                    style: TextStyle(
                      color: AppTheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Bookmark items you\'re interested in',
                    style: TextStyle(color: AppTheme.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }

          final items = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return _buildSavedItemCard(items[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildSavedItemCard(MarketplaceItemModel item) {
    return Card(
      color: AppTheme.surface,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Item image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item.imageUrls.isNotEmpty
                  ? Image.network(
                      item.imageUrls.first,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholderImage();
                      },
                    )
                  : _buildPlaceholderImage(),
            ),
            const SizedBox(width: 12),

            // Item info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: AppTheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.displayPrice,
                    style: TextStyle(
                      color: item.displayPrice == 'FREE'
                          ? AppTheme.mintGreen
                          : AppTheme.softPeach,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (item.location != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: AppTheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.location!,
                            style: const TextStyle(
                              color: AppTheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // Unsave button
            IconButton(
              onPressed: () async {
                final success = await _marketplaceService.unsaveItem(item.id);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Item removed from saved')),
                  );
                }
              },
              icon: const Icon(
                Icons.bookmark,
                color: AppTheme.softPeach,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 80,
      height: 80,
      color: AppTheme.darkGrey,
      child: const Icon(
        Icons.storefront,
        size: 32,
        color: AppTheme.onSurfaceVariant,
      ),
    );
  }
}
