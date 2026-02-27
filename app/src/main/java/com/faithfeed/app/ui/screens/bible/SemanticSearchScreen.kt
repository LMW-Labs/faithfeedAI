package com.faithfeed.app.ui.screens.bible

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.outlined.Search
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
import com.faithfeed.app.ui.components.EmptyState
import com.faithfeed.app.ui.components.SimpleTopBar
import com.faithfeed.app.ui.theme.FaithFeedColors
import com.faithfeed.app.ui.theme.Nunito
import com.faithfeed.app.ui.theme.Typography

@Composable
fun SemanticSearchScreen(
    navController: NavController,
    viewModel: SemanticSearchViewModel = hiltViewModel()
) {
    val query by viewModel.query.collectAsStateWithLifecycle()
    val results by viewModel.results.collectAsStateWithLifecycle()
    val isSearching by viewModel.isSearching.collectAsStateWithLifecycle()
    val focusManager = LocalFocusManager.current

    Scaffold(
        containerColor = FaithFeedColors.BackgroundPrimary,
        topBar = {
            SimpleTopBar(title = "AI Bible Search", onBack = { navController.popBackStack() })
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // Search Bar Area
            Surface(
                color = FaithFeedColors.BackgroundSecondary,
                modifier = Modifier.fillMaxWidth()
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    OutlinedTextField(
                        value = query,
                        onValueChange = viewModel::onQueryChange,
                        modifier = Modifier.weight(1f),
                        placeholder = { Text("Ask a question (e.g., 'verses about anxiety')") },
                        keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
                        keyboardActions = KeyboardActions(
                            onSearch = {
                                focusManager.clearFocus()
                                viewModel.search()
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
                        singleLine = true,
                        leadingIcon = {
                            Icon(Icons.Default.Search, contentDescription = "Search", tint = FaithFeedColors.GoldAccent)
                        }
                    )
                }
            }

            if (isSearching) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator(color = FaithFeedColors.GoldAccent)
                }
            } else if (results.isEmpty() && query.isEmpty()) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    EmptyState(
                        icon = Icons.Outlined.Search,
                        title = "Semantic Search",
                        subtitle = "Find verses by meaning, emotion, or topic."
                    )
                }
            } else if (results.isEmpty() && query.isNotEmpty()) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    EmptyState(
                        icon = Icons.Outlined.Search,
                        title = "No Results Found",
                        subtitle = "Try rephrasing your search."
                    )
                }
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    items(results, key = { it.id }) { verse ->
                        Card(
                            modifier = Modifier.fillMaxWidth(),
                            colors = CardDefaults.cardColors(containerColor = FaithFeedColors.BackgroundSecondary),
                            shape = RoundedCornerShape(12.dp)
                        ) {
                            Column(modifier = Modifier.padding(16.dp)) {
                                Text(
                                    text = "${verse.book} ${verse.chapter}:${verse.verse}",
                                    style = Typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                                    color = FaithFeedColors.GoldAccent
                                )
                                Spacer(modifier = Modifier.height(8.dp))
                                Text(
                                    text = verse.text,
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
