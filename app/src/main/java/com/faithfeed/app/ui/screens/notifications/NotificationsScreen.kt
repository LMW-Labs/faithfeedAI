package com.faithfeed.app.ui.screens.notifications

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Notifications
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import coil3.compose.AsyncImage
import com.faithfeed.app.data.model.Notification
import com.faithfeed.app.ui.components.EmptyState
import com.faithfeed.app.ui.theme.Cinzel
import com.faithfeed.app.ui.theme.FaithFeedColors
import com.faithfeed.app.ui.theme.Nunito

@Composable
fun NotificationsScreen(
    navController: NavController,
    viewModel: NotificationsViewModel = hiltViewModel()
) {
    val notifications by viewModel.notifications.collectAsState()
    val unreadCount by viewModel.unreadCount.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(FaithFeedColors.BackgroundPrimary)
    ) {
        NotificationsTopBar(
            unreadCount = unreadCount,
            onBack = { navController.popBackStack() },
            onMarkAllRead = { viewModel.markAllRead() }
        )

        if (notifications.isEmpty()) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                EmptyState(
                    icon = Icons.Outlined.Notifications,
                    title = "No notifications yet",
                    subtitle = "Likes, comments, and friend requests will appear here"
                )
            }
        } else {
            LazyColumn(modifier = Modifier.fillMaxSize()) {
                items(notifications, key = { it.id }) { notification ->
                    NotificationRow(notification = notification)
                }
            }
        }
    }
}

@Composable
private fun NotificationsTopBar(
    unreadCount: Int,
    onBack: () -> Unit,
    onMarkAllRead: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(FaithFeedColors.BackgroundPrimary)
            .statusBarsPadding()
            .padding(horizontal = 16.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .size(40.dp)
                .clip(RoundedCornerShape(12.dp))
                .background(FaithFeedColors.GlassBackground)
                .clickable(
                    onClick = onBack,
                    indication = null,
                    interactionSource = remember { MutableInteractionSource() }
                ),
            contentAlignment = Alignment.Center
        ) {
            Text("←", color = FaithFeedColors.GoldAccent, fontSize = 18.sp)
        }

        Spacer(Modifier.width(12.dp))

        Text(
            text = "Notifications",
            fontFamily = Cinzel,
            fontWeight = FontWeight.SemiBold,
            fontSize = 18.sp,
            color = FaithFeedColors.TextPrimary,
            modifier = Modifier.weight(1f)
        )

        if (unreadCount > 0) {
            TextButton(onClick = onMarkAllRead) {
                Text(
                    text = "Mark all read",
                    fontFamily = Nunito,
                    fontSize = 13.sp,
                    color = FaithFeedColors.GoldAccent
                )
            }
        }
    }
}

@Composable
private fun NotificationRow(notification: Notification) {
    val isUnread = !notification.isRead
    val goldColor = FaithFeedColors.GoldAccent

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(
                if (isUnread) FaithFeedColors.BackgroundSecondary
                else FaithFeedColors.BackgroundPrimary
            )
            .then(
                if (isUnread) Modifier.drawBehind {
                    // 2dp gold stripe on the leading edge
                    val strokePx = 2.dp.toPx()
                    drawLine(
                        color = goldColor,
                        start = Offset(strokePx / 2f, 0f),
                        end = Offset(strokePx / 2f, size.height),
                        strokeWidth = strokePx
                    )
                } else Modifier
            )
            .padding(start = if (isUnread) 18.dp else 16.dp, end = 16.dp, top = 12.dp, bottom = 12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        ActorAvatar(avatarUrl = notification.actor?.avatarUrl, size = 36.dp)

        Spacer(Modifier.width(12.dp))

        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = notificationText(notification),
                fontFamily = Nunito,
                fontSize = 14.sp,
                fontWeight = if (isUnread) FontWeight.SemiBold else FontWeight.Normal,
                color = if (isUnread) FaithFeedColors.TextPrimary else FaithFeedColors.TextSecondary,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )
            Text(
                text = relativeTime(notification.createdAt),
                fontFamily = Nunito,
                fontSize = 12.sp,
                color = FaithFeedColors.TextTertiary,
                modifier = Modifier.padding(top = 2.dp)
            )
        }
    }
}

@Composable
private fun ActorAvatar(avatarUrl: String?, size: Dp) {
    Box(
        modifier = Modifier
            .size(size)
            .clip(CircleShape)
            .background(FaithFeedColors.PurpleDark),
        contentAlignment = Alignment.Center
    ) {
        if (!avatarUrl.isNullOrBlank()) {
            AsyncImage(
                model = avatarUrl,
                contentDescription = null,
                modifier = Modifier.size(size).clip(CircleShape),
                contentScale = ContentScale.Crop
            )
        } else {
            Icon(
                imageVector = Icons.Outlined.Person,
                contentDescription = null,
                tint = FaithFeedColors.GoldAccent.copy(alpha = 0.6f),
                modifier = Modifier.size(size * 0.5f)
            )
        }
    }
}

private fun notificationText(n: Notification): String {
    val name = n.actor?.displayName?.takeIf { it.isNotBlank() }
        ?: n.actor?.username?.takeIf { it.isNotBlank() }
        ?: "Someone"
    return when (n.type) {
        "like"           -> "$name liked your post"
        "comment"        -> "$name commented on your post"
        "friend_request" -> "$name sent you a friend request"
        "prayer"         -> "$name prayed for you"
        "mention"        -> "$name mentioned you"
        else             -> "$name interacted with you"
    }
}

/** Converts ISO-8601 timestamp to a human-readable relative time string. */
private fun relativeTime(createdAt: String): String {
    return try {
        val instant = java.time.Instant.parse(createdAt)
        val seconds = java.time.Duration.between(instant, java.time.Instant.now()).seconds
        when {
            seconds < 60      -> "Just now"
            seconds < 3_600   -> "${seconds / 60}m ago"
            seconds < 86_400  -> "${seconds / 3_600}h ago"
            seconds < 604_800 -> "${seconds / 86_400}d ago"
            else              -> "${seconds / 604_800}w ago"
        }
    } catch (_: Exception) {
        ""
    }
}
