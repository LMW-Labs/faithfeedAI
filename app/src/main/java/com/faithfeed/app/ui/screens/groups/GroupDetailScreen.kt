package com.faithfeed.app.ui.screens.groups

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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Group
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material.icons.outlined.People
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavController
import coil3.compose.AsyncImage
import com.faithfeed.app.data.model.User
import com.faithfeed.app.ui.components.ButtonStyle
import com.faithfeed.app.ui.components.FaithFeedButton
import com.faithfeed.app.ui.components.SimpleTopBar
import com.faithfeed.app.ui.theme.FaithFeedColors
import com.faithfeed.app.ui.theme.Typography

@Composable
fun GroupDetailScreen(
    groupId: String,
    navController: NavController,
    viewModel: GroupDetailViewModel = hiltViewModel()
) {
    LaunchedEffect(groupId) { viewModel.init(groupId) }
    val group by viewModel.group.collectAsStateWithLifecycle()
    val members by viewModel.members.collectAsStateWithLifecycle()
    val isJoining by viewModel.isJoining.collectAsStateWithLifecycle()

    Scaffold(
        containerColor = FaithFeedColors.BackgroundPrimary,
        topBar = {
            SimpleTopBar(
                title = group?.name ?: "Group",
                onBack = { navController.popBackStack() }
            )
        }
    ) { paddingValues ->
        if (group == null) {
            Box(
                modifier = Modifier.fillMaxSize().padding(paddingValues),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator(color = FaithFeedColors.GoldAccent)
            }
            return@Scaffold
        }

        val g = group!!

        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(paddingValues)
        ) {
            // Cover image / header
            item {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(160.dp)
                        .background(FaithFeedColors.PurpleDark),
                    contentAlignment = Alignment.Center
                ) {
                    if (g.coverUrl != null) {
                        AsyncImage(
                            model = g.coverUrl,
                            contentDescription = null,
                            modifier = Modifier.fillMaxSize(),
                            contentScale = ContentScale.Crop
                        )
                    } else {
                        Icon(
                            Icons.Outlined.Group,
                            contentDescription = null,
                            tint = FaithFeedColors.GoldAccent.copy(alpha = 0.6f),
                            modifier = Modifier.size(64.dp)
                        )
                    }
                }
            }

            // Info row
            item {
                Column(modifier = Modifier.padding(16.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.Top
                    ) {
                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                text = g.name,
                                style = Typography.headlineSmall.copy(fontWeight = FontWeight.Bold),
                                color = FaithFeedColors.TextPrimary
                            )
                            Spacer(Modifier.height(4.dp))
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(
                                    imageVector = if (g.isPrivate) Icons.Outlined.Lock else Icons.Outlined.People,
                                    contentDescription = null,
                                    tint = FaithFeedColors.TextTertiary,
                                    modifier = Modifier.size(14.dp)
                                )
                                Spacer(Modifier.width(4.dp))
                                Text(
                                    text = "${g.memberCount} members · ${if (g.isPrivate) "Private" else "Public"}",
                                    style = Typography.bodySmall,
                                    color = FaithFeedColors.TextTertiary
                                )
                            }
                        }

                        Spacer(Modifier.width(16.dp))

                        if (isJoining) {
                            CircularProgressIndicator(
                                color = FaithFeedColors.GoldAccent,
                                modifier = Modifier.size(36.dp)
                            )
                        } else {
                            FaithFeedButton(
                                text = if (g.isMember) "Leave" else "Join",
                                onClick = { viewModel.toggleMembership(g) },
                                style = if (g.isMember) ButtonStyle.Ghost else ButtonStyle.Primary
                            )
                        }
                    }

                    if (g.description.isNotBlank()) {
                        Spacer(Modifier.height(12.dp))
                        Text(
                            text = g.description,
                            style = Typography.bodyMedium,
                            color = FaithFeedColors.TextSecondary
                        )
                    }
                }
            }

            item { HorizontalDivider(color = FaithFeedColors.GlassBorder) }

            if (members.isNotEmpty()) {
                item {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Text(
                            text = "Members",
                            style = Typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                            color = FaithFeedColors.TextPrimary
                        )
                        Spacer(Modifier.height(12.dp))
                        LazyRow(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                            items(members) { member -> MemberAvatar(member) }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun MemberAvatar(user: User) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier.width(64.dp)
    ) {
        Box(
            modifier = Modifier
                .size(48.dp)
                .clip(CircleShape)
                .background(FaithFeedColors.GlassBackground),
            contentAlignment = Alignment.Center
        ) {
            if (user.avatarUrl != null) {
                AsyncImage(
                    model = user.avatarUrl,
                    contentDescription = user.displayName,
                    modifier = Modifier.fillMaxSize().clip(CircleShape),
                    contentScale = ContentScale.Crop
                )
            } else {
                Text(
                    text = user.displayName.take(1).uppercase().ifEmpty { "?" },
                    style = Typography.titleMedium,
                    color = FaithFeedColors.GoldAccent
                )
            }
        }
        Spacer(Modifier.height(4.dp))
        Text(
            text = user.displayName.split(" ").firstOrNull()?.ifEmpty { user.username } ?: user.username,
            style = Typography.bodySmall,
            color = FaithFeedColors.TextSecondary,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )
    }
}
