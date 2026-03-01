package com.faithfeed.app.ui.screens.explore

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.AutoAwesome
import androidx.compose.material.icons.outlined.CalendarMonth
import androidx.compose.material.icons.outlined.Delete
import androidx.compose.material.icons.outlined.LibraryBooks
import androidx.compose.material.icons.outlined.Summarize
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.ScrollableTabRow
import androidx.compose.material3.Surface
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRowDefaults
import androidx.compose.material3.TabRowDefaults.tabIndicatorOffset
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavController
import com.faithfeed.app.data.model.AIInteraction
import com.faithfeed.app.ui.components.EmptyState
import com.faithfeed.app.ui.components.SimpleTopBar
import com.faithfeed.app.ui.theme.FaithFeedColors
import com.faithfeed.app.ui.theme.Typography

private val FILTERS = listOf(
    "All" to "all",
    "Devotionals" to "devotional",
    "Summaries" to "summary",
    "Plans" to "study_plan"
)

@Composable
fun AILibraryScreen(
    navController: NavController,
    viewModel: AILibraryViewModel = hiltViewModel()
) {
    val currentFilter by viewModel.filter.collectAsStateWithLifecycle()
    val filteredItems by viewModel.filtered.collectAsStateWithLifecycle()

    val selectedTabIndex = FILTERS.indexOfFirst { it.second == currentFilter }.coerceAtLeast(0)

    Scaffold(
        containerColor = FaithFeedColors.BackgroundPrimary,
        topBar = {
            SimpleTopBar(title = "A.I. Library", onBack = { navController.popBackStack() })
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // Filter tabs
            Surface(
                color = FaithFeedColors.BackgroundSecondary,
                modifier = Modifier.fillMaxWidth()
            ) {
                ScrollableTabRow(
                    selectedTabIndex = selectedTabIndex,
                    containerColor = FaithFeedColors.BackgroundSecondary,
                    contentColor = FaithFeedColors.GoldAccent,
                    edgePadding = 16.dp,
                    indicator = { tabPositions ->
                        if (selectedTabIndex < tabPositions.size) {
                            TabRowDefaults.SecondaryIndicator(
                                Modifier.tabIndicatorOffset(tabPositions[selectedTabIndex]),
                                color = FaithFeedColors.GoldAccent
                            )
                        }
                    }
                ) {
                    FILTERS.forEachIndexed { index, (label, typeKey) ->
                        Tab(
                            selected = selectedTabIndex == index,
                            onClick = { viewModel.setFilter(typeKey) },
                            text = {
                                Text(
                                    label,
                                    color = if (selectedTabIndex == index)
                                        FaithFeedColors.GoldAccent else FaithFeedColors.TextSecondary
                                )
                            }
                        )
                    }
                }
            }

            Box(modifier = Modifier.fillMaxSize()) {
                if (filteredItems.isEmpty()) {
                    EmptyState(
                        icon = Icons.Outlined.LibraryBooks,
                        title = "Library Empty",
                        subtitle = "Generate a devotional, summary, or study plan to save it here."
                    )
                } else {
                    LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(16.dp),
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        items(filteredItems, key = { it.id }) { item ->
                            LibraryItemCard(
                                item = item,
                                onDelete = { viewModel.delete(item.id) }
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun LibraryItemCard(item: AIInteraction, onDelete: () -> Unit) {
    val typeLabel = when (item.type) {
        "devotional" -> "Devotional"
        "summary" -> "Summary"
        "study_plan" -> "Study Plan"
        else -> item.type.replaceFirstChar { it.uppercase() }
    }
    val typeIcon = when (item.type) {
        "devotional" -> Icons.Outlined.AutoAwesome
        "summary" -> Icons.Outlined.Summarize
        "study_plan" -> Icons.Outlined.CalendarMonth
        else -> Icons.Outlined.LibraryBooks
    }
    val dateDisplay = item.createdAt.take(10)

    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = FaithFeedColors.BackgroundSecondary),
        shape = RoundedCornerShape(12.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = typeIcon,
                        contentDescription = null,
                        tint = FaithFeedColors.GoldAccent,
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = typeLabel,
                        style = Typography.labelSmall.copy(fontWeight = FontWeight.Bold),
                        color = FaithFeedColors.GoldAccent
                    )
                }
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = dateDisplay,
                        style = Typography.bodySmall,
                        color = FaithFeedColors.TextTertiary
                    )
                    IconButton(onClick = onDelete, modifier = Modifier.size(32.dp)) {
                        Icon(
                            Icons.Outlined.Delete,
                            contentDescription = "Delete",
                            tint = FaithFeedColors.TextTertiary,
                            modifier = Modifier.size(16.dp)
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            Text(
                text = item.title,
                style = Typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                color = FaithFeedColors.TextPrimary
            )

            Spacer(modifier = Modifier.height(4.dp))

            Text(
                text = item.content,
                style = Typography.bodyMedium,
                color = FaithFeedColors.TextSecondary,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )
        }
    }
}
