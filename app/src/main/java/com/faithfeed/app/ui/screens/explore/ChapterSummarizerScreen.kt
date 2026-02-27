package com.faithfeed.app.ui.screens.explore

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowDropDown
import androidx.compose.material.icons.outlined.Summarize
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavController
import com.faithfeed.app.ui.components.ButtonStyle
import com.faithfeed.app.ui.components.EmptyState
import com.faithfeed.app.ui.components.FaithFeedButton
import com.faithfeed.app.ui.components.SimpleTopBar
import com.faithfeed.app.ui.theme.FaithFeedColors
import com.faithfeed.app.ui.theme.Nunito
import com.faithfeed.app.ui.theme.Typography

@Composable
fun ChapterSummarizerScreen(
    navController: NavController,
    viewModel: ChapterSummarizerViewModel = hiltViewModel()
) {
    val selectedBook by viewModel.selectedBook.collectAsStateWithLifecycle()
    val selectedChapter by viewModel.selectedChapter.collectAsStateWithLifecycle()
    val summary by viewModel.summary.collectAsStateWithLifecycle()
    val isLoading by viewModel.isLoading.collectAsStateWithLifecycle()
    val allBooks by viewModel.allBooks.collectAsStateWithLifecycle()
    val chaptersForBook by viewModel.chaptersForBook.collectAsStateWithLifecycle()

    var showBookSelector by remember { mutableStateOf(false) }
    var showChapterSelector by remember { mutableStateOf(false) }

    Scaffold(
        containerColor = FaithFeedColors.BackgroundPrimary,
        topBar = {
            SimpleTopBar(title = "Chapter Summarizer", onBack = { navController.popBackStack() })
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            Surface(
                color = FaithFeedColors.BackgroundSecondary,
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(
                        text = "Select a chapter to summarize",
                        style = Typography.titleMedium.copy(fontWeight = androidx.compose.ui.text.font.FontWeight.Bold),
                        color = FaithFeedColors.TextPrimary
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        // Book Selector
                        Surface(
                            color = FaithFeedColors.GlassBackground,
                            shape = RoundedCornerShape(8.dp),
                            modifier = Modifier
                                .weight(2f)
                                .clickable { showBookSelector = true }
                        ) {
                            Row(
                                modifier = Modifier.padding(12.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    text = selectedBook,
                                    style = Typography.bodyLarge,
                                    color = FaithFeedColors.TextPrimary
                                )
                                Icon(Icons.Default.ArrowDropDown, contentDescription = "Select Book", tint = FaithFeedColors.TextSecondary)
                            }
                        }

                        Surface(
                            color = FaithFeedColors.GlassBackground,
                            shape = RoundedCornerShape(8.dp),
                            modifier = Modifier
                                .weight(1f)
                                .clickable { showChapterSelector = true }
                        ) {
                            Row(
                                modifier = Modifier.padding(12.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    text = "Ch $selectedChapter",
                                    style = Typography.bodyLarge,
                                    color = FaithFeedColors.TextPrimary
                                )
                                Icon(Icons.Default.ArrowDropDown, contentDescription = "Select Chapter", tint = FaithFeedColors.TextSecondary)
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(16.dp))
                    
                    FaithFeedButton(
                        text = "Generate Summary",
                        onClick = { viewModel.generateSummary() },
                        style = ButtonStyle.Primary,
                        modifier = Modifier.fillMaxWidth(),
                        enabled = !isLoading
                    )
                }
            }

            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(16.dp)
            ) {
                if (isLoading) {
                    CircularProgressIndicator(
                        color = FaithFeedColors.GoldAccent,
                        modifier = Modifier.align(Alignment.Center)
                    )
                } else if (summary.isEmpty()) {
                    EmptyState(
                        icon = Icons.Outlined.Summarize,
                        title = "Chapter Summarizer",
                        subtitle = "Select a book and chapter to receive an AI-generated summary of its core themes."
                    )
                } else {
                    Card(
                        modifier = Modifier
                            .fillMaxSize()
                            .verticalScroll(rememberScrollState()),
                        colors = CardDefaults.cardColors(containerColor = FaithFeedColors.BackgroundSecondary),
                        shape = RoundedCornerShape(16.dp)
                    ) {
                        Text(
                            text = summary,
                            style = Typography.bodyLarge.copy(lineHeight = 24.sp),
                            color = FaithFeedColors.TextPrimary,
                            fontFamily = Nunito,
                            modifier = Modifier.padding(24.dp)
                        )
                    }
                }
            }
        }

        if (showChapterSelector) {
            AlertDialog(
                onDismissRequest = { showChapterSelector = false },
                containerColor = FaithFeedColors.BackgroundSecondary,
                title = { Text("Select Chapter", color = FaithFeedColors.TextPrimary) },
                text = {
                    LazyColumn(modifier = Modifier.heightIn(max = 400.dp)) {
                        items(chaptersForBook) { ch ->
                            Text(
                                text = "Chapter $ch",
                                style = Typography.bodyLarge,
                                color = if (ch == selectedChapter) FaithFeedColors.GoldAccent else FaithFeedColors.TextPrimary,
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .clickable {
                                        viewModel.selectChapter(ch)
                                        showChapterSelector = false
                                    }
                                    .padding(vertical = 12.dp, horizontal = 16.dp)
                            )
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
                                color = if (book == selectedBook) FaithFeedColors.GoldAccent else FaithFeedColors.TextPrimary,
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
    }
}
