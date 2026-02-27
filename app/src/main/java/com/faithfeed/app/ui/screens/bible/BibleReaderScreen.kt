package com.faithfeed.app.ui.screens.bible

import android.content.Intent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
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
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavController
import com.faithfeed.app.data.model.BibleVerse
import com.faithfeed.app.navigation.Route
import com.faithfeed.app.ui.components.FaithFeedTopBar
import com.faithfeed.app.ui.theme.FaithFeedColors
import com.faithfeed.app.ui.theme.Nunito
import com.faithfeed.app.ui.theme.Typography
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BibleReaderScreen(
    navController: NavController,
    viewModel: BibleReaderViewModel = hiltViewModel()
) {
    val verses by viewModel.verses.collectAsStateWithLifecycle()
    val currentBook by viewModel.currentBook.collectAsStateWithLifecycle()
    val currentChapter by viewModel.currentChapter.collectAsStateWithLifecycle()
    val allBooks by viewModel.allBooks.collectAsStateWithLifecycle()
    val selectedVerse by viewModel.selectedVerse.collectAsStateWithLifecycle()
    val isSpeaking by viewModel.isSpeaking.collectAsStateWithLifecycle()
    val isAutoScrolling by viewModel.isAutoScrolling.collectAsStateWithLifecycle()

    var showBookSelector by remember { mutableStateOf(false) }
    val listState = rememberLazyListState()
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    val scope = rememberCoroutineScope()

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
                    // TTS + Autoscroll row
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
                        Surface(
                            color = FaithFeedColors.GlassBackground,
                            shape = RoundedCornerShape(8.dp),
                            modifier = Modifier.clickable { showBookSelector = true }
                        ) {
                            Row(
                                modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    text = currentBook,
                                    style = Typography.labelLarge.copy(fontWeight = FontWeight.Bold),
                                    color = FaithFeedColors.TextPrimary
                                )
                                Spacer(Modifier.width(4.dp))
                                Icon(Icons.Default.ArrowDropDown, contentDescription = "Select Book", tint = FaithFeedColors.TextSecondary)
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
                    val isSelected = selectedVerse?.verse == verse.verse
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(
                                if (isSelected) FaithFeedColors.GoldAccent.copy(alpha = 0.08f)
                                else FaithFeedColors.BackgroundPrimary
                            )
                            .clickable { viewModel.onVerseClick(verse) }
                            .padding(vertical = 8.dp, horizontal = 4.dp)
                    ) {
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
                            color = if (isSelected) FaithFeedColors.TextPrimary else FaithFeedColors.TextPrimary.copy(alpha = 0.9f),
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

        // Verse action bottom sheet
        if (selectedVerse != null) {
            VerseActionSheet(
                verse = selectedVerse!!,
                isSpeaking = isSpeaking,
                sheetState = sheetState,
                onDismiss = { viewModel.onDismissVerse() },
                onListen = {
                    if (isSpeaking) viewModel.stopSpeaking()
                    else viewModel.speakVerse(selectedVerse!!.text)
                },
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
    sheetState: SheetState,
    onDismiss: () -> Unit,
    onListen: () -> Unit,
    onNavigate: (Route) -> Unit
) {
    val clipboardManager = LocalClipboardManager.current
    val context = LocalContext.current
    val verseRef = "${verse.book} ${verse.chapter}:${verse.verse}"
    var selectedTab by remember { mutableIntStateOf(0) }
    val tabs = listOf("Community", "Topics", "Commentary", "Words")

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
                Text(
                    text = verseRef,
                    style = Typography.labelLarge.copy(fontWeight = FontWeight.Bold),
                    color = FaithFeedColors.GoldAccent
                )
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
                    onClick = { /* TODO: highlight */ }
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
                    onClick = { onNavigate(Route.Notes) }
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
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(180.dp)
                    .padding(16.dp),
                contentAlignment = Alignment.Center
            ) {
                when (selectedTab) {
                    0 -> Text(
                        "Community notes for this verse will appear here.",
                        style = Typography.bodyMedium,
                        color = FaithFeedColors.TextTertiary,
                        textAlign = TextAlign.Center
                    )
                    1 -> Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text("See verses related to $verseRef", style = Typography.bodyMedium, color = FaithFeedColors.TextSecondary, textAlign = TextAlign.Center)
                        Spacer(Modifier.height(12.dp))
                        TextButton(onClick = { onNavigate(Route.RelatedVerses(verseRef)) }) {
                            Text("View Related Verses →", color = FaithFeedColors.GoldAccent, style = Typography.labelLarge)
                        }
                    }
                    2 -> Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text("Commentary on $verseRef", style = Typography.bodyMedium, color = FaithFeedColors.TextSecondary, textAlign = TextAlign.Center)
                        Spacer(Modifier.height(12.dp))
                        TextButton(onClick = { onNavigate(Route.VerseCommentary(verseRef)) }) {
                            Text("View Commentary →", color = FaithFeedColors.GoldAccent, style = Typography.labelLarge)
                        }
                    }
                    3 -> Text(
                        "Word index (Strong's concordance) coming soon.",
                        style = Typography.bodyMedium,
                        color = FaithFeedColors.TextTertiary,
                        textAlign = TextAlign.Center
                    )
                }
            }

            Spacer(Modifier.navigationBarsPadding())
        }
    }
}

@Composable
private fun VerseActionButton(
    icon: ImageVector,
    label: String,
    onClick: () -> Unit,
    tint: androidx.compose.ui.graphics.Color = FaithFeedColors.GoldAccent
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
