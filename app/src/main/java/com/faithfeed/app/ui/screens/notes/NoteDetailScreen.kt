package com.faithfeed.app.ui.screens.notes

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavController
import com.faithfeed.app.ui.components.ButtonStyle
import com.faithfeed.app.ui.components.FaithFeedButton
import com.faithfeed.app.ui.components.SimpleTopBar
import com.faithfeed.app.ui.theme.FaithFeedColors
import com.faithfeed.app.ui.theme.Typography

@Composable
fun NoteDetailScreen(
    noteId: String,
    prefilledVerseRef: String = "",
    navController: NavController,
    viewModel: NoteDetailViewModel = hiltViewModel()
) {
    LaunchedEffect(noteId) { viewModel.init(noteId, prefilledVerseRef) }

    val title by viewModel.title.collectAsStateWithLifecycle()
    val content by viewModel.content.collectAsStateWithLifecycle()
    val verseRef by viewModel.verseRef.collectAsStateWithLifecycle()
    val tags by viewModel.tags.collectAsStateWithLifecycle()
    val tagInput by viewModel.tagInput.collectAsStateWithLifecycle()
    val isNewNote by viewModel.isNewNote.collectAsStateWithLifecycle()
    val isSaving by viewModel.isSaving.collectAsStateWithLifecycle()
    val error by viewModel.error.collectAsStateWithLifecycle()

    val snackbarHostState = remember { SnackbarHostState() }
    LaunchedEffect(error) {
        error?.let { snackbarHostState.showSnackbar(it); viewModel.clearError() }
    }

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) },
        containerColor = FaithFeedColors.BackgroundPrimary,
        topBar = {
            SimpleTopBar(
                title = if (isNewNote) "New Note" else "Edit Note",
                onBack = { navController.popBackStack() }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Verse Reference
            NoteTextField(
                value = verseRef,
                onValueChange = viewModel::onVerseRefChange,
                label = "Verse Reference (optional)",
                placeholder = "e.g. John 3:16",
                singleLine = true,
                capitalization = KeyboardCapitalization.Words
            )

            // Title
            NoteTextField(
                value = title,
                onValueChange = viewModel::onTitleChange,
                label = "Title",
                placeholder = "Note title",
                singleLine = true,
                capitalization = KeyboardCapitalization.Sentences
            )

            // Content
            NoteTextField(
                value = content,
                onValueChange = viewModel::onContentChange,
                label = "Note",
                placeholder = "Write your thoughts, questions, or insights...",
                singleLine = false,
                minLines = 5,
                maxLines = 12,
                capitalization = KeyboardCapitalization.Sentences
            )

            // Tags
            Column {
                Text(
                    text = "Tags",
                    style = Typography.labelMedium.copy(fontWeight = FontWeight.Bold),
                    color = FaithFeedColors.TextSecondary
                )
                Spacer(Modifier.height(8.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    NoteTextField(
                        value = tagInput,
                        onValueChange = viewModel::onTagInputChange,
                        label = "",
                        placeholder = "Add tag...",
                        singleLine = true,
                        capitalization = KeyboardCapitalization.None,
                        modifier = Modifier.weight(1f)
                    )
                    Spacer(Modifier.width(8.dp))
                    TextButton(
                        onClick = { viewModel.addTag() },
                        enabled = tagInput.isNotBlank()
                    ) {
                        Text(
                            "Add",
                            color = if (tagInput.isNotBlank()) FaithFeedColors.GoldAccent else FaithFeedColors.TextTertiary,
                            style = Typography.labelLarge
                        )
                    }
                }
                if (tags.isNotEmpty()) {
                    Spacer(Modifier.height(8.dp))
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        tags.forEach { tag ->
                            Surface(
                                color = FaithFeedColors.GoldAccent.copy(alpha = 0.15f),
                                shape = RoundedCornerShape(8.dp)
                            ) {
                                Row(
                                    verticalAlignment = Alignment.CenterVertically,
                                    modifier = Modifier.padding(start = 10.dp, end = 4.dp, top = 4.dp, bottom = 4.dp)
                                ) {
                                    Text(
                                        text = tag,
                                        style = Typography.labelSmall,
                                        color = FaithFeedColors.GoldAccent
                                    )
                                    IconButton(
                                        onClick = { viewModel.removeTag(tag) },
                                        modifier = Modifier.size(20.dp)
                                    ) {
                                        Icon(
                                            Icons.Outlined.Close,
                                            contentDescription = "Remove $tag",
                                            tint = FaithFeedColors.GoldAccent,
                                            modifier = Modifier.size(12.dp)
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Spacer(Modifier.height(8.dp))

            FaithFeedButton(
                text = if (isSaving) "Saving..." else "Save Note",
                onClick = { if (!isSaving) viewModel.save { navController.popBackStack() } },
                style = ButtonStyle.Primary,
                modifier = Modifier.fillMaxWidth(),
                enabled = !isSaving
            )

            Spacer(Modifier.height(32.dp))
        }
    }
}

@Composable
private fun NoteTextField(
    value: String,
    onValueChange: (String) -> Unit,
    label: String,
    placeholder: String,
    singleLine: Boolean,
    capitalization: KeyboardCapitalization,
    minLines: Int = 1,
    maxLines: Int = 1,
    modifier: Modifier = Modifier.fillMaxWidth()
) {
    OutlinedTextField(
        value = value,
        onValueChange = onValueChange,
        label = if (label.isNotEmpty()) ({ Text(label, color = FaithFeedColors.TextSecondary) }) else null,
        placeholder = { Text(placeholder, color = FaithFeedColors.TextTertiary) },
        singleLine = singleLine,
        minLines = minLines,
        maxLines = if (singleLine) 1 else maxLines,
        keyboardOptions = KeyboardOptions(capitalization = capitalization),
        modifier = modifier,
        colors = OutlinedTextFieldDefaults.colors(
            focusedTextColor = FaithFeedColors.TextPrimary,
            unfocusedTextColor = FaithFeedColors.TextPrimary,
            focusedBorderColor = FaithFeedColors.GoldAccent,
            unfocusedBorderColor = FaithFeedColors.GlassBorder,
            focusedLabelColor = FaithFeedColors.GoldAccent,
            cursorColor = FaithFeedColors.GoldAccent,
            focusedContainerColor = FaithFeedColors.GlassBackground,
            unfocusedContainerColor = FaithFeedColors.GlassBackground
        ),
        shape = RoundedCornerShape(12.dp)
    )
}
