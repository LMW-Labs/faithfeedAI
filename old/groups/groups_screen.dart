import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import '../../theme/app_theme.dart';
import '../../services/group_service.dart';
import '../../models/group_model.dart';
import 'create_group_screen.dart';
import 'discover_groups_screen.dart';
import 'group_detail_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> with SingleTickerProviderStateMixin {
  final GroupService _groupService = GroupService();
  late TabController _tabController;
  String _selectedCategory = 'All';

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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.lightBackgroundGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // Sleek App Bar with gradient
            SliverAppBar(
              expandedHeight: 160,
              floating: false,
              pinned: true,
              backgroundColor: AppTheme.surface,
              systemOverlayStyle: SystemUiOverlayStyle.light,
              actions: [
                IconButton(
                  icon: const Icon(Icons.explore_rounded, color: Colors.white),
                  tooltip: 'Discover Groups',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DiscoverGroupsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Groups',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
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
                        right: -30,
                        bottom: -30,
                        child: Icon(
                          Icons.groups_rounded,
                          size: 180,
                          color: Colors.white.withAlpha(26),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Tab Bar
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppTheme.primaryTeal,
                  indicatorWeight: 3,
                  labelColor: AppTheme.primaryTeal,
                  unselectedLabelColor: AppTheme.onSurfaceVariant,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  tabs: const [
                    Tab(text: 'Discover'),
                    Tab(text: 'My Groups'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildDiscoverTab(),
            _buildMyGroupsTab(),
          ],
        ),
      ),

      // Floating Action Button - Sleek and modern
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateGroupScreen()),
          );
        },
        backgroundColor: AppTheme.primaryTeal,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Create Group',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 4,
      ),
      ),
    );
  }

  Widget _buildDiscoverTab() {
    return Column(
      children: [
        // Category Filter - Horizontal scrollable chips
        Container(
          height: 50,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildCategoryChip('All'),
              ...GroupService.categories.map((category) => _buildCategoryChip(category)),
            ],
          ),
        ),

        // Groups List
        Expanded(
          child: StreamBuilder<List<Group>>(
            stream: _selectedCategory == 'All'
                ? _groupService.getPublicGroups()
                : _groupService.getGroupsByCategory(_selectedCategory),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryTeal),
                );
              }

              if (snapshot.hasError) {
                return Center(
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
                );
              }

              final groups = snapshot.data ?? [];

              if (groups.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.groups_outlined,
                        size: 80,
                        color: AppTheme.onSurfaceVariant.withValues(alpha:0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No groups found',
                        style: TextStyle(
                          color: AppTheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Be the first to create one!',
                        style: TextStyle(color: AppTheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  return _buildGroupCard(groups[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMyGroupsTab() {
    final userId = _groupService.currentUserId;

    if (userId == null) {
      return const Center(
        child: Text('Please sign in to view your groups'),
      );
    }

    return StreamBuilder<List<Group>>(
      stream: _groupService.getUserGroups(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryTeal),
          );
        }

        final groups = snapshot.data ?? [];

        if (groups.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.groups_outlined,
                  size: 80,
                  color: AppTheme.onSurfaceVariant.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'You haven\'t joined any groups yet',
                  style: TextStyle(
                    color: AppTheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Explore groups to get started',
                  style: TextStyle(color: AppTheme.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            return _buildGroupCard(groups[index], showRole: true);
          },
        );
      },
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

  Widget _buildGroupCard(Group group, {bool showRole = false}) {
    final userId = _groupService.currentUserId ?? '';
    final isAdmin = group.isAdmin(userId);
    final isCreator = group.isCreator(userId);

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
              height: 120,
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
                        color: AppTheme.primaryTeal.withValues(alpha:0.9),
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

                  // Role Badge (if applicable)
                  if (showRole && (isAdmin || isCreator))
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isCreator ? AppTheme.mintGreen : AppTheme.lightBlue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isCreator ? 'CREATOR' : 'ADMIN',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
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
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    group.description,
                    style: const TextStyle(
                      color: AppTheme.onSurfaceVariant,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Stats Row
                  Row(
                    children: [
                      // Members
                      _buildStat(
                        Icons.people_outline,
                        '${group.currentMemberCount}',
                        'members',
                      ),
                      const SizedBox(width: 16),

                      // Sessions
                      _buildStat(
                        Icons.video_camera_front_outlined,
                        '${group.totalSessions}',
                        'sessions',
                      ),

                      const Spacer(),

                      // Privacy Icon
                      Icon(
                        group.isPublic ? Icons.public : Icons.lock_outline,
                        size: 18,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ],
                  ),

                  // Meeting Schedule (if exists)
                  if (group.meetingSchedule != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.primaryTeal.withValues(alpha:0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: AppTheme.primaryTeal,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            group.formattedSchedule,
                            style: const TextStyle(
                              color: AppTheme.primaryTeal,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppTheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// Custom SliverPersistentHeaderDelegate for TabBar
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

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
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
