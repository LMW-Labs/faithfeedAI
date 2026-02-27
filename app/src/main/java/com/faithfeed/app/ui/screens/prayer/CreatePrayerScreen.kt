package com.faithfeed.app.ui.screens.prayer

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavController
import com.faithfeed.app.ui.components.ButtonStyle
import com.faithfeed.app.ui.components.FaithFeedButton
import com.faithfeed.app.ui.components.SimpleTopBar
import com.faithfeed.app.ui.theme.FaithFeedColors
import com.faithfeed.app.ui.theme.Typography

@Composable
fun CreatePrayerScreen(
    navController: NavController,
    viewModel: CreatePrayerViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()

    Scaffold(
        containerColor = FaithFeedColors.BackgroundPrimary,
        topBar = {
            SimpleTopBar(title = "Add Prayer Request", onBack = { navController.popBackStack() })
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
            // Header copy
            Text(
                text = "Share Your Heart",
                style = Typography.titleLarge.copy(fontWeight = FontWeight.Bold),
                color = FaithFeedColors.TextPrimary
            )
            Text(
                text = "Your request will be lifted up by the FaithFeed community.",
                style = Typography.bodyMedium,
                color = FaithFeedColors.TextSecondary
            )

            Spacer(Modifier.height(4.dp))

            // Title field
            OutlinedTextField(
                value = uiState.title,
                onValueChange = viewModel::onTitleChange,
                label = { Text("Prayer Title", color = FaithFeedColors.TextTertiary) },
                placeholder = { Text("e.g. Healing for my mother...", color = FaithFeedColors.TextTertiary) },
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedTextColor = FaithFeedColors.TextPrimary,
                    unfocusedTextColor = FaithFeedColors.TextPrimary,
                    focusedBorderColor = FaithFeedColors.GoldAccent,
                    unfocusedBorderColor = FaithFeedColors.GlassBorder,
                    focusedLabelColor = FaithFeedColors.GoldAccent,
                    cursorColor = FaithFeedColors.GoldAccent,
                    focusedContainerColor = FaithFeedColors.GlassBackground,
                    unfocusedContainerColor = FaithFeedColors.GlassBackground
                ),
                shape = RoundedCornerShape(12.dp)
            )

            // Content field
            OutlinedTextField(
                value = uiState.content,
                onValueChange = viewModel::onContentChange,
                label = { Text("Prayer Details", color = FaithFeedColors.TextTertiary) },
                placeholder = { Text("Share the details of your prayer request...", color = FaithFeedColors.TextTertiary) },
                minLines = 5,
                maxLines = 10,
                modifier = Modifier.fillMaxWidth(),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedTextColor = FaithFeedColors.TextPrimary,
                    unfocusedTextColor = FaithFeedColors.TextPrimary,
                    focusedBorderColor = FaithFeedColors.GoldAccent,
                    unfocusedBorderColor = FaithFeedColors.GlassBorder,
                    focusedLabelColor = FaithFeedColors.GoldAccent,
                    cursorColor = FaithFeedColors.GoldAccent,
                    focusedContainerColor = FaithFeedColors.GlassBackground,
                    unfocusedContainerColor = FaithFeedColors.GlassBackground
                ),
                shape = RoundedCornerShape(12.dp)
            )

            // Anonymous toggle
            Surface(
                color = FaithFeedColors.BackgroundSecondary,
                shape = RoundedCornerShape(12.dp)
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 12.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = "Post Anonymously",
                            style = Typography.bodyMedium.copy(fontWeight = FontWeight.SemiBold),
                            color = FaithFeedColors.TextPrimary
                        )
                        Text(
                            text = "Your name won't be shown with this request",
                            style = Typography.bodyMedium,
                            color = FaithFeedColors.TextTertiary
                        )
                    }
                    Switch(
                        checked = uiState.isAnonymous,
                        onCheckedChange = viewModel::onAnonymousToggle,
                        colors = SwitchDefaults.colors(
                            checkedThumbColor = FaithFeedColors.GoldAccent,
                            checkedTrackColor = FaithFeedColors.GoldAccent.copy(alpha = 0.3f),
                            uncheckedThumbColor = FaithFeedColors.TextTertiary,
                            uncheckedTrackColor = FaithFeedColors.GlassBorder
                        )
                    )
                }
            }

            // Error
            if (uiState.error != null) {
                Text(
                    text = uiState.error!!,
                    style = Typography.bodyMedium,
                    color = Color(0xFFFF6B6B)
                )
            }

            Spacer(Modifier.height(8.dp))

            // Submit button
            if (uiState.isSubmitting) {
                Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator(color = FaithFeedColors.GoldAccent)
                }
            } else {
                FaithFeedButton(
                    text = "Submit Prayer Request",
                    onClick = { viewModel.submit { navController.popBackStack() } },
                    style = ButtonStyle.Primary,
                    modifier = Modifier.fillMaxWidth()
                )
            }

            Spacer(Modifier.height(32.dp))
        }
    }
}
