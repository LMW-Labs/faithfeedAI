import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../services/prayer_service.dart';
import '../../../models/prayer_request_model.dart';
import '../../prayer/create_prayer_request_screen.dart';
import '../../../services/mock_data_service.dart';

// UX ENHANCEMENTS
import '../../../utils/ui_helpers.dart';
import '../../../widgets/skeleton_loading.dart';
import '../../../widgets/empty_states.dart';
import '../../../widgets/optimized_image.dart';

// Main Tab Widget
class PrayerWallTab extends StatefulWidget {
  const PrayerWallTab({super.key});

  @override
  State<PrayerWallTab> createState() => _PrayerWallTabState();
}

class _PrayerWallTabState extends State<PrayerWallTab> {
  final PrayerService _prayerService = PrayerService();
  List<PrayerRequest> _prayerRequests = [];
  StreamSubscription<QuerySnapshot>? _prayerSubscription;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _listenToPrayers();
  }

  @override
  void dispose() {
    _prayerSubscription?.cancel();
    super.dispose();
  }

  void _listenToPrayers() {
    _prayerSubscription =
        _prayerService.getPrayerRequestsDocumentStream().listen((snapshot) {
      setState(() {
        _isLoading = false;
        _prayerRequests = snapshot.docs
            .map((doc) => PrayerRequest.fromFirestore(doc))
            .toList();
      });
    }, onError: (error) {
      print('Error loading prayers: $error');
      setState(() {
        _isLoading = false;
      });
      // Handle error, e.g., show a snackbar
    });
  }

  Future<void> _refreshPrayerRequests() async {
    // This will re-trigger the stream and refresh the data
    setState(() {
      _isLoading = true;
      _prayerRequests = [];
    });
    _prayerSubscription?.cancel();
    _listenToPrayers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Prayer Wall'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              HapticHelper.light();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreatePrayerRequestScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: PullToRefreshWrapper(
        onRefresh: _refreshPrayerRequests,
        child: _isLoading
            ? ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                itemCount: 5,
                itemBuilder: (context, index) => const SkeletonPrayerCard(),
              )
            : _prayerRequests.isEmpty
                ? EmptyState(
                    icon: Icons.error_outline,
                    title: 'No Prayers Yet',
                    message: 'Be the first to add a prayer to the wall.',
                    actionLabel: 'Add Prayer',
                    onAction: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const CreatePrayerRequestScreen(),
                        ),
                      );
                    },
                    iconColor: AppTheme.primaryCoral.withOpacity(0.5),
                    textColor: AppTheme.lightOnSurface,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _prayerRequests.length,
                    itemBuilder: (context, index) {
                      return PrayerRequestCard(
                        request: _prayerRequests[index],
                        prayerService: _prayerService,
                      );
                    },
                  ),
      ),
    );
  }
}

// A stateful widget for each card to manage prayer interactions
class PrayerRequestCard extends StatefulWidget {
  final PrayerRequest request;
  final PrayerService prayerService;

  const PrayerRequestCard({
    super.key,
    required this.request,
    required this.prayerService,
  });

  @override
  State<PrayerRequestCard> createState() => _PrayerRequestCardState();
}

class _PrayerRequestCardState extends State<PrayerRequestCard> {
  bool _isProcessing = false;
  bool _hasUserPrayed = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPrayerStatus();
  }

  Future<void> _checkPrayerStatus() async {
    final currentUserId = widget.prayerService.currentUserId;
    if (currentUserId == null) {
      setState(() {
        _hasUserPrayed = false;
        _isLoading = false;
      });
      return;
    }

    final hasPrayed = await widget.prayerService.hasUserPrayedForRequest(
      widget.request.id,
      currentUserId,
    );

    if (mounted) {
      setState(() {
        _hasUserPrayed = hasPrayed;
        _isLoading = false;
      });
    }
  }

  Future<void> _handlePrayerTap() async {
    if (_isProcessing) return;

    HapticHelper.medium();

    final currentUserId = widget.prayerService.currentUserId;
    if (currentUserId == null) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Must be logged in to pray');
      }
      return;
    }

    // OPTIMISTIC UI: Update immediately
    final wasPraying = _hasUserPrayed;
    setState(() {
      _hasUserPrayed = !_hasUserPrayed;
      _isProcessing = true;
    });

    try {
      bool success;
      if (wasPraying) {
        success = await widget.prayerService.unprayForRequest(widget.request.id);
      } else {
        success = await widget.prayerService.prayForRequest(widget.request.id);
      }

      if (success && mounted) {
        // Success - show feedback
        if (!wasPraying) {
          SnackbarHelper.showSuccess(context, 'You are praying for this request');
        }
      } else {
        // Failed - revert optimistic update
        if (mounted) {
          setState(() {
            _hasUserPrayed = wasPraying;
          });
          SnackbarHelper.showError(
            context,
            'Something went wrong. Please try again.',
          );
        }
      }
    } catch (e) {
      // Error - revert optimistic update
      if (mounted) {
        setState(() {
          _hasUserPrayed = wasPraying;
        });
        SnackbarHelper.showError(context, 'Failed to update prayer');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showOptionsMenu() {
    final currentUserId = widget.prayerService.currentUserId;
    final isOwner = currentUserId == widget.request.userId;

    HapticHelper.light();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOwner)
              ListTile(
                leading: const Icon(Icons.delete, color: AppTheme.primaryCoral),
                title: const Text(
                  'Delete Prayer Request',
                  style: TextStyle(color: AppTheme.primaryCoral),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final confirmed = await ConfirmationDialog.showDeleteConfirmation(
                    context,
                    title: 'Delete Prayer Request?',
                    message: 'This action cannot be undone.',
                  );

                  if (confirmed && mounted) {
                    final success = await widget.prayerService.deletePrayerRequest(widget.request.id);
                    if (mounted) {
                      if (success) {
                        SnackbarHelper.showSuccess(context, 'Prayer request deleted');
                      } else {
                        SnackbarHelper.showError(context, 'Failed to delete prayer request');
                      }
                    }
                  }
                },
              ),
            ListTile(
              leading: const Icon(Icons.cancel, color: AppTheme.onSurfaceVariant),
              title: const Text(
                'Cancel',
                style: TextStyle(color: AppTheme.onSurfaceVariant),
              ),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = widget.prayerService.currentUserId;
    final isOwner = currentUserId == widget.request.userId;

    return Card(
      color: AppTheme.surface,
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (!widget.request.isAnonymous && widget.request.userProfileImageUrl.isNotEmpty) ...[
                        OptimizedAvatar(
                          imageUrl: widget.request.userProfileImageUrl,
                          size: 32,
                          fallbackIcon: Icons.person,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          widget.request.displayName,
                          style: const TextStyle(
                            color: AppTheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOwner)
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: AppTheme.onSurfaceVariant),
                    onPressed: _showOptionsMenu,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.request.request,
              style: const TextStyle(
                color: AppTheme.onSurfaceVariant,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: AppTheme.darkGrey),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${widget.request.prayerCount} ${widget.request.prayerCount == 1 ? 'person is' : 'people are'} praying',
                  style: const TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                TextButton.icon(
                  onPressed: (_isProcessing || _isLoading) ? null : _handlePrayerTap,
                  icon: (_isProcessing || _isLoading)
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.softPeach,
                          ),
                        )
                      : Icon(
                          _hasUserPrayed ? Icons.favorite : Icons.volunteer_activism,
                          size: 18,
                          color: const Color(0xFFF5EB2F), // Yellow pray button
                        ),
                  label: Text(
                    _hasUserPrayed ? "Praying" : "I'm Praying",
                    style: const TextStyle(
                      color: Color(0xFFF5EB2F), // Yellow pray button text
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFF5EB2F).withOpacity(0.1), // Yellow background
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
