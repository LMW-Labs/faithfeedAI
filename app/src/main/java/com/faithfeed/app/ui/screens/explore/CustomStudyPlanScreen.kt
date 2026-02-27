package com.faithfeed.app.ui.screens.explore

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.CalendarMonth
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
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
fun CustomStudyPlanScreen(
    navController: NavController,
    viewModel: CustomStudyPlanViewModel = hiltViewModel()
) {
    val topic by viewModel.topic.collectAsStateWithLifecycle()
    val durationDays by viewModel.durationDays.collectAsStateWithLifecycle()
    val plan by viewModel.plan.collectAsStateWithLifecycle()
    val isLoading by viewModel.isLoading.collectAsStateWithLifecycle()
    
    val focusManager = LocalFocusManager.current

    Scaffold(
        containerColor = FaithFeedColors.BackgroundPrimary,
        topBar = {
            SimpleTopBar(title = "Custom Study Plan", onBack = { navController.popBackStack() })
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
                        text = "Design Your Custom Plan",
                        style = Typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                        color = FaithFeedColors.TextPrimary
                    )
                    Spacer(modifier = Modifier.height(12.dp))
                    
                    OutlinedTextField(
                        value = topic,
                        onValueChange = viewModel::onTopicChange,
                        modifier = Modifier.fillMaxWidth(),
                        placeholder = { Text("Topic or Book (e.g., Romans, Leadership)") },
                        keyboardOptions = KeyboardOptions(imeAction = ImeAction.Done),
                        keyboardActions = KeyboardActions(
                            onDone = { focusManager.clearFocus() }
                        ),
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor = FaithFeedColors.GoldAccent,
                            unfocusedBorderColor = FaithFeedColors.GlassBorder,
                            focusedTextColor = FaithFeedColors.TextPrimary,
                            unfocusedTextColor = FaithFeedColors.TextPrimary,
                            focusedContainerColor = FaithFeedColors.GlassBackground,
                            unfocusedContainerColor = FaithFeedColors.GlassBackground
                        ),
                        shape = RoundedCornerShape(12.dp),
                        singleLine = true
                    )
                    
                    Spacer(modifier = Modifier.height(16.dp))
                    
                    Text(
                        text = "Duration: $durationDays Days",
                        style = Typography.bodyMedium,
                        color = FaithFeedColors.TextSecondary
                    )
                    Slider(
                        value = durationDays.toFloat(),
                        onValueChange = { viewModel.onDurationChange(it.toInt()) },
                        valueRange = 3f..90f,
                        steps = 86, // (90-3)-1
                        colors = SliderDefaults.colors(
                            thumbColor = FaithFeedColors.GoldAccent,
                            activeTrackColor = FaithFeedColors.GoldAccent,
                            inactiveTrackColor = FaithFeedColors.GlassBorder
                        )
                    )
                    
                    Spacer(modifier = Modifier.height(16.dp))
                    
                    FaithFeedButton(
                        text = "Generate Plan",
                        onClick = {
                            focusManager.clearFocus()
                            viewModel.generatePlan()
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
                } else if (plan.isEmpty()) {
                    EmptyState(
                        icon = Icons.Outlined.CalendarMonth,
                        title = "Custom Plan",
                        subtitle = "Select a topic and duration to generate a personalized study schedule."
                    )
                } else {
                    Card(
                        modifier = Modifier
                            .fillMaxSize()
                            .verticalScroll(rememberScrollState()),
                        colors = CardDefaults.cardColors(containerColor = FaithFeedColors.BackgroundSecondary),
                        shape = RoundedCornerShape(16.dp)
                    ) {
                        Column(modifier = Modifier.padding(24.dp)) {
                            Text(
                                text = "$durationDays-Day Plan: $topic",
                                style = Typography.titleLarge.copy(fontWeight = FontWeight.Bold),
                                color = FaithFeedColors.GoldAccent
                            )
                            Spacer(modifier = Modifier.height(16.dp))
                            Text(
                                text = plan,
                                style = Typography.bodyLarge.copy(lineHeight = 24.sp),
                                color = FaithFeedColors.TextPrimary,
                                fontFamily = Nunito
                            )
                        }
                    }
                }
            }
        }
    }
}
