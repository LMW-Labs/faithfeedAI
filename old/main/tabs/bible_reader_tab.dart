import 'package:flutter/material.dart';
import 'package:faithfeed/services/logger_service.dart';
import 'package:flutter/gestures.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/bible_verse_model.dart';
import '../../../services/semantic_search_service.dart';
import '../../../services/text_to_speech_service.dart';
import '../../../services/openai_tts_service.dart';
import '../../../services/highlight_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/verse_actions_modal.dart';
import '../../../widgets/add_verse_note_sheet.dart';
import '../../../data/bible_data.dart';

class BibleReaderTab extends StatefulWidget {
  final String? initialBook;
  final int? initialChapter;
  final int? initialVerse;

  const BibleReaderTab({
    super.key,
    this.initialBook,
    this.initialChapter,
    this.initialVerse,
  });

  @override
  State<BibleReaderTab> createState() => _BibleReaderTabState();
}

class _BibleReaderTabState extends State<BibleReaderTab> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final TextToSpeechService _ttsService = TextToSpeechService();
  final OpenAITTSService _openAiTts = OpenAITTSService();

  bool _isAutoScrolling = false;
  final double _autoScrollSpeed = 30.0; // pixels per second
  Timer? _autoScrollTimer;
  DateTime? _lastTapTime; // For double-tap detection
  int _tapCount = 0; // For triple-tap detection
  Timer? _tapTimer; // Reset tap count after delay

  List<BibleVerseModel> _verses = [];
  bool _isSearching = false;
  bool _loadingSearch = false;
  bool _loadingChapter = false;
  bool _isSpeaking = false;
  bool _isPaused = false;
  bool _isOpenAiTtsSpeaking = false; // For long-press TTS
  int? _currentReadingVerseIndex; // Track which verse is being read

  // Multi-verse selection
  bool _isSelectionMode = false;
  Set<String> _selectedVerseRefs = {}; // Stores verse references (e.g., "John 3:16")

  // Verse highlights
  final HighlightService _highlightService = HighlightService();
  Map<String, String> _highlights = {}; // verse reference -> color name

  // Default to Genesis 1
  String _currentBook = "Genesis";
  int _currentChapter = 1;
  String? _focusedVerseRef;

  @override
  void initState() {
    super.initState();
    if (widget.initialBook != null && widget.initialBook!.isNotEmpty) {
      _currentBook = widget.initialBook!;
    }
    if (widget.initialChapter != null && widget.initialChapter! > 0) {
      _currentChapter = widget.initialChapter!;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChapter(_currentBook, _currentChapter, focusVerse: widget.initialVerse);
      _checkAndShowGestureTutorial();
    });
    _loadHighlights();

    // Set up OpenAI TTS callbacks
    _openAiTts.onStart = () {
      if (mounted) setState(() => _isOpenAiTtsSpeaking = true);
    };
    _openAiTts.onComplete = () {
      if (mounted) {
        setState(() => _isOpenAiTtsSpeaking = false);
        // Continue to next verse if there are more
        _readNextVerse();
      }
    };
    _openAiTts.onInterrupted = () {
      if (mounted) {
        setState(() {
          _isOpenAiTtsSpeaking = false;
          _currentReadingVerseIndex = null;
        });
      }
    };
  }

  Future<void> _checkAndShowGestureTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenGestureTutorial = prefs.getBool('hasSeenGestureTutorial') ?? false;

    // Only auto-show popup on first ever open of reader
    if (!hasSeenGestureTutorial && mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        _showGestureInfo();
        // Mark as seen so it won't auto-show again until reinstall/cache clear
        await prefs.setBool('hasSeenGestureTutorial', true);
      }
    }
  }

  Future<void> _loadHighlights() async {
    final highlights = await _highlightService.getHighlights();
    setState(() {
      _highlights = highlights;
    });
  }

  Future<void> _highlightVerse(String verseReference, String colorName) async {
    await _highlightService.saveHighlight(verseReference, colorName);
    await _loadHighlights();
  }

  Future<void> _removeHighlight(String verseReference) async {
    await _highlightService.removeHighlight(verseReference);
    await _loadHighlights();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _autoScrollTimer?.cancel();
    _tapTimer?.cancel();
    _openAiTts.dispose();
    super.dispose();
  }

  /// Show confirmation dialog for long-press TTS
  void _showTtsConfirmation(BibleVerseModel verse, int verseIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryTeal.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.volume_up, color: AppTheme.primaryTeal, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Read Aloud',
                style: TextStyle(color: AppTheme.onSurface, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Start reading from:',
              style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.darkBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primaryTeal.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    verse.reference,
                    style: const TextStyle(
                      color: AppTheme.primaryTeal,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    verse.text.length > 100 ? '${verse.text.substring(0, 100)}...' : verse.text,
                    style: TextStyle(
                      color: AppTheme.onSurface,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Will read ${_verses.length - verseIndex} verse${_verses.length - verseIndex != 1 ? 's' : ''} to end of chapter.',
              style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppTheme.onSurfaceVariant)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _startReadingFromVerse(verseIndex);
            },
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('Start Reading'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryTeal,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Start reading from a specific verse index
  void _startReadingFromVerse(int startIndex) {
    if (startIndex < 0 || startIndex >= _verses.length) return;

    setState(() {
      _currentReadingVerseIndex = startIndex;
      _isOpenAiTtsSpeaking = true;
    });

    // Read the first verse
    final verse = _verses[startIndex];
    final textToRead = '${verse.reference}. ${verse.text}';
    Log.d('TTS: Starting to read from ${verse.reference}');
    _openAiTts.speak(textToRead);
  }

  /// Continue reading to the next verse
  void _readNextVerse() {
    if (_currentReadingVerseIndex == null) return;

    final nextIndex = _currentReadingVerseIndex! + 1;
    if (nextIndex >= _verses.length) {
      // Finished reading chapter
      Log.d('TTS: Finished reading chapter');
      setState(() {
        _currentReadingVerseIndex = null;
        _isOpenAiTtsSpeaking = false;
      });
      return;
    }

    // Read next verse - just the text, no verse number announcement
    setState(() => _currentReadingVerseIndex = nextIndex);
    final verse = _verses[nextIndex];
    Log.d('TTS: Reading ${verse.reference}');
    _openAiTts.speak(verse.text);
  }

  /// Stop the long-press TTS reading
  void _stopOpenAiTts() {
    _openAiTts.stop();
    setState(() {
      _currentReadingVerseIndex = null;
      _isOpenAiTtsSpeaking = false;
    });
  }


  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    setState(() => _isAutoScrolling = true);
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.offset;
        final newScroll = currentScroll + (_autoScrollSpeed * 0.05);

        if (newScroll >= maxScroll) {
          _stopAutoScroll();
        } else {
          _scrollController.jumpTo(newScroll);
        }
      }
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    setState(() => _isAutoScrolling = false);
  }

  void _onDoubleTap() {
    // Double-tap to toggle auto-scroll
    if (_isAutoScrolling) {
      _stopAutoScroll();
    } else {
      _startAutoScroll();
    }
  }

  void _onTap() {
    // Track taps for triple-tap detection (for TTS)
    _tapCount++;

    // Reset tap count after 500ms if no more taps
    _tapTimer?.cancel();
    _tapTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() => _tapCount = 0);
    });

    // Triple-tap detected - play TTS
    if (_tapCount == 3) {
      _tapCount = 0;
      _tapTimer?.cancel();
      if (_verses.isNotEmpty) {
        _playChapter();
      }
    }
  }

  void _showGestureInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Reader Gestures', style: TextStyle(color: AppTheme.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGestureItem(Icons.touch_app, 'Tap verse', 'View verse actions & highlights'),
            const SizedBox(height: 12),
            _buildGestureItem(Icons.touch_app_outlined, 'Double-tap', 'Start/stop auto-scroll'),
            const SizedBox(height: 12),
            _buildGestureItem(Icons.volume_up, 'Long-press verse', 'Read aloud from that verse'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it', style: TextStyle(color: AppTheme.primaryTeal)),
          ),
        ],
      ),
    );
  }

  Widget _buildGestureItem(IconData icon, String gesture, String description) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryTeal, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                gesture,
                style: const TextStyle(
                  color: AppTheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                description,
                style: const TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _playChapter() async {
    if (_verses.isEmpty) return;

    setState(() {
      _isSpeaking = true;
      _isPaused = false;
    });

    // Combine all verses into chapter text
    final chapterText = _verses.map((v) => v.text).join(' ');
    final reference = '$_currentBook $_currentChapter';

    try {
      await _ttsService.readChapter(
        chapterText: chapterText,
        reference: reference,
      );
      setState(() {
        _isSpeaking = false;
        _isPaused = false;
      });
    } catch (e) {
      Log.d('TTS Error: $e');
      setState(() {
        _isSpeaking = false;
        _isPaused = false;
      });
    }
  }

  Future<void> _pauseResume() async {
    if (_isPaused) {
      await _ttsService.resume();
      setState(() => _isPaused = false);
    } else {
      await _ttsService.pause();
      setState(() => _isPaused = true);
    }
  }

  Future<void> _stopSpeech() async {
    await _ttsService.stop();
    setState(() {
      _isSpeaking = false;
      _isPaused = false;
    });
  }

  Future<void> _loadChapter(String bookName, int chapter, {int? focusVerse}) async {
    setState(() {
      _loadingChapter = true;
      _isSearching = false;
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('verses')
          .where('version_shortcode', isEqualTo: 'ASV')
          .where('book_name', isEqualTo: bookName)
          .where('chapter_number', isEqualTo: chapter)
          .orderBy('verse_number')
          .get();

      final verses = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return BibleVerseModel(
          book: data['book_name'] ?? '',
          chapter: data['chapter_number'] ?? 0,
          verse: data['verse_number'] ?? 0,
          text: data['text'] ?? '',
          reference: '${data['book_name']} ${data['chapter_number']}:${data['verse_number']}',
        );
      }).toList();

      setState(() {
        _verses = verses;
        _currentBook = bookName;
        _currentChapter = chapter;
        _loadingChapter = false;
        _focusedVerseRef =
            focusVerse != null ? '$bookName $chapter:$focusVerse' : null;
      });
    } catch (e) {
      setState(() => _loadingChapter = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load chapter: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _performSearch() async {
    if (_searchController.text.trim().isEmpty) return;

    setState(() {
      _loadingSearch = true;
      _isSearching = true;
    });

    try {
      final results = await SemanticSearchService().searchVerses(
        query: _searchController.text.trim(),
        limit: 10,
      );

      Log.d('Semantic search returned ${results.length} results');
      if (results.isNotEmpty) {
        Log.d('First result keys: ${results.first.keys.toList()}');
        Log.d('First result: ${results.first}');
      }

      setState(() {
        _verses = results.map((result) {
          // The API returns structured data with these fields:
          // reference, text, score, book_name, book, chapter_number, chapter, verse_number, verse (as int)
          final reference = result['reference'] as String? ?? '';
          final text = result['text'] as String? ?? '';

          // Use the structured fields directly from the API
          final bookName = result['book_name'] as String? ??
                          result['book'] as String? ??
                          'Unknown';
          final chapter = (result['chapter_number'] ?? result['chapter'] ?? 0) as int;
          final verseNum = (result['verse_number'] ?? 0) as int;

          return BibleVerseModel(
            book: bookName,
            chapter: chapter,
            verse: verseNum,
            text: text,
            reference: reference.isNotEmpty ? reference : '$bookName $chapter:$verseNum',
          );
        }).toList();
        _loadingSearch = false;
      });
    } catch (e, stackTrace) {
      Log.e('Semantic search failed: $e');
      Log.e('Stack trace: $stackTrace');
      setState(() => _loadingSearch = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: ${e.toString()}')),
        );
      }
    }
  }

  void _handleVerseTap(BibleVerseModel verse) {
    if (_isSelectionMode) {
      // Multi-selection mode: toggle selection
      setState(() {
        if (_selectedVerseRefs.contains(verse.reference)) {
          _selectedVerseRefs.remove(verse.reference);
          // Exit selection mode if no verses selected
          if (_selectedVerseRefs.isEmpty) {
            _isSelectionMode = false;
          }
        } else {
          _selectedVerseRefs.add(verse.reference);
        }
      });
    } else {
      // Single verse tap: show context modal
      _showVerseActions(verse);
    }
  }

  void _showVerseActions(BibleVerseModel verse) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VerseActionsModal(
        verse: verse,
        onHighlight: (colorName) async {
          await _highlightVerse(verse.reference, colorName);
        },
        onRemoveHighlight: () async {
          await _removeHighlight(verse.reference);
        },
        currentHighlight: _highlights[verse.reference],
      ),
    );
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedVerseRefs.clear();
      }
    });
  }

  void _addSelectedToStudy() async {
    if (_selectedVerseRefs.isEmpty) return;

    final selectedVerses = _verses
        .where((v) => _selectedVerseRefs.contains(v.reference))
        .toList();

    // Show action sheet with options
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.note_add, color: AppTheme.primaryTeal),
              title: Text('Create Note (${selectedVerses.length} verses)'),
              onTap: () {
                Navigator.pop(context);
                _createNoteFromMultipleVerses(selectedVerses);
              },
            ),
            ListTile(
              leading: const Icon(Icons.palette, color: AppTheme.primaryTeal),
              title: Text('Highlight All (${selectedVerses.length} verses)'),
              onTap: () {
                Navigator.pop(context);
                _highlightMultipleVerses(selectedVerses);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: AppTheme.primaryTeal),
              title: Text('Share (${selectedVerses.length} verses)'),
              onTap: () {
                Navigator.pop(context);
                _shareMultipleVerses(selectedVerses);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_add, color: AppTheme.primaryTeal),
              title: Text('Bookmark (${selectedVerses.length} verses)'),
              onTap: () {
                Navigator.pop(context);
                _saveMultipleVersesToStudy(selectedVerses);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _createNoteFromMultipleVerses(List<BibleVerseModel> verses) async {
    // Create combined verse text
    final combinedText = verses.map((v) => '${v.reference}: ${v.text}').join('\n\n');
    final firstVerse = verses.first;

    // For now, use first verse as the primary reference
    // TODO: Could enhance to support multi-verse notes in the future
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: FractionallySizedBox(
          heightFactor: 0.85,
          child: Container(
            decoration: const BoxDecoration(
              color: AppTheme.darkGrey,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: AddVerseNoteSheet(verse: firstVerse),
          ),
        ),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Creating note for ${verses.length} verses'),
        backgroundColor: AppTheme.primaryTeal,
      ),
    );

    _toggleSelectionMode();
  }

  void _highlightMultipleVerses(List<BibleVerseModel> verses) async {
    // Show color picker
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkGrey,
        title: const Text('Choose Highlight Color', style: TextStyle(color: AppTheme.onSurface)),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: HighlightService.highlightColors.entries.map((entry) {
            return GestureDetector(
              onTap: () async {
                Navigator.pop(context);
                for (final verse in verses) {
                  await _highlightService.saveHighlight(verse.reference, entry.key);
                }
                await _loadHighlights();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Highlighted ${verses.length} verses in ${entry.key}'),
                    backgroundColor: AppTheme.primaryTeal,
                  ),
                );
                _toggleSelectionMode();
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: entry.value,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _shareMultipleVerses(List<BibleVerseModel> verses) async {
    final text = verses.map((v) => '${v.reference}\n${v.text}').join('\n\n');

    // Use Share package (assuming it's already in dependencies)
    try {
      // TODO: Add share_plus package if not already present
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sharing ${verses.length} verses...'),
          backgroundColor: AppTheme.primaryTeal,
        ),
      );
      // await Share.share(text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Share feature coming soon'),
          backgroundColor: Colors.orange,
        ),
      );
    }

    _toggleSelectionMode();
  }

  void _saveMultipleVersesToStudy(List<BibleVerseModel> verses) async {
    // TODO: Integrate with BookmarkService to save multiple verses
    for (final verse in verses) {
      // await BookmarkService.addToStudy(verse);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${verses.length} verses to study'),
        backgroundColor: AppTheme.primaryTeal,
      ),
    );

    _toggleSelectionMode();
  }

  void _bookmarkSelected() async {
    if (_selectedVerseRefs.isEmpty) return;

    final selectedVerses = _verses
        .where((v) => _selectedVerseRefs.contains(v.reference))
        .toList();

    // Bookmark all selected verses
    for (final verse in selectedVerses) {
      // TODO: Implement bookmark service call
      Log.d('Bookmarking ${verse.reference}');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Bookmarked ${selectedVerses.length} verses'),
        backgroundColor: AppTheme.primaryTeal,
      ),
    );

    _toggleSelectionMode();
  }

  Widget _buildBibleText() {
    return RichText(
      textAlign: TextAlign.justify,
      text: TextSpan(
        style: const TextStyle(
          color: Colors.white, // White text for dark theme
          fontSize: 17,
          height: 1.8,
          fontFamily: 'Urbanist',
          letterSpacing: 0.3,
        ),
        children: _verses.asMap().entries.map((entry) {
          final verseIndex = entry.key;
          final verse = entry.value;
          final isSelected = _selectedVerseRefs.contains(verse.reference);
          final highlightColorName = _highlights[verse.reference];
          final isFocusedVerse = _focusedVerseRef == verse.reference;
          final isCurrentlyReading = _currentReadingVerseIndex == verseIndex;
          final highlightColor = highlightColorName != null
              ? HighlightService.highlightColors[highlightColorName]
              : null;

          final tapRecognizer = TapGestureRecognizer()
            ..onTap = () {
              Log.d('Verse tapped: ${verse.reference}');
              _handleVerseTap(verse);
            };

          // Determine background color priority: reading > selection > highlight > default
          Color? backgroundColor;
          if (isCurrentlyReading) {
            backgroundColor = AppTheme.primaryTeal.withValues(alpha: 0.25);
          } else if (isSelected) {
            backgroundColor = AppTheme.primaryTeal.withValues(alpha: 0.15);
          } else if (highlightColor != null) {
            backgroundColor = highlightColor.withValues(alpha: 0.3);
          } else if (isFocusedVerse) {
            backgroundColor = AppTheme.primaryTeal.withValues(alpha: 0.08);
          }

          return TextSpan(
            children: [
              // Verse number (superscript style) - tappable with better visibility
              TextSpan(
                text: '${verse.verse} ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isCurrentlyReading
                      ? AppTheme.primaryTeal
                      : (isSelected || isFocusedVerse)
                          ? AppTheme.primaryTeal
                          : AppTheme.primaryTeal.withValues(alpha: 0.7), // Subtle teal color
                  letterSpacing: 0.5,
                  backgroundColor: backgroundColor,
                ),
                recognizer: tapRecognizer,
              ),
              // Verse text - tappable for actions, long-press for TTS
              WidgetSpan(
                child: GestureDetector(
                  onTap: () {
                    Log.d('Verse tapped: ${verse.reference}');
                    _handleVerseTap(verse);
                  },
                  onLongPress: () {
                    Log.d('Verse long-pressed: ${verse.reference}');
                    _showTtsConfirmation(verse, verseIndex);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      '${verse.text} ',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        height: 1.8,
                        fontFamily: 'Urbanist',
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void showSearchModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.onSurfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Search header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppTheme.primaryTeal, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'AI Semantic Search',
                    style: TextStyle(
                      color: AppTheme.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Search input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: AppTheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Search by meaning: "love your neighbor", "faith and hope"...',
                  hintStyle: TextStyle(color: AppTheme.onSurfaceVariant),
                  filled: true,
                  fillColor: AppTheme.darkBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) async {
                  await _performSearch();
                  if (mounted) Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 16),
            if (_loadingSearch)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  void _showBookChapterPicker() {
    Book selectedBook = bibleBooks.firstWhere(
      (b) => b.name == _currentBook,
      orElse: () => bibleBooks.first,
    );
    String searchQuery = '';
    List<Book> filteredBooks = bibleBooks;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.onSurfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Book & Chapter',
                      style: TextStyle(
                        color: AppTheme.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Search field for quick book finding
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: TextField(
                  onChanged: (value) {
                    setModalState(() {
                      searchQuery = value.toLowerCase();
                      if (searchQuery.isEmpty) {
                        filteredBooks = bibleBooks;
                      } else {
                        filteredBooks = bibleBooks
                            .where((book) =>
                                book.name.toLowerCase().contains(searchQuery))
                            .toList();
                      }
                    });
                  },
                  style: const TextStyle(color: AppTheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Search books (e.g., "John", "Gen", "Rev")...',
                    hintStyle: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: AppTheme.primaryTeal, size: 20),
                    filled: true,
                    fillColor: AppTheme.darkBackground,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              // Two-column layout: Books | Chapters
              Expanded(
                child: Row(
                  children: [
                    // Books list (left side)
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.2),
                            ),
                          ),
                        ),
                        child: filteredBooks.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text(
                                    'No books found',
                                    style: TextStyle(
                                      color: AppTheme.onSurfaceVariant,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: filteredBooks.length,
                                itemBuilder: (context, index) {
                                  final book = filteredBooks[index];
                                  final isSelected = book.name == selectedBook.name;
                                  return InkWell(
                                    onTap: () {
                                      setModalState(() {
                                        selectedBook = book;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                      color: isSelected
                                          ? AppTheme.primaryTeal.withValues(alpha: 0.15)
                                          : Colors.transparent,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              book.name,
                                              style: TextStyle(
                                                color: isSelected
                                                    ? AppTheme.primaryTeal
                                                    : AppTheme.onSurface,
                                                fontSize: 16,
                                                fontWeight: isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                          if (isSelected)
                                            const Icon(
                                              Icons.chevron_right,
                                              color: AppTheme.primaryTeal,
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                    // Chapters grid (right side)
                    Expanded(
                      flex: 3,
                      child: Container(
                        color: AppTheme.darkBackground,
                        padding: const EdgeInsets.all(12),
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            childAspectRatio: 1.2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: selectedBook.chapterCount,
                          itemBuilder: (context, index) {
                            final chapter = index + 1;
                            final isCurrentChapter = selectedBook.name == _currentBook &&
                                chapter == _currentChapter;
                            return InkWell(
                              onTap: () {
                                _loadChapter(selectedBook.name, chapter);
                                Navigator.pop(context);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isCurrentChapter
                                      ? AppTheme.primaryTeal
                                      : AppTheme.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isCurrentChapter
                                        ? AppTheme.primaryTeal
                                        : AppTheme.onSurfaceVariant.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '$chapter',
                                    style: TextStyle(
                                      color: isCurrentChapter
                                          ? Colors.white
                                          : AppTheme.onSurface,
                                      fontSize: 16,
                                      fontWeight: isCurrentChapter
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: AppTheme.darkBackground,
          // Full-screen Bible card (entire space under app bar)
          child: _loadingChapter
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryTeal),
                )
              : _verses.isEmpty
                  ? const Center(
                      child: Text(
                        'No verses found',
                        style: TextStyle(color: AppTheme.onSurfaceVariant),
                      ),
                    )
                  : Stack(
                      children: [
                        // Main content with scrollable verses
                        GestureDetector(
                          onTap: _onTap, // Single tap for triple-tap detection
                          onDoubleTap: _onDoubleTap, // Double-tap for auto-scroll
                          child: Container(
                            color: AppTheme.background, // Dark background instead of white paper
                            child: ListView(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(40, 80, 40, 48),
                              children: [
                                // Verses flowing like a real Bible
                                _buildBibleText(),
                              ],
                            ),
                          ),
                        ),

                        // Chapter title and navigation overlaid at top
                        Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    AppTheme.background, // Dark background
                                    AppTheme.background.withValues(alpha: 0.0), // Fade to transparent
                                  ],
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Previous chapter arrow OR Cancel selection button
                                  _isSelectionMode
                                      ? IconButton(
                                          onPressed: _toggleSelectionMode,
                                          icon: const Icon(Icons.close, size: 28),
                                          color: AppTheme.primaryTeal,
                                        )
                                      : IconButton(
                                          onPressed: _currentChapter > 1
                                              ? () => _loadChapter(_currentBook, _currentChapter - 1)
                                              : null,
                                          icon: const Icon(Icons.chevron_left, size: 28),
                                          color: Colors.white,
                                        ),
                                  // Tappable chapter title OR selection count
                                  Expanded(
                                    child: _isSelectionMode
                                        ? Center(
                                            child: Text(
                                              '${_selectedVerseRefs.length} verse${_selectedVerseRefs.length != 1 ? 's' : ''} selected',
                                              style: const TextStyle(
                                                color: AppTheme.primaryTeal,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          )
                                        : GestureDetector(
                                            onTap: _showBookChapterPicker,
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  '$_currentBook $_currentChapter',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    fontFamily: 'Urbanist',
                                                    decoration: TextDecoration.underline,
                                                    decorationColor: Colors.white,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                const Icon(
                                                  Icons.expand_more,
                                                  size: 20,
                                                  color: Colors.white,
                                                ),
                                              ],
                                            ),
                                          ),
                                  ),
                                  // Next chapter arrow OR Select mode toggle
                                  _isSelectionMode
                                      ? const SizedBox(width: 48) // Placeholder for symmetry
                                      : Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Select button to enter selection mode
                                            TextButton(
                                              onPressed: _toggleSelectionMode,
                                              style: TextButton.styleFrom(
                                                foregroundColor: AppTheme.primaryTeal,
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              ),
                                              child: const Text(
                                                'Select',
                                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                            // Next chapter arrow
                                            IconButton(
                                              onPressed: () => _loadChapter(_currentBook, _currentChapter + 1),
                                              icon: const Icon(Icons.chevron_right, size: 28),
                                              color: Colors.white,
                                            ),
                                          ],
                                        ),
                                ],
                              ),
                            ),
                          ),

                          // Selection mode action bar
                          if (_isSelectionMode && _selectedVerseRefs.isNotEmpty)
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: SafeArea(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surface,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, -2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      // Actions button - opens action menu
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: _addSelectedToStudy,
                                          icon: const Icon(Icons.more_horiz, size: 20),
                                          label: const Text('Actions'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.primaryTeal,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Highlight button - quick access to most common action
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            final selectedVerses = _verses
                                                .where((v) => _selectedVerseRefs.contains(v.reference))
                                                .toList();
                                            _highlightMultipleVerses(selectedVerses);
                                          },
                                          icon: const Icon(Icons.palette, size: 20),
                                          label: const Text('Highlight'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.surface,
                                            foregroundColor: AppTheme.primaryTeal,
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            side: const BorderSide(color: AppTheme.primaryTeal, width: 2),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                ),
        // Info button (tap for gesture info - moved to top-right corner)
        if (!_isSelectionMode)
          Positioned(
            top: 80,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // OpenAI TTS Controls when reading aloud (long-press TTS)
                if (_isOpenAiTtsSpeaking) ...[
                  // Current verse indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTeal,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.volume_up, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Reading v${_currentReadingVerseIndex != null ? _verses[_currentReadingVerseIndex!].verse : ""}',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  FloatingActionButton(
                    heroTag: 'stop_openai_tts',
                    onPressed: _stopOpenAiTts,
                    backgroundColor: Colors.red,
                    child: const Icon(
                      Icons.stop,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                // Legacy TTS Controls when speaking (triple-tap TTS)
                if (_isSpeaking) ...[
                  FloatingActionButton(
                    heroTag: 'pause_resume',
                    onPressed: _pauseResume,
                    backgroundColor: AppTheme.primaryTeal,
                    child: Icon(
                      _isPaused ? Icons.play_arrow : Icons.pause,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    heroTag: 'stop',
                    onPressed: _stopSpeech,
                    backgroundColor: Colors.red,
                    child: const Icon(
                      Icons.stop,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                // Gesture hint button (tap to show gestures)
                if (_verses.isNotEmpty && !_isOpenAiTtsSpeaking && !_isSpeaking)
                  GestureDetector(
                    onTap: _showGestureInfo,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.primaryTeal, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.touch_app,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _VerseCard extends StatefulWidget {
  final BibleVerseModel verse;
  final VoidCallback onTap;

  const _VerseCard({
    required this.verse,
    required this.onTap,
  });

  @override
  State<_VerseCard> createState() => _VerseCardState();
}

class _VerseCardState extends State<_VerseCard> {
  bool _isSelected = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() => _isSelected = true);
        widget.onTap();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) setState(() => _isSelected = false);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isSelected
              ? AppTheme.primaryTeal.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _isSelected
                ? AppTheme.primaryTeal
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Verse reference
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.verse.reference,
                    style: const TextStyle(
                      color: AppTheme.primaryTeal,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Verse text
            Text(
              widget.verse.text,
              style: const TextStyle(
                color: Color(0xFF2A2A2A), // Dark text on light book page
                fontSize: 16,
                height: 1.6,
                fontFamily: 'Urbanist',
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
