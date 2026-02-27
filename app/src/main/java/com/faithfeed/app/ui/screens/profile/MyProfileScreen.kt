package com.faithfeed.app.ui.screens.profile

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Language
import androidx.compose.material.icons.outlined.LocationOn
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material.icons.outlined.VerifiedUser
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.VerticalDivider
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavController
import coil3.compose.AsyncImage
import com.faithfeed.app.data.model.Post
import com.faithfeed.app.data.model.User
import com.faithfeed.app.navigation.Route
import com.faithfeed.app.ui.components.ButtonStyle
import com.faithfeed.app.ui.components.FaithFeedButton
import com.faithfeed.app.ui.theme.Cinzel
import com.faithfeed.app.ui.theme.FaithFeedColors
import com.faithfeed.app.ui.theme.Nunito
import com.faithfeed.app.ui.theme.Typography

@Composable
fun MyProfileScreen(
    userId: String,
    navController: NavController,
    viewModel: ProfileViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()

    LaunchedEffect(userId) { viewModel.loadProfile(userId) }

    Scaffold(
        containerColor = FaithFeedColors.BackgroundPrimary,
        topBar = {
            ProfileTopBar(
                title = "My Profile",
                onBack = null,
                action = {
                    IconButton(onClick = { navController.navigate(Route.AccountSettings) }) {
                        Icon(
                            imageVector = Icons.Outlined.Settings,
                            contentDescription = "Account Settings",
                            tint = FaithFeedColors.TextSecondary,
                            modifier = Modifier.size(22.dp)
                        )
                    }
                }
            )
        }
    ) { padding ->
        if (uiState.isLoading) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator(color = FaithFeedColors.GoldAccent)
            }
            return@Scaffold
        }

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
        ) {
            uiState.user?.let { user ->
                ProfileHeader(user = user)

                Spacer(Modifier.height(16.dp))

                // Stats row
                ProfileStatsRow(user = user)

                Spacer(Modifier.height(20.dp))

                // Action buttons
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp),
                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    FaithFeedButton(
                        text = "Edit Profile",
                        onClick = { navController.navigate(Route.EditProfile) },
                        style = ButtonStyle.Secondary,
                        modifier = Modifier.weight(1f)
                    )
                    FaithFeedButton(
                        text = "Profile Settings",
                        onClick = { navController.navigate(Route.ProfileSettings) },
                        style = ButtonStyle.Ghost,
                        modifier = Modifier.weight(1f)
                    )
                }
            }

            Spacer(Modifier.height(24.dp))

            // Posts section
            PostsSection(
                posts = uiState.posts,
                isLoading = uiState.isLoadingPosts
            )

            Spacer(Modifier.height(32.dp))
        }
    }
}

// ── Shared: ProfileHeader ─────────────────────────────────────────────────────

@Composable
internal fun ProfileHeader(user: User, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 20.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Avatar
        Box(
            modifier = Modifier
                .size(96.dp)
                .clip(CircleShape)
                .border(2.dp, FaithFeedColors.GoldAccent, CircleShape)
                .background(FaithFeedColors.BackgroundSecondary),
            contentAlignment = Alignment.Center
        ) {
            if (!user.avatarUrl.isNullOrBlank()) {
                AsyncImage(
                    model = user.avatarUrl,
                    contentDescription = "Profile picture",
                    modifier = Modifier
                        .fillMaxSize()
                        .clip(CircleShape),
                    contentScale = ContentScale.Crop
                )
            } else {
                val initials = user.displayName
                    .split(" ")
                    .take(2)
                    .joinToString("") { it.take(1).uppercase() }
                    .ifBlank { user.username.take(1).uppercase() }
                Text(
                    text = initials,
                    fontFamily = Cinzel,
                    fontWeight = FontWeight.Bold,
                    fontSize = 28.sp,
                    color = FaithFeedColors.GoldAccent
                )
            }
        }

        Spacer(Modifier.height(12.dp))

        // Display name + verified badge
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            Text(
                text = user.displayName.ifBlank { user.username },
                style = Typography.titleLarge,
                color = FaithFeedColors.TextPrimary,
                fontFamily = Cinzel,
                fontWeight = FontWeight.SemiBold,
                textAlign = TextAlign.Center
            )
            if (user.isVerified) {
                Icon(
                    imageVector = Icons.Outlined.VerifiedUser,
                    contentDescription = "Verified",
                    tint = FaithFeedColors.GoldAccent,
                    modifier = Modifier.size(18.dp)
                )
            }
        }

        Spacer(Modifier.height(2.dp))

        // Username
        Text(
            text = "@${user.username}",
            style = Typography.bodyMedium,
            color = FaithFeedColors.TextSecondary,
            fontSize = 13.sp
        )

        // Bio
        if (!user.bio.isNullOrBlank()) {
            Spacer(Modifier.height(10.dp))
            Text(
                text = user.bio,
                style = Typography.bodyMedium,
                color = FaithFeedColors.TextSecondary,
                textAlign = TextAlign.Center,
                maxLines = 4,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.padding(horizontal = 8.dp)
            )
        }

        // Location + Website chips
        val hasChips = !user.location.isNullOrBlank() || !user.website.isNullOrBlank()
        if (hasChips) {
            Spacer(Modifier.height(10.dp))
            Row(
                horizontalArrangement = Arrangement.spacedBy(10.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                if (!user.location.isNullOrBlank()) {
                    ProfileChip(
                        icon = { Icon(Icons.Outlined.LocationOn, null, tint = FaithFeedColors.GoldAccent, modifier = Modifier.size(13.dp)) },
                        label = user.location
                    )
                }
                if (!user.website.isNullOrBlank()) {
                    ProfileChip(
                        icon = { Icon(Icons.Outlined.Language, null, tint = FaithFeedColors.GoldAccent, modifier = Modifier.size(13.dp)) },
                        label = user.website.removePrefix("https://").removePrefix("http://").trimEnd('/')
                    )
                }
            }
        }
    }
}

@Composable
private fun ProfileChip(icon: @Composable () -> Unit, label: String) {
    Surface(
        shape = RoundedCornerShape(20.dp),
        color = FaithFeedColors.BackgroundSecondary,
        border = androidx.compose.foundation.BorderStroke(1.dp, FaithFeedColors.GlassBorder)
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 10.dp, vertical = 5.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            icon()
            Text(
                text = label,
                fontFamily = Nunito,
                fontSize = 12.sp,
                color = FaithFeedColors.TextTertiary,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }
    }
}

// ── Shared: ProfileStatsRow ───────────────────────────────────────────────────

@Composable
internal fun ProfileStatsRow(user: User, modifier: Modifier = Modifier) {
    Surface(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp),
        color = FaithFeedColors.BackgroundSecondary,
        shape = RoundedCornerShape(16.dp),
        border = androidx.compose.foundation.BorderStroke(1.dp, FaithFeedColors.GlassBorder)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 16.dp),
            horizontalArrangement = Arrangement.SpaceEvenly,
            verticalAlignment = Alignment.CenterVertically
        ) {
            StatColumn(value = user.postCount.toString(), label = "Posts")
            VerticalDivider(
                modifier = Modifier.height(32.dp),
                color = FaithFeedColors.GlassBorder,
                thickness = 1.dp
            )
            StatColumn(value = user.followerCount.formatCompact(), label = "Friends")
            VerticalDivider(
                modifier = Modifier.height(32.dp),
                color = FaithFeedColors.GlassBorder,
                thickness = 1.dp
            )
            StatColumn(value = user.followingCount.formatCompact(), label = "Following")
        }
    }
}

@Composable
private fun StatColumn(value: String, label: String) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(
            text = value,
            fontFamily = Cinzel,
            fontWeight = FontWeight.Bold,
            fontSize = 20.sp,
            color = FaithFeedColors.TextPrimary
        )
        Spacer(Modifier.height(2.dp))
        Text(
            text = label,
            fontFamily = Nunito,
            fontSize = 12.sp,
            color = FaithFeedColors.TextTertiary
        )
    }
}

private fun Int.formatCompact(): String = when {
    this >= 1_000_000 -> "${this / 1_000_000}M"
    this >= 1_000 -> "${this / 1_000}K"
    else -> toString()
}

// ── Shared: PostsSection ──────────────────────────────────────────────────────

@Composable
internal fun PostsSection(posts: List<Post>, isLoading: Boolean) {
    Column(modifier = Modifier.fillMaxWidth()) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 4.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text(
                text = "Posts",
                fontFamily = Cinzel,
                fontWeight = FontWeight.SemiBold,
                fontSize = 16.sp,
                color = FaithFeedColors.TextPrimary
            )
            Text(
                text = posts.size.toString(),
                fontFamily = Nunito,
                fontSize = 13.sp,
                color = FaithFeedColors.TextTertiary
            )
        }

        HorizontalDivider(
            color = FaithFeedColors.GlassBorder,
            thickness = 0.5.dp,
            modifier = Modifier.padding(horizontal = 16.dp)
        )

        Spacer(Modifier.height(8.dp))

        if (isLoading) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(80.dp),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator(
                    color = FaithFeedColors.GoldAccent,
                    modifier = Modifier.size(24.dp),
                    strokeWidth = 2.dp
                )
            }
        } else if (posts.isEmpty()) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 32.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "No posts yet",
                    fontFamily = Nunito,
                    fontSize = 14.sp,
                    color = FaithFeedColors.TextTertiary
                )
            }
        } else {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                posts.forEach { post ->
                    PostSummaryCard(post = post)
                }
            }
        }
    }
}

@Composable
internal fun PostSummaryCard(post: Post) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        color = FaithFeedColors.BackgroundSecondary,
        shape = RoundedCornerShape(14.dp),
        border = androidx.compose.foundation.BorderStroke(1.dp, FaithFeedColors.GlassBorder)
    ) {
        Column(modifier = Modifier.padding(14.dp)) {
            // Verse ref if present
            if (!post.verseRef.isNullOrBlank()) {
                Text(
                    text = post.verseRef,
                    fontFamily = Cinzel,
                    fontSize = 11.sp,
                    color = FaithFeedColors.GoldAccent,
                    fontWeight = FontWeight.Medium
                )
                Spacer(Modifier.height(4.dp))
            }

            // Content
            Text(
                text = post.content,
                style = Typography.bodyMedium,
                color = FaithFeedColors.TextPrimary,
                maxLines = 4,
                overflow = TextOverflow.Ellipsis
            )

            Spacer(Modifier.height(10.dp))

            // Engagement row
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                PostStat(emoji = "♥", count = post.likeCount)
                PostStat(emoji = "🙏", count = post.prayerCount)
                PostStat(emoji = "💬", count = post.commentCount)
                Spacer(Modifier.weight(1f))
                Text(
                    text = post.createdAt.take(10),
                    fontFamily = Nunito,
                    fontSize = 11.sp,
                    color = FaithFeedColors.TextTertiary
                )
            }
        }
    }
}

@Composable
private fun PostStat(emoji: String, count: Int) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(3.dp)
    ) {
        Text(text = emoji, fontSize = 12.sp)
        Text(
            text = count.toString(),
            fontFamily = Nunito,
            fontSize = 12.sp,
            color = FaithFeedColors.TextTertiary
        )
    }
}

// ── ProfileTopBar ─────────────────────────────────────────────────────────────

@Composable
private fun ProfileTopBar(
    title: String,
    onBack: (() -> Unit)?,
    action: (@Composable () -> Unit)? = null
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(FaithFeedColors.BackgroundPrimary)
            .padding(horizontal = 4.dp)
            .height(56.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        if (onBack != null) {
            IconButton(onClick = onBack) {
                Text("←", color = FaithFeedColors.GoldAccent, fontSize = 20.sp)
            }
        } else {
            Spacer(Modifier.width(12.dp))
        }

        Text(
            text = title,
            fontFamily = Cinzel,
            fontWeight = FontWeight.SemiBold,
            fontSize = 18.sp,
            color = FaithFeedColors.TextPrimary,
            modifier = Modifier.weight(1f)
        )

        action?.invoke() ?: Spacer(Modifier.width(48.dp))
    }
}
