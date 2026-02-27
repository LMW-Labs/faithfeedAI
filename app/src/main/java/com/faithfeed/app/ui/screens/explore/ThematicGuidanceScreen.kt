package com.faithfeed.app.ui.screens.explore

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Lightbulb
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
import com.faithfeed.app.ui.components.EmptyState
import com.faithfeed.app.ui.components.SimpleTopBar
import com.faithfeed.app.ui.theme.FaithFeedColors
import com.faithfeed.app.ui.theme.Nunito
import com.faithfeed.app.ui.theme.Typography

@Composable
fun ThematicGuidanceScreen(
    navController: NavController,
    viewModel: ThematicGuidanceViewModel = hiltViewModel()
) {
    val selectedTheme by viewModel.selectedTheme.collectAsStateWithLifecycle()
    val guidance by viewModel.guidance.collectAsStateWithLifecycle()
    val isLoading by viewModel.isLoading.collectAsStateWithLifecycle()
    
    var inputText by remember { mutableStateOf("") }
    val focusManager = LocalFocusManager.current

    val suggestedThemes = listOf(
        "Anxiety", "Forgiveness", "Leadership", "Marriage", "Patience", "Hope", "Grief"
    )

    Scaffold(
        containerColor = FaithFeedColors.BackgroundPrimary,
        topBar = {
            SimpleTopBar(title = "Thematic Guidance", onBack = { navController.popBackStack() })
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
                    OutlinedTextField(
                        value = inputText,
                        onValueChange = { inputText = it },
                        modifier = Modifier.fillMaxWidth(),
                        placeholder = { Text("Enter a topic (e.g., handling anger)") },
                        keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
                        keyboardActions = KeyboardActions(
                            onSearch = {
                                focusManager.clearFocus()
                                viewModel.onThemeSelect(inputText)
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
                    
                    Text(
                        text = "Suggested Themes",
                        style = Typography.labelMedium,
                        color = FaithFeedColors.TextTertiary
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    LazyRow(
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        items(suggestedThemes) { theme ->
                            Surface(
                                color = if (theme.equals(selectedTheme, ignoreCase = true)) FaithFeedColors.GoldAccent else FaithFeedColors.GlassBackground,
                                shape = RoundedCornerShape(16.dp),
                                modifier = Modifier.clickable {
                                    inputText = theme
                                    focusManager.clearFocus()
                                    viewModel.onThemeSelect(theme)
                                }
                            ) {
                                Text(
                                    text = theme,
                                    style = Typography.bodyMedium.copy(
                                        color = if (theme.equals(selectedTheme, ignoreCase = true)) FaithFeedColors.BackgroundPrimary else FaithFeedColors.TextSecondary,
                                        fontWeight = FontWeight.Bold
                                    ),
                                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
                                )
                            }
                        }
                    }
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
                } else if (guidance.isEmpty()) {
                    EmptyState(
                        icon = Icons.Outlined.Lightbulb,
                        title = "Thematic Guidance",
                        subtitle = "Select a theme or search a topic to see what the Bible says about it."
                    )
                } else {
                    LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        items(guidance, key = { it.id.ifEmpty { it.content.hashCode().toString() } }) { message ->
                            Card(
                                modifier = Modifier.fillMaxWidth(),
                                colors = CardDefaults.cardColors(containerColor = FaithFeedColors.BackgroundSecondary),
                                shape = RoundedCornerShape(16.dp)
                            ) {
                                Column(modifier = Modifier.padding(20.dp)) {
                                    Text(
                                        text = selectedTheme.uppercase(),
                                        style = Typography.labelSmall.copy(fontWeight = FontWeight.Bold, letterSpacing = 1.sp),
                                        color = FaithFeedColors.GoldAccent
                                    )
                                    Spacer(modifier = Modifier.height(12.dp))
                                    Text(
                                        text = message.content,
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
    }
}
