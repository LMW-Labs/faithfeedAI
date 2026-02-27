package com.faithfeed.app.ui.components

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.outlined.AddAPhoto
import androidx.compose.material.icons.outlined.Edit
import androidx.compose.material.icons.outlined.Notifications
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material.icons.outlined.Storefront
import androidx.compose.material.icons.outlined.VolunteerActivism
import androidx.compose.material3.Badge
import androidx.compose.material3.BadgedBox
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.MenuDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil3.compose.AsyncImage
import com.faithfeed.app.R
import com.faithfeed.app.ui.theme.Cinzel
import com.faithfeed.app.ui.theme.FaithFeedColors

@Composable
fun FaithFeedTopBar(
    title: String? = null,
    onSearchClick: (() -> Unit)? = null,
    onNotificationsClick: (() -> Unit)? = null,
    onProfileClick: (() -> Unit)? = null,
    avatarUrl: String? = null,
    unreadNotifications: Int = 0,
    // Create content actions — if any are non-null, the + button appears
    onCreatePost: (() -> Unit)? = null,
    onCreateStory: (() -> Unit)? = null,
    onCreateListing: (() -> Unit)? = null,
    onCreatePrayer: (() -> Unit)? = null,
    modifier: Modifier = Modifier
) {
    val showCreateButton = onCreatePost != null || onCreateStory != null ||
        onCreateListing != null || onCreatePrayer != null
    var showCreateMenu by remember { mutableStateOf(false) }

    Row(
        modifier = modifier
            .fillMaxWidth()
            .background(FaithFeedColors.BackgroundPrimary)
            .statusBarsPadding()
            .height(56.dp)
            .padding(horizontal = 16.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        // Logo + title
        Row(verticalAlignment = Alignment.CenterVertically) {
            Image(
                painter = painterResource(R.drawable.omega),
                contentDescription = "FaithFeed",
                modifier = Modifier.size(32.dp)
            )
            Spacer(Modifier.padding(horizontal = 6.dp))
            Text(
                text = title ?: "FaithFeed",
                fontFamily = Cinzel,
                fontWeight = FontWeight.SemiBold,
                fontSize = 18.sp,
                color = FaithFeedColors.GoldAccent
            )
        }

        // Action icons
        Row(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            if (onSearchClick != null) {
                TopBarIconButton(
                    icon = Icons.Outlined.Search,
                    contentDescription = "Search",
                    onClick = onSearchClick
                )
            }

            if (onNotificationsClick != null) {
                BadgedBox(
                    badge = {
                        if (unreadNotifications > 0) {
                            Badge(containerColor = FaithFeedColors.GoldAccent) {
                                Text(
                                    text = if (unreadNotifications > 9) "9+" else unreadNotifications.toString(),
                                    fontSize = 8.sp,
                                    color = FaithFeedColors.BackgroundPrimary
                                )
                            }
                        }
                    }
                ) {
                    TopBarIconButton(
                        icon = Icons.Outlined.Notifications,
                        contentDescription = "Notifications",
                        onClick = onNotificationsClick
                    )
                }
            }

            // + Create button with dropdown
            if (showCreateButton) {
                Box {
                    Box(
                        modifier = Modifier
                            .size(36.dp)
                            .clip(CircleShape)
                            .background(FaithFeedColors.GoldAccent)
                            .clickable { showCreateMenu = true },
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.Default.Add,
                            contentDescription = "Create",
                            tint = FaithFeedColors.BackgroundPrimary,
                            modifier = Modifier.size(20.dp)
                        )
                    }

                    DropdownMenu(
                        expanded = showCreateMenu,
                        onDismissRequest = { showCreateMenu = false },
                        modifier = Modifier.background(FaithFeedColors.BackgroundSecondary)
                    ) {
                        if (onCreatePost != null) {
                            CreateMenuItem(
                                icon = Icons.Outlined.Edit,
                                label = "New Post",
                                onClick = { showCreateMenu = false; onCreatePost() }
                            )
                        }
                        if (onCreateStory != null) {
                            CreateMenuItem(
                                icon = Icons.Outlined.AddAPhoto,
                                label = "New Story",
                                onClick = { showCreateMenu = false; onCreateStory() }
                            )
                        }
                        if (onCreateListing != null) {
                            CreateMenuItem(
                                icon = Icons.Outlined.Storefront,
                                label = "New Listing",
                                onClick = { showCreateMenu = false; onCreateListing() }
                            )
                        }
                        if (onCreatePrayer != null) {
                            CreateMenuItem(
                                icon = Icons.Outlined.VolunteerActivism,
                                label = "Prayer Request",
                                onClick = { showCreateMenu = false; onCreatePrayer() }
                            )
                        }
                    }
                }
            }

            // Profile avatar — tapping navigates to MyProfile
            if (onProfileClick != null) {
                Box(
                    modifier = Modifier
                        .size(36.dp)
                        .clip(CircleShape)
                        .background(FaithFeedColors.PurpleDark)
                        .border(1.5.dp, FaithFeedColors.GoldAccent, CircleShape)
                        .clickable(onClick = onProfileClick),
                    contentAlignment = Alignment.Center
                ) {
                    if (!avatarUrl.isNullOrBlank()) {
                        AsyncImage(
                            model = avatarUrl,
                            contentDescription = "Profile",
                            modifier = Modifier.fillMaxSize().clip(CircleShape),
                            contentScale = ContentScale.Crop
                        )
                    } else {
                        Icon(
                            imageVector = Icons.Outlined.Person,
                            contentDescription = "Profile",
                            tint = FaithFeedColors.GoldAccent,
                            modifier = Modifier.size(20.dp)
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun CreateMenuItem(
    icon: ImageVector,
    label: String,
    onClick: () -> Unit
) {
    DropdownMenuItem(
        text = {
            Text(
                text = label,
                color = FaithFeedColors.TextPrimary,
                fontSize = 14.sp
            )
        },
        leadingIcon = {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = FaithFeedColors.GoldAccent,
                modifier = Modifier.size(18.dp)
            )
        },
        onClick = onClick,
        colors = MenuDefaults.itemColors(
            textColor = FaithFeedColors.TextPrimary,
            leadingIconColor = FaithFeedColors.GoldAccent
        )
    )
}

@Composable
private fun TopBarIconButton(
    icon: ImageVector,
    contentDescription: String,
    onClick: () -> Unit
) {
    Box(
        modifier = Modifier
            .size(40.dp)
            .clip(CircleShape)
            .background(FaithFeedColors.GlassBackground)
            .border(1.dp, FaithFeedColors.GlassBorder, CircleShape)
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        Icon(
            imageVector = icon,
            contentDescription = contentDescription,
            tint = FaithFeedColors.TextSecondary,
            modifier = Modifier.size(20.dp)
        )
    }
}

@Composable
fun SimpleTopBar(
    title: String,
    onBack: (() -> Unit)? = null,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .background(FaithFeedColors.BackgroundPrimary)
            .statusBarsPadding()
            .height(56.dp)
            .padding(horizontal = 16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        if (onBack != null) {
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .clip(RoundedCornerShape(12.dp))
                    .background(FaithFeedColors.GlassBackground)
                    .clickable(onClick = onBack),
                contentAlignment = Alignment.Center
            ) {
                Text("←", color = FaithFeedColors.GoldAccent, fontSize = 18.sp)
            }
            Spacer(Modifier.padding(horizontal = 8.dp))
        }
        Text(
            text = title,
            fontFamily = Cinzel,
            fontWeight = FontWeight.SemiBold,
            fontSize = 18.sp,
            color = FaithFeedColors.TextPrimary
        )
    }
}
