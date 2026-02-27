package com.faithfeed.app.ui.screens.post

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.expandVertically
import androidx.compose.animation.shrinkVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.AutoAwesome
import androidx.compose.material.icons.outlined.Image
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Snackbar
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.faithfeed.app.ui.theme.Cinzel
import com.faithfeed.app.ui.theme.FaithFeedColors
import com.faithfeed.app.ui.theme.Nunito

private val AUDIENCES = listOf("public", "friends", "church")
private val AUDIENCE_LABELS = mapOf("public" to "Public", "friends" to "Friends", "church" to "Church")

@Composable
fun CreatePostScreen(
    navController: NavController,
    viewModel: CreatePostViewModel = hiltViewModel()
) {
    val state by viewModel.uiState.collectAsState()
    val snackbarHostState = remember { SnackbarHostState() }
    var showVerseFields by remember { mutableStateOf(false) }

    LaunchedEffect(state.isDone) {
        if (state.isDone) navController.popBackStack()
    }

    LaunchedEffect(state.error) {
        state.error?.let {
            snackbarHostState.showSnackbar(it)
            viewModel.clearError()
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(FaithFeedColors.BackgroundPrimary)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .navigationBarsPadding()
                .imePadding()
        ) {
            // Top bar — custom to accommodate trailing "Post" button
            CreatePostTopBar(
                isPosting = state.isPosting,
                canPost = state.content.isNotBlank(),
                onBack = { navController.popBackStack() },
                onPost = { viewModel.post() }
            )

            // Divider
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(1.dp)
                    .background(FaithFeedColors.GlassBorder)
            )

            // Scrollable content area
            Column(
                modifier = Modifier
                    .weight(1f)
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = 20.dp, vertical = 16.dp)
            ) {
                // Main content text area
                Box(modifier = Modifier.fillMaxWidth().padding(vertical = 4.dp)) {
                    if (state.content.isEmpty()) {
                        Text(
                            text = "What\u2019s on your heart?",
                            style = TextStyle(
                                fontFamily = Nunito,
                                fontSize = 17.sp,
                                color = FaithFeedColors.TextTertiary
                            )
                        )
                    }
                    BasicTextField(
                        value = state.content,
                        onValueChange = viewModel::onContentChange,
                        modifier = Modifier.fillMaxWidth(),
                        textStyle = TextStyle(
                            fontFamily = Nunito,
                            fontSize = 17.sp,
                            color = FaithFeedColors.TextPrimary,
                            lineHeight = 26.sp
                        ),
                        cursorBrush = SolidColor(FaithFeedColors.GoldAccent),
                        minLines = 6
                    )
                }

                Spacer(Modifier.height(20.dp))

                // Verse attachment section
                AnimatedVisibility(
                    visible = showVerseFields,
                    enter = expandVertically(),
                    exit = shrinkVertically()
                ) {
                    VerseAttachmentSection(
                        verseRef = state.verseRef,
                        verseText = state.verseText,
                        onVerseRefChange = viewModel::onVerseRefChange,
                        onVerseTextChange = viewModel::onVerseTextChange
                    )
                }

                Spacer(Modifier.height(20.dp))

                // Audience selector
                AudienceSelector(
                    selected = state.audience,
                    onSelect = viewModel::onAudienceChange
                )
            }

            // Bottom toolbar
            BottomToolbar(
                verseActive = showVerseFields,
                onToggleVerse = { showVerseFields = !showVerseFields }
            )
        }

        // Loading overlay
        if (state.isPosting) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(FaithFeedColors.BackgroundPrimary.copy(alpha = 0.7f))
                    .clickable(enabled = false) {},
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator(color = FaithFeedColors.GoldAccent, strokeWidth = 2.dp)
            }
        }

        // Snackbar
        SnackbarHost(
            hostState = snackbarHostState,
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .navigationBarsPadding()
                .imePadding()
        ) { data ->
            Snackbar(
                snackbarData = data,
                containerColor = FaithFeedColors.BackgroundSecondary,
                contentColor = FaithFeedColors.TextPrimary,
                actionColor = FaithFeedColors.GoldAccent
            )
        }
    }
}

@Composable
private fun CreatePostTopBar(
    isPosting: Boolean,
    canPost: Boolean,
    onBack: () -> Unit,
    onPost: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(FaithFeedColors.BackgroundPrimary)
            .statusBarsPadding()
            .height(56.dp)
            .padding(horizontal = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        // Back button
        Box(
            modifier = Modifier
                .size(40.dp)
                .clip(RoundedCornerShape(12.dp))
                .background(FaithFeedColors.GlassBackground)
                .clickable(onClick = onBack, enabled = !isPosting),
            contentAlignment = Alignment.Center
        ) {
            Text("\u2190", color = FaithFeedColors.GoldAccent, fontSize = 18.sp)
        }

        // Title
        Text(
            text = "New Post",
            fontFamily = Cinzel,
            fontWeight = FontWeight.SemiBold,
            fontSize = 18.sp,
            color = FaithFeedColors.TextPrimary
        )

        // Post button
        Box(
            modifier = Modifier
                .clip(RoundedCornerShape(20.dp))
                .background(
                    if (canPost && !isPosting) FaithFeedColors.GoldAccent
                    else FaithFeedColors.GlassBackground
                )
                .clickable(enabled = canPost && !isPosting, onClick = onPost)
                .padding(horizontal = 20.dp, vertical = 8.dp),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = "Post",
                fontFamily = Nunito,
                fontWeight = FontWeight.Bold,
                fontSize = 14.sp,
                color = if (canPost && !isPosting) FaithFeedColors.BackgroundPrimary
                        else FaithFeedColors.TextTertiary
            )
        }
    }
}

@Composable
private fun VerseAttachmentSection(
    verseRef: String,
    verseText: String,
    onVerseRefChange: (String) -> Unit,
    onVerseTextChange: (String) -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(FaithFeedColors.GlassBackground)
            .border(1.dp, FaithFeedColors.GlassBorder, RoundedCornerShape(12.dp))
            .padding(14.dp)
    ) {
        Text(
            text = "Attach a Verse",
            fontFamily = Cinzel,
            fontWeight = FontWeight.Medium,
            fontSize = 12.sp,
            color = FaithFeedColors.GoldAccent,
            letterSpacing = 0.8.sp
        )
        Spacer(Modifier.height(10.dp))

        // Verse reference field
        Box(modifier = Modifier.fillMaxWidth()) {
            if (verseRef.isEmpty()) {
                Text(
                    text = "Reference (e.g. John 3:16)",
                    style = TextStyle(
                        fontFamily = Nunito,
                        fontSize = 14.sp,
                        color = FaithFeedColors.TextTertiary
                    )
                )
            }
            BasicTextField(
                value = verseRef,
                onValueChange = onVerseRefChange,
                modifier = Modifier.fillMaxWidth(),
                textStyle = TextStyle(
                    fontFamily = Nunito,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 14.sp,
                    color = FaithFeedColors.GoldHighlight
                ),
                cursorBrush = SolidColor(FaithFeedColors.GoldAccent),
                singleLine = true
            )
        }

        if (verseRef.isNotEmpty()) {
            Spacer(Modifier.height(8.dp))
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(1.dp)
                    .background(FaithFeedColors.GlassBorder)
            )
            Spacer(Modifier.height(8.dp))

            // Verse text field (optional manual entry)
            Box(modifier = Modifier.fillMaxWidth()) {
                if (verseText.isEmpty()) {
                    Text(
                        text = "Verse text (optional)",
                        style = TextStyle(
                            fontFamily = Nunito,
                            fontStyle = FontStyle.Italic,
                            fontSize = 13.sp,
                            color = FaithFeedColors.TextTertiary
                        )
                    )
                }
                BasicTextField(
                    value = verseText,
                    onValueChange = onVerseTextChange,
                    modifier = Modifier.fillMaxWidth(),
                    textStyle = TextStyle(
                        fontFamily = Nunito,
                        fontStyle = FontStyle.Italic,
                        fontSize = 13.sp,
                        color = FaithFeedColors.GoldAccent,
                        lineHeight = 20.sp
                    ),
                    cursorBrush = SolidColor(FaithFeedColors.GoldAccent),
                    minLines = 2
                )
            }
        }
    }
}

@Composable
private fun AudienceSelector(
    selected: String,
    onSelect: (String) -> Unit
) {
    Column(modifier = Modifier.fillMaxWidth()) {
        Text(
            text = "Audience",
            fontFamily = Cinzel,
            fontWeight = FontWeight.Medium,
            fontSize = 12.sp,
            color = FaithFeedColors.TextTertiary,
            letterSpacing = 0.8.sp
        )
        Spacer(Modifier.height(8.dp))
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            AUDIENCES.forEach { audience ->
                val isSelected = selected == audience
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .clip(RoundedCornerShape(20.dp))
                        .background(
                            if (isSelected) FaithFeedColors.GoldAccent.copy(alpha = 0.15f)
                            else FaithFeedColors.GlassBackground
                        )
                        .border(
                            width = 1.dp,
                            color = if (isSelected) FaithFeedColors.GoldAccent else FaithFeedColors.GlassBorder,
                            shape = RoundedCornerShape(20.dp)
                        )
                        .clickable { onSelect(audience) }
                        .padding(vertical = 9.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = AUDIENCE_LABELS[audience] ?: audience,
                        fontFamily = Nunito,
                        fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal,
                        fontSize = 13.sp,
                        color = if (isSelected) FaithFeedColors.GoldAccent else FaithFeedColors.TextSecondary
                    )
                }
            }
        }
    }
}

@Composable
private fun BottomToolbar(
    verseActive: Boolean,
    onToggleVerse: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(FaithFeedColors.BackgroundSecondary)
            .border(
                width = 1.dp,
                color = FaithFeedColors.GlassBorder,
                shape = RoundedCornerShape(topStart = 0.dp, topEnd = 0.dp)
            )
            .padding(horizontal = 8.dp, vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Image button (placeholder — not yet implemented)
        IconButton(onClick = { /* TODO: image picker */ }) {
            Icon(
                imageVector = Icons.Outlined.Image,
                contentDescription = "Add Image",
                tint = FaithFeedColors.TextTertiary,
                modifier = Modifier.size(22.dp)
            )
        }

        // Separator
        Box(
            modifier = Modifier
                .width(1.dp)
                .height(24.dp)
                .background(FaithFeedColors.GlassBorder)
        )

        // Verse toggle button
        IconButton(onClick = onToggleVerse) {
            Icon(
                imageVector = Icons.Outlined.AutoAwesome,
                contentDescription = "Attach Verse",
                tint = if (verseActive) FaithFeedColors.GoldAccent else FaithFeedColors.TextTertiary,
                modifier = Modifier.size(22.dp)
            )
        }

        Spacer(Modifier.weight(1f))

        // Character count hint
        Text(
            text = "Share your faith",
            fontFamily = Nunito,
            fontSize = 11.sp,
            color = FaithFeedColors.TextTertiary
        )

        Spacer(Modifier.width(8.dp))
    }
}
