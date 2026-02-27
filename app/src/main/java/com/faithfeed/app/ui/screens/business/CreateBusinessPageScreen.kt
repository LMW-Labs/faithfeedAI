package com.faithfeed.app.ui.screens.business

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.AddBusiness
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.navigation.NavController
import com.faithfeed.app.ui.components.EmptyState
import com.faithfeed.app.ui.components.SimpleTopBar
import com.faithfeed.app.ui.theme.FaithFeedColors

@Composable
fun CreateBusinessPageScreen(navController: NavController) {
    Column(modifier = Modifier.fillMaxSize().background(FaithFeedColors.BackgroundPrimary)) {
        SimpleTopBar(title = "Create Ministry Page", onBack = { navController.popBackStack() })
        Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            EmptyState(icon = Icons.Outlined.AddBusiness, title = "Create Ministry Page", subtitle = "Register your church, ministry, or Christian business")
        }
    }
}
