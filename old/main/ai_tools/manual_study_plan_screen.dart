import 'package:flutter/material.dart';
import 'package:faithfeed/services/logger_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/bible_verse_model.dart';
import '../../../services/study_plan_service.dart';
import '../../../data/bible_data.dart';
import '../../../theme/app_theme.dart';

class ManualStudyPlanScreen extends StatefulWidget {
  const ManualStudyPlanScreen({super.key});

  @override
  State<ManualStudyPlanScreen> createState() => _ManualStudyPlanScreenState();
}

class _ManualStudyPlanScreenState extends State<ManualStudyPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<ManualStudyDay> _days = [];
  bool _isCreating = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addDay() {
    setState(() {
      _days.add(ManualStudyDay(
        day: _days.length + 1,
        title: '',
        verses: [],
        notes: '',
      ));
    });
  }

  void _removeDay(int index) {
    setState(() {
      _days.removeAt(index);
      // Re-number remaining days
      for (int i = 0; i < _days.length; i++) {
        _days[i].day = i + 1;
      }
    });
  }

  Future<void> _createPlan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_days.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one day to your study plan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Convert manual days to StudyDay format
      final studyDays = _days.map((manualDay) {
        // Build scriptures list from either verses or chapters
        List<Map<String, String>> scriptures;
        if (manualDay.useChapters && manualDay.chapters.isNotEmpty) {
          scriptures = manualDay.chapters.map((ch) => {
            'reference': ch,
            'text': 'Read full chapter',
          }).toList();
        } else {
          scriptures = manualDay.verses.map((v) => {
            'reference': v.reference,
            'text': v.text,
          }).toList();
        }

        return StudyDay(
          day: manualDay.day,
          title: manualDay.title.isEmpty ? 'Day ${manualDay.day}' : manualDay.title,
          description: manualDay.notes,
          scriptures: scriptures,
          reflection: manualDay.notes,
          prayer: '',
          actionItem: '',
          estimatedMinutes: manualDay.useChapters ? 20 : 15,
          isCompleted: false,
        );
      }).toList();

      final studyPlan = StudyPlan(
        id: '',
        userId: user.uid,
        title: _titleController.text,
        description: _descriptionController.text,
        goal: 'Custom manual study plan',
        duration: '${_days.length} days',
        topics: ['Custom'],
        experienceLevel: 'custom',
        focusArea: 'Manual',
        sessionsPerWeek: _days.length >= 7 ? 7 : _days.length,
        days: studyDays,
        createdAt: DateTime.now(),
        isActive: true,
        progress: 0,
      );

      // Save to Firestore
      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('studyPlans')
          .add(studyPlan.toFirestore());

      Log.d('✅ Manual study plan created: ${docRef.id}');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Study plan created successfully!'),
          backgroundColor: AppTheme.primaryTeal,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      Log.d('❌ Error creating manual study plan: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating plan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Create Manual Study Plan', style: TextStyle(color: AppTheme.lightOnSurface)),
        iconTheme: IconThemeData(color: AppTheme.lightOnSurface),
        actions: [
          if (_isCreating)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryTeal,
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _createPlan,
              child: const Text(
                'Create',
                style: TextStyle(
                  color: AppTheme.primaryTeal,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Plan Title
            TextFormField(
              controller: _titleController,
              style: const TextStyle(color: AppTheme.onSurface),
              decoration: const InputDecoration(
                labelText: 'Plan Title',
                labelStyle: TextStyle(color: AppTheme.onSurfaceVariant),
                hintText: 'e.g., Morning Devotional, Prayer Journey',
                hintStyle: TextStyle(color: AppTheme.onSurfaceVariant),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.onSurfaceVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.primaryTeal),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Plan Description
            TextFormField(
              controller: _descriptionController,
              style: const TextStyle(color: AppTheme.onSurface),
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                labelStyle: TextStyle(color: AppTheme.onSurfaceVariant),
                hintText: 'What is this study plan about?',
                hintStyle: TextStyle(color: AppTheme.onSurfaceVariant),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.onSurfaceVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.primaryTeal),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Days section header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Study Days',
                  style: TextStyle(
                    color: AppTheme.primaryTeal,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addDay,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Day'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryTeal,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Days list
            if (_days.isEmpty)
              Card(
                color: AppTheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 64,
                        color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No days added yet',
                        style: TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap "Add Day" to start building your study plan',
                        style: TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ...List.generate(_days.length, (index) {
                return _DayCard(
                  day: _days[index],
                  onRemove: () => _removeDay(index),
                  onUpdate: () => setState(() {}),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class ManualStudyDay {
  int day;
  String title;
  List<BibleVerseModel> verses;
  List<String> chapters; // For chapter-based study (e.g., "Genesis 1", "John 3")
  String notes;
  bool useChapters; // true = chapter mode, false = verse mode

  ManualStudyDay({
    required this.day,
    required this.title,
    required this.verses,
    required this.notes,
    List<String>? chapters,
    this.useChapters = false,
  }) : chapters = chapters ?? [];
}

class _DayCard extends StatefulWidget {
  final ManualStudyDay day;
  final VoidCallback onRemove;
  final VoidCallback onUpdate;

  const _DayCard({
    required this.day,
    required this.onRemove,
    required this.onUpdate,
  });

  @override
  State<_DayCard> createState() => _DayCardState();
}

class _DayCardState extends State<_DayCard> {
  bool _isExpanded = false;
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.day.title;
    _notesController.text = widget.day.notes;

    _titleController.addListener(() {
      widget.day.title = _titleController.text;
    });

    _notesController.addListener(() {
      widget.day.notes = _notesController.text;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _toggleMode(bool useChapters) {
    setState(() {
      widget.day.useChapters = useChapters;
    });
    widget.onUpdate();
  }

  Future<void> _addChapter() async {
    Book? selectedBook;
    int? selectedChapter;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text(
            'Add Chapter',
            style: TextStyle(color: AppTheme.onSurface),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Book dropdown
              DropdownButtonFormField<Book>(
                value: selectedBook,
                dropdownColor: AppTheme.surface,
                decoration: const InputDecoration(
                  labelText: 'Select Book',
                  labelStyle: TextStyle(color: AppTheme.onSurfaceVariant),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.onSurfaceVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primaryTeal),
                  ),
                ),
                items: bibleBooks.map((book) {
                  return DropdownMenuItem(
                    value: book,
                    child: Text(
                      book.name,
                      style: const TextStyle(color: AppTheme.onSurface),
                    ),
                  );
                }).toList(),
                onChanged: (book) {
                  setDialogState(() {
                    selectedBook = book;
                    selectedChapter = null;
                  });
                },
              ),
              const SizedBox(height: 16),
              // Chapter dropdown
              if (selectedBook != null)
                DropdownButtonFormField<int>(
                  value: selectedChapter,
                  dropdownColor: AppTheme.surface,
                  decoration: const InputDecoration(
                    labelText: 'Select Chapter',
                    labelStyle: TextStyle(color: AppTheme.onSurfaceVariant),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.onSurfaceVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.primaryTeal),
                    ),
                  ),
                  items: List.generate(selectedBook!.chapterCount, (i) => i + 1)
                      .map((ch) => DropdownMenuItem(
                            value: ch,
                            child: Text(
                              'Chapter $ch',
                              style: const TextStyle(color: AppTheme.onSurface),
                            ),
                          ))
                      .toList(),
                  onChanged: (ch) {
                    setDialogState(() {
                      selectedChapter = ch;
                    });
                  },
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: selectedBook != null && selectedChapter != null
                  ? () => Navigator.pop(
                      context, '${selectedBook!.name} $selectedChapter')
                  : null,
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        widget.day.chapters.add(result);
      });
      widget.onUpdate();
    }
  }

  Future<void> _addVerseFromReference() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Add Verse(s)',
          style: TextStyle(color: AppTheme.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              style: const TextStyle(color: AppTheme.onSurface),
              decoration: const InputDecoration(
                hintText: 'e.g., John 3:16 or John 3:16-21',
                hintStyle: TextStyle(color: AppTheme.onSurfaceVariant),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.onSurfaceVariant),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.primaryTeal),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tip: You can enter verse ranges like "Romans 8:28-30"',
              style: TextStyle(
                color: AppTheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        widget.day.verses.add(BibleVerseModel(
          book: result.split(' ')[0],
          chapter: 1,
          verse: 1,
          reference: result,
          text: 'Verse text will be loaded from your Bible translation',
          translation: 'ASV',
        ));
      });
      widget.onUpdate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = widget.day.useChapters
        ? widget.day.chapters.length
        : widget.day.verses.length;
    final itemLabel = widget.day.useChapters ? 'chapter(s)' : 'verse(s)';

    return Card(
      color: AppTheme.surface,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryTeal,
              child: Text(
                '${widget.day.day}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              widget.day.title.isEmpty
                  ? 'Day ${widget.day.day}'
                  : widget.day.title,
              style: const TextStyle(
                color: AppTheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '$itemCount $itemLabel',
              style: const TextStyle(color: AppTheme.onSurfaceVariant),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppTheme.primaryTeal,
                  ),
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: widget.onRemove,
                ),
              ],
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day Title
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(color: AppTheme.onSurface),
                    decoration: const InputDecoration(
                      labelText: 'Day Title',
                      labelStyle: TextStyle(color: AppTheme.onSurfaceVariant),
                      hintText: 'e.g., Faith & Trust',
                      hintStyle: TextStyle(color: AppTheme.onSurfaceVariant),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppTheme.onSurfaceVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppTheme.primaryTeal),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Mode toggle: Chapters vs Verses
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.darkBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Study Mode',
                          style: TextStyle(
                            color: AppTheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _toggleMode(false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: !widget.day.useChapters
                                        ? AppTheme.primaryTeal
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: AppTheme.primaryTeal,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.format_quote,
                                        size: 16,
                                        color: !widget.day.useChapters
                                            ? Colors.white
                                            : AppTheme.primaryTeal,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Verses',
                                        style: TextStyle(
                                          color: !widget.day.useChapters
                                              ? Colors.white
                                              : AppTheme.primaryTeal,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _toggleMode(true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: widget.day.useChapters
                                        ? AppTheme.primaryTeal
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: AppTheme.primaryTeal,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.menu_book,
                                        size: 16,
                                        color: widget.day.useChapters
                                            ? Colors.white
                                            : AppTheme.primaryTeal,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Chapters',
                                        style: TextStyle(
                                          color: widget.day.useChapters
                                              ? Colors.white
                                              : AppTheme.primaryTeal,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Content section (Chapters or Verses based on mode)
                  if (widget.day.useChapters) ...[
                    // Chapters section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Chapters',
                          style: TextStyle(
                            color: AppTheme.primaryTeal,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _addChapter,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Chapter'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryTeal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            textStyle: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (widget.day.chapters.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.darkBackground,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'No chapters added\nTap "Add Chapter" to select a book and chapter',
                            style: TextStyle(color: AppTheme.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.day.chapters.asMap().entries.map((entry) {
                          final index = entry.key;
                          final chapter = entry.value;
                          return Chip(
                            label: Text(
                              chapter,
                              style: const TextStyle(color: AppTheme.onSurface),
                            ),
                            backgroundColor: AppTheme.darkBackground,
                            deleteIcon: const Icon(Icons.close, size: 16),
                            deleteIconColor: Colors.red,
                            onDeleted: () {
                              setState(() {
                                widget.day.chapters.removeAt(index);
                              });
                              widget.onUpdate();
                            },
                          );
                        }).toList(),
                      ),
                  ] else ...[
                    // Verses section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Verses',
                          style: TextStyle(
                            color: AppTheme.primaryTeal,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _addVerseFromReference,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Verse'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryTeal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            textStyle: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (widget.day.verses.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.darkBackground,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'No verses added\nTap "Add Verse" to enter a reference',
                            style: TextStyle(color: AppTheme.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      ...widget.day.verses.asMap().entries.map((entry) {
                        final index = entry.key;
                        final verse = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.darkBackground,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      verse.reference,
                                      style: const TextStyle(
                                        color: AppTheme.primaryTeal,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      verse.text,
                                      style: const TextStyle(
                                        color: AppTheme.onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                color: Colors.red,
                                onPressed: () {
                                  setState(() {
                                    widget.day.verses.removeAt(index);
                                  });
                                  widget.onUpdate();
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                  const SizedBox(height: 16),

                  // Notes
                  TextField(
                    controller: _notesController,
                    style: const TextStyle(color: AppTheme.onSurface),
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes / Reflection',
                      labelStyle: TextStyle(color: AppTheme.onSurfaceVariant),
                      hintText: 'Add notes or reflection questions...',
                      hintStyle: TextStyle(color: AppTheme.onSurfaceVariant),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppTheme.onSurfaceVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppTheme.primaryTeal),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
