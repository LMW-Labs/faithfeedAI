package com.faithfeed.app.ui.screens.explore

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.GridItemSpan
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.faithfeed.app.navigation.Route
import com.faithfeed.app.ui.components.FaithFeedTopBar
import com.faithfeed.app.ui.theme.FaithFeedColors
import com.faithfeed.app.ui.theme.Typography

data class ExploreItem(
    val title: String,
    val subtitle: String,
    val icon: ImageVector,
    val route: Route
)

@Composable
fun ExploreScreen(
    navController: NavController,
    viewModel: ExploreViewModel = hiltViewModel()
) {
    val aiTools = listOf(
        ExploreItem("AI Study Partner", "Chat with a virtual theologian", Icons.Outlined.ChatBubbleOutline, Route.AIStudyPartner),
        ExploreItem("Devotional", "Custom daily devotionals", Icons.Outlined.AutoAwesome, Route.DevotionalGenerator),
        ExploreItem("Chapter Summary", "AI-powered chapter insights", Icons.Outlined.Summarize, Route.ChapterSummarizer),
        ExploreItem("By Theme", "Browse by spiritual theme", Icons.Outlined.Category, Route.ThematicGuidance),
        ExploreItem("Topical Studies", "Deep-dive topic curricula", Icons.Outlined.School, Route.TopicalStudies),
        ExploreItem("Semantic Search", "Search by meaning & context", Icons.Outlined.Search, Route.SemanticSearch)
    )

    val bibleStudy = listOf(
        ExploreItem("My Notes", "Your verse notes & highlights", Icons.Outlined.EditNote, Route.Notes),
        ExploreItem("A.I. Library", "Saved AI insights", Icons.Outlined.LibraryBooks, Route.AILibrary),
        ExploreItem("Custom Study Plans", "Tailored reading schedules", Icons.Outlined.MenuBook, Route.CustomStudyPlan)
    )

    val games = listOf(
        ExploreItem("The Walk", "Story-driven faith journey", Icons.Outlined.DirectionsWalk, Route.TheWalk),
        ExploreItem("Bible Trivia", "Test your knowledge", Icons.Outlined.Quiz, Route.BibleTrivia),
        ExploreItem("Bible Connections", "Find hidden links", Icons.Outlined.GridView, Route.BibleConnections),
        ExploreItem("Leaderboard", "See top players", Icons.Outlined.Leaderboard, Route.Leaderboard)
    )

    Scaffold(
        containerColor = FaithFeedColors.BackgroundPrimary,
        topBar = {
            FaithFeedTopBar(title = "Explore")
        }
    ) { paddingValues ->
        LazyVerticalGrid(
            columns = GridCells.Fixed(2),
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues),
            contentPadding = PaddingValues(16.dp),
            horizontalArrangement = Arrangement.spacedBy(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            item(span = { GridItemSpan(2) }) {
                SectionHeader("AI Tools")
            }
            items(aiTools) { tool ->
                ExploreCard(item = tool, onClick = { navController.navigate(tool.route) })
            }

            item(span = { GridItemSpan(2) }) {
                SectionHeader("Bible Study")
            }
            items(bibleStudy) { item ->
                ExploreCard(item = item, onClick = { navController.navigate(item.route) })
            }

            item(span = { GridItemSpan(2) }) {
                SectionHeader("Games")
            }
            items(games) { game ->
                ExploreCard(item = game, onClick = { navController.navigate(game.route) })
            }
            
            // Add padding at bottom for nav bar
            item(span = { GridItemSpan(2) }) {
                Spacer(modifier = Modifier.height(80.dp))
            }
        }
    }
}

@Composable
fun SectionHeader(title: String) {
    Text(
        text = title,
        style = Typography.titleLarge.copy(fontWeight = FontWeight.Bold),
        color = FaithFeedColors.TextPrimary,
        modifier = Modifier.padding(top = 8.dp, bottom = 4.dp)
    )
}

@Composable
fun ExploreCard(item: ExploreItem, onClick: () -> Unit) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onClick() }
            .aspectRatio(1f),
        colors = CardDefaults.cardColors(containerColor = FaithFeedColors.BackgroundSecondary),
        shape = RoundedCornerShape(16.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(
                imageVector = item.icon,
                contentDescription = item.title,
                tint = FaithFeedColors.GoldAccent,
                modifier = Modifier.size(40.dp)
            )
            Spacer(modifier = Modifier.height(12.dp))
            Text(
                text = item.title,
                style = Typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                color = FaithFeedColors.TextPrimary,
                textAlign = androidx.compose.ui.text.style.TextAlign.Center
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = item.subtitle,
                style = Typography.bodySmall,
                color = FaithFeedColors.TextSecondary,
                textAlign = androidx.compose.ui.text.style.TextAlign.Center,
                maxLines = 2
            )
        }
    }
}