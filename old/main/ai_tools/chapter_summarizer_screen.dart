import 'package:faithfeed/data/bible_data.dart';
import 'package:faithfeed/services/logger_service.dart';
import 'package:faithfeed/services/chapter_summarizer_service.dart';
import 'package:faithfeed/services/ai_library_service.dart';
import 'package:faithfeed/services/premium_gate_service.dart';
import 'package:faithfeed/screens/main/ai_library_screen.dart';
import 'package:faithfeed/theme/app_theme.dart';
import 'package:faithfeed/widgets/premium_badge.dart';
import 'package:faithfeed/widgets/premium_paywall.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class ChapterSummarizerScreen extends StatefulWidget {
  const ChapterSummarizerScreen({super.key});

  @override
  State<ChapterSummarizerScreen> createState() =>
      _ChapterSummarizerScreenState();
}

class _ChapterSummarizerScreenState extends State<ChapterSummarizerScreen> {
  final ChapterSummarizerService _summarizerService =
      ChapterSummarizerService();
  final AILibraryService _aiLibraryService = AILibraryService();

  Book? _selectedBook;
  int? _selectedChapter;
  bool _isLoading = false;
  ChapterSummary? _summary;

  Future<void> _generateSummary() async {
    if (_selectedBook == null || _selectedChapter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a book and chapter'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check premium gate
    final gateService = Provider.of<PremiumGateService>(context, listen: false);
    final gateResult = await gateService.canAccess(PremiumGateService.summarizer);

    if (!gateResult.allowed) {
      if (mounted) {
        showPremiumPaywall(
          context: context,
          featureName: 'Chapter Summarizer',
          featureDescription: 'Get unlimited AI-powered chapter summaries with key verses, themes, and cross-references.',
          featureIcon: Icons.auto_stories,
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _summary = null;
    });

    try {
      // Consume the use before generating
      await gateService.consumeUse(PremiumGateService.summarizer);

      final summary = await _summarizerService.summarizeChapter(
        bookName: _selectedBook!.name,
        chapterNumber: _selectedChapter!,
      );

      // Save to AI Library
      final now = DateTime.now();
      final title =
          'Chapter Summary - ${_selectedBook!.name} $_selectedChapter - ${now.month}/${now.day}/${now.year}';

      // Format content for AI Library
      final content = _formatSummaryForLibrary(summary);

      await _aiLibraryService.saveChapterSummary(
        title: title,
        content: content,
        bookName: _selectedBook!.name,
        chapterNumber: _selectedChapter!,
      );

      if (mounted) {
        setState(() {
          _summary = summary;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Parse error message for user-friendly display
        String errorMessage;
        final errorString = e.toString();

        if (errorString.contains('unauthenticated') || errorString.contains('Authentication required')) {
          errorMessage = 'Please sign in to use this feature';
        } else if (errorString.contains('timeout')) {
          errorMessage = 'Request timed out. The chapter may be very long - please try again';
        } else if (errorString.contains('not-found') || errorString.contains('No verses found')) {
          errorMessage = 'Chapter not found. Please select a valid book and chapter';
        } else if (errorString.contains('network')) {
          errorMessage = 'Network error. Please check your connection';
        } else {
          errorMessage = 'Failed to generate summary. Please try again';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.primaryCoral,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _generateSummary,
            ),
          ),
        );

        Log.d('❌ Chapter Summarizer Error: $e');
      }
    }
  }

  String _formatSummaryForLibrary(ChapterSummary summary) {
    final buffer = StringBuffer();

    buffer.writeln('# ${summary.reference}\n');
    buffer.writeln('## Main Theme');
    buffer.writeln('${summary.summary.mainTheme}\n');

    buffer.writeln('## Key Points');
    for (int i = 0; i < summary.summary.keyPoints.length; i++) {
      buffer.writeln('${i + 1}. ${summary.summary.keyPoints[i]}');
    }
    buffer.writeln();

    buffer.writeln('## Theological Significance');
    buffer.writeln('${summary.summary.theologicalSignificance}\n');

    buffer.writeln('## Practical Application');
    buffer.writeln('${summary.summary.practicalApplication}\n');

    buffer.writeln('## Literary Context');
    buffer.writeln('${summary.summary.literaryContext}\n');

    buffer.writeln('## Preaching Points');
    for (int i = 0; i < summary.summary.preachingPoints.length; i++) {
      buffer.writeln('${i + 1}. ${summary.summary.preachingPoints[i]}');
    }
    buffer.writeln();

    if (summary.keyVerses.isNotEmpty) {
      buffer.writeln('## Key Verses (Semantically Identified)');
      for (var kv in summary.keyVerses) {
        buffer.writeln('**${kv.reference}**: "${kv.text}"');
      }
      buffer.writeln();
    }

    if (summary.crossReferences.isNotEmpty) {
      buffer.writeln('## Cross-References (Semantic Similarity)');
      for (var cr in summary.crossReferences) {
        buffer.writeln('**${cr.reference}**: "${cr.text}"');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground, // Set base background for consistency
      appBar: AppBar(
        backgroundColor: AppTheme.surface, // Frosted theme AppBar background
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light, // Ensure light status bar icons
        title: const Text(
          'Chapter Summarizer',
          style: TextStyle(color: AppTheme.onSurface), // Readable title text color
        ),
        iconTheme: const IconThemeData(color: AppTheme.onSurface), // Readable icon color
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Analyzing chapter and generating summary...',
                    style: TextStyle(color: AppTheme.onSurfaceVariant), // Readable text
                  ),
                  SizedBox(height: 8),
                  Text(
                    'This may take 30-60 seconds',
                    style: TextStyle(
                      color: AppTheme.onSurfaceVariant, // Readable text
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          : CustomScrollView(
              slivers: [
                // Header section - scrolls away
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Only show header when no summary
                        if (_summary == null) ...[
                          const Icon(
                            Icons.auto_stories,
                            size: 60,
                            color: AppTheme.primaryTeal,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Chapter Summary Generator',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.onSurface, // Readable text
                                ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Get comprehensive summaries with key verses, themes, and cross-references',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.onSurfaceVariant, // Readable text
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Usage limit indicator for free users
                          Consumer<PremiumGateService>(
                            builder: (context, gateService, _) {
                              if (gateService.isPremium) {
                                return const SizedBox.shrink();
                              }
                              return FutureBuilder<GateCheckResult>(
                                future: gateService.canAccess(PremiumGateService.summarizer),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) return const SizedBox.shrink();
                                  final result = snapshot.data!;
                                  return UsageLimitIndicator(
                                    remaining: result.remainingUses ?? 0,
                                    total: result.maxUses ?? 3,
                                    label: '${result.remainingUses ?? 0}/${result.maxUses ?? 3} summaries today',
                                  );
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Book Selection - compact when summary shown
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.primaryTeal.withOpacity(0.3)),
                                ),
                                child: DropdownButtonFormField<Book>(
                                  value: _selectedBook,
                                  decoration: InputDecoration(
                                    labelText: _summary == null ? 'Select Book' : 'Book',
                                    labelStyle: const TextStyle(color: AppTheme.onSurfaceVariant), // Readable label
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                  dropdownColor: AppTheme.surface,
                                  style: const TextStyle(color: AppTheme.onSurface), // Readable selected value
                                  iconEnabledColor: AppTheme.onSurfaceVariant,
                                  isExpanded: true,
                                  items: bibleBooks.map((book) {
                                    return DropdownMenuItem(
                                      value: book,
                                      child: Text(book.name, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.onSurface)), // Readable item text
                                    );
                                  }).toList(),
                                  onChanged: (book) {
                                    setState(() {
                                      _selectedBook = book;
                                      _selectedChapter = null;
                                      _summary = null;
                                    });
                                  },
                                ),
                              ),
                            ),
                            if (_selectedBook != null) ...[
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 120,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppTheme.primaryTeal.withOpacity(0.3)),
                                  ),
                                  child: DropdownButtonFormField<int>(
                                    value: _selectedChapter,
                                    decoration: InputDecoration(
                                      labelText: _summary == null ? 'Chapter' : 'Ch',
                                      labelStyle: const TextStyle(color: AppTheme.onSurfaceVariant), // Readable label
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    ),
                                    dropdownColor: AppTheme.surface,
                                    style: const TextStyle(color: AppTheme.onSurface), // Readable selected value
                                    iconEnabledColor: AppTheme.onSurfaceVariant,
                                    isExpanded: true,
                                    items: List.generate(_selectedBook!.chapterCount, (index) {
                                      final chapter = index + 1;
                                      return DropdownMenuItem(
                                        value: chapter,
                                        child: Text('$chapter', style: const TextStyle(color: AppTheme.onSurface)), // Readable item text
                                      );
                                    }),
                                    onChanged: (chapter) {
                                      setState(() {
                                        _selectedChapter = chapter;
                                        _summary = null;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Generate Button
                        SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _generateSummary,
                            icon: const Icon(Icons.auto_awesome, size: 20),
                            label: Text(
                              _summary == null ? 'Generate Summary' : 'Regenerate',
                              style: const TextStyle(fontSize: 16),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryTeal,
                              foregroundColor: AppTheme.onPrimary, // Readable button text
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Summary Display - fills remaining space and scrolls
                if (_summary != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Card(
                        color: AppTheme.surface, // Consistent background
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _summary!.reference,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryTeal, // Consistent text color
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy),
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(
                                          text: _formatSummaryForLibrary(_summary!)));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Summary copied to clipboard'),
                                          backgroundColor: AppTheme.primaryTeal,
                                        ),
                                      );
                                    },
                                    color: AppTheme.onSurface, // Consistent icon color
                                  ),
                                ],
                              ),
                              const Divider(color: AppTheme.onSurfaceVariant), // Consistent divider
                              const SizedBox(height: 8),

                              // Main Theme
                              const Text(
                                'Main Theme',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryTeal,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _summary!.summary.mainTheme,
                                style: const TextStyle(fontSize: 14, height: 1.6, color: AppTheme.onSurface),
                              ),
                              const SizedBox(height: 16),

                              // Key Points
                              const Text(
                                'Key Points',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryTeal,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ..._summary!.summary.keyPoints.map((point) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('• ', style: TextStyle(fontSize: 14, color: AppTheme.onSurface)),
                                        Expanded(
                                          child: Text(
                                            point,
                                            style: const TextStyle(fontSize: 14, height: 1.6, color: AppTheme.onSurface),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                              const SizedBox(height: 16),

                              // Theological Significance
                              const Text(
                                'Theological Significance',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryTeal,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _summary!.summary.theologicalSignificance,
                                style: const TextStyle(fontSize: 14, height: 1.6, color: AppTheme.onSurface),
                              ),
                              const SizedBox(height: 16),

                              // Practical Application
                              const Text(
                                'Practical Application',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryTeal,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _summary!.summary.practicalApplication,
                                style: const TextStyle(fontSize: 14, height: 1.6, color: AppTheme.onSurface),
                              ),
                              const SizedBox(height: 16),

                              // Literary Context
                              if (_summary!.summary.literaryContext.isNotEmpty) ...[
                                const Text(
                                  'Literary Context',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryTeal,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _summary!.summary.literaryContext,
                                  style: const TextStyle(fontSize: 14, height: 1.6, color: AppTheme.onSurface),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Preaching Points
                              if (_summary!.summary.preachingPoints.isNotEmpty) ...[
                                const Text(
                                  'Preaching Points',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryTeal,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ..._summary!.summary.preachingPoints.map((point) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('• ', style: TextStyle(fontSize: 14, color: AppTheme.onSurface)),
                                          Expanded(
                                            child: Text(
                                              point,
                                              style: const TextStyle(fontSize: 14, height: 1.6, color: AppTheme.onSurface),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),
                                const SizedBox(height: 16),
                              ],

                              // Key Verses
                              if (_summary!.keyVerses.isNotEmpty) ...[
                                const Text(
                                  'Key Verses (AI-Identified)',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryTeal,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ..._summary!.keyVerses.map((kv) => Padding(
                                      padding: const EdgeInsets.only(bottom: 12.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            kv.reference,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primaryTeal,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '"${kv.text}"',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontStyle: FontStyle.italic,
                                              height: 1.6,
                                              color: AppTheme.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),
                                const SizedBox(height: 16),
                              ],

                              // Cross References
                              if (_summary!.crossReferences.isNotEmpty) ...[
                                const Text(
                                  'Cross-References',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryTeal,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ..._summary!.crossReferences.map((cr) => Padding(
                                      padding: const EdgeInsets.only(bottom: 12.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cr.reference,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primaryTeal,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '"${cr.text}"',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontStyle: FontStyle.italic,
                                              height: 1.6,
                                              color: AppTheme.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),
                                const SizedBox(height: 16),
                              ],

                              // View in AI Library button
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const AILibraryScreen(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.library_books),
                                  label: const Text('View in AI Library'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.primaryTeal,
                                    side: const BorderSide(color: AppTheme.primaryTeal),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // Bottom padding
                const SliverToBoxAdapter(
                  child: SizedBox(height: 40),
                )
              ],
            ),
    );
  }
}