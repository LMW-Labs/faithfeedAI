package com.faithfeed.app.ui.screens.post

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Send
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavController
import coil3.compose.AsyncImage
import com.faithfeed.app.data.model.Comment
import com.faithfeed.app.ui.components.SimpleTopBar
import com.faithfeed.app.ui.screens.home.PostCard
import com.faithfeed.app.ui.theme.FaithFeedColors
import com.faithfeed.app.ui.theme.Nunito
import com.faithfeed.app.ui.theme.Typography

@Composable
fun PostDetailScreen(
    postId: String,
    navController: NavController,
    viewModel: PostDetailViewModel = hiltViewModel()
) {
    LaunchedEffect(postId) { viewModel.loadPost(postId) }

    val uiState by viewModel.uiState.collectAsStateWithLifecycle()

    Scaffold(
        containerColor = FaithFeedColors.BackgroundPrimary,
        topBar = {
            SimpleTopBar(title = "Post", onBack = { navController.popBackStack() })
        },
        bottomBar = {
            CommentInputBar(
                text = uiState.commentText,
                onTextChange = viewModel::onCommentTextChange,
                onSend = viewModel::submitComment,
                isSending = uiState.isCommenting
            )
        }
    ) { paddingValues ->
        if (uiState.isLoading && uiState.post == null) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator(color = FaithFeedColors.GoldAccent)
            }
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues),
                contentPadding = PaddingValues(bottom = 8.dp)
            ) {
                // Full post card
                uiState.post?.let { post ->
                    item(key = "post_${post.id}") {
                        PostCard(
                            post = post,
                            onUserClick = { navController.navigate(
                                com.faithfeed.app.navigation.Route.UserProfile(post.userId)
                            ) },
                            onPostClick = {},
                            onLikeClick = { viewModel.likePost(post.id) },
                            onPrayClick = { viewModel.prayPost(post.id) },
                            onCommentClick = {}
                        )
                    }
                }

                // Comments section header
                item(key = "comments_header") {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp, vertical = 12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        HorizontalDivider(
                            modifier = Modifier.weight(1f),
                            color = FaithFeedColors.GlassBorder
                        )
                        Text(
                            text = "  Comments (${uiState.comments.size})  ",
                            style = Typography.labelMedium.copy(fontWeight = FontWeight.SemiBold),
                            color = FaithFeedColors.GoldAccent
                        )
                        HorizontalDivider(
                            modifier = Modifier.weight(1f),
                            color = FaithFeedColors.GlassBorder
                        )
                    }
                }

                // Empty state
                if (uiState.comments.isEmpty() && !uiState.isLoading) {
                    item(key = "empty_comments") {
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 32.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = "Be the first to comment",
                                style = Typography.bodyMedium,
                                color = FaithFeedColors.TextTertiary
                            )
                        }
                    }
                }

                // Comment rows
                items(uiState.comments, key = { it.id.ifBlank { it.createdAt } }) { comment ->
                    CommentRow(comment = comment)
                }
            }
        }
    }
}

@Composable
private fun CommentRow(comment: Comment) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        verticalAlignment = Alignment.Top
    ) {
        // Avatar
        AsyncImage(
            model = comment.author?.avatarUrl,
            contentDescription = "Avatar",
            contentScale = ContentScale.Crop,
            modifier = Modifier
                .size(36.dp)
                .clip(CircleShape)
                .background(FaithFeedColors.GlassBackground)
                .border(1.dp, FaithFeedColors.GlassBorder, CircleShape)
        )

        Spacer(modifier = Modifier.width(12.dp))

        Column(modifier = Modifier.weight(1f)) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Text(
                    text = comment.author?.displayName ?: comment.author?.username ?: "Unknown",
                    style = Typography.labelMedium.copy(fontWeight = FontWeight.Bold),
                    color = FaithFeedColors.TextPrimary
                )
                Text(
                    text = comment.createdAt.take(10),
                    style = Typography.labelSmall,
                    color = FaithFeedColors.TextTertiary
                )
            }
            Spacer(modifier = Modifier.height(2.dp))
            Text(
                text = comment.content,
                style = Typography.bodyMedium,
                color = FaithFeedColors.TextSecondary,
                fontFamily = Nunito,
                lineHeight = 20.sp
            )
        }
    }
}

@Composable
private fun CommentInputBar(
    text: String,
    onTextChange: (String) -> Unit,
    onSend: () -> Unit,
    isSending: Boolean
) {
    Surface(
        color = FaithFeedColors.BackgroundSecondary,
        tonalElevation = 0.dp,
        modifier = Modifier
            .fillMaxWidth()
            .border(
                width = 1.dp,
                color = FaithFeedColors.GlassBorder,
                shape = RoundedCornerShape(topStart = 0.dp, topEnd = 0.dp)
            )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .navigationBarsPadding()
                .padding(horizontal = 12.dp, vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            TextField(
                value = text,
                onValueChange = onTextChange,
                placeholder = {
                    Text(
                        "Add a comment...",
                        style = Typography.bodyMedium,
                        color = FaithFeedColors.TextTertiary
                    )
                },
                modifier = Modifier.weight(1f),
                colors = TextFieldDefaults.colors(
                    focusedContainerColor = FaithFeedColors.GlassBackground,
                    unfocusedContainerColor = FaithFeedColors.GlassBackground,
                    focusedTextColor = FaithFeedColors.TextPrimary,
                    unfocusedTextColor = FaithFeedColors.TextPrimary,
                    focusedIndicatorColor = androidx.compose.ui.graphics.Color.Transparent,
                    unfocusedIndicatorColor = androidx.compose.ui.graphics.Color.Transparent,
                    cursorColor = FaithFeedColors.GoldAccent
                ),
                shape = RoundedCornerShape(24.dp),
                textStyle = Typography.bodyMedium.copy(fontFamily = Nunito),
                singleLine = false,
                maxLines = 4
            )

            Spacer(modifier = Modifier.width(8.dp))

            val sendEnabled = text.isNotBlank() && !isSending
            IconButton(
                onClick = onSend,
                enabled = sendEnabled,
                modifier = Modifier
                    .size(44.dp)
                    .clip(CircleShape)
                    .background(
                        if (sendEnabled) FaithFeedColors.GoldAccent
                        else FaithFeedColors.GlassBackground
                    )
            ) {
                if (isSending) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(20.dp),
                        strokeWidth = 2.dp,
                        color = FaithFeedColors.BackgroundPrimary
                    )
                } else {
                    Icon(
                        imageVector = Icons.Outlined.Send,
                        contentDescription = "Send",
                        tint = if (sendEnabled) FaithFeedColors.BackgroundPrimary
                        else FaithFeedColors.TextTertiary,
                        modifier = Modifier.size(20.dp)
                    )
                }
            }
        }
    }
}
