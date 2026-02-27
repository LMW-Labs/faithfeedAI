package com.faithfeed.app.ui.screens.profile

import androidx.compose.foundation.background
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
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavController
import com.faithfeed.app.navigation.Route
import com.faithfeed.app.ui.components.ButtonStyle
import com.faithfeed.app.ui.components.FaithFeedButton
import com.faithfeed.app.ui.theme.Cinzel
import com.faithfeed.app.ui.theme.FaithFeedColors

@Composable
fun UserProfileScreen(
    userId: String,
    navController: NavController,
    viewModel: ProfileViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val snackbarHostState = remember { SnackbarHostState() }

    LaunchedEffect(userId) { viewModel.loadProfile(userId) }

    LaunchedEffect(uiState.chatNav) {
        uiState.chatNav?.let { (chatId, name) ->
            viewModel.clearChatNav()
            navController.navigate(Route.Chat(chatId, name))
        }
    }

    LaunchedEffect(uiState.error) {
        uiState.error?.let {
            snackbarHostState.showSnackbar(it)
            viewModel.clearError()
        }
    }

    Scaffold(
        containerColor = FaithFeedColors.BackgroundPrimary,
        snackbarHost = { SnackbarHost(snackbarHostState) },
        topBar = {
            UserProfileTopBar(
                displayName = uiState.user?.let {
                    it.displayName.ifBlank { it.username }
                } ?: "",
                onBack = { navController.popBackStack() }
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

                ProfileStatsRow(user = user)

                Spacer(Modifier.height(20.dp))

                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp),
                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    FaithFeedButton(
                        text = if (uiState.friendRequestSent) "Request Sent" else "Add Friend",
                        onClick = {
                            if (!uiState.friendRequestSent) viewModel.sendFriendRequest(userId)
                        },
                        style = ButtonStyle.Primary,
                        enabled = !uiState.friendRequestSent,
                        modifier = Modifier.weight(1f)
                    )
                    FaithFeedButton(
                        text = "Message",
                        onClick = { viewModel.startDirectChat() },
                        style = ButtonStyle.Secondary,
                        modifier = Modifier.weight(1f)
                    )
                }
            }

            Spacer(Modifier.height(24.dp))

            PostsSection(
                posts = uiState.posts,
                isLoading = uiState.isLoadingPosts
            )

            Spacer(Modifier.height(32.dp))
        }
    }
}

@Composable
private fun UserProfileTopBar(displayName: String, onBack: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(FaithFeedColors.BackgroundPrimary)
            .statusBarsPadding()
            .height(56.dp)
            .padding(horizontal = 4.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        IconButton(onClick = onBack) {
            Text("←", color = FaithFeedColors.GoldAccent, fontSize = 20.sp)
        }
        Text(
            text = displayName,
            fontFamily = Cinzel,
            fontWeight = FontWeight.SemiBold,
            fontSize = 18.sp,
            color = FaithFeedColors.TextPrimary,
            modifier = Modifier.weight(1f)
        )
        Spacer(modifier = Modifier.size(48.dp))
    }
}
