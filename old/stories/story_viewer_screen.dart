import 'package:flutter/material.dart';
import 'package:faithfeed/services/logger_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../../models/story_model.dart';
import '../../theme/app_theme.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:faithfeed/screens/profile/user_profile_view_screen.dart'; // Import for UserProfileViewScreen

class StoryViewerScreen extends StatefulWidget {
  final List<Story> stories;
  final int initialIndex;

  const StoryViewerScreen({
    super.key,
    required this.stories,
    this.initialIndex = 0,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  int _currentIndex = 0;
  VideoPlayerController? _videoController;
  bool _isVideoInitializing = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextStory();
      }
    });

    _initializeCurrentStory();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCurrentStory() async {
    final story = widget.stories[_currentIndex];

    if (story.isVideo) {
      await _initializeVideoPlayer(story);
    } else {
      _progressController.forward();
    }
  }

  Future<void> _initializeVideoPlayer(Story story) async {
    setState(() {
      _isVideoInitializing = true;
    });

    try {
      _videoController?.dispose();
      final controller = VideoPlayerController.networkUrl(Uri.parse(story.mediaUrl));
      await controller.initialize();

      if (!mounted) return;

      setState(() {
        _videoController = controller;
        _isVideoInitializing = false;
      });

      // Set progress duration to video duration
      final videoDuration = controller.value.duration;
      _progressController.duration = videoDuration;

      controller.play();
      _progressController.forward();

      // Listen for video completion
      controller.addListener(() {
        if (controller.value.position >= controller.value.duration) {
          _nextStory();
        }
      });
    } catch (e) {
      Log.e('initializing video: $e');
      setState(() {
        _isVideoInitializing = false;
      });
      // Fall back to image-like behavior
      _progressController.duration = const Duration(seconds: 5);
      _progressController.forward();
    }
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onPageChanged(int index) {
    _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;

    setState(() {
      _currentIndex = index;
    });

    _progressController.reset();

    final story = widget.stories[index];
    if (story.isVideo) {
      _initializeVideoPlayer(story);
    } else {
      _progressController.duration = const Duration(seconds: 5);
      _progressController.forward();
    }
  }

  void _pauseStory() {
    _progressController.stop();
    _videoController?.pause();
  }

  void _resumeStory() {
    _progressController.forward();
    final story = widget.stories[_currentIndex];
    if (story.isVideo) {
      _videoController?.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          final tapPosition = details.globalPosition.dx;

          if (tapPosition < screenWidth / 2) {
            _previousStory();
          } else {
            _nextStory();
          }
        },
        onLongPress: _pauseStory,
        onLongPressEnd: (_) => _resumeStory(),
        child: Stack(
          children: [
            // Story content (images and videos)
            PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: widget.stories.length,
              itemBuilder: (context, index) {
                final story = widget.stories[index];

                if (story.isVideo && index == _currentIndex) {
                  // Show video player for current video story
                  if (_isVideoInitializing) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryTeal,
                      ),
                    );
                  }

                  if (_videoController != null && _videoController!.value.isInitialized) {
                    return Center(
                      child: AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      ),
                    );
                  }
                }

                // Show image for image stories or non-current video stories
                return CachedNetworkImage(
                  imageUrl: story.imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryTeal,
                    ),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),
                );
              },
            ),

            // Video indicator
            if (widget.stories[_currentIndex].isVideo)
              Positioned(
                bottom: 80,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.videocam, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Video',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),

            // Progress indicators
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: List.generate(
                    widget.stories.length,
                    (index) => Expanded(
                      child: Container(
                        height: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(1),
                        ),
                        child: index == _currentIndex
                            ? AnimatedBuilder(
                                animation: _progressController,
                                builder: (context, child) {
                                  return FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: _progressController.value,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(1),
                                      ),
                                    ),
                                  );
                                },
                              )
                            : index < _currentIndex
                                ? Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(1),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // User info header
            Positioned(
              top: 40,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          _pauseStory();
                          final userId = widget.stories[_currentIndex].userId;
                          if (userId.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserProfileViewScreen(userId: userId),
                              ),
                            ).then((_) => _resumeStory());
                          }
                        },
                        child: CircleAvatar(
                          radius: 20,
                          backgroundImage: widget.stories[_currentIndex]
                                  .userImageUrl
                                  .isNotEmpty
                              ? CachedNetworkImageProvider(
                                  widget.stories[_currentIndex].userImageUrl)
                              : null,
                          backgroundColor: AppTheme.surface,
                          child: widget.stories[_currentIndex].userImageUrl.isEmpty
                              ? const Icon(Icons.person,
                                  color: AppTheme.onSurfaceVariant)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            _pauseStory();
                            final userId = widget.stories[_currentIndex].userId;
                            if (userId.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserProfileViewScreen(userId: userId),
                                ),
                              ).then((_) => _resumeStory());
                            }
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.stories[_currentIndex].userName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                timeago.format(widget.stories[_currentIndex].createdAt),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
