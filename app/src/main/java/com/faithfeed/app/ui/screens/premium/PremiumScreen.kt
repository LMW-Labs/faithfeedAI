package com.faithfeed.app.ui.screens.premium

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Stars
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.faithfeed.app.ui.components.EmptyState
import com.faithfeed.app.ui.components.SimpleTopBar
import com.faithfeed.app.ui.theme.FaithFeedColors

@Composable
fun PremiumScreen(navController: NavController, viewModel: PremiumViewModel = hiltViewModel()) {
    Column(modifier = Modifier.fillMaxSize().background(FaithFeedColors.BackgroundPrimary)) {
        SimpleTopBar(title = "Premium", onBack = { navController.popBackStack() })
        Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            EmptyState(icon = Icons.Outlined.Stars, title = "FaithFeed Premium", subtitle = "Unlock unlimited AI study, ad-free experience, and more")
        }
    }
}
