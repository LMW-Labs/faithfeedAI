import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:faithfeed/models/friend_model.dart';
import 'package:faithfeed/services/friends_service.dart';
import 'package:faithfeed/theme/app_theme.dart';
import 'package:faithfeed/utils/ui_helpers.dart';
import 'package:faithfeed/widgets/optimized_image.dart';
import 'package:faithfeed/widgets/skeleton_loading.dart';
import '../profile/user_profile_view_screen.dart';

class FindFriendsScreen extends StatefulWidget {
  const FindFriendsScreen({super.key});

  @override
  State<FindFriendsScreen> createState() => _FindFriendsScreenState();
}

class _FindFriendsScreenState extends State<FindFriendsScreen> {
  final FriendsService _friendsService = FriendsService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<Friend> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _errorMessage;

  // Advanced search filters
  bool _showAdvancedFilters = false;
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _churchController = TextEditingController();
  final TextEditingController _denominationController = TextEditingController();

  // Debounce timer for live search
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Auto-focus search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });

    // Add listener for live search
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _churchController.dispose();
    _denominationController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // Cancel previous timer
    _debounceTimer?.cancel();

    final query = _searchController.text.trim();

    // Only search if query has at least 2 characters
    if (query.length >= 2) {
      // Debounce: wait 300ms after user stops typing
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        _performSearch();
      });
    } else if (query.isEmpty && _hasSearched) {
      // Clear results if search is cleared
      setState(() {
        _searchResults = [];
        _hasSearched = false;
        _errorMessage = null;
      });
    }
  }

  bool get _hasActiveFilters {
    return _cityController.text.isNotEmpty ||
        _stateController.text.isNotEmpty ||
        _churchController.text.isNotEmpty ||
        _denominationController.text.isNotEmpty;
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();

    // Require either a search query or at least one filter
    if (query.isEmpty && !_hasActiveFilters) {
      setState(() {
        _errorMessage = 'Please enter a search term or use filters';
        _searchResults = [];
        _hasSearched = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasSearched = true;
    });

    try {
      List<Friend> results;

      if (_hasActiveFilters) {
        // Use advanced search with filters
        results = await _friendsService.advancedSearchUsers(
          query: query.isNotEmpty ? query : null,
          city: _cityController.text.trim().isNotEmpty
              ? _cityController.text.trim()
              : null,
          state: _stateController.text.trim().isNotEmpty
              ? _stateController.text.trim()
              : null,
          church: _churchController.text.trim().isNotEmpty
              ? _churchController.text.trim()
              : null,
          denomination: _denominationController.text.trim().isNotEmpty
              ? _denominationController.text.trim()
              : null,
        );
      } else {
        // Use simple search
        results = await _friendsService.searchUsers(query);
      }

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error searching. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  void _clearFilters() {
    setState(() {
      _cityController.clear();
      _stateController.clear();
      _churchController.clear();
      _denominationController.clear();
    });
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchResults = [];
      _hasSearched = false;
      _errorMessage = null;
    });
    _searchFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: const Text(
          'Find Friends',
          style: TextStyle(color: AppTheme.onSurface),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.onSurfaceVariant),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Section - Container instead of Flexible flex:0
            Container(
              color: AppTheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(16),
                                                                child: SingleChildScrollView(
                                                                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                                                                  child: Column(
                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                    children: [
                                                                      // Main search field
                                                                      TextField(
                                                                        controller: _searchController,
                                                                        focusNode: _searchFocusNode,
                                                                        style: const TextStyle(color: AppTheme.onSurface),
                                                                        decoration: InputDecoration(
                                                                          hintText: 'Search by name, username, or email',
                                                                          hintStyle: TextStyle(
                                                                            color: AppTheme.onSurface.withValues(alpha: 0.5),
                                                                          ),
                                                                          prefixIcon: const Icon(
                                                                            Icons.search,
                                                                            color: AppTheme.onSurfaceVariant,
                                                                          ),
                                                                          suffixIcon: _searchController.text.isNotEmpty
                                                                              ? IconButton(
                                                                                  icon: const Icon(
                                                                                    Icons.clear,
                                                                                    color: AppTheme.onSurfaceVariant,
                                                                                  ),
                                                                                  onPressed: _clearSearch,
                                                                                )
                                                                              : null,
                                                                          filled: true,
                                                                          fillColor: AppTheme.background,
                                                                          border: OutlineInputBorder(
                                                                            borderRadius: BorderRadius.circular(12),
                                                                            borderSide: BorderSide.none,
                                                                          ),
                                                                          contentPadding: const EdgeInsets.symmetric(
                                                                            horizontal: 16,
                                                                            vertical: 12,
                                                                          ),
                                                                        ),
                                                                        textInputAction: TextInputAction.search,
                                                                        onSubmitted: (_) => _performSearch(),
                                                                        onChanged: (_) => setState(() {}),
                                                                      ),
                                                
                                                                      const SizedBox(height: 12),
                                                
                                                                      // Advanced filters toggle and search button row
                                                                      Wrap(
                                                                        spacing: 8,
                                                                        runSpacing: 8,
                                                                        alignment: WrapAlignment.spaceBetween,
                                                                        crossAxisAlignment: WrapCrossAlignment.center,
                                                                        children: [
                                                                          // Advanced filters toggle
                                                                          TextButton.icon(
                                                                            onPressed: () {
                                                                              setState(() {
                                                                                _showAdvancedFilters = !_showAdvancedFilters;
                                                                              });
                                                                            },
                                                                            icon: Icon(
                                                                              _showAdvancedFilters
                                                                                  ? Icons.expand_less
                                                                                  : Icons.tune,
                                                                              size: 20,
                                                                              color: _hasActiveFilters
                                                                                  ? AppTheme.primaryCoral
                                                                                  : AppTheme.onSurfaceVariant,
                                                                            ),
                                                                            label: Text(
                                                                              _showAdvancedFilters ? 'Hide' : 'Advanced',
                                                                              style: TextStyle(
                                                                                color: _hasActiveFilters
                                                                                    ? AppTheme.primaryCoral
                                                                                    : AppTheme.onSurfaceVariant,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          if (_hasActiveFilters)
                                                                            TextButton(
                                                                              onPressed: _clearFilters,
                                                                              child: const Text(
                                                                                'Clear',
                                                                                style: TextStyle(color: AppTheme.onSurfaceVariant),
                                                                              ),
                                                                            ),
                                                                          // Search button
                                                                          ElevatedButton(
                                                                            onPressed: _isLoading ? null : _performSearch,
                                                                            style: ElevatedButton.styleFrom(
                                                                              backgroundColor: AppTheme.primaryCoral,
                                                                              foregroundColor: Colors.white,
                                                                              shape: RoundedRectangleBorder(
                                                                                borderRadius: BorderRadius.circular(8),
                                                                              ),
                                                                              padding: const EdgeInsets.symmetric(
                                                                                horizontal: 20,
                                                                                vertical: 10,
                                                                              ),
                                                                            ),
                                                                            child: _isLoading
                                                                                ? const SizedBox(
                                                                                    width: 20,
                                                                                    height: 20,
                                                                                    child: CircularProgressIndicator(
                                                                                      strokeWidth: 2,
                                                                                      color: Colors.white,
                                                                                    ),
                                                                                  )
                                                                                : const Text('Search'),
                                                                          ),
                                                                        ],
                                                                      ),
                                                
                                                                      // Advanced filters section
                                                                      if (_showAdvancedFilters) ...[
                                                                        const SizedBox(height: 16),
                                                                        const Divider(height: 1),
                                                                        const SizedBox(height: 16),
                                                                        const Text(
                                                                          'Filter by:',
                                                                          style: TextStyle(
                                                                            color: AppTheme.onSurfaceVariant,
                                                                            fontWeight: FontWeight.w500,
                                                                          ),
                                                                        ),
                                                                        const SizedBox(height: 12),
                                                                        // Location row
                                                                        Row(
                                                                          children: [
                                                                            Expanded(
                                                                              child: _buildFilterField(
                                                                                controller: _cityController,
                                                                                hint: 'City',
                                                                                icon: Icons.location_city,
                                                                              ),
                                                                            ),
                                                                            const SizedBox(width: 12),
                                                                            Expanded(
                                                                              child: _buildFilterField(
                                                                                controller: _stateController,
                                                                                hint: 'State',
                                                                                icon: Icons.map,
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                        const SizedBox(height: 12),
                                                                        // Church/Denomination row
                                                                        Row(
                                                                          children: [
                                                                            Expanded(
                                                                              child: _buildFilterField(
                                                                                controller: _churchController,
                                                                                hint: 'Church',
                                                                                icon: Icons.church,
                                                                              ),
                                                                            ),
                                                                            const SizedBox(width: 12),
                                                                            Expanded(
                                                                              child: _buildFilterField(
                                                                                controller: _denominationController,
                                                                                hint: 'Denomination',
                                                                                icon: Icons.groups,
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ],
                                                                    ],
                                                                  ),
                                                                ),
              ),
            ),
            // Results Section
            Expanded(
              child: _buildResultsSection(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: AppTheme.onSurface, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: AppTheme.onSurface.withValues(alpha: 0.5),
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, size: 20, color: AppTheme.onSurfaceVariant),
        filled: true,
        fillColor: AppTheme.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: true,
      ),
      textInputAction: TextInputAction.next,
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildResultsSection() {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) => const SkeletonUserTile(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: AppTheme.primaryCoral.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppTheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (!_hasSearched) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_search,
                size: 64,
                color: AppTheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              const Text(
                'Search for friends',
                style: TextStyle(
                  color: AppTheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Search by name, username, or email.\nUse advanced filters to find people by location or church.',
                style: TextStyle(
                  color: AppTheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 48,
                color: AppTheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              const Text(
                'No users found',
                style: TextStyle(
                  color: AppTheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try a different search term or adjust your filters.',
                style: TextStyle(
                  color: AppTheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return _UserSearchResultTile(
          user: user,
          friendsService: _friendsService,
          onTap: () {
            HapticHelper.light();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserProfileViewScreen(userId: user.id),
              ),
            );
          },
        );
      },
    );
  }
}

class _UserSearchResultTile extends StatefulWidget {
  final Friend user;
  final FriendsService friendsService;
  final VoidCallback onTap;

  const _UserSearchResultTile({
    required this.user,
    required this.friendsService,
    required this.onTap,
  });

  @override
  State<_UserSearchResultTile> createState() => _UserSearchResultTileState();
}

class _UserSearchResultTileState extends State<_UserSearchResultTile> {
  String? _requestStatus;
  bool _isLoading = false;
  bool _isFriend = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final isFriend = await widget.friendsService.areFriends(
      widget.friendsService.currentUserId ?? '',
      widget.user.id,
    );
    if (isFriend) {
      if (mounted) setState(() => _isFriend = true);
      return;
    }

    final status = await widget.friendsService.getFriendRequestStatus(widget.user.id);
    if (mounted) setState(() => _requestStatus = status);
  }

  Future<void> _sendFriendRequest() async {
    setState(() => _isLoading = true);
    try {
      await widget.friendsService.sendFriendRequest(widget.user.id);
      if (mounted) {
        setState(() {
          _requestStatus = 'sent';
          _isLoading = false;
        });
        SnackbarHelper.showSuccess(context, 'Friend request sent!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelper.showError(context, 'Failed to send request: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: OptimizedAvatar(
        imageUrl: widget.user.profileImageUrl.isNotEmpty
            ? widget.user.profileImageUrl
            : null,
        size: 50,
        fallbackIcon: Icons.person,
      ),
      title: Text(
        widget.user.displayName,
        style: const TextStyle(
          color: AppTheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: widget.user.username.isNotEmpty
          ? Text(
              '@${widget.user.username}',
              style: TextStyle(
                color: AppTheme.onSurface.withValues(alpha: 0.6),
              ),
            )
          : null,
      trailing: _buildTrailingWidget(),
      onTap: widget.onTap,
    );
  }

  Widget _buildTrailingWidget() {
    if (_isFriend) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.successGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'Friends',
          style: TextStyle(
            color: AppTheme.successGreen,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    if (_isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (_requestStatus == 'sent') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.onSurfaceVariant.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          'Pending',
          style: TextStyle(
            color: AppTheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    if (_requestStatus == 'received') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.primaryCoral.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          'Respond',
          style: TextStyle(
            color: AppTheme.primaryCoral,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return IconButton(
      icon: const Icon(Icons.person_add, color: AppTheme.primaryCoral),
      onPressed: _sendFriendRequest,
    );
  }
}

extension FriendsServiceExtension on FriendsService {
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;
}