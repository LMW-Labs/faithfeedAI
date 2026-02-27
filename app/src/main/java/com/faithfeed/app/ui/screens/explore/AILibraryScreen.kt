package com.faithfeed.app.ui.screens.explore

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.material3.TabRowDefaults.tabIndicatorOffset
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import com.faithfeed.app.ui.components.EmptyState
import com.faithfeed.app.ui.components.SimpleTopBar
import com.faithfeed.app.ui.theme.FaithFeedColors
import com.faithfeed.app.ui.theme.Typography

data class SavedAILibraryItem(
    val id: String,
    val type: String, // "devotional", "summary", "plan"
    val title: String,
    val date: String,
    val previewText: String
)

@Composable
fun AILibraryScreen(navController: NavController) {
    var selectedFilter by remember { mutableStateOf("All") }
    val filters = listOf("All", "Devotionals", "Summaries", "Plans")

    // Mock data to show the UI
    val savedItems = listOf(
        SavedAILibraryItem("1", "devotional", "Devotional: Trusting God", "Oct 12, 2024", "Today's devotional focuses on Proverbs 3:5-6. In our busy lives..."),
        SavedAILibraryItem("2", "summary", "Summary: Genesis Chapter 1", "Oct 10, 2024", "This chapter covers the beginning of creation. God speaks the universe..."),
        SavedAILibraryItem("3", "plan", "7-Day Plan: Leadership in the Bible", "Oct 05, 2024", "Day 1: David's Heart. Read 1 Samuel 16:7 and reflect on...")
    )

    val filteredItems = if (selectedFilter == "All") savedItems else savedItems.filter {
        when (selectedFilter) {
            "Devotionals" -> it.type == "devotional"
            "Summaries" -> it.type == "summary"
            "Plans" -> it.type == "plan"
            else -> true
        }
    }

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
            // Filter Row
            Surface(
                color = FaithFeedColors.BackgroundSecondary,
                modifier = Modifier.fillMaxWidth()
            ) {
                ScrollableTabRow(
                    selectedTabIndex = filters.indexOf(selectedFilter),
                    containerColor = FaithFeedColors.BackgroundSecondary,
                    contentColor = FaithFeedColors.GoldAccent,
                    edgePadding = 16.dp,
                    indicator = { tabPositions ->
                        val index = filters.indexOf(selectedFilter).takeIf { it >= 0 } ?: 0
                        TabRowDefaults.SecondaryIndicator(
                            Modifier.tabIndicatorOffset(tabPositions[index]),
                            color = FaithFeedColors.GoldAccent
                        )
                    }
                ) {
                    filters.forEach { filter ->
                        Tab(
                            selected = selectedFilter == filter,
                            onClick = { selectedFilter = filter },
                            text = { 
                                Text(
                                    filter, 
                                    color = if (selectedFilter == filter) FaithFeedColors.GoldAccent else FaithFeedColors.TextSecondary 
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
                        subtitle = "When you save AI generations, they will appear here."
                    )
                } else {
                    LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(16.dp),
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        items(filteredItems, key = { it.id }) { item ->
                            LibraryItemCard(item = item, onClick = { /* TODO: Navigate to detail view */ })
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun LibraryItemCard(item: SavedAILibraryItem, onClick: () -> Unit) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onClick() },
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
                        imageVector = when (item.type) {
                            "devotional" -> Icons.Outlined.AutoAwesome
                            "summary" -> Icons.Outlined.Summarize
                            "plan" -> Icons.Outlined.CalendarMonth
                            else -> Icons.Outlined.LibraryBooks
                        },
                        contentDescription = null,
                        tint = FaithFeedColors.GoldAccent,
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = item.type.replaceFirstChar { it.uppercase() },
                        style = Typography.labelSmall.copy(fontWeight = FontWeight.Bold),
                        color = FaithFeedColors.GoldAccent
                    )
                }
                Text(
                    text = item.date,
                    style = Typography.bodySmall,
                    color = FaithFeedColors.TextTertiary
                )
            }
            
            Spacer(modifier = Modifier.height(12.dp))
            
            Text(
                text = item.title,
                style = Typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                color = FaithFeedColors.TextPrimary
            )
            
            Spacer(modifier = Modifier.height(4.dp))
            
            Text(
                text = item.previewText,
                style = Typography.bodyMedium,
                color = FaithFeedColors.TextSecondary,
                maxLines = 2,
                overflow = androidx.compose.ui.text.style.TextOverflow.Ellipsis
            )
        }
    }
}
