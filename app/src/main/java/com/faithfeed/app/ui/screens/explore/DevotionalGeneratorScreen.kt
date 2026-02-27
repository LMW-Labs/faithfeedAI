package com.faithfeed.app.ui.screens.explore

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.AutoAwesome
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavController
import com.faithfeed.app.ui.components.ButtonStyle
import com.faithfeed.app.ui.components.EmptyState
import com.faithfeed.app.ui.components.FaithFeedButton
import com.faithfeed.app.ui.components.SimpleTopBar
import com.faithfeed.app.ui.theme.FaithFeedColors
import com.faithfeed.app.ui.theme.Nunito
import com.faithfeed.app.ui.theme.Typography

@Composable
fun DevotionalGeneratorScreen(
    navController: NavController,
    viewModel: DevotionalGeneratorViewModel = hiltViewModel()
) {
    val devotional by viewModel.devotional.collectAsStateWithLifecycle()
    val isLoading by viewModel.isLoading.collectAsStateWithLifecycle()
    var topic by remember { mutableStateOf("") }
    val focusManager = LocalFocusManager.current

    Scaffold(
        containerColor = FaithFeedColors.BackgroundPrimary,
        topBar = {
            SimpleTopBar(title = "Devotional Generator", onBack = { navController.popBackStack() })
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            Surface(
                color = FaithFeedColors.BackgroundSecondary,
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(
                        text = "What is on your heart today?",
                        style = Typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                        color = FaithFeedColors.TextPrimary
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    OutlinedTextField(
                        value = topic,
                        onValueChange = { topic = it },
                        modifier = Modifier.fillMaxWidth(),
                        placeholder = { Text("e.g., anxiety, trusting God, leadership...") },
                        keyboardOptions = KeyboardOptions(imeAction = ImeAction.Done),
                        keyboardActions = KeyboardActions(
                            onDone = {
                                focusManager.clearFocus()
                                viewModel.generateDevotional(topic)
                            }
                        ),
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor = FaithFeedColors.GoldAccent,
                            unfocusedBorderColor = FaithFeedColors.GlassBorder,
                            focusedTextColor = FaithFeedColors.TextPrimary,
                            unfocusedTextColor = FaithFeedColors.TextPrimary,
                            focusedContainerColor = FaithFeedColors.GlassBackground,
                            unfocusedContainerColor = FaithFeedColors.GlassBackground
                        ),
                        shape = RoundedCornerShape(12.dp)
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    FaithFeedButton(
                        text = "Generate Devotional",
                        onClick = {
                            focusManager.clearFocus()
                            viewModel.generateDevotional(topic)
                        },
                        style = ButtonStyle.Primary,
                        modifier = Modifier.fillMaxWidth(),
                        enabled = topic.isNotBlank() && !isLoading
                    )
                }
            }

            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(16.dp)
            ) {
                if (isLoading) {
                    CircularProgressIndicator(
                        color = FaithFeedColors.GoldAccent,
                        modifier = Modifier.align(Alignment.Center)
                    )
                } else if (devotional.isEmpty()) {
                    EmptyState(
                        icon = Icons.Outlined.AutoAwesome,
                        title = "Devotional Generator",
                        subtitle = "Enter a topic to receive a personalized, AI-generated daily devotional."
                    )
                } else {
                    Card(
                        modifier = Modifier
                            .fillMaxSize()
                            .verticalScroll(rememberScrollState()),
                        colors = CardDefaults.cardColors(containerColor = FaithFeedColors.BackgroundSecondary),
                        shape = RoundedCornerShape(16.dp)
                    ) {
                        Text(
                            text = devotional,
                            style = Typography.bodyLarge.copy(lineHeight = 24.sp),
                            color = FaithFeedColors.TextPrimary,
                            fontFamily = Nunito,
                            modifier = Modifier.padding(24.dp)
                        )
                    }
                }
            }
        }
    }
}
