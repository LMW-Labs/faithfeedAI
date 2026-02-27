package com.faithfeed.app.ui.screens.stories

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavController
import coil3.compose.AsyncImage
import com.faithfeed.app.ui.theme.FaithFeedColors
import com.faithfeed.app.ui.theme.Nunito
import com.faithfeed.app.ui.theme.Typography
import kotlinx.coroutines.delay

@Composable
fun StoryViewerScreen(
    userId: String,
    navController: NavController,
    viewModel: StoryViewerViewModel = hiltViewModel()
) {
    val stories by viewModel.stories.collectAsStateWithLifecycle()
    val currentIndex by viewModel.currentIndex.collectAsStateWithLifecycle()
    val isLoading by viewModel.isLoading.collectAsStateWithLifecycle()

    LaunchedEffect(userId) { viewModel.loadStoriesForUser(userId) }

    // Auto-advance every 5 seconds
    LaunchedEffect(currentIndex, stories.size) {
        if (stories.isNotEmpty()) {
            delay(5_000)
            if (viewModel.hasNext()) {
                viewModel.next()
            } else {
                navController.popBackStack()
            }
        }
    }

    val current = stories.getOrNull(currentIndex)

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black)
    ) {
        when {
            isLoading -> {
                CircularProgressIndicator(
                    color = FaithFeedColors.GoldAccent,
                    modifier = Modifier.align(Alignment.Center)
                )
            }
            current == null -> {
                navController.popBackStack()
            }
            else -> {
                // Story media
                AsyncImage(
                    model = current.mediaUrl,
                    contentDescription = "Story",
                    contentScale = ContentScale.Crop,
                    modifier = Modifier.fillMaxSize()
                )

                // Top gradient
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(140.dp)
                        .align(Alignment.TopCenter)
                        .background(
                            Brush.verticalGradient(
                                listOf(Color.Black.copy(alpha = 0.65f), Color.Transparent)
                            )
                        )
                )

                // Bottom gradient + caption
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .align(Alignment.BottomCenter)
                        .background(
                            Brush.verticalGradient(
                                listOf(Color.Transparent, Color.Black.copy(alpha = 0.7f))
                            )
                        )
                        .padding(horizontal = 16.dp, vertical = 24.dp)
                ) {
                    if (!current.caption.isNullOrBlank()) {
                        Text(
                            text = current.caption,
                            color = Color.White,
                            style = Typography.bodyMedium,
                            fontFamily = Nunito
                        )
                    }
                }

                // Progress bars
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .statusBarsPadding()
                        .padding(horizontal = 8.dp, vertical = 8.dp)
                        .align(Alignment.TopStart),
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    stories.forEachIndexed { i, _ ->
                        val progress = when {
                            i < currentIndex -> 1f
                            i == currentIndex -> 0.5f
                            else -> 0f
                        }
                        LinearProgressIndicator(
                            progress = { progress },
                            modifier = Modifier
                                .weight(1f)
                                .height(2.dp)
                                .clip(RoundedCornerShape(1.dp)),
                            color = Color.White,
                            trackColor = Color.White.copy(alpha = 0.35f)
                        )
                    }
                }

                // Author info + close button
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .statusBarsPadding()
                        .padding(horizontal = 12.dp)
                        .padding(top = 20.dp)
                        .align(Alignment.TopStart),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    AsyncImage(
                        model = current.author?.avatarUrl,
                        contentDescription = null,
                        contentScale = ContentScale.Crop,
                        modifier = Modifier
                            .size(36.dp)
                            .clip(CircleShape)
                            .background(FaithFeedColors.GlassBackground)
                    )
                    Spacer(Modifier.width(8.dp))
                    Column {
                        Text(
                            text = current.author?.displayName ?: "User",
                            color = Color.White,
                            fontWeight = FontWeight.Bold,
                            fontSize = 14.sp
                        )
                        Text(
                            text = current.createdAt.take(10),
                            color = Color.White.copy(alpha = 0.7f),
                            fontSize = 11.sp
                        )
                    }
                    Spacer(Modifier.weight(1f))
                    IconButton(onClick = { navController.popBackStack() }) {
                        Icon(
                            imageVector = Icons.Default.Close,
                            contentDescription = "Close",
                            tint = Color.White
                        )
                    }
                }

                // Tap zones: left = previous, right = next
                Row(modifier = Modifier.fillMaxSize()) {
                    Box(
                        modifier = Modifier
                            .weight(1f)
                            .fillMaxHeight()
                            .clickable(
                                indication = null,
                                interactionSource = remember { MutableInteractionSource() }
                            ) { viewModel.previous() }
                    )
                    Box(
                        modifier = Modifier
                            .weight(1f)
                            .fillMaxHeight()
                            .clickable(
                                indication = null,
                                interactionSource = remember { MutableInteractionSource() }
                            ) {
                                if (viewModel.hasNext()) viewModel.next()
                                else navController.popBackStack()
                            }
                    )
                }
            }
        }
    }
}
