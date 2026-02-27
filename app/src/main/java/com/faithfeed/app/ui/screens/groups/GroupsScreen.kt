package com.faithfeed.app.ui.screens.groups

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.outlined.Group
import androidx.compose.material3.*
import androidx.compose.material3.TabRowDefaults.tabIndicatorOffset
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavController
import com.faithfeed.app.data.model.Group
import com.faithfeed.app.navigation.Route
import com.faithfeed.app.ui.components.EmptyState
import com.faithfeed.app.ui.components.SimpleTopBar
import com.faithfeed.app.ui.theme.FaithFeedColors
import com.faithfeed.app.ui.theme.Typography

@Composable
fun GroupsScreen(
    navController: NavController,
    viewModel: GroupsViewModel = hiltViewModel()
) {
    val myGroups by viewModel.myGroups.collectAsStateWithLifecycle()
    val discoverGroups by viewModel.discoverGroups.collectAsStateWithLifecycle()

    var selectedTabIndex by remember { mutableStateOf(0) }

    Scaffold(
        containerColor = FaithFeedColors.BackgroundPrimary,
        topBar = {
            SimpleTopBar(title = "Groups", onBack = { navController.popBackStack() })
        },
        floatingActionButton = {
            FloatingActionButton(
                onClick = { navController.navigate(Route.CreateGroup) },
                containerColor = FaithFeedColors.GoldAccent,
                contentColor = FaithFeedColors.BackgroundPrimary
            ) {
                Icon(Icons.Default.Add, contentDescription = "Create Group")
            }
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            TabRow(
                selectedTabIndex = selectedTabIndex,
                containerColor = FaithFeedColors.BackgroundPrimary,
                contentColor = FaithFeedColors.GoldAccent,
                indicator = { tabPositions ->
                    if (selectedTabIndex < tabPositions.size) {
                        TabRowDefaults.SecondaryIndicator(
                            Modifier.tabIndicatorOffset(tabPositions[selectedTabIndex]),
                            color = FaithFeedColors.GoldAccent
                        )
                    }
                }
            ) {
                Tab(
                    selected = selectedTabIndex == 0,
                    onClick = { selectedTabIndex = 0 },
                    text = { Text("My Groups", color = if (selectedTabIndex == 0) FaithFeedColors.GoldAccent else FaithFeedColors.TextSecondary) }
                )
                Tab(
                    selected = selectedTabIndex == 1,
                    onClick = { selectedTabIndex = 1 },
                    text = { Text("Discover", color = if (selectedTabIndex == 1) FaithFeedColors.GoldAccent else FaithFeedColors.TextSecondary) }
                )
            }

            Box(modifier = Modifier.fillMaxSize()) {
                if (selectedTabIndex == 0) {
                    if (myGroups.isEmpty()) {
                        EmptyState(
                            icon = Icons.Outlined.Group,
                            title = "No Groups Yet",
                            subtitle = "Join a group to connect with others"
                        )
                    } else {
                        GroupList(groups = myGroups, navController = navController)
                    }
                } else {
                    if (discoverGroups.isEmpty()) {
                        EmptyState(
                            icon = Icons.Outlined.Group,
                            title = "No Groups Found",
                            subtitle = "Check back later for new communities"
                        )
                    } else {
                        GroupList(groups = discoverGroups, navController = navController)
                    }
                }
            }
        }
    }
}

@Composable
fun GroupList(groups: List<Group>, navController: NavController) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        items(groups, key = { it.id }) { group ->
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { navController.navigate(Route.GroupDetail(group.id)) },
                colors = CardDefaults.cardColors(containerColor = FaithFeedColors.BackgroundSecondary),
                shape = RoundedCornerShape(12.dp)
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Box(
                        modifier = Modifier
                            .size(56.dp)
                            .clip(CircleShape)
                            .background(FaithFeedColors.GlassBackground),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(Icons.Outlined.Group, contentDescription = null, tint = FaithFeedColors.GoldAccent)
                    }
                    Spacer(modifier = Modifier.width(16.dp))
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = group.name,
                            style = Typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                            color = FaithFeedColors.TextPrimary
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = "${group.memberCount} members",
                            style = Typography.bodySmall,
                            color = FaithFeedColors.TextSecondary
                        )
                    }
                }
            }
        }
    }
}