package com.faithfeed.app.ui.screens.prayer

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.FavoriteBorder
import androidx.compose.material.icons.outlined.VolunteerActivism
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavController
import coil3.compose.AsyncImage
import com.faithfeed.app.data.model.PrayerRequest
import com.faithfeed.app.navigation.Route
import com.faithfeed.app.ui.components.EmptyState
import com.faithfeed.app.ui.components.FaithFeedTopBar
import com.faithfeed.app.ui.theme.FaithFeedColors
import com.faithfeed.app.ui.theme.Nunito
import com.faithfeed.app.ui.theme.Typography

@Composable
fun PrayerWallScreen(
    navController: NavController,
    viewModel: PrayerWallViewModel = hiltViewModel()
) {
    val prayers by viewModel.prayers.collectAsStateWithLifecycle()
    val currentUserId by viewModel.currentUserId.collectAsStateWithLifecycle()

    Scaffold(
        containerColor = FaithFeedColors.BackgroundPrimary,
        topBar = {
            FaithFeedTopBar(
                title = "Prayer Wall",
                onSearchClick = { navController.navigate(Route.SemanticSearch) },
                onNotificationsClick = { navController.navigate(Route.Notifications) },
                onProfileClick = {
                    if (currentUserId.isNotBlank()) navController.navigate(Route.MyProfile(currentUserId))
                },
                onCreatePost = { navController.navigate(Route.CreatePost) },
                onCreateStory = { navController.navigate(Route.CreateStory) },
                onCreateListing = { navController.navigate(Route.CreateListing) },
                onCreatePrayer = { navController.navigate(Route.CreatePrayer) }
            )
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            if (prayers.isEmpty()) {
                EmptyState(
                    icon = Icons.Outlined.VolunteerActivism,
                    title = "No Prayers Yet",
                    subtitle = "Be the first to add a prayer request to the wall."
                )
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    items(prayers, key = { it.id }) { prayer ->
                        PrayerCard(
                            prayer = prayer,
                            onPrayClick = { viewModel.prayForRequest(prayer.id) }
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun PrayerCard(
    prayer: PrayerRequest,
    onPrayClick: () -> Unit
) {
    val displayName = if (prayer.isAnonymous || prayer.author == null) "Anonymous" else prayer.author.displayName
    val avatarUrl = if (prayer.isAnonymous) null else prayer.author?.avatarUrl

    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = FaithFeedColors.BackgroundSecondary),
        shape = RoundedCornerShape(12.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            // Header: User Info
            Row(verticalAlignment = Alignment.CenterVertically) {
                if (avatarUrl != null) {
                    AsyncImage(
                        model = avatarUrl,
                        contentDescription = "Avatar",
                        contentScale = ContentScale.Crop,
                        modifier = Modifier
                            .size(36.dp)
                            .clip(CircleShape)
                            .background(FaithFeedColors.GlassBackground)
                    )
                } else {
                    Box(
                        modifier = Modifier
                            .size(36.dp)
                            .clip(CircleShape)
                            .background(FaithFeedColors.GlassBackground),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.Outlined.VolunteerActivism,
                            contentDescription = "Anonymous",
                            tint = FaithFeedColors.TextTertiary,
                            modifier = Modifier.size(20.dp)
                        )
                    }
                }
                Spacer(modifier = Modifier.width(12.dp))
                Column {
                    Text(
                        text = displayName,
                        style = Typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                        color = FaithFeedColors.TextPrimary
                    )
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Content
            Text(
                text = prayer.title,
                style = Typography.titleMedium,
                color = FaithFeedColors.GoldAccent,
                fontFamily = Nunito,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = prayer.content,
                style = Typography.bodyMedium,
                color = FaithFeedColors.TextSecondary,
                fontFamily = Nunito
            )

            Spacer(modifier = Modifier.height(16.dp))
            HorizontalDivider(color = FaithFeedColors.GlassBorder)
            Spacer(modifier = Modifier.height(8.dp))

            // Footer: Count and Button
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "${prayer.prayerCount} ${if (prayer.prayerCount == 1) "person is" else "people are"} praying",
                    style = Typography.bodySmall,
                    color = FaithFeedColors.TextTertiary,
                    fontFamily = Nunito
                )

                Surface(
                    color = FaithFeedColors.GoldAccent.copy(alpha = 0.1f),
                    shape = RoundedCornerShape(20.dp),
                    modifier = Modifier.clickable { onPrayClick() }
                ) {
                    Row(
                        modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = if (prayer.hasPrayed) Icons.Outlined.VolunteerActivism else Icons.Outlined.FavoriteBorder,
                            contentDescription = "Pray",
                            tint = FaithFeedColors.GoldAccent,
                            modifier = Modifier.size(16.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = if (prayer.hasPrayed) "Praying" else "I'm Praying",
                            style = Typography.labelMedium.copy(fontWeight = FontWeight.Bold),
                            color = FaithFeedColors.GoldAccent,
                            fontFamily = Nunito
                        )
                    }
                }
            }
        }
    }
}
