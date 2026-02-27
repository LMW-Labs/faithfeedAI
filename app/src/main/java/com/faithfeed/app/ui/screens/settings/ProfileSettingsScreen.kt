package com.faithfeed.app.ui.screens.settings

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.BookmarkBorder
import androidx.compose.material.icons.outlined.Email
import androidx.compose.material.icons.outlined.FilterList
import androidx.compose.material.icons.outlined.Groups
import androidx.compose.material.icons.outlined.Home
import androidx.compose.material.icons.outlined.Language
import androidx.compose.material.icons.automirrored.outlined.MenuBook
import androidx.compose.material.icons.automirrored.outlined.ViewList
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material.icons.outlined.PersonAdd
import androidx.compose.material.icons.outlined.Phone
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material.icons.outlined.Visibility
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavController
import com.faithfeed.app.data.model.ProfilePrivacy
import com.faithfeed.app.ui.components.SimpleTopBar
import com.faithfeed.app.ui.theme.FaithFeedColors
import com.faithfeed.app.ui.theme.Typography

@Composable
fun ProfileSettingsScreen(
    navController: NavController,
    viewModel: ProfileSettingsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()

    Scaffold(
        containerColor = FaithFeedColors.BackgroundPrimary,
        topBar = {
            SimpleTopBar(title = "Profile Settings", onBack = { navController.popBackStack() })
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 16.dp, vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // ── Privacy Controls ──────────────────────────────────────────────
            ProfileSettingsSection(title = "Privacy Controls") {
                PrivacyRow(
                    icon = Icons.Outlined.Person,
                    label = "Bio",
                    current = uiState.privacy.bioVisibility,
                    onLevelSelected = { viewModel.updatePrivacy("bio", it) }
                )
                ProfileDivider()
                PrivacyRow(
                    icon = Icons.Outlined.Home,
                    label = "Location",
                    current = uiState.privacy.locationVisibility,
                    onLevelSelected = { viewModel.updatePrivacy("location", it) }
                )
                ProfileDivider()
                PrivacyRow(
                    icon = Icons.Outlined.Phone,
                    label = "Phone Number",
                    current = uiState.privacy.phoneVisibility,
                    onLevelSelected = { viewModel.updatePrivacy("phone", it) }
                )
                ProfileDivider()
                PrivacyRow(
                    icon = Icons.AutoMirrored.Outlined.ViewList,
                    label = "Posts",
                    current = uiState.privacy.postsVisibility,
                    onLevelSelected = { viewModel.updatePrivacy("posts", it) }
                )
                ProfileDivider()
                PrivacyRow(
                    icon = Icons.Outlined.Groups,
                    label = "Friends List",
                    current = uiState.privacy.friendsVisibility,
                    onLevelSelected = { viewModel.updatePrivacy("friends", it) }
                )
                ProfileDivider()
                PrivacyRow(
                    icon = Icons.Outlined.Visibility,
                    label = "Activity Status",
                    current = uiState.privacy.activityVisibility,
                    onLevelSelected = { viewModel.updatePrivacy("activity", it) }
                )
                ProfileDivider()
                PrivacyRow(
                    icon = Icons.Outlined.Email,
                    label = "Email Address",
                    current = uiState.privacy.emailVisibility,
                    onLevelSelected = { viewModel.updatePrivacy("email", it) }
                )
                // Saving indicator
                if (uiState.isSaving) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp, vertical = 8.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.End
                    ) {
                        CircularProgressIndicator(
                            color = FaithFeedColors.GoldAccent,
                            modifier = Modifier.size(14.dp),
                            strokeWidth = 2.dp
                        )
                        Spacer(Modifier.width(6.dp))
                        Text(
                            text = "Saving…",
                            style = Typography.bodyMedium,
                            color = FaithFeedColors.TextTertiary,
                            fontSize = 12.sp
                        )
                    }
                }
            }

            // ── Visibility ────────────────────────────────────────────────────
            ProfileSettingsSection(title = "Visibility") {
                ProfileToggleRow(
                    icon = Icons.Outlined.Visibility,
                    label = "Show Activity Status",
                    description = "Let others see when you were last active",
                    checked = uiState.showActivityStatus,
                    onCheckedChange = viewModel::toggleActivityStatus
                )
                ProfileDivider()
                ProfileToggleRow(
                    icon = Icons.Outlined.PersonAdd,
                    label = "Allow Friend Requests",
                    description = "Let others send you connection requests",
                    checked = uiState.allowFriendRequests,
                    onCheckedChange = viewModel::toggleFriendRequests
                )
                ProfileDivider()
                ProfileToggleRow(
                    icon = Icons.Outlined.Search,
                    label = "Appear in Search",
                    description = "Allow others to find your profile by name",
                    checked = uiState.showInSearchResults,
                    onCheckedChange = viewModel::toggleSearchVisibility
                )
            }

            // ── Content Preferences ───────────────────────────────────────────
            ProfileSettingsSection(title = "Content Preferences") {
                ProfileInfoRow(
                    icon = Icons.Outlined.Language,
                    label = "Content Language",
                    value = uiState.contentLanguage
                )
                ProfileDivider()
                ProfileInfoRow(
                    icon = Icons.Outlined.FilterList,
                    label = "Feed Content Filter",
                    value = uiState.feedContentFilter
                )
                ProfileDivider()
                ProfileInfoRow(
                    icon = Icons.Outlined.Home,
                    label = "Home Church",
                    value = "Not set"
                )
            }

            // ── Faith Interests ───────────────────────────────────────────────
            ProfileSettingsSection(title = "Faith Interests") {
                ProfileInfoRow(
                    icon = Icons.Outlined.BookmarkBorder,
                    label = "Topics",
                    value = "Manage topics"
                )
                ProfileDivider()
                ProfileInfoRow(
                    icon = Icons.AutoMirrored.Outlined.MenuBook,
                    label = "Reading Plan",
                    value = "Not enrolled"
                )
            }

            Spacer(Modifier.height(32.dp))
        }
    }
}

// ── Privacy Row ───────────────────────────────────────────────────────────────

@Composable
private fun PrivacyRow(
    icon: ImageVector,
    label: String,
    current: String,
    onLevelSelected: (String) -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 10.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = FaithFeedColors.GoldAccent,
                modifier = Modifier.size(18.dp)
            )
            Spacer(Modifier.width(8.dp))
            Text(
                text = label,
                style = Typography.bodyMedium,
                color = FaithFeedColors.TextPrimary
            )
        }
        Spacer(Modifier.height(8.dp))
        VisibilitySelector(current = current, onLevelSelected = onLevelSelected)
    }
}

// ── VisibilitySelector ────────────────────────────────────────────────────────

@Composable
private fun VisibilitySelector(current: String, onLevelSelected: (String) -> Unit) {
    Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
        ProfilePrivacy.LEVEL_LABELS.forEach { (key, label) ->
            val isSelected = current == key
            Surface(
                onClick = { onLevelSelected(key) },
                shape = RoundedCornerShape(16.dp),
                color = if (isSelected) FaithFeedColors.GoldAccent else Color.Transparent,
                border = if (!isSelected) BorderStroke(1.dp, FaithFeedColors.GlassBorder) else null,
                modifier = Modifier.height(28.dp)
            ) {
                Text(
                    text = label,
                    fontSize = 11.sp,
                    color = if (isSelected) FaithFeedColors.BackgroundPrimary else FaithFeedColors.TextTertiary,
                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                )
            }
        }
    }
}

// ── Section container ─────────────────────────────────────────────────────────

@Composable
private fun ProfileSettingsSection(
    title: String,
    content: @Composable ColumnScope.() -> Unit
) {
    Column {
        Text(
            text = title.uppercase(),
            style = Typography.labelLarge,
            color = FaithFeedColors.GoldAccent,
            modifier = Modifier.padding(horizontal = 4.dp, vertical = 8.dp)
        )
        Surface(
            color = FaithFeedColors.BackgroundSecondary,
            shape = RoundedCornerShape(12.dp),
            modifier = Modifier
                .fillMaxWidth()
                .border(1.dp, FaithFeedColors.GlassBorder, RoundedCornerShape(12.dp))
        ) {
            Column(modifier = Modifier.padding(vertical = 4.dp), content = content)
        }
    }
}

// ── Toggle row ────────────────────────────────────────────────────────────────

@Composable
private fun ProfileToggleRow(
    icon: ImageVector,
    label: String,
    description: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = FaithFeedColors.GoldAccent,
            modifier = Modifier.size(20.dp)
        )
        Spacer(Modifier.width(12.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(text = label, style = Typography.bodyMedium, color = FaithFeedColors.TextPrimary)
            Text(
                text = description,
                style = Typography.bodyMedium.copy(fontSize = 12.sp),
                color = FaithFeedColors.TextTertiary
            )
        }
        Spacer(Modifier.width(8.dp))
        Switch(
            checked = checked,
            onCheckedChange = onCheckedChange,
            colors = SwitchDefaults.colors(
                checkedThumbColor = FaithFeedColors.GoldAccent,
                checkedTrackColor = FaithFeedColors.GoldAccent.copy(alpha = 0.3f),
                uncheckedThumbColor = FaithFeedColors.TextTertiary,
                uncheckedTrackColor = FaithFeedColors.GlassBorder
            )
        )
    }
}

// ── Info row ──────────────────────────────────────────────────────────────────

@Composable
private fun ProfileInfoRow(icon: ImageVector, label: String, value: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = FaithFeedColors.GoldAccent,
            modifier = Modifier.size(20.dp)
        )
        Spacer(Modifier.width(12.dp))
        Text(
            text = label,
            style = Typography.bodyMedium,
            color = FaithFeedColors.TextPrimary,
            modifier = Modifier.weight(1f)
        )
        Text(text = value, style = Typography.bodyMedium, color = FaithFeedColors.TextTertiary)
    }
}

// ── Divider ───────────────────────────────────────────────────────────────────

@Composable
private fun ProfileDivider() {
    HorizontalDivider(
        color = FaithFeedColors.GlassBorder,
        thickness = 0.5.dp,
        modifier = Modifier.padding(horizontal = 16.dp)
    )
}
