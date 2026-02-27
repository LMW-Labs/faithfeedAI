import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import '../../theme/app_theme.dart';
import '../../services/group_service.dart';
import '../../models/group_model.dart';
import 'group_detail_screen.dart';

class DiscoverGroupsScreen extends StatefulWidget {
  const DiscoverGroupsScreen({super.key});

  @override
  State<DiscoverGroupsScreen> createState() => _DiscoverGroupsScreenState();
}

class _DiscoverGroupsScreenState extends State<DiscoverGroupsScreen> {
  final GroupService _groupService = GroupService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: CustomScrollView(
        slivers: [
          // App Bar with frosted glass gradient
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.surface,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Discover Groups',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Colors.white,
                ),
              ),
              background: ClipRect(
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
                    // Icon decoration
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Icon(
                        Icons.explore_rounded,
                        size: 120,
                        color: Colors.white.withAlpha(26),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: AppTheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Search groups...',
                  hintStyle: TextStyle(color: AppTheme.onSurfaceVariant.withAlpha(180)),
                  prefixIcon: const Icon(Icons.search, color: AppTheme.primaryTeal),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppTheme.onSurfaceVariant),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppTheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value.trim());
                },
              ),
            ),
          ),

          // Category Filter Chips
          SliverToBoxAdapter(
            child: SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildCategoryChip('All'),
                  ...GroupService.categories.map((category) => _buildCategoryChip(category)),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 8),
          ),

          // Groups List
          _buildGroupsList(),

          // Bottom padding
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(category),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = category;
          });
        },
        backgroundColor: AppTheme.surface,
        selectedColor: AppTheme.primaryTeal,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppTheme.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        elevation: isSelected ? 4 : 0,
        pressElevation: 2,
      ),
    );
  }

  Widget _buildGroupsList() {
    // Use search query if provided, otherwise use category filter
    Stream<List<Group>> groupsStream;

    if (_searchQuery.isNotEmpty) {
      groupsStream = _groupService.searchGroups(_searchQuery);
    } else if (_selectedCategory == 'All') {
      groupsStream = _groupService.getPublicGroups();
    } else {
      groupsStream = _groupService.getGroupsByCategory(_selectedCategory);
    }

    return StreamBuilder<List<Group>>(
      stream: groupsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(color: AppTheme.primaryTeal),
            ),
          );
        }

        if (snapshot.hasError) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppTheme.primaryCoral),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading groups',
                    style: TextStyle(color: AppTheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          );
        }

        final groups = snapshot.data ?? [];

        // Filter by category if searching
        final filteredGroups = _searchQuery.isNotEmpty && _selectedCategory != 'All'
            ? groups.where((g) => g.category == _selectedCategory).toList()
            : groups;

        if (filteredGroups.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.groups_outlined,
                    size: 80,
                    color: AppTheme.onSurfaceVariant.withAlpha(128),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'No groups match "$_searchQuery"'
                        : 'No groups found',
                    style: const TextStyle(
                      color: AppTheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'Try a different search term'
                        : 'Be the first to create one!',
                    style: TextStyle(color: AppTheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return _buildGroupCard(filteredGroups[index]);
              },
              childCount: filteredGroups.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildGroupCard(Group group) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppTheme.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupDetailScreen(groupId: group.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image or Gradient Header
            Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.softPeach,
                    AppTheme.lightBlue,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                image: group.coverImageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(group.coverImageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: Stack(
                children: [
                  // Category Badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal.withAlpha(230),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        group.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Privacy Icon
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(100),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        group.isPublic ? Icons.public : Icons.lock_outline,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Group Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group Name
                  Text(
                    group.name,
                    style: const TextStyle(
                      color: AppTheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Description
                  Text(
                    group.description,
                    style: const TextStyle(
                      color: AppTheme.onSurfaceVariant,
                      fontSize: 13,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Stats Row
                  Row(
                    children: [
                      // Members
                      Icon(Icons.people_outline, size: 16, color: AppTheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        '${group.currentMemberCount}',
                        style: const TextStyle(
                          color: AppTheme.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'members',
                        style: TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Sessions
                      Icon(Icons.video_camera_front_outlined, size: 16, color: AppTheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        '${group.totalSessions}',
                        style: const TextStyle(
                          color: AppTheme.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'sessions',
                        style: TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),

                      const Spacer(),

                      // Join button
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GroupDetailScreen(groupId: group.id),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: AppTheme.primaryTeal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'View',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
