package com.faithfeed.app.ui.screens.home

import android.content.Intent
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.outlined.ChatBubbleOutline
import androidx.compose.material.icons.outlined.FavoriteBorder
import androidx.compose.material.icons.outlined.Share
import androidx.compose.material.icons.outlined.VolunteerActivism
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavController
import androidx.paging.LoadState
import androidx.paging.compose.collectAsLazyPagingItems
import coil3.compose.AsyncImage
import com.faithfeed.app.data.model.DailyVerse
import com.faithfeed.app.data.model.Post
import com.faithfeed.app.data.model.Story
import com.faithfeed.app.navigation.Route
import com.faithfeed.app.ui.components.FaithFeedTopBar
import com.faithfeed.app.ui.theme.FaithFeedColors
import com.faithfeed.app.ui.theme.Nunito
import com.faithfeed.app.ui.theme.Typography

@Composable
fun HomeScreen(
    navController: NavController,
    viewModel: HomeViewModel = hiltViewModel()
) {
    val stories by viewModel.stories.collectAsStateWithLifecycle()
    val dailyVerse by viewModel.dailyVerse.collectAsStateWithLifecycle()
    val feedItems = viewModel.feedPager.collectAsLazyPagingItems()
    val currentUserId by viewModel.currentUserId.collectAsStateWithLifecycle()

    Scaffold(
        containerColor = FaithFeedColors.BackgroundPrimary,
        topBar = {
            FaithFeedTopBar(
                onSearchClick = { navController.navigate(Route.SemanticSearch) },
                onNotificationsClick = { navController.navigate(Route.Notifications) },
                onProfileClick = {
                    if (currentUserId.isNotBlank()) {
                        navController.navigate(Route.MyProfile(currentUserId))
                    }
                },
                onCreatePost = { navController.navigate(Route.CreatePost) },
                onCreateStory = { navController.navigate(Route.CreateStory) },
                onCreateListing = { navController.navigate(Route.CreateListing) },
                onCreatePrayer = { navController.navigate(Route.CreatePrayer) }
            )
        }
    ) { paddingValues ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues),
            contentPadding = PaddingValues(bottom = 80.dp)
        ) {
            // Stories Row — always shown; includes "Add Story" button as first item
            item {
                StoriesRow(
                    stories = stories,
                    onStoryClick = { story -> navController.navigate(Route.StoryViewer(story.userId)) },
                    onAddStoryClick = { navController.navigate(Route.CreateStory) }
                )
            }

            // Daily verse card — sits between stories and the feed
            if (dailyVerse != null) {
                item {
                    DailyVerseCard(
                        dailyVerse = dailyVerse!!,
                        modifier = Modifier.padding(horizontal = 16.dp, vertical = 4.dp)
                    )
                }
            }

            // Paging feed
            items(feedItems.itemCount) { index ->
                val post = feedItems[index]
                if (post != null) {
                    PostCard(
                        post = post,
                        onUserClick = { navController.navigate(Route.UserProfile(post.userId)) },
                        onPostClick = { navController.navigate(Route.PostDetail(post.id)) },
                        onLikeClick = { viewModel.likePost(post.id) },
                        onPrayClick = { viewModel.prayPost(post.id) },
                        onCommentClick = { navController.navigate(Route.PostDetail(post.id)) },
                        onShareClick = { viewModel.sharePost(post.id) }
                    )
                }
            }

            // Loading and error states
            feedItems.apply {
                when {
                    loadState.refresh is LoadState.Loading -> {
                        item {
                            Box(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(32.dp),
                                contentAlignment = Alignment.Center
                            ) {
                                CircularProgressIndicator(color = FaithFeedColors.GoldAccent)
                            }
                        }
                    }
                    loadState.append is LoadState.Loading -> {
                        item {
                            Box(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(16.dp),
                                contentAlignment = Alignment.Center
                            ) {
                                CircularProgressIndicator(
                                    color = FaithFeedColors.GoldAccent,
                                    modifier = Modifier.size(24.dp)
                                )
                            }
                        }
                    }
                    loadState.refresh is LoadState.Error -> {
                        item {
                            Box(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(32.dp),
                                contentAlignment = Alignment.Center
                            ) {
                                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                    Text(
                                        "Could not load feed",
                                        style = Typography.bodyMedium,
                                        color = FaithFeedColors.TextTertiary
                                    )
                                    Spacer(Modifier.height(8.dp))
                                    TextButton(onClick = { feedItems.retry() }) {
                                        Text("Retry", color = FaithFeedColors.GoldAccent)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun DailyVerseCard(dailyVerse: DailyVerse, modifier: Modifier = Modifier) {
    Surface(
        color = FaithFeedColors.PurpleDark.copy(alpha = 0.6f),
        shape = RoundedCornerShape(16.dp),
        modifier = modifier
            .fillMaxWidth()
            .border(1.dp, FaithFeedColors.GoldAccent.copy(alpha = 0.3f), RoundedCornerShape(16.dp))
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                text = "Today's Verse",
                style = Typography.labelSmall,
                color = FaithFeedColors.GoldAccent
            )
            Spacer(Modifier.height(8.dp))
            Text(
                text = "\"${dailyVerse.text}\"",
                style = Typography.bodyMedium.copy(fontStyle = FontStyle.Italic, lineHeight = 22.sp),
                color = FaithFeedColors.TextPrimary,
                fontFamily = Nunito
            )
            Spacer(Modifier.height(8.dp))
            Text(
                text = "— ${dailyVerse.reference}",
                style = Typography.labelMedium.copy(fontWeight = FontWeight.Bold),
                color = FaithFeedColors.GoldAccent
            )
            if (dailyVerse.reflection != null) {
                Spacer(Modifier.height(8.dp))
                Text(
                    text = dailyVerse.reflection,
                    style = Typography.bodySmall,
                    color = FaithFeedColors.TextSecondary
                )
            }
        }
    }
}

@Composable
fun StoriesRow(
    stories: List<Story>,
    onStoryClick: (Story) -> Unit,
    onAddStoryClick: () -> Unit = {}
) {
    LazyRow(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 12.dp),
        contentPadding = PaddingValues(horizontal = 16.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        // Always-visible "Add Story" button
        item {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier
                    .width(72.dp)
                    .clickable { onAddStoryClick() }
            ) {
                Box(
                    modifier = Modifier
                        .size(64.dp)
                        .clip(CircleShape)
                        .border(2.dp, FaithFeedColors.GoldAccent.copy(alpha = 0.5f), CircleShape)
                        .background(FaithFeedColors.GlassBackground),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = "+",
                        fontSize = 28.sp,
                        color = FaithFeedColors.GoldAccent,
                        fontWeight = androidx.compose.ui.text.font.FontWeight.Light
                    )
                }
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = "Your Story",
                    style = Typography.labelSmall,
                    color = FaithFeedColors.TextSecondary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }
        }

        items(stories, key = { it.id }) { story ->
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier
                    .width(72.dp)
                    .clickable { onStoryClick(story) }
            ) {
                Box(
                    modifier = Modifier
                        .size(64.dp)
                        .clip(CircleShape)
                        .border(2.dp, FaithFeedColors.GoldAccent, CircleShape)
                        .padding(4.dp)
                ) {
                    AsyncImage(
                        model = story.author?.avatarUrl ?: story.mediaUrl,
                        contentDescription = "Story from ${story.author?.displayName}",
                        contentScale = ContentScale.Crop,
                        modifier = Modifier
                            .fillMaxSize()
                            .clip(CircleShape)
                            .background(FaithFeedColors.GlassBackground)
                    )
                }
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = story.author?.displayName?.split(" ")?.first() ?: "User",
                    style = Typography.labelSmall,
                    color = FaithFeedColors.TextSecondary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }
        }
    }
}

@Composable
fun PostCard(
    post: Post,
    onUserClick: () -> Unit,
    onPostClick: () -> Unit,
    onLikeClick: () -> Unit = {},
    onPrayClick: () -> Unit = {},
    onCommentClick: () -> Unit = {},
    onShareClick: () -> Unit = {}
) {
    val context = LocalContext.current
    // Local optimistic state for immediate UI feedback before server round-trip
    var likeCount by remember(post.id) { mutableIntStateOf(post.likeCount) }
    var prayCount by remember(post.id) { mutableIntStateOf(post.prayerCount) }
    var isLiked by remember(post.id) { mutableStateOf(post.isLiked) }

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp)
            .clickable { onPostClick() },
        colors = CardDefaults.cardColors(containerColor = FaithFeedColors.BackgroundSecondary),
        shape = RoundedCornerShape(12.dp)
    ) {
        Column(modifier = Modifier.fillMaxWidth().padding(16.dp)) {
            // Header
            Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.fillMaxWidth()) {
                AsyncImage(
                    model = post.author?.avatarUrl,
                    contentDescription = "Avatar",
                    contentScale = ContentScale.Crop,
                    modifier = Modifier
                        .size(40.dp)
                        .clip(CircleShape)
                        .background(FaithFeedColors.GlassBackground)
                        .clickable { onUserClick() }
                )
                Spacer(modifier = Modifier.width(12.dp))
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = post.author?.displayName ?: "Unknown User",
                        style = Typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                        color = FaithFeedColors.TextPrimary,
                        modifier = Modifier.clickable { onUserClick() }
                    )
                    Text(
                        text = post.createdAt.take(10),
                        style = Typography.bodySmall,
                        color = FaithFeedColors.TextTertiary
                    )
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Body
            if (post.content.isNotEmpty()) {
                Text(
                    text = post.content,
                    style = Typography.bodyLarge,
                    color = FaithFeedColors.TextPrimary,
                    fontFamily = Nunito
                )
                Spacer(modifier = Modifier.height(12.dp))
            }

            // Verse Attachment
            if (post.verseRef != null && post.verseText != null) {
                Surface(
                    color = FaithFeedColors.GlassBackground,
                    shape = RoundedCornerShape(8.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(
                        modifier = Modifier
                            .padding(12.dp)
                            .border(1.dp, FaithFeedColors.GlassBorder, RoundedCornerShape(8.dp))
                            .padding(12.dp)
                    ) {
                        Text(
                            text = post.verseRef,
                            style = Typography.labelLarge.copy(fontWeight = FontWeight.Bold),
                            color = FaithFeedColors.GoldAccent
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = "\"${post.verseText}\"",
                            style = Typography.bodyMedium.copy(fontStyle = FontStyle.Italic),
                            color = FaithFeedColors.TextSecondary
                        )
                    }
                }
                Spacer(modifier = Modifier.height(12.dp))
            }

            // Image Attachment
            if (post.mediaUrls.isNotEmpty()) {
                AsyncImage(
                    model = post.mediaUrls.first(),
                    contentDescription = "Post Image",
                    contentScale = ContentScale.Crop,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(200.dp)
                        .clip(RoundedCornerShape(8.dp))
                        .background(FaithFeedColors.GlassBackground)
                )
                Spacer(modifier = Modifier.height(12.dp))
            }

            HorizontalDivider(color = FaithFeedColors.GlassBorder)
            Spacer(modifier = Modifier.height(8.dp))

            // Action Row
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                PostActionButton(
                    icon = if (isLiked) Icons.Filled.Favorite else Icons.Outlined.FavoriteBorder,
                    label = likeCount.toString(),
                    tint = if (isLiked) FaithFeedColors.GoldHighlight else FaithFeedColors.TextSecondary,
                    onClick = {
                        isLiked = !isLiked
                        likeCount += if (isLiked) 1 else -1
                        onLikeClick()
                    }
                )
                PostActionButton(
                    icon = Icons.Outlined.ChatBubbleOutline,
                    label = post.commentCount.toString(),
                    onClick = onCommentClick
                )
                PostActionButton(
                    icon = Icons.Outlined.VolunteerActivism,
                    label = prayCount.toString(),
                    tint = FaithFeedColors.GoldAccent,
                    onClick = {
                        prayCount += 1
                        onPrayClick()
                    }
                )
                PostActionButton(
                    icon = Icons.Outlined.Share,
                    label = "",
                    onClick = {
                        val text = buildString {
                            append(post.content)
                            if (post.verseRef != null) append("\n\n${post.verseRef}")
                            append("\n\nShared from FaithFeed — Where Scripture Meets Scroll")
                        }
                        context.startActivity(
                            Intent.createChooser(
                                Intent(Intent.ACTION_SEND).apply {
                                    type = "text/plain"
                                    putExtra(Intent.EXTRA_TEXT, text)
                                },
                                "Share via"
                            )
                        )
                        onShareClick()
                    }
                )
            }
        }
    }
}

@Composable
fun PostActionButton(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    label: String,
    tint: Color = FaithFeedColors.TextSecondary,
    onClick: () -> Unit
) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier
            .clickable { onClick() }
            .padding(8.dp)
    ) {
        Icon(icon, contentDescription = null, tint = tint, modifier = Modifier.size(20.dp))
        if (label.isNotEmpty()) {
            Spacer(modifier = Modifier.width(6.dp))
            Text(text = label, style = Typography.labelMedium, color = tint)
        }
    }
}
