package com.faithfeed.app.ui.screens.chat

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Chat
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavController
import coil3.compose.AsyncImage
import com.faithfeed.app.data.model.Chat
import com.faithfeed.app.navigation.Route
import com.faithfeed.app.ui.components.EmptyState
import com.faithfeed.app.ui.components.SimpleTopBar
import com.faithfeed.app.ui.theme.FaithFeedColors
import com.faithfeed.app.ui.theme.Nunito
import com.faithfeed.app.ui.theme.Typography

@Composable
fun ChatListScreen(
    navController: NavController,
    viewModel: ChatListViewModel = hiltViewModel()
) {
    val conversations by viewModel.conversations.collectAsStateWithLifecycle()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(FaithFeedColors.BackgroundPrimary)
    ) {
        SimpleTopBar(title = "Messages", onBack = { navController.popBackStack() })

        if (conversations.isEmpty()) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                EmptyState(
                    icon = Icons.Outlined.Chat,
                    title = "No Messages",
                    subtitle = "Start a conversation from someone's profile"
                )
            }
        } else {
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(vertical = 8.dp)
            ) {
                items(conversations, key = { it.id }) { chat ->
                    ConversationRow(
                        chat = chat,
                        onClick = {
                            navController.navigate(
                                Route.Chat(
                                    conversationId = chat.id,
                                    otherUserName = chat.name ?: "Chat"
                                )
                            )
                        }
                    )
                    HorizontalDivider(
                        modifier = Modifier.padding(horizontal = 72.dp),
                        color = FaithFeedColors.GlassBorder
                    )
                }
            }
        }
    }
}

@Composable
private fun ConversationRow(chat: Chat, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Avatar
        Box(
            modifier = Modifier
                .size(52.dp)
                .clip(CircleShape)
                .background(FaithFeedColors.PurpleDark),
            contentAlignment = Alignment.Center
        ) {
            if (!chat.avatarUrl.isNullOrBlank()) {
                AsyncImage(
                    model = chat.avatarUrl,
                    contentDescription = null,
                    contentScale = ContentScale.Crop,
                    modifier = Modifier.fillMaxSize().clip(CircleShape)
                )
            } else {
                Text(
                    text = (chat.name?.firstOrNull() ?: "?").toString().uppercase(),
                    color = FaithFeedColors.GoldAccent,
                    fontWeight = FontWeight.Bold,
                    fontSize = 20.sp
                )
            }
        }

        Spacer(Modifier.width(12.dp))

        // Name + last message
        Column(modifier = Modifier.weight(1f)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = chat.name ?: "Chat",
                    style = Typography.titleMedium.copy(fontWeight = FontWeight.SemiBold),
                    color = FaithFeedColors.TextPrimary
                )
                if (!chat.lastMessageAt.isNullOrBlank()) {
                    Text(
                        text = chat.lastMessageAt.take(10),
                        style = Typography.bodySmall,
                        color = FaithFeedColors.TextTertiary,
                        fontSize = 11.sp
                    )
                }
            }
            Spacer(Modifier.height(2.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = chat.lastMessage ?: "No messages yet",
                    style = Typography.bodySmall,
                    color = if (chat.unreadCount > 0) FaithFeedColors.TextPrimary
                    else FaithFeedColors.TextTertiary,
                    fontFamily = Nunito,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f)
                )
                if (chat.unreadCount > 0) {
                    Spacer(Modifier.width(8.dp))
                    Badge(containerColor = FaithFeedColors.GoldAccent) {
                        Text(
                            text = if (chat.unreadCount > 9) "9+" else chat.unreadCount.toString(),
                            fontSize = 10.sp,
                            color = FaithFeedColors.BackgroundPrimary
                        )
                    }
                }
            }
        }
    }
}
