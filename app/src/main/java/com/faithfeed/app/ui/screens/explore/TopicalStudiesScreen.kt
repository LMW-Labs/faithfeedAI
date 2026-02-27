package com.faithfeed.app.ui.screens.explore

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Topic
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
fun TopicalStudiesScreen(
    navController: NavController,
    viewModel: TopicalStudiesViewModel = hiltViewModel()
) {
    val topic by viewModel.topic.collectAsStateWithLifecycle()
    val studyPlan by viewModel.studyPlan.collectAsStateWithLifecycle()
    val isLoading by viewModel.isLoading.collectAsStateWithLifecycle()
    
    var inputText by remember { mutableStateOf("") }
    val focusManager = LocalFocusManager.current

    Scaffold(
        containerColor = FaithFeedColors.BackgroundPrimary,
        topBar = {
            SimpleTopBar(title = "Topical Studies", onBack = { navController.popBackStack() })
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
                        text = "Create a 7-Day Study Plan",
                        style = Typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                        color = FaithFeedColors.TextPrimary
                    )
                    Spacer(modifier = Modifier.height(12.dp))
                    OutlinedTextField(
                        value = inputText,
                        onValueChange = { inputText = it },
                        modifier = Modifier.fillMaxWidth(),
                        placeholder = { Text("Enter a topic (e.g., The Miracles of Jesus)") },
                        keyboardOptions = KeyboardOptions(imeAction = ImeAction.Done),
                        keyboardActions = KeyboardActions(
                            onDone = {
                                focusManager.clearFocus()
                                viewModel.generateStudy(inputText)
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
                        shape = RoundedCornerShape(12.dp),
                        singleLine = true
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    FaithFeedButton(
                        text = "Generate Study",
                        onClick = {
                            focusManager.clearFocus()
                            viewModel.generateStudy(inputText)
                        },
                        style = ButtonStyle.Primary,
                        modifier = Modifier.fillMaxWidth(),
                        enabled = inputText.isNotBlank() && !isLoading
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
                } else if (studyPlan.isEmpty()) {
                    EmptyState(
                        icon = Icons.Outlined.Topic,
                        title = "Topical Studies",
                        subtitle = "Enter any topic to receive a structured, multi-day Bible study plan."
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
                                text = "Study Plan: $topic",
                                style = Typography.titleLarge.copy(fontWeight = FontWeight.Bold),
                                color = FaithFeedColors.GoldAccent
                            )
                            Spacer(modifier = Modifier.height(16.dp))
                            Text(
                                text = studyPlan,
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
