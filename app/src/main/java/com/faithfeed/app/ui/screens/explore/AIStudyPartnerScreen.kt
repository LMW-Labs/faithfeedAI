package com.faithfeed.app.ui.screens.explore

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Send
import androidx.compose.material.icons.outlined.Psychology
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavController
import com.faithfeed.app.data.model.AIMessage
import com.faithfeed.app.ui.components.SimpleTopBar
import com.faithfeed.app.ui.theme.FaithFeedColors
import com.faithfeed.app.ui.theme.Nunito
import com.faithfeed.app.ui.theme.Typography

@Composable
fun AIStudyPartnerScreen(
    navController: NavController,
    viewModel: AIStudyPartnerViewModel = hiltViewModel()
) {
    val messages by viewModel.messages.collectAsStateWithLifecycle()
    val isLoading by viewModel.isLoading.collectAsStateWithLifecycle()
    var inputText by remember { mutableStateOf("") }
    val focusManager = LocalFocusManager.current

    Scaffold(
        containerColor = FaithFeedColors.BackgroundPrimary,
        topBar = {
            SimpleTopBar(title = "AI Study Partner", onBack = { navController.popBackStack() })
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            LazyColumn(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth(),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                items(messages, key = { it.id }) { message ->
                    ChatMessage(message = message)
                }
                if (isLoading) {
                    item {
                        Box(modifier = Modifier.fillMaxWidth().padding(8.dp), contentAlignment = Alignment.CenterStart) {
                            CircularProgressIndicator(color = FaithFeedColors.GoldAccent, modifier = Modifier.size(24.dp))
                        }
                    }
                }
            }

            Surface(
                color = FaithFeedColors.BackgroundSecondary,
                modifier = Modifier.fillMaxWidth()
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    OutlinedTextField(
                        value = inputText,
                        onValueChange = { inputText = it },
                        modifier = Modifier.weight(1f),
                        placeholder = { Text("Ask a question...") },
                        keyboardOptions = KeyboardOptions(imeAction = ImeAction.Send),
                        keyboardActions = KeyboardActions(
                            onSend = {
                                viewModel.sendMessage(inputText)
                                inputText = ""
                                focusManager.clearFocus()
                            }
                        ),
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor = FaithFeedColors.GoldAccent,
                            unfocusedBorderColor = FaithFeedColors.GlassBorder,
                            focusedTextColor = FaithFeedColors.TextPrimary,
                            unfocusedTextColor = FaithFeedColors.TextPrimary,
                            focusedContainerColor = FaithFeedColors.GlassBackground,
                            unfocusedContainerColor = FaithFeedColors.GlassBackground
                        ),
                        shape = RoundedCornerShape(24.dp),
                        maxLines = 3
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    IconButton(
                        onClick = {
                            viewModel.sendMessage(inputText)
                            inputText = ""
                            focusManager.clearFocus()
                        },
                        enabled = inputText.isNotBlank() && !isLoading,
                        colors = IconButtonDefaults.iconButtonColors(contentColor = FaithFeedColors.GoldAccent)
                    ) {
                        Icon(Icons.Default.Send, contentDescription = "Send")
                    }
                }
            }
        }
    }
}

@Composable
fun ChatMessage(message: AIMessage) {
    val isUser = message.role == "user"
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = if (isUser) Arrangement.End else Arrangement.Start
    ) {
        if (!isUser) {
            Icon(
                imageVector = Icons.Outlined.Psychology,
                contentDescription = "AI",
                tint = FaithFeedColors.GoldAccent,
                modifier = Modifier.size(28.dp).padding(top = 4.dp, end = 8.dp)
            )
        }
        Surface(
            color = if (isUser) FaithFeedColors.GoldAccent.copy(alpha = 0.2f) else FaithFeedColors.BackgroundSecondary,
            shape = RoundedCornerShape(
                topStart = 16.dp,
                topEnd = 16.dp,
                bottomStart = if (isUser) 16.dp else 4.dp,
                bottomEnd = if (isUser) 4.dp else 16.dp
            ),
            modifier = Modifier.widthIn(max = 280.dp)
        ) {
            Text(
                text = message.content,
                modifier = Modifier.padding(12.dp),
                color = if (isUser) FaithFeedColors.GoldAccent else FaithFeedColors.TextPrimary,
                style = Typography.bodyLarge,
                fontFamily = Nunito
            )
        }
    }
}
