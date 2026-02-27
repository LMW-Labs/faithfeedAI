package com.faithfeed.app.ui.screens.chat

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Send
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavController
import coil3.compose.AsyncImage
import com.faithfeed.app.data.model.Message
import com.faithfeed.app.ui.components.SimpleTopBar
import com.faithfeed.app.ui.theme.FaithFeedColors
import com.faithfeed.app.ui.theme.Nunito
import com.faithfeed.app.ui.theme.Typography

@Composable
fun ChatScreen(
    conversationId: String,
    otherUserName: String,
    navController: NavController,
    viewModel: ChatViewModel = hiltViewModel()
) {
    LaunchedEffect(conversationId) { viewModel.init(conversationId) }

    val messages by viewModel.messages.collectAsStateWithLifecycle()
    val inputText by viewModel.inputText.collectAsStateWithLifecycle()
    val currentUserId by viewModel.currentUserId.collectAsStateWithLifecycle()
    val listState = rememberLazyListState()

    // Scroll to bottom on new messages
    LaunchedEffect(messages.size) {
        if (messages.isNotEmpty()) {
            listState.animateScrollToItem(messages.size - 1)
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(FaithFeedColors.BackgroundPrimary)
    ) {
        SimpleTopBar(title = otherUserName, onBack = { navController.popBackStack() })

        // Messages list
        LazyColumn(
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth(),
            state = listState,
            contentPadding = PaddingValues(horizontal = 12.dp, vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            items(messages, key = { it.id }) { message ->
                MessageBubble(
                    message = message,
                    isSent = message.senderId == currentUserId
                )
            }
        }

        // Input row
        Surface(
            color = FaithFeedColors.BackgroundSecondary,
            tonalElevation = 4.dp
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 12.dp, vertical = 8.dp)
                    .navigationBarsPadding(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                OutlinedTextField(
                    value = inputText,
                    onValueChange = viewModel::onInputChange,
                    placeholder = {
                        Text("Message...", color = FaithFeedColors.TextTertiary, fontSize = 14.sp)
                    },
                    modifier = Modifier.weight(1f),
                    shape = RoundedCornerShape(24.dp),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = FaithFeedColors.GoldAccent,
                        unfocusedBorderColor = FaithFeedColors.GlassBorder,
                        cursorColor = FaithFeedColors.GoldAccent,
                        focusedTextColor = FaithFeedColors.TextPrimary,
                        unfocusedTextColor = FaithFeedColors.TextPrimary,
                        focusedContainerColor = FaithFeedColors.BackgroundPrimary,
                        unfocusedContainerColor = FaithFeedColors.BackgroundPrimary
                    ),
                    maxLines = 4,
                    textStyle = Typography.bodyMedium.copy(
                        color = FaithFeedColors.TextPrimary,
                        fontFamily = Nunito
                    )
                )
                Spacer(Modifier.width(8.dp))
                Box(
                    modifier = Modifier
                        .size(44.dp)
                        .clip(CircleShape)
                        .background(
                            if (inputText.isNotBlank()) FaithFeedColors.GoldAccent
                            else FaithFeedColors.GlassBackground
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    IconButton(
                        onClick = viewModel::sendMessage,
                        enabled = inputText.isNotBlank()
                    ) {
                        Icon(
                            imageVector = Icons.Default.Send,
                            contentDescription = "Send",
                            tint = if (inputText.isNotBlank()) FaithFeedColors.BackgroundPrimary
                            else FaithFeedColors.TextTertiary,
                            modifier = Modifier.size(20.dp)
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun MessageBubble(message: Message, isSent: Boolean) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = if (isSent) Arrangement.End else Arrangement.Start
    ) {
        if (!isSent) {
            AsyncImage(
                model = message.sender?.avatarUrl,
                contentDescription = null,
                contentScale = ContentScale.Crop,
                modifier = Modifier
                    .size(32.dp)
                    .clip(CircleShape)
                    .background(FaithFeedColors.GlassBackground)
                    .align(Alignment.Bottom)
            )
            Spacer(Modifier.width(6.dp))
        }

        Column(
            horizontalAlignment = if (isSent) Alignment.End else Alignment.Start,
            modifier = Modifier.widthIn(max = 280.dp)
        ) {
            if (!isSent && message.sender != null) {
                Text(
                    text = message.sender.displayName,
                    style = Typography.labelSmall,
                    color = FaithFeedColors.TextTertiary,
                    modifier = Modifier.padding(horizontal = 4.dp, vertical = 2.dp)
                )
            }
            Surface(
                color = if (isSent) FaithFeedColors.GoldAccent.copy(alpha = 0.85f)
                else FaithFeedColors.BackgroundSecondary,
                shape = RoundedCornerShape(
                    topStart = 16.dp,
                    topEnd = 16.dp,
                    bottomStart = if (isSent) 16.dp else 4.dp,
                    bottomEnd = if (isSent) 4.dp else 16.dp
                )
            ) {
                Text(
                    text = message.content,
                    modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
                    style = Typography.bodyMedium,
                    fontFamily = Nunito,
                    color = if (isSent) FaithFeedColors.BackgroundPrimary
                    else FaithFeedColors.TextPrimary,
                    fontSize = 14.sp
                )
            }
            Text(
                text = message.createdAt.take(16).replace("T", " "),
                style = Typography.bodySmall,
                color = FaithFeedColors.TextTertiary,
                fontSize = 10.sp,
                modifier = Modifier.padding(horizontal = 4.dp, vertical = 2.dp)
            )
        }

        if (isSent) {
            Spacer(Modifier.width(6.dp))
        }
    }
}
