package com.faithfeed.app.ui.screens.marketplace

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Chat
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.navigation.NavController
import com.faithfeed.app.ui.components.EmptyState
import com.faithfeed.app.ui.components.SimpleTopBar
import com.faithfeed.app.ui.theme.FaithFeedColors

@Composable
fun MarketplaceChatScreen(conversationId: String, navController: NavController) {
    Column(modifier = Modifier.fillMaxSize().background(FaithFeedColors.BackgroundPrimary)) {
        SimpleTopBar(title = "Chat with Seller", onBack = { navController.popBackStack() })
        Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            EmptyState(icon = Icons.Outlined.Chat, title = "Marketplace Chat", subtitle = "Chat with the seller about this item")
        }
    }
}
