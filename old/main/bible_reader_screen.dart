import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'tabs/bible_reader_tab.dart';

class BibleReaderScreen extends StatelessWidget {
  final String? initialBook;
  final int? initialChapter;
  final int? initialVerse;

  const BibleReaderScreen({
    super.key,
    this.initialBook,
    this.initialChapter,
    this.initialVerse,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text('Bible Reader'),
      ),
      body: BibleReaderTab(
        initialBook: initialBook,
        initialChapter: initialChapter,
        initialVerse: initialVerse,
      ),
    );
  }
}
