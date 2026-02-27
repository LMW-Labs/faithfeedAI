import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import '../../theme/app_theme.dart';
import '../../services/group_service.dart';
import '../../models/group_model.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;

  const GroupDetailScreen({
    super.key,
    required this.groupId,
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> with SingleTickerProviderStateMixin {
  final GroupService _groupService = GroupService();
  late TabController _tabController;
  Group? _group;
  bool _isLoading = true;
  bool _isMember = false;
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadGroup();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGroup() async {
    setState(() => _isLoading = true);

    final group = await _groupService.getGroup(widget.groupId);

    if (mounted) {
      setState(() {
        _group = group;
        _isLoading = false;
        if (group != null && _groupService.currentUserId != null) {
          _isMember = group.isMember(_groupService.currentUserId!);
        }
      });
    }
  }

  Future<void> _toggleMembership() async {
    if (_group == null || _groupService.currentUserId == null) return;

    setState(() => _isJoining = true);

    bool success;
    if (_isMember) {
      success = await _groupService.leaveGroup(widget.groupId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Left group')),
        );
      }
    } else {
      if (_group!.isFull) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This group is full'),
            backgroundColor: AppTheme.primaryCoral,
          ),
        );
        setState(() => _isJoining = false);
        return;
      }

      success = await _groupService.joinGroup(widget.groupId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_group!.requiresApproval
                ? 'Join request sent - awaiting approval'
                : 'Joined group successfully!'),
            backgroundColor: AppTheme.mintGreen,
          ),
        );
      }
    }

    if (success) {
      await _loadGroup();
    }

    setState(() => _isJoining = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
            iconTheme: IconThemeData(color: AppTheme.lightOnSurface),
          ),
          body: const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryTeal),
          ),
        ),
      );
    }

    if (_group == null) {
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
            iconTheme: IconThemeData(color: AppTheme.lightOnSurface),
          ),
          body: Center(
            child: Text(
              'Group not found',
              style: TextStyle(color: AppTheme.lightOnSurface),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.lightBackgroundGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 250,
              floating: false,
              pinned: true,
              backgroundColor: AppTheme.surface,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  _group!.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 3.0,
                        color: Color.fromARGB(128, 0, 0, 0),
                      ),
                    ],
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryTeal,
                        AppTheme.lightBlue,
                      ],
                    ),
                    image: _group!.coverImageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(_group!.coverImageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha:0.7),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            // Group Info Header
            Container(
              color: AppTheme.surface,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Badge & Stats
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryTeal,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _group!.category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      _buildStatChip(
                        Icons.people,
                        '${_group!.currentMemberCount}/${_group!.maxMembers}',
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        Icons.video_camera_front,
                        '${_group!.totalSessions}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Description
                  Text(
                    _group!.description,
                    style: const TextStyle(
                      color: AppTheme.onSurfaceVariant,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),

                  // Meeting Schedule
                  if (_group!.meetingSchedule != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryTeal.withValues(alpha:0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: AppTheme.primaryTeal,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _group!.formattedSchedule,
                            style: const TextStyle(
                              color: AppTheme.primaryTeal,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Join/Leave Button
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isJoining ? null : _toggleMembership,
                      icon: _isJoining
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(_isMember ? Icons.exit_to_app : Icons.group_add),
                      label: Text(
                        _isMember ? 'Leave Group' : 'Join Group',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isMember ? AppTheme.primaryCoral : AppTheme.primaryTeal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              color: AppTheme.surface,
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primaryTeal,
                labelColor: AppTheme.primaryTeal,
                unselectedLabelColor: AppTheme.onSurfaceVariant,
                tabs: const [
                  Tab(text: 'Feed'),
                  Tab(text: 'Members'),
                  Tab(text: 'About'),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildFeedTab(),
                  _buildMembersTab(),
                  _buildAboutTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedTab() {
    // Placeholder for group discussions - coming soon
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.forum_outlined,
            size: 64,
            color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Group Discussions',
            style: TextStyle(
              color: AppTheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Coming soon! Share prayer requests,\nverses, and discussions with your group.',
            style: TextStyle(color: AppTheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMembersTab() {
    if (_group == null) return const SizedBox();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Member count header
        Text(
          '${_group!.currentMemberCount} Members',
          style: const TextStyle(
            color: AppTheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Creator/Admin section
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryTeal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryTeal,
                child: const Icon(Icons.admin_panel_settings, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _group!.creatorName,
                      style: const TextStyle(
                        color: AppTheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Group Creator',
                      style: TextStyle(
                        color: AppTheme.primaryTeal,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Other members placeholder
        if (_group!.memberIds.length > 1) ...[
          Text(
            '${_group!.memberIds.length - 1} other member${_group!.memberIds.length > 2 ? 's' : ''}',
            style: const TextStyle(
              color: AppTheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAboutTab() {
    if (_group == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description section
          const Text(
            'About',
            style: TextStyle(
              color: AppTheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _group!.description,
            style: const TextStyle(
              color: AppTheme.onSurfaceVariant,
              fontSize: 15,
              height: 1.5,
            ),
          ),

          // Rules section
          if (_group!.rules.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Group Rules',
              style: TextStyle(
                color: AppTheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(_group!.rules.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: AppTheme.primaryTeal,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _group!.rules[index],
                        style: const TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          // Group Settings Info
          const SizedBox(height: 24),
          const Text(
            'Group Info',
            style: TextStyle(
              color: AppTheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.category, 'Category', _group!.category),
          _buildInfoRow(
            Icons.lock_outline,
            'Privacy',
            _group!.isPublic ? 'Public' : 'Private',
          ),
          _buildInfoRow(
            Icons.how_to_reg,
            'Membership',
            _group!.requiresApproval ? 'Requires approval' : 'Open to join',
          ),
          _buildInfoRow(
            Icons.people,
            'Capacity',
            '${_group!.currentMemberCount}/${_group!.maxMembers} members',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(
              color: AppTheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
