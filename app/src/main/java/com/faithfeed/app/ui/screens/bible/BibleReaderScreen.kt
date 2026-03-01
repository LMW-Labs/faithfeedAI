package com.faithfeed.app.ui.screens.bible

import android.content.Intent
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowDropDown
import androidx.compose.material.icons.filled.ChevronLeft
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavController
import com.faithfeed.app.data.model.BibleVerse
import com.faithfeed.app.data.model.Note
import com.faithfeed.app.data.model.StrongsEntry
import com.faithfeed.app.data.model.StrongsLexiconEntry
import com.faithfeed.app.navigation.Route
import com.faithfeed.app.ui.components.FaithFeedTopBar
import com.faithfeed.app.ui.theme.FaithFeedColors
import com.faithfeed.app.ui.theme.Nunito
import com.faithfeed.app.ui.theme.Typography
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

// Preset highlight colors
private val HIGHLIGHT_COLORS = listOf(
    "#C9A84C" to Color(0xFFC9A84C),   // Gold
    "#4A9EFF" to Color(0xFF4A9EFF),   // Blue
    "#4CAF7D" to Color(0xFF4CAF7D),   // Green
    "#FF6B9D" to Color(0xFFFF6B9D),   // Pink
    "#9B6DFF" to Color(0xFF9B6DFF),   // Purple
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BibleReaderScreen(
    navController: NavController,
    initialBook: String? = null,
    initialChapter: Int? = null,
    viewModel: BibleReaderViewModel = hiltViewModel()
) {
    val verses by viewModel.verses.collectAsStateWithLifecycle()
    val currentBook by viewModel.currentBook.collectAsStateWithLifecycle()
    val currentChapter by viewModel.currentChapter.collectAsStateWithLifecycle()
    val allBooks by viewModel.allBooks.collectAsStateWithLifecycle()
    val chapters by viewModel.chapters.collectAsStateWithLifecycle()
    val selectedVerse by viewModel.selectedVerse.collectAsStateWithLifecycle()
    val isSpeaking by viewModel.isSpeaking.collectAsStateWithLifecycle()
    val isAutoScrolling by viewModel.isAutoScrolling.collectAsStateWithLifecycle()
    val verseNotes by viewModel.verseNotes.collectAsStateWithLifecycle()
    val highlights by viewModel.highlights.collectAsStateWithLifecycle()
    val verseStrongs by viewModel.verseStrongs.collectAsStateWithLifecycle()
    val strongsLexicon by viewModel.strongsLexicon.collectAsStateWithLifecycle()
    val strongsLoading by viewModel.strongsLoading.collectAsStateWithLifecycle()

    var showBookSelector by remember { mutableStateOf(false) }
    var showChapterSelector by remember { mutableStateOf(false) }
    val listState = rememberLazyListState()
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    val scope = rememberCoroutineScope()

    // Apply initial book/chapter when navigated from ConcordanceResults
    LaunchedEffect(initialBook, initialChapter) {
        if (initialBook != null) viewModel.selectBook(initialBook)
        if (initialChapter != null) viewModel.selectChapter(initialChapter)
    }

    // Autoscroll effect
    LaunchedEffect(isAutoScrolling) {
        if (!isAutoScrolling) return@LaunchedEffect
        while (true) {
            delay(4000L)
            val next = listState.firstVisibleItemIndex + 1
            if (next < listState.layoutInfo.totalItemsCount) {
                listState.animateScrollToItem(next)
            } else {
                viewModel.onToggleAutoScroll()
                break
            }
        }
    }

    Scaffold(
        containerColor = FaithFeedColors.BackgroundPrimary,
        topBar = {
            FaithFeedTopBar(
                title = "$currentBook $currentChapter",
                onSearchClick = { navController.navigate(Route.SemanticSearch) }
            )
        },
        bottomBar = {
            Surface(
                color = FaithFeedColors.BackgroundSecondary,
                modifier = Modifier.fillMaxWidth()
            ) {
                Column {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp, vertical = 4.dp),
                        horizontalArrangement = Arrangement.End,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        IconButton(onClick = { viewModel.onToggleAutoScroll() }) {
                            Icon(
                                imageVector = if (isAutoScrolling) Icons.Outlined.PauseCircle else Icons.Outlined.PlayCircle,
                                contentDescription = "Autoscroll",
                                tint = if (isAutoScrolling) FaithFeedColors.GoldAccent else FaithFeedColors.TextSecondary,
                                modifier = Modifier.size(22.dp)
                            )
                        }
                        Spacer(Modifier.width(4.dp))
                        Text(
                            text = if (isAutoScrolling) "Scrolling" else "Auto",
                            style = Typography.labelSmall,
                            color = if (isAutoScrolling) FaithFeedColors.GoldAccent else FaithFeedColors.TextTertiary
                        )
                    }
                    HorizontalDivider(color = FaithFeedColors.GlassBorder, thickness = 0.5.dp)
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp, vertical = 12.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        IconButton(onClick = { viewModel.previousChapter() }) {
                            Icon(Icons.Default.ChevronLeft, contentDescription = "Previous", tint = FaithFeedColors.GoldAccent)
                        }
                        Row(
                            horizontalArrangement = Arrangement.spacedBy(8.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            // Book picker chip
                            Surface(
                                color = FaithFeedColors.GlassBackground,
                                shape = RoundedCornerShape(8.dp),
                                modifier = Modifier.clickable { showBookSelector = true }
                            ) {
                                Row(
                                    modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text(
                                        text = currentBook,
                                        style = Typography.labelLarge.copy(fontWeight = FontWeight.Bold),
                                        color = FaithFeedColors.TextPrimary,
                                        maxLines = 1,
                                        overflow = TextOverflow.Ellipsis
                                    )
                                    Icon(Icons.Default.ArrowDropDown, contentDescription = "Select Book", tint = FaithFeedColors.TextSecondary, modifier = Modifier.size(18.dp))
                                }
                            }
                            // Chapter picker chip
                            Surface(
                                color = FaithFeedColors.GlassBackground,
                                shape = RoundedCornerShape(8.dp),
                                modifier = Modifier.clickable { showChapterSelector = true }
                            ) {
                                Row(
                                    modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text(
                                        text = "$currentChapter",
                                        style = Typography.labelLarge.copy(fontWeight = FontWeight.Bold),
                                        color = FaithFeedColors.GoldAccent
                                    )
                                    Icon(Icons.Default.ArrowDropDown, contentDescription = "Select Chapter", tint = FaithFeedColors.TextSecondary, modifier = Modifier.size(18.dp))
                                }
                            }
                        }
                        IconButton(onClick = { viewModel.nextChapter() }) {
                            Icon(Icons.Default.ChevronRight, contentDescription = "Next", tint = FaithFeedColors.GoldAccent)
                        }
                    }
                }
            }
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            LazyColumn(
                state = listState,
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(horizontal = 16.dp, vertical = 24.dp)
            ) {
                items(verses, key = { "${it.book}${it.chapter}${it.verse}" }) { verse ->
                    val verseRef = "${verse.book} ${verse.chapter}:${verse.verse}"
                    val isSelected = selectedVerse?.verse == verse.verse
                    val highlightHex = highlights[verseRef]
                    val highlightColor = highlightHex?.let {
                        HIGHLIGHT_COLORS.find { (hex, _) -> hex == it }?.second
                    }
                    val bgColor = when {
                        isSelected -> FaithFeedColors.GoldAccent.copy(alpha = 0.12f)
                        highlightColor != null -> highlightColor.copy(alpha = 0.15f)
                        else -> FaithFeedColors.BackgroundPrimary
                    }
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(bgColor)
                            .clickable { viewModel.onVerseClick(verse) }
                            .padding(vertical = 8.dp, horizontal = 4.dp)
                    ) {
                        // Highlight indicator strip
                        if (highlightColor != null) {
                            Box(
                                modifier = Modifier
                                    .width(3.dp)
                                    .height(20.dp)
                                    .clip(RoundedCornerShape(2.dp))
                                    .background(highlightColor)
                                    .align(Alignment.CenterVertically)
                            )
                            Spacer(Modifier.width(6.dp))
                        }
                        Text(
                            text = "${verse.verse}",
                            style = Typography.labelSmall.copy(fontWeight = FontWeight.Bold),
                            color = FaithFeedColors.GoldAccent,
                            modifier = Modifier
                                .padding(top = 4.dp, end = 8.dp)
                                .width(24.dp)
                        )
                        Text(
                            text = verse.text,
                            style = Typography.bodyLarge.copy(lineHeight = 26.sp),
                            color = FaithFeedColors.TextPrimary,
                            fontFamily = Nunito
                        )
                    }
                }
                if (verses.isEmpty()) {
                    item {
                        Text(
                            text = "No verses found.",
                            color = FaithFeedColors.TextTertiary,
                            modifier = Modifier.padding(16.dp)
                        )
                    }
                }
            }
        }

        // Book selector dialog
        if (showBookSelector) {
            AlertDialog(
                onDismissRequest = { showBookSelector = false },
                containerColor = FaithFeedColors.BackgroundSecondary,
                title = { Text("Select Book", color = FaithFeedColors.TextPrimary) },
                text = {
                    LazyColumn(modifier = Modifier.heightIn(max = 400.dp)) {
                        items(allBooks) { book ->
                            Text(
                                text = book,
                                style = Typography.bodyLarge,
                                color = if (book == currentBook) FaithFeedColors.GoldAccent else FaithFeedColors.TextPrimary,
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .clickable {
                                        viewModel.selectBook(book)
                                        showBookSelector = false
                                    }
                                    .padding(vertical = 12.dp, horizontal = 16.dp)
                            )
                        }
                    }
                },
                confirmButton = {
                    TextButton(onClick = { showBookSelector = false }) {
                        Text("Close", color = FaithFeedColors.GoldAccent)
                    }
                }
            )
        }

        // Chapter selector dialog
        if (showChapterSelector) {
            val chapterList = chapters.ifEmpty { (1..150).toList() }
            AlertDialog(
                onDismissRequest = { showChapterSelector = false },
                containerColor = FaithFeedColors.BackgroundSecondary,
                title = { Text("Chapter — $currentBook", color = FaithFeedColors.TextPrimary, style = Typography.titleMedium) },
                text = {
                    LazyColumn(modifier = Modifier.heightIn(max = 360.dp)) {
                        val rows = chapterList.chunked(5)
                        items(rows) { row ->
                            Row(
                                modifier = Modifier.fillMaxWidth().padding(vertical = 3.dp),
                                horizontalArrangement = Arrangement.spacedBy(6.dp)
                            ) {
                                row.forEach { ch ->
                                    val isSelected = ch == currentChapter
                                    Box(
                                        modifier = Modifier
                                            .weight(1f)
                                            .clip(RoundedCornerShape(6.dp))
                                            .background(
                                                if (isSelected) FaithFeedColors.GoldAccent
                                                else FaithFeedColors.GlassBackground
                                            )
                                            .clickable {
                                                viewModel.selectChapter(ch)
                                                showChapterSelector = false
                                            }
                                            .padding(vertical = 10.dp),
                                        contentAlignment = Alignment.Center
                                    ) {
                                        Text(
                                            text = "$ch",
                                            style = Typography.bodySmall.copy(fontWeight = FontWeight.SemiBold),
                                            color = if (isSelected) FaithFeedColors.BackgroundPrimary else FaithFeedColors.TextPrimary
                                        )
                                    }
                                }
                                // Fill remaining cells in the last row
                                repeat(5 - row.size) { Spacer(modifier = Modifier.weight(1f)) }
                            }
                        }
                    }
                },
                confirmButton = {
                    TextButton(onClick = { showChapterSelector = false }) {
                        Text("Close", color = FaithFeedColors.GoldAccent)
                    }
                }
            )
        }

        // Verse action bottom sheet
        if (selectedVerse != null) {
            VerseActionSheet(
                verse = selectedVerse!!,
                isSpeaking = isSpeaking,
                verseNotes = verseNotes,
                verseStrongs = verseStrongs,
                strongsLexicon = strongsLexicon,
                strongsLoading = strongsLoading,
                highlights = highlights,
                sheetState = sheetState,
                onDismiss = { viewModel.onDismissVerse() },
                onListen = {
                    if (isSpeaking) viewModel.stopSpeaking()
                    else viewModel.speakVerse(selectedVerse!!.text)
                },
                onHighlight = { ref, hex -> viewModel.highlightVerse(ref, hex) },
                onRemoveHighlight = { ref -> viewModel.removeHighlight(ref) },
                onNavigate = { route ->
                    viewModel.onDismissVerse()
                    navController.navigate(route)
                }
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun VerseActionSheet(
    verse: BibleVerse,
    isSpeaking: Boolean,
    verseNotes: List<Note>,
    verseStrongs: List<StrongsEntry>,
    strongsLexicon: Map<String, StrongsLexiconEntry>,
    strongsLoading: Boolean,
    highlights: Map<String, String>,
    sheetState: SheetState,
    onDismiss: () -> Unit,
    onListen: () -> Unit,
    onHighlight: (String, String) -> Unit,
    onRemoveHighlight: (String) -> Unit,
    onNavigate: (Route) -> Unit
) {
    val clipboardManager = LocalClipboardManager.current
    val context = LocalContext.current
    val verseRef = "${verse.book} ${verse.chapter}:${verse.verse}"
    var selectedTab by remember { mutableIntStateOf(0) }
    val tabs = listOf("Mine", "Topics", "Commentary", "Words")
    var showHighlightPicker by remember { mutableStateOf(false) }
    var selectedStrongsEntry by remember { mutableStateOf<StrongsLexiconEntry?>(null) }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        containerColor = FaithFeedColors.BackgroundSecondary,
        dragHandle = {
            Box(
                Modifier
                    .padding(vertical = 12.dp)
                    .width(40.dp)
                    .height(4.dp)
                    .background(FaithFeedColors.GlassBorder, RoundedCornerShape(2.dp))
            )
        }
    ) {
        Column(modifier = Modifier.fillMaxWidth()) {
            // Verse header
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp, vertical = 4.dp)
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = verseRef,
                        style = Typography.labelLarge.copy(fontWeight = FontWeight.Bold),
                        color = FaithFeedColors.GoldAccent,
                        modifier = Modifier.weight(1f)
                    )
                    // Highlight dot indicator
                    highlights[verseRef]?.let { hex ->
                        val color = HIGHLIGHT_COLORS.find { (h, _) -> h == hex }?.second
                        if (color != null) {
                            Box(
                                modifier = Modifier
                                    .size(10.dp)
                                    .clip(CircleShape)
                                    .background(color)
                            )
                        }
                    }
                }
                Spacer(Modifier.height(6.dp))
                Text(
                    text = verse.text,
                    style = Typography.bodyMedium.copy(lineHeight = 22.sp),
                    color = FaithFeedColors.TextSecondary,
                    fontFamily = Nunito
                )
            }

            Spacer(Modifier.height(16.dp))
            HorizontalDivider(color = FaithFeedColors.GlassBorder)
            Spacer(Modifier.height(12.dp))

            // Action buttons row
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 8.dp),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                VerseActionButton(
                    icon = Icons.Outlined.Highlight,
                    label = "Highlight",
                    onClick = { showHighlightPicker = true },
                    tint = highlights[verseRef]?.let { hex ->
                        HIGHLIGHT_COLORS.find { (h, _) -> h == hex }?.second
                    } ?: FaithFeedColors.GoldAccent
                )
                VerseActionButton(
                    icon = if (isSpeaking) Icons.Outlined.StopCircle else Icons.Outlined.VolumeUp,
                    label = if (isSpeaking) "Stop" else "Listen",
                    onClick = onListen,
                    tint = if (isSpeaking) FaithFeedColors.GoldHighlight else FaithFeedColors.GoldAccent
                )
                VerseActionButton(
                    icon = Icons.Outlined.EditNote,
                    label = "Note",
                    onClick = { onNavigate(Route.NoteDetail("new", verseRef)) }
                )
                VerseActionButton(
                    icon = Icons.Outlined.Share,
                    label = "Share",
                    onClick = {
                        val intent = Intent(Intent.ACTION_SEND).apply {
                            type = "text/plain"
                            putExtra(Intent.EXTRA_TEXT, "\"${verse.text}\" — $verseRef (ASV)\n\nShared from FaithFeed")
                        }
                        context.startActivity(Intent.createChooser(intent, "Share Verse"))
                    }
                )
                VerseActionButton(
                    icon = Icons.Outlined.ContentCopy,
                    label = "Copy",
                    onClick = {
                        clipboardManager.setText(AnnotatedString("\"${verse.text}\" — $verseRef"))
                    }
                )
                VerseActionButton(
                    icon = Icons.Outlined.MenuBook,
                    label = "Study",
                    onClick = { onNavigate(Route.VerseCommentary(verseRef)) }
                )
            }

            Spacer(Modifier.height(16.dp))
            HorizontalDivider(color = FaithFeedColors.GlassBorder)

            // Tabs
            TabRow(
                selectedTabIndex = selectedTab,
                containerColor = FaithFeedColors.BackgroundSecondary,
                contentColor = FaithFeedColors.GoldAccent
            ) {
                tabs.forEachIndexed { index, title ->
                    Tab(
                        selected = selectedTab == index,
                        onClick = { selectedTab = index },
                        text = {
                            Text(
                                text = title,
                                style = Typography.labelMedium,
                                color = if (selectedTab == index) FaithFeedColors.GoldAccent else FaithFeedColors.TextTertiary
                            )
                        }
                    )
                }
            }

            // Tab content
            when (selectedTab) {
                0 -> NotesMineTab(verseNotes, verseRef, onNavigate)
                1 -> SimpleNavigateTab(
                    message = "See verses related to $verseRef",
                    buttonText = "View Related Verses →",
                    onClick = { onNavigate(Route.RelatedVerses(verseRef)) }
                )
                2 -> SimpleNavigateTab(
                    message = "Commentary on $verseRef",
                    buttonText = "View Commentary →",
                    onClick = { onNavigate(Route.VerseCommentary(verseRef)) }
                )
                3 -> WordsTab(
                    verseStrongs = verseStrongs,
                    strongsLexicon = strongsLexicon,
                    isLoading = strongsLoading,
                    onWordTap = { entry -> selectedStrongsEntry = entry },
                    onNavigateConcordance = { tag -> onNavigate(Route.ConcordanceResults(tag)) }
                )
            }

            Spacer(Modifier.navigationBarsPadding())
        }
    }

    // Highlight color picker dialog
    if (showHighlightPicker) {
        HighlightPickerDialog(
            currentHex = highlights[verseRef],
            onColorSelected = { hex ->
                onHighlight(verseRef, hex)
                showHighlightPicker = false
            },
            onRemove = {
                onRemoveHighlight(verseRef)
                showHighlightPicker = false
            },
            onDismiss = { showHighlightPicker = false }
        )
    }

    // Lexicon detail dialog
    selectedStrongsEntry?.let { entry ->
        LexiconDetailDialog(
            entry = entry,
            onNavigateConcordance = { tag ->
                selectedStrongsEntry = null
                onNavigate(Route.ConcordanceResults(tag))
            },
            onDismiss = { selectedStrongsEntry = null }
        )
    }
}

@Composable
private fun NotesMineTab(
    verseNotes: List<Note>,
    verseRef: String,
    onNavigate: (Route) -> Unit
) {
    if (verseNotes.isEmpty()) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(160.dp)
                .padding(16.dp),
            contentAlignment = Alignment.Center
        ) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(
                    "No notes on this verse yet.",
                    style = Typography.bodyMedium,
                    color = FaithFeedColors.TextTertiary,
                    textAlign = TextAlign.Center
                )
                Spacer(Modifier.height(12.dp))
                TextButton(onClick = { onNavigate(Route.NoteDetail("new", verseRef)) }) {
                    Text("Add a Note →", color = FaithFeedColors.GoldAccent, style = Typography.labelLarge)
                }
            }
        }
    } else {
        LazyColumn(
            modifier = Modifier
                .fillMaxWidth()
                .heightIn(max = 200.dp),
            contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp)
        ) {
            items(verseNotes, key = { it.id }) { note ->
                Column(modifier = Modifier
                    .fillMaxWidth()
                    .clickable { onNavigate(Route.NoteDetail(note.id)) }
                    .padding(vertical = 8.dp)
                ) {
                    if (note.title.isNotBlank()) {
                        Text(
                            text = note.title,
                            style = Typography.labelLarge.copy(fontWeight = FontWeight.SemiBold),
                            color = FaithFeedColors.TextPrimary
                        )
                    }
                    if (note.content.isNotBlank()) {
                        Text(
                            text = note.content,
                            style = Typography.bodySmall,
                            color = FaithFeedColors.TextSecondary,
                            maxLines = 2,
                            overflow = TextOverflow.Ellipsis,
                            modifier = Modifier.padding(top = 2.dp)
                        )
                    }
                }
                HorizontalDivider(color = FaithFeedColors.GlassBorder, thickness = 0.5.dp)
            }
            item {
                TextButton(
                    onClick = { onNavigate(Route.NoteDetail("new", verseRef)) },
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text("+ Add Note", color = FaithFeedColors.GoldAccent, style = Typography.labelMedium)
                }
            }
        }
    }
}

@Composable
private fun SimpleNavigateTab(
    message: String,
    buttonText: String,
    onClick: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(160.dp)
            .padding(16.dp),
        contentAlignment = Alignment.Center
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(message, style = Typography.bodyMedium, color = FaithFeedColors.TextSecondary, textAlign = TextAlign.Center)
            Spacer(Modifier.height(12.dp))
            TextButton(onClick = onClick) {
                Text(buttonText, color = FaithFeedColors.GoldAccent, style = Typography.labelLarge)
            }
        }
    }
}

@Composable
private fun WordsTab(
    verseStrongs: List<StrongsEntry>,
    strongsLexicon: Map<String, StrongsLexiconEntry>,
    isLoading: Boolean,
    onWordTap: (StrongsLexiconEntry) -> Unit,
    onNavigateConcordance: (String) -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = 120.dp, max = 280.dp)
    ) {
        when {
            isLoading -> Box(Modifier.fillMaxWidth().padding(32.dp), contentAlignment = Alignment.Center) {
                CircularProgressIndicator(color = FaithFeedColors.GoldAccent, modifier = Modifier.size(28.dp))
            }
            verseStrongs.isEmpty() -> Box(Modifier.fillMaxWidth().padding(32.dp), contentAlignment = Alignment.Center) {
                Text(
                    "No word data available for this verse.",
                    style = Typography.bodyMedium,
                    color = FaithFeedColors.TextTertiary,
                    textAlign = TextAlign.Center
                )
            }
            else -> LazyColumn(
                contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp)
            ) {
                items(verseStrongs, key = { "${it.wordPosition}_${it.strongsTag}" }) { entry ->
                    val lexEntry = strongsLexicon[entry.strongsTag]
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable(enabled = lexEntry != null) { lexEntry?.let { onWordTap(it) } }
                            .padding(vertical = 8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        // Position number
                        Text(
                            text = "${entry.wordPosition}",
                            fontFamily = FontFamily.Monospace,
                            fontSize = 11.sp,
                            color = FaithFeedColors.TextTertiary,
                            modifier = Modifier.width(24.dp)
                        )
                        // Strongs tag
                        Surface(
                            color = FaithFeedColors.GlassBackground,
                            shape = RoundedCornerShape(4.dp),
                            modifier = Modifier.clickable { onNavigateConcordance(entry.strongsTag) }
                        ) {
                            Text(
                                text = entry.strongsTag,
                                fontFamily = FontFamily.Monospace,
                                fontSize = 11.sp,
                                color = FaithFeedColors.GoldAccent,
                                modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                            )
                        }
                        Spacer(Modifier.width(10.dp))
                        // Gloss
                        Text(
                            text = lexEntry?.gloss ?: "…",
                            fontFamily = Nunito,
                            fontWeight = FontWeight.SemiBold,
                            fontSize = 14.sp,
                            color = if (lexEntry != null) FaithFeedColors.TextPrimary else FaithFeedColors.TextTertiary,
                            modifier = Modifier.weight(1f)
                        )
                        // Lemma (Hebrew/Greek)
                        if (lexEntry != null && lexEntry.lemma.isNotBlank()) {
                            Text(
                                text = lexEntry.lemma,
                                fontSize = 14.sp,
                                color = FaithFeedColors.TextSecondary
                            )
                        }
                    }
                    HorizontalDivider(color = FaithFeedColors.GlassBorder, thickness = 0.5.dp)
                }
            }
        }
    }
}

@Composable
private fun HighlightPickerDialog(
    currentHex: String?,
    onColorSelected: (String) -> Unit,
    onRemove: () -> Unit,
    onDismiss: () -> Unit
) {
    Dialog(onDismissRequest = onDismiss) {
        Surface(
            color = FaithFeedColors.BackgroundSecondary,
            shape = RoundedCornerShape(16.dp)
        ) {
            Column(modifier = Modifier.padding(20.dp)) {
                Text(
                    "Highlight Verse",
                    style = Typography.titleMedium,
                    color = FaithFeedColors.TextPrimary
                )
                Spacer(Modifier.height(16.dp))
                Row(
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    HIGHLIGHT_COLORS.forEach { (hex, color) ->
                        val isSelected = hex == currentHex
                        Box(
                            modifier = Modifier
                                .size(36.dp)
                                .clip(CircleShape)
                                .background(color)
                                .then(
                                    if (isSelected) Modifier.border(2.dp, Color.White, CircleShape)
                                    else Modifier
                                )
                                .clickable { onColorSelected(hex) }
                        )
                    }
                }
                if (currentHex != null) {
                    Spacer(Modifier.height(12.dp))
                    TextButton(
                        onClick = onRemove,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text("Remove Highlight", color = FaithFeedColors.TextTertiary, style = Typography.labelMedium)
                    }
                }
            }
        }
    }
}

@Composable
private fun LexiconDetailDialog(
    entry: StrongsLexiconEntry,
    onNavigateConcordance: (String) -> Unit,
    onDismiss: () -> Unit
) {
    Dialog(onDismissRequest = onDismiss) {
        Surface(
            color = FaithFeedColors.BackgroundSecondary,
            shape = RoundedCornerShape(16.dp)
        ) {
            Column(
                modifier = Modifier
                    .padding(20.dp)
                    .fillMaxWidth()
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = entry.lemma,
                        fontSize = 22.sp,
                        fontWeight = FontWeight.Bold,
                        color = FaithFeedColors.TextPrimary
                    )
                    if (entry.transliteration.isNotBlank()) {
                        Spacer(Modifier.width(8.dp))
                        Text(
                            text = entry.transliteration,
                            fontFamily = Nunito,
                            fontStyle = FontStyle.Italic,
                            fontSize = 14.sp,
                            color = FaithFeedColors.TextSecondary
                        )
                    }
                }
                Row(
                    modifier = Modifier.padding(top = 2.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Surface(color = FaithFeedColors.GlassBackground, shape = RoundedCornerShape(4.dp)) {
                        Text(
                            text = entry.strongsTag,
                            fontFamily = FontFamily.Monospace,
                            fontSize = 11.sp,
                            color = FaithFeedColors.GoldAccent,
                            modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                        )
                    }
                    if (entry.morph.isNotBlank()) {
                        Text(
                            text = entry.morph,
                            fontFamily = FontFamily.Monospace,
                            fontSize = 11.sp,
                            color = FaithFeedColors.TextTertiary
                        )
                    }
                }
                if (entry.gloss.isNotBlank()) {
                    Spacer(Modifier.height(10.dp))
                    Text(
                        text = entry.gloss,
                        fontFamily = Nunito,
                        fontWeight = FontWeight.SemiBold,
                        fontSize = 15.sp,
                        color = FaithFeedColors.GoldAccent
                    )
                }
                if (entry.definition.isNotBlank()) {
                    Spacer(Modifier.height(8.dp))
                    Text(
                        text = entry.definition
                            .replace(Regex("<br\\s*/?>", RegexOption.IGNORE_CASE), "\n")
                            .replace(Regex("<[^>]+>"), "")
                            .trim(),
                        fontFamily = Nunito,
                        fontSize = 13.sp,
                        color = FaithFeedColors.TextSecondary,
                        maxLines = 8,
                        overflow = TextOverflow.Ellipsis
                    )
                }
                Spacer(Modifier.height(16.dp))
                TextButton(
                    onClick = { onNavigateConcordance(entry.strongsTag) },
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text(
                        "Find all verses with ${entry.strongsTag} →",
                        color = FaithFeedColors.GoldAccent,
                        style = Typography.labelMedium
                    )
                }
            }
        }
    }
}

@Composable
private fun VerseActionButton(
    icon: ImageVector,
    label: String,
    onClick: () -> Unit,
    tint: Color = FaithFeedColors.GoldAccent
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier
            .clickable(onClick = onClick)
            .padding(8.dp)
    ) {
        Icon(imageVector = icon, contentDescription = label, tint = tint, modifier = Modifier.size(26.dp))
        Spacer(Modifier.height(4.dp))
        Text(text = label, style = Typography.labelSmall, color = FaithFeedColors.TextSecondary)
    }
}
