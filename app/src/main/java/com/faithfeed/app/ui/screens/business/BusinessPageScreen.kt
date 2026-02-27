package com.faithfeed.app.ui.screens.business

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Business
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.faithfeed.app.ui.components.EmptyState
import com.faithfeed.app.ui.components.SimpleTopBar
import com.faithfeed.app.ui.theme.FaithFeedColors

@Composable
fun BusinessPageScreen(pageId: String, navController: NavController, viewModel: BusinessPageViewModel = hiltViewModel()) {
    LaunchedEffect(pageId) { viewModel.init(pageId) }
    Column(modifier = Modifier.fillMaxSize().background(FaithFeedColors.BackgroundPrimary)) {
        SimpleTopBar(title = "Ministry Page", onBack = { navController.popBackStack() })
        Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            EmptyState(icon = Icons.Outlined.Business, title = "Ministry Page", subtitle = "Church, ministry, or Christian business")
        }
    }
}
