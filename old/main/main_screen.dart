import 'dart:ui' show ImageFilter;
import 'package:faithfeed/models/notification_model.dart' as model;
import 'package:faithfeed/services/notification_service.dart';
import 'package:faithfeed/services/logger_service.dart';
import 'package:faithfeed/services/user_profile_service.dart';
import 'package:faithfeed/services/semantic_search_service.dart';
import 'package:faithfeed/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../models/bible_verse_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/verse_actions_modal.dart';
import '../../widgets/profile_switcher.dart';
import 'ai_tools/ai_study_partner_screen.dart';
import '../chat/chat_contacts_screen.dart';
import '../../widgets/floating_ai_button.dart';
import 'create_post_modal.dart';
import 'friends_list_screen.dart';
import '../groups/groups_screen.dart';
import 'tabs/bible_reader_tab.dart';
import 'tabs/explore_tab.dart';
import 'tabs/home_tab.dart';
import 'tabs/marketplace_tab.dart';
import 'tabs/prayer_wall_tab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  final List<_TabInfo> _tabs = const [
    _TabInfo(
      svgPath: 'assets/home.svg',
    ),
    _TabInfo(
      svgPath: 'assets/reader.svg',
    ),
    _TabInfo(
      svgPath: 'assets/explore.svg',
    ),
    _TabInfo(
      svgPath: 'assets/marketplace.svg',
    ),
    _TabInfo(
      svgPath: 'assets/prayerhands.svg',
    ),
  ];

  final List<Widget> _pages = const [
    HomeTab(), // Feed/Home tab
    BibleReaderTab(), // Reader tab
    ExploreTab(), // Explore tab with tools/games
    MarketplaceTab(), // Marketplace tab
    PrayerWallTab(), // Prayer Wall tab
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentIndex = _tabController.index;
        });
      }
    });

    // Load user profile on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileService = Provider.of<UserProfileService>(context, listen: false);
      profileService.fetchUserProfile();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAISearchModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AISemanticSearchModal(),
    );
  }

  void _openNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.lightSurface,
      builder: (context) => const _NotificationsSheet(),
    );
  }

  void _closeDrawerThen(VoidCallback action) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    Future.microtask(() {
      if (mounted) {
        action();
      }
    });
  }

  void _openCreatePostComposer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.90,
        child: const CreatePostModal(),
      ),
    );
  }

  void _showFeaturesDrawer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.lightSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
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
                    'Features',
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
            Divider(color: AppTheme.lightOnSurfaceMuted.withValues(alpha: 0.3)),
            // Menu items
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(
                    icon: Icons.add_circle_outline,
                    title: 'Create Post',
                    subtitle: 'Share your faith journey',
                    onTap: () {
                      _closeDrawerThen(_openCreatePostComposer);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.message_outlined,
                    title: 'Messages',
                    subtitle: 'Chat with friends',
                    onTap: () {
                      _closeDrawerThen(() {
                        Navigator.of(this.context).push(
                          MaterialPageRoute(
                            builder: (context) => const ChatContactsScreen(),
                          ),
                        );
                      });
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.people_outline,
                    title: 'Friends',
                    subtitle: 'Connect with believers',
                    onTap: () {
                      _closeDrawerThen(() {
                        Navigator.of(this.context).push(
                          MaterialPageRoute(
                            builder: (context) => const FriendsListScreen(),
                          ),
                        );
                      });
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.groups_outlined,
                    title: 'Groups',
                    subtitle: 'Prayer groups & Bible studies',
                    onTap: () {
                      _closeDrawerThen(() {
                        Navigator.of(this.context).push(
                          MaterialPageRoute(
                            builder: (context) => const GroupsScreen(),
                          ),
                        );
                      });
                    },
                  ),
                  Divider(color: AppTheme.lightOnSurfaceMuted.withValues(alpha: 0.3), height: 32),
                  // Logout option
                  _buildDrawerItem(
                    icon: Icons.logout,
                    title: 'Log Out',
                    subtitle: 'Sign out of your account',
                    onTap: () async {
                      Navigator.pop(context); // Close drawer first

                      // Get authService before async gap
                      final authService = Provider.of<AuthService>(context, listen: false);

                      // Show confirmation dialog
                      final confirmed = await showDialog<bool>(
                        context: this.context,
                        builder: (context) => AlertDialog(
                          backgroundColor: AppTheme.lightSurface,
                          title: Text(
                            'Log Out',
                            style: TextStyle(color: AppTheme.lightOnSurface),
                          ),
                          content: Text(
                            'Are you sure you want to log out?',
                            style: TextStyle(color: AppTheme.lightOnSurfaceVariant),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                'Log Out',
                                style: TextStyle(color: AppTheme.primaryCoral),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true && mounted) {
                        await authService.signOut();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Track unread messages count - can be updated via stream/provider
  int _unreadMessagesCount = 0;

  Widget _buildMessagesIcon() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(
            Icons.chat_bubble_outline, 
            size: 24, 
            color: Colors.white,
            shadows: [
              Shadow(color: AppTheme.primaryBlue.withValues(alpha: 0.8), blurRadius: 12),
              const Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
            ],
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ChatContactsScreen(),
              ),
            );
          },
          tooltip: 'Messages',
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(),
        ),
        // Badge for unread messages
        if (_unreadMessagesCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppTheme.primaryCoral,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                _unreadMessagesCount > 9 ? '9+' : '$_unreadMessagesCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNotificationsIcon() {
    return StreamBuilder<int>(
      stream: NotificationService().getUnreadCountStream(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Icon(
                Icons.notifications_none, 
                size: 24, 
                color: Colors.white,
                shadows: [
                  Shadow(color: AppTheme.primaryBlue.withValues(alpha: 0.8), blurRadius: 12),
                  const Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
                ],
              ),
              onPressed: _openNotificationsSheet,
              tooltip: 'Notifications',
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
            ),
            // Badge for unread notifications
            if (unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryCoral,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isComingSoon = false,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 24, color: AppTheme.primaryBlue),
      ),
      title: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppTheme.lightOnSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (isComingSoon)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryCoral.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryCoral, width: 1),
                ),
                child: const Text(
                  'Coming Soon',
                  style: TextStyle(
                    color: AppTheme.primaryCoral,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppTheme.lightOnSurfaceVariant,
          fontSize: 13,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: AppTheme.lightOnSurfaceVariant),
      onTap: onTap,
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
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(100), // 48 toolbar + 50 tabs + 2 (indicator/border)
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryTeal.withValues(alpha: 0.9), // Slightly more opaque light blue
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      // Toolbar
                      SizedBox(
                        height: 48,
                        child: Stack(
                          children: [
                            // faithfeed logo centered with glow
                            Positioned.fill(
                              child: Center(
                                child: Container(
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withValues(alpha: 0.8),
                                        blurRadius: 25,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: SvgPicture.asset(
                                    'assets/images/faithfeed.svg',
                                    height: 38, // Slightly larger
                                  ),
                                ),
                              ),
                            ),
                            // Left side icons
                            Positioned(
                              left: 8,
                              top: 0,
                              bottom: 0,
                              child: Row(
                                children: [
                                  _buildNotificationsIcon(),
                                  const SizedBox(width: 4),
                                  // Features Menu Drawer (was + button)
                                  IconButton(
                                    icon: Icon(
                                      Icons.menu, 
                                      size: 24, 
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(color: AppTheme.primaryBlue.withValues(alpha: 0.8), blurRadius: 12),
                                        const Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
                                      ],
                                    ),
                                    onPressed: () {
                                      _showFeaturesDrawer();
                                    },
                                    tooltip: 'Features',
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ),
                            // Right side icons
                            Positioned(
                              right: 8,
                              top: 0,
                              bottom: 0,
                              child: Row(
                                children: [
                                  // Messages icon with badge support
                                  _buildMessagesIcon(),
                                  const SizedBox(width: 4),
                                  // Profile switcher (rounded square)
                                  const ProfileSwitcher(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // TabBar
                      SizedBox(
                        height: 50,
                        child: TabBar(
                          controller: _tabController,
                          indicatorColor: Colors.white,
                          indicatorWeight: 3.0,
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
                          tabs: _tabs.asMap().entries.map((entry) {
                            final index = entry.key;
                            final tab = entry.value;
                            final isSelected = _currentIndex == index;

                            return Tab(
                              icon: Container(
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryBlue.withValues(alpha: isSelected ? 0.4 : 0.2),
                                      blurRadius: isSelected ? 12 : 8,
                                      spreadRadius: isSelected ? 1 : 0,
                                    ),
                                  ],
                                ),
                                child: tab.svgPath != null
                                    ? SvgPicture.asset(
                                        tab.svgPath!,
                                        width: 26,
                                        height: 26,
                                        colorFilter: ColorFilter.mode(
                                          isSelected ? Colors.white : Colors.white.withValues(alpha: 0.6),
                                          BlendMode.srcIn,
                                        ),
                                      )
                                    : Icon(
                                        isSelected ? tab.selectedIcon : tab.icon,
                                        size: 26,
                                        color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.6),
                                        shadows: [
                                          Shadow(
                                            color: AppTheme.primaryBlue.withValues(alpha: 0.6),
                                            blurRadius: isSelected ? 10 : 6,
                                          ),
                                        ],
                                      ),
                              ),
                              height: 50,
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            SafeArea(
              top: false, // AppBar already handles top safe area
              child: TabBarView(
                controller: _tabController,
                children: _pages,
              ),
            ),
            // Draggable FAB - shows Semantic Search on Bible tab, AI Study Partner on others
            FloatingAIButton(
              onPressed: () {
                if (_currentIndex == 1) {
                  // Bible Reader tab - show semantic search
                  _showAISearchModal();
                } else {
                  // Other tabs - show AI Study Partner
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AIStudyPartnerScreen(),
                    ),
                  );
                }
              },
              showSearchIcon: _currentIndex == 1,
            ),
          ],
        ),
      ),
    );
  }
}

class _TabInfo {
  final String? svgPath; // Path to SVG asset (if using custom SVG)
  final IconData? icon; // Fallback IconData (if no SVG)
  final IconData? selectedIcon;

  const _TabInfo({
    this.svgPath,
    this.icon,
    this.selectedIcon,
  });
}

// AI Semantic Search Modal
class _AISemanticSearchModal extends StatefulWidget {
  const _AISemanticSearchModal();

  @override
  State<_AISemanticSearchModal> createState() => _AISemanticSearchModalState();
}

class _AISemanticSearchModalState extends State<_AISemanticSearchModal> {
  final TextEditingController _searchController = TextEditingController();
  final SemanticSearchService _searchService = SemanticSearchService();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  String? _errorMessage;
  bool _isListening = false;
  bool _isSpeechAvailable = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      _isSpeechAvailable = await _speechToText.initialize(
        onError: (error) {
          Log.d('Speech error: $error');
          if (mounted) {
            setState(() => _isListening = false);
          }
        },
        onStatus: (status) {
          Log.d('Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            if (mounted) {
              setState(() => _isListening = false);
            }
          }
        },
      );
    } catch (e) {
      Log.e('Speech initialization failed: $e');
      _isSpeechAvailable = false;
    }
    if (mounted) setState(() {});
  }

  Future<void> _startListening() async {
    if (!_isSpeechAvailable) return;

    // Strong click haptic feedback
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 50), () {
      HapticFeedback.selectionClick();
    });
    setState(() => _isListening = true);

    try {
      await _speechToText.listen(
        onResult: (result) {
          if (!mounted) return;
          setState(() {
            _searchController.text = result.recognizedWords;
          });
          // Auto-search when user stops speaking
          if (result.finalResult && _searchController.text.isNotEmpty) {
            _performSearch(_searchController.text);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );
    } catch (e) {
      Log.d('Speech listen error: $e');
      if (mounted) {
        setState(() => _isListening = false);
      }
    }
  }

  Future<void> _stopListening() async {
    // Strong click haptic feedback
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 50), () {
      HapticFeedback.selectionClick();
    });
    try {
      await _speechToText.stop();
    } catch (e) {
      Log.d('Error stopping speech: $e');
    }
    if (mounted) {
      setState(() => _isListening = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _speechToText.stop();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _searchResults = [];
    });

    try {
      final results = await _searchService.findSimilarVerses(
        verseText: query,
        limit: 20,
      );

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      Log.d('❌ Search error: $e');
      Log.e('Error type: ${e.runtimeType}');
      final errorStr = e.toString();
      String displayError;
      if (errorStr.contains('quota')) {
        displayError = 'AI Search temporarily unavailable. Please try again later.';
      } else if (errorStr.contains('unauthenticated') || errorStr.contains('Authentication')) {
        displayError = 'Please sign in to use semantic search.';
      } else if (errorStr.contains('internal') || errorStr.contains('INTERNAL')) {
        displayError = 'Server error. Please try again in a moment.';
      } else if (errorStr.contains('timeout') || errorStr.contains('DEADLINE_EXCEEDED')) {
        displayError = 'Search timed out. Please try a shorter query.';
      } else if (errorStr.contains('unavailable') || errorStr.contains('UNAVAILABLE')) {
        displayError = 'AI Search service is temporarily unavailable. Please try again.';
      } else {
        // Show actual error for debugging
        displayError = 'Search failed: ${errorStr.replaceAll('Exception: ', '')}';
      }
      setState(() {
        _errorMessage = displayError;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: AppTheme.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
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
          // Search header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: AppTheme.primaryBlue, size: 24),
                const SizedBox(width: 8),
                Text(
                  'AI Semantic Search',
                  style: TextStyle(
                    color: AppTheme.lightOnSurface,
                    fontSize: 20,
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
          // Search description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Search by meaning, not just keywords. Try "love your neighbor" or "faith and hope"',
              style: TextStyle(
                color: AppTheme.lightOnSurfaceVariant,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          // Search input with mic button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    autofocus: !_isListening,
                    style: TextStyle(color: AppTheme.lightOnSurface),
                    decoration: InputDecoration(
                      hintText: _isListening ? 'Listening...' : 'Search scriptures by meaning...',
                      hintStyle: TextStyle(
                        color: _isListening ? AppTheme.primaryBlue : AppTheme.lightOnSurfaceVariant,
                        fontStyle: _isListening ? FontStyle.italic : FontStyle.normal,
                      ),
                      filled: true,
                      fillColor: AppTheme.lightSurfaceHighlight,
                      prefixIcon: Icon(Icons.search, color: AppTheme.primaryBlue),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: AppTheme.lightOnSurfaceVariant),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchResults = [];
                                  _errorMessage = null;
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) => setState(() {}),
                    onSubmitted: _performSearch,
                  ),
                ),
                const SizedBox(width: 8),
                // Mic button
                GestureDetector(
                  onTap: () {
                    if (_isListening) {
                      _stopListening();
                    } else {
                      _startListening();
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening
                          ? AppTheme.primaryBlue
                          : AppTheme.lightSurfaceHighlight,
                      border: Border.all(
                        color: _isListening
                            ? AppTheme.primaryBlue
                            : AppTheme.lightOnSurfaceMuted.withValues(alpha: 0.3),
                        width: 1,
                      ),
                      boxShadow: _isListening
                          ? [
                              BoxShadow(
                                color: AppTheme.primaryBlue.withValues(alpha: 0.4),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      _isListening ? Icons.stop : Icons.mic,
                      color: _isListening ? Colors.white : AppTheme.primaryBlue,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Results
          Expanded(
            child: _buildResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryBlue),
            const SizedBox(height: 16),
            Text(
              'Searching scriptures...',
              style: TextStyle(color: AppTheme.lightOnSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              'First search may take up to a minute',
              style: TextStyle(
                color: AppTheme.lightOnSurfaceVariant.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppTheme.lightOnSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(color: AppTheme.lightOnSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _performSearch(_searchController.text),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_searchResults.isEmpty && _searchController.text.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No results found. Try a different search.',
            style: TextStyle(color: AppTheme.lightOnSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search, size: 64, color: AppTheme.lightOnSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                'Enter a search to find verses',
                style: TextStyle(
                  color: AppTheme.lightOnSurfaceVariant,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try searching for concepts like:\n"comfort in hard times"\n"God\'s promises"\n"trusting in faith"',
                style: TextStyle(
                  color: AppTheme.lightOnSurfaceVariant,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        final verseModel = _mapResultToVerse(result);
        final reference = verseModel?.reference ?? _extractReference(result['verse']) ?? 'Unknown';
        final text = verseModel?.text ?? _extractVerseText(result);
        final score = ((result['score'] ?? 0.0) as num).toDouble() * 100;

        return Card(
          color: AppTheme.lightSurfaceHighlight,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppTheme.lightOnSurfaceMuted.withValues(alpha: 0.2)),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: verseModel == null
                ? null
                : () {
                    Navigator.pop(context);
                    _openVerseActions(verseModel);
                  },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          reference,
                          style: TextStyle(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${score.clamp(0, 100).toStringAsFixed(0)}% match',
                          style: TextStyle(
                            color: AppTheme.primaryBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    text,
                    style: TextStyle(
                      color: AppTheme.lightOnSurface,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  BibleVerseModel? _mapResultToVerse(Map<String, dynamic> result) {
    final reference = (result['reference'] ?? _extractReference(result['verse']))?.toString();
    final text = (result['text'] ?? _extractVerseText(result)).toString();
    if (reference == null || reference.isEmpty || text.isEmpty) {
      return null;
    }

    final parsed = _parseReference(reference);
    if (parsed == null) {
      return null;
    }

    return BibleVerseModel(
      book: parsed.book,
      chapter: parsed.chapter,
      verse: parsed.verse,
      text: text,
      reference: reference,
      translation: (result['version'] ?? result['translation'] ?? 'ASV').toString(),
    );
  }

  Future<void> _openVerseActions(BibleVerseModel verse) async {
    final nextVerse = await showModalBottomSheet<BibleVerseModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VerseActionsModal(verse: verse),
    );
    if (!mounted || nextVerse == null) return;
    await _openVerseActions(nextVerse);
  }

  String? _extractReference(dynamic raw) {
    if (raw == null) return null;
    final input = raw.toString().trim();
    if (input.isEmpty) return null;
    final match = RegExp(r'^([1-3]?\s?[A-Za-z]+(?:\s+[A-Za-z]+)*)\s+(\d+):(\d+)').firstMatch(input);
    if (match == null) return null;
    return '${match.group(1)} ${match.group(2)}:${match.group(3)}';
  }

  String _extractVerseText(Map<String, dynamic> result) {
    final verse = result['verse']?.toString();
    if (verse == null || verse.isEmpty) {
      return result['text']?.toString() ?? '';
    }
    final reference = _extractReference(verse);
    if (reference == null) {
      return verse;
    }
    return verse.substring(reference.length).trim();
  }

  _ParsedReference? _parseReference(String reference) {
    final match = RegExp(r'^([1-3]?\s?[A-Za-z]+(?:\s+[A-Za-z]+)*)\s+(\d+):(\d+)').firstMatch(reference.trim());
    if (match == null) return null;
    return _ParsedReference(
      book: match.group(1)!.trim(),
      chapter: int.tryParse(match.group(2)!) ?? 0,
      verse: int.tryParse(match.group(3)!) ?? 0,
    );
  }
}

class _ParsedReference {
  final String book;
  final int chapter;
  final int verse;

  const _ParsedReference({
    required this.book,
    required this.chapter,
    required this.verse,
  });
}

class _NotificationsSheet extends StatefulWidget {
  const _NotificationsSheet();

  @override
  State<_NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<_NotificationsSheet> {
  late Future<List<model.Notification>> _notificationsFuture;
  final NotificationService _notificationService = NotificationService();
  List<model.Notification> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    setState(() {
      _notificationsFuture = _notificationService.getNotifications();
    });
    _notificationsFuture.then((notifications) {
      setState(() {
        _notifications = notifications;
      });
    });
  }

  IconData _getIconForType(model.NotificationType type) {
    switch (type) {
      case model.NotificationType.friendRequest:
        return Icons.person_add;
      case model.NotificationType.friendAccepted:
        return Icons.people;
      case model.NotificationType.postLike:
      case model.NotificationType.like:
        return Icons.favorite;
      case model.NotificationType.postComment:
      case model.NotificationType.comment:
        return Icons.comment;
      case model.NotificationType.postMention:
        return Icons.alternate_email;
      case model.NotificationType.prayerRequest:
        return Icons.volunteer_activism;
      case model.NotificationType.prayerAnswered:
        return Icons.celebration;
      case model.NotificationType.communityInvite:
        return Icons.group_add;
      case model.NotificationType.follow:
        return Icons.person_add;
      case model.NotificationType.system:
        return Icons.notifications;
    }
  }

  Future<void> _dismissNotification(String notificationId) async {
    final success = await _notificationService.dismissNotification(notificationId);
    if (success) {
      setState(() {
        _notifications.removeWhere((n) => n.id == notificationId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification dismissed'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _markAsRead(model.Notification notification) async {
    if (!notification.isRead) {
      await _notificationService.markAsRead(notification.id);
      setState(() {
        notification.isRead = true;
      });
    }
  }

  void _handleNotificationTap(model.Notification notification) {
    // Close the notification sheet
    Navigator.pop(context);

    // Navigate based on notification type
    switch (notification.type) {
      case model.NotificationType.friendRequest:
      case model.NotificationType.friendAccepted:
      case model.NotificationType.follow:
        // Navigate to friends list
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FriendsListScreen()),
        );
        break;
      case model.NotificationType.postLike:
      case model.NotificationType.postComment:
      case model.NotificationType.postMention:
      case model.NotificationType.like:
      case model.NotificationType.comment:
        // TODO: Navigate to specific post if postId is in data
        break;
      case model.NotificationType.prayerRequest:
      case model.NotificationType.prayerAnswered:
        // TODO: Navigate to prayer wall or specific prayer
        break;
      case model.NotificationType.communityInvite:
        // TODO: Navigate to community
        break;
      case model.NotificationType.system:
        // System notifications don't navigate anywhere
        break;
    }
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.lightSurface,
        title: Text('Clear All Notifications', style: TextStyle(color: AppTheme.lightOnSurface)),
        content: Text(
          'Are you sure you want to delete all notifications?',
          style: TextStyle(color: AppTheme.lightOnSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _notificationService.clearAllNotifications();
      if (success && mounted) {
        setState(() {
          _notifications.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications cleared')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: AppTheme.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          // Header with actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notifications',
                  style: TextStyle(
                    color: AppTheme.lightOnSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    if (_notifications.any((n) => !n.isRead))
                      TextButton(
                        onPressed: () async {
                          await _notificationService.markAllAsRead();
                          setState(() {
                            for (var n in _notifications) {
                              n.isRead = true;
                            }
                          });
                        },
                        child: const Text('Mark all read'),
                      ),
                    if (_notifications.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.delete_sweep, color: AppTheme.lightOnSurfaceVariant),
                        onPressed: _clearAll,
                        tooltip: 'Clear all',
                      ),
                  ],
                ),
              ],
            ),
          ),
          Divider(color: AppTheme.lightOnSurfaceMuted.withValues(alpha: 0.3)),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<model.Notification>>(
              future: _notificationsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading notifications.',
                      style: TextStyle(color: AppTheme.lightOnSurfaceVariant),
                    ),
                  );
                }

                if (_notifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_outlined, size: 64, color: AppTheme.lightOnSurfaceVariant),
                        const SizedBox(height: 16),
                        Text(
                          'You\'re all caught up!',
                          style: TextStyle(
                            color: AppTheme.lightOnSurfaceVariant,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    return Dismissible(
                      key: Key(notification.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        _dismissNotification(notification.id);
                      },
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: Card(
                        color: notification.isRead ? AppTheme.lightSurfaceHighlight : AppTheme.lightSurface,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: AppTheme.lightOnSurfaceMuted.withValues(alpha: 0.2)),
                        ),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: notification.senderPhotoUrl != null && notification.senderPhotoUrl!.isNotEmpty
                              ? CircleAvatar(
                                  backgroundImage: NetworkImage(notification.senderPhotoUrl!),
                                  radius: 20,
                                )
                              : Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: notification.isRead
                                        ? AppTheme.lightOnSurfaceVariant.withValues(alpha: 0.1)
                                        : AppTheme.primaryBlue.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _getIconForType(notification.type),
                                    color: notification.isRead ? AppTheme.lightOnSurfaceVariant : AppTheme.primaryBlue,
                                    size: 20,
                                  ),
                                ),
                          title: Text(
                            notification.title.isNotEmpty ? notification.title : notification.body,
                            style: TextStyle(
                              color: notification.isRead ? AppTheme.lightOnSurfaceVariant : AppTheme.lightOnSurface,
                              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w600,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (notification.title.isNotEmpty && notification.body.isNotEmpty)
                                Text(
                                  notification.body,
                                  style: TextStyle(
                                    color: AppTheme.lightOnSurfaceVariant,
                                    fontSize: 13,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              Text(
                                notification.timeAgo,
                                style: TextStyle(
                                  color: AppTheme.lightOnSurfaceVariant.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          trailing: !notification.isRead
                              ? Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryBlue,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : null,
                          onTap: () {
                            _markAsRead(notification);
                            _handleNotificationTap(notification);
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

}
