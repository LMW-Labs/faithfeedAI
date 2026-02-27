package com.faithfeed.app.ui.screens.settings

import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
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
import androidx.compose.material.icons.automirrored.outlined.Logout
import androidx.compose.material.icons.outlined.ChatBubbleOutline
import androidx.compose.material.icons.outlined.Email
import androidx.compose.material.icons.outlined.Group
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material.icons.outlined.MailOutline
import androidx.compose.material.icons.outlined.Notifications
import androidx.compose.material.icons.outlined.Public
import androidx.compose.material.icons.outlined.VolunteerActivism
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavController
import com.faithfeed.app.ui.components.SimpleTopBar
import com.faithfeed.app.ui.theme.FaithFeedColors
import com.faithfeed.app.ui.theme.Typography

private val SignOutRed = Color(0xFFFF6B6B)

@Composable
fun AccountSettingsScreen(
    navController: NavController,
    onLogout: () -> Unit,
    viewModel: AccountSettingsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()

    Scaffold(
        containerColor = FaithFeedColors.BackgroundPrimary,
        topBar = {
            SimpleTopBar(title = "Account Settings", onBack = { navController.popBackStack() })
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
            // Account section
            SettingsSection(title = "Account") {
                SettingsInfoRow(
                    icon = Icons.Outlined.Email,
                    label = "Email",
                    value = uiState.email.ifBlank { "Not available" }
                )
                SettingsDivider()
                SettingsInfoRow(
                    icon = Icons.Outlined.Lock,
                    label = "Password",
                    value = "Change password"
                )
            }

            // Notifications section
            SettingsSection(title = "Notifications") {
                SettingsToggleRow(
                    icon = Icons.Outlined.Notifications,
                    label = "Push Notifications",
                    checked = uiState.pushNotificationsEnabled,
                    onCheckedChange = viewModel::togglePushNotifications
                )
                SettingsDivider()
                SettingsToggleRow(
                    icon = Icons.Outlined.VolunteerActivism,
                    label = "Prayer Replies",
                    checked = uiState.prayerNotificationsEnabled,
                    onCheckedChange = viewModel::togglePrayerNotifications
                )
                SettingsDivider()
                SettingsToggleRow(
                    icon = Icons.Outlined.ChatBubbleOutline,
                    label = "Comments",
                    checked = uiState.commentNotificationsEnabled,
                    onCheckedChange = viewModel::toggleCommentNotifications
                )
                SettingsDivider()
                SettingsToggleRow(
                    icon = Icons.Outlined.MailOutline,
                    label = "Messages",
                    checked = uiState.messageNotificationsEnabled,
                    onCheckedChange = viewModel::toggleMessageNotifications
                )
            }

            // Privacy section
            SettingsSection(title = "Privacy") {
                SettingsInfoRow(
                    icon = Icons.Outlined.Public,
                    label = "Profile Visibility",
                    value = "Public"
                )
                SettingsDivider()
                SettingsInfoRow(
                    icon = Icons.Outlined.Group,
                    label = "Post Visibility",
                    value = "Friends"
                )
            }

            // Danger zone
            SettingsSection(title = "Danger Zone") {
                if (uiState.isSigningOut) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator(
                            color = FaithFeedColors.GoldAccent,
                            modifier = Modifier.size(32.dp)
                        )
                    }
                } else {
                    TextButton(
                        onClick = { viewModel.signOut(onLogout) },
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(8.dp)
                    ) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Outlined.Logout,
                            contentDescription = "Sign Out",
                            tint = SignOutRed
                        )
                        Spacer(Modifier.width(8.dp))
                        Text(
                            text = "Sign Out",
                            style = Typography.titleLarge.copy(
                                fontSize = androidx.compose.ui.unit.TextUnit(
                                    16f,
                                    androidx.compose.ui.unit.TextUnitType.Sp
                                ),
                                fontWeight = FontWeight.Bold
                            ),
                            color = SignOutRed
                        )
                    }
                }
            }

            Spacer(Modifier.height(32.dp))
        }
    }
}

@Composable
private fun SettingsSection(
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

@Composable
private fun SettingsToggleRow(
    icon: ImageVector,
    label: String,
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
        Text(
            text = label,
            style = Typography.bodyMedium,
            color = FaithFeedColors.TextPrimary,
            modifier = Modifier.weight(1f)
        )
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

@Composable
private fun SettingsInfoRow(
    icon: ImageVector,
    label: String,
    value: String
) {
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
        Text(
            text = value,
            style = Typography.bodyMedium,
            color = FaithFeedColors.TextTertiary
        )
    }
}

@Composable
private fun SettingsDivider() {
    HorizontalDivider(
        color = FaithFeedColors.GlassBorder,
        thickness = 0.5.dp,
        modifier = Modifier.padding(horizontal = 16.dp)
    )
}
