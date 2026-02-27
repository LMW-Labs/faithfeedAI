package com.faithfeed.app.ui.screens.notes

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Add
import androidx.compose.material.icons.outlined.BookmarkBorder
import androidx.compose.material.icons.outlined.Notes
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavController
import com.faithfeed.app.data.model.Note
import com.faithfeed.app.navigation.Route
import com.faithfeed.app.ui.components.EmptyState
import com.faithfeed.app.ui.components.SimpleTopBar
import com.faithfeed.app.ui.theme.FaithFeedColors
import com.faithfeed.app.ui.theme.Typography

@Composable
fun NotesScreen(
    navController: NavController,
    viewModel: NotesViewModel = hiltViewModel()
) {
    val notes by viewModel.notes.collectAsStateWithLifecycle()
    val searchQuery by viewModel.searchQuery.collectAsStateWithLifecycle()

    val filteredNotes = remember(notes, searchQuery) {
        if (searchQuery.isBlank()) notes
        else notes.filter { note ->
            note.title.contains(searchQuery, ignoreCase = true) ||
            note.content.contains(searchQuery, ignoreCase = true) ||
            note.verseRef?.contains(searchQuery, ignoreCase = true) == true
        }
    }

    Scaffold(
        containerColor = FaithFeedColors.BackgroundPrimary,
        topBar = {
            SimpleTopBar(title = "My Notes", onBack = { navController.popBackStack() })
        },
        floatingActionButton = {
            FloatingActionButton(
                onClick = { navController.navigate(Route.NoteDetail("new")) },
                containerColor = FaithFeedColors.GoldAccent,
                contentColor = FaithFeedColors.BackgroundPrimary
            ) {
                Icon(Icons.Outlined.Add, contentDescription = "New Note")
            }
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            // Search bar
            OutlinedTextField(
                value = searchQuery,
                onValueChange = viewModel::onSearchChange,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 12.dp),
                placeholder = { Text("Search notes...", color = FaithFeedColors.TextTertiary) },
                leadingIcon = {
                    Icon(Icons.Outlined.Search, contentDescription = "Search", tint = FaithFeedColors.TextTertiary)
                },
                singleLine = true,
                colors = OutlinedTextFieldDefaults.colors(
                    focusedTextColor = FaithFeedColors.TextPrimary,
                    unfocusedTextColor = FaithFeedColors.TextPrimary,
                    focusedBorderColor = FaithFeedColors.GoldAccent,
                    unfocusedBorderColor = FaithFeedColors.GlassBorder,
                    cursorColor = FaithFeedColors.GoldAccent,
                    focusedContainerColor = FaithFeedColors.GlassBackground,
                    unfocusedContainerColor = FaithFeedColors.GlassBackground
                ),
                shape = RoundedCornerShape(12.dp)
            )

            if (filteredNotes.isEmpty()) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    EmptyState(
                        icon = Icons.Outlined.Notes,
                        title = if (searchQuery.isBlank()) "No Notes Yet" else "No Results",
                        subtitle = if (searchQuery.isBlank())
                            "Tap a verse while reading to add notes, highlights, or questions"
                        else
                            "Try a different search term"
                    )
                }
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(start = 16.dp, top = 0.dp, end = 16.dp, bottom = 80.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    items(filteredNotes, key = { it.id }) { note ->
                        NoteCard(
                            note = note,
                            onClick = { navController.navigate(Route.NoteDetail(note.id)) }
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun NoteCard(note: Note, onClick: () -> Unit) {
    Surface(
        color = FaithFeedColors.BackgroundSecondary,
        shape = RoundedCornerShape(16.dp),
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .border(1.dp, FaithFeedColors.GlassBorder, RoundedCornerShape(16.dp))
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            // Verse ref chip
            if (note.verseRef != null) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = Icons.Outlined.BookmarkBorder,
                        contentDescription = null,
                        tint = FaithFeedColors.GoldAccent,
                        modifier = Modifier.size(14.dp)
                    )
                    Spacer(Modifier.width(4.dp))
                    Text(
                        text = note.verseRef,
                        style = Typography.labelSmall,
                        color = FaithFeedColors.GoldAccent
                    )
                }
                Spacer(Modifier.height(8.dp))
            }

            // Title
            if (note.title.isNotBlank()) {
                Text(
                    text = note.title,
                    style = Typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                    color = FaithFeedColors.TextPrimary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                Spacer(Modifier.height(6.dp))
            }

            // Content preview
            Text(
                text = note.content,
                style = Typography.bodyMedium,
                color = FaithFeedColors.TextSecondary,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )

            // Tags + date row
            if (note.tags.isNotEmpty() || note.updatedAt.isNotBlank()) {
                Spacer(Modifier.height(10.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                        note.tags.take(3).forEach { tag ->
                            Surface(
                                color = FaithFeedColors.GoldAccent.copy(alpha = 0.1f),
                                shape = RoundedCornerShape(8.dp)
                            ) {
                                Text(
                                    text = tag,
                                    style = Typography.labelSmall,
                                    color = FaithFeedColors.GoldAccent,
                                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp)
                                )
                            }
                        }
                    }
                    if (note.updatedAt.isNotBlank()) {
                        Text(
                            text = note.updatedAt.take(10), // show date portion
                            style = Typography.labelSmall,
                            color = FaithFeedColors.TextTertiary
                        )
                    }
                }
            }
        }
    }
}
