package com.faithfeed.app.ui.screens.groups

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Group
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
fun GroupDetailScreen(groupId: String, navController: NavController, viewModel: GroupDetailViewModel = hiltViewModel()) {
    LaunchedEffect(groupId) { viewModel.init(groupId) }
    Column(modifier = Modifier.fillMaxSize().background(FaithFeedColors.BackgroundPrimary)) {
        SimpleTopBar(title = "Group", onBack = { navController.popBackStack() })
        Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            EmptyState(icon = Icons.Outlined.Group, title = "Group", subtitle = "Members, posts, and group activity")
        }
    }
}
