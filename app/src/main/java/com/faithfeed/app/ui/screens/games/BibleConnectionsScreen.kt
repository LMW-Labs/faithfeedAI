package com.faithfeed.app.ui.screens.games

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavController
import com.faithfeed.app.ui.components.ButtonStyle
import com.faithfeed.app.ui.components.FaithFeedButton
import com.faithfeed.app.ui.components.SimpleTopBar
import com.faithfeed.app.ui.theme.FaithFeedColors
import com.faithfeed.app.ui.theme.Typography

@Composable
fun BibleConnectionsScreen(
    navController: NavController,
    viewModel: BibleConnectionsViewModel = hiltViewModel()
) {
    val boardWords by viewModel.boardWords.collectAsStateWithLifecycle()
    val selectedWords by viewModel.selectedWords.collectAsStateWithLifecycle()
    val foundGroups by viewModel.foundGroups.collectAsStateWithLifecycle()
    val mistakesRemaining by viewModel.mistakesRemaining.collectAsStateWithLifecycle()
    val gameStatus by viewModel.gameStatus.collectAsStateWithLifecycle()

    Scaffold(
        containerColor = FaithFeedColors.BackgroundPrimary,
        topBar = {
            SimpleTopBar(title = "Bible Connections", onBack = { navController.popBackStack() })
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = "Create four groups of four!",
                style = Typography.titleMedium,
                color = FaithFeedColors.TextPrimary
            )
            Spacer(modifier = Modifier.height(24.dp))

            // Found Groups
            foundGroups.forEach { group ->
                Surface(
                    color = Color(android.graphics.Color.parseColor(group.difficultyColor)),
                    shape = RoundedCornerShape(8.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(bottom = 8.dp)
                        .height(80.dp)
                ) {
                    Column(
                        modifier = Modifier.fillMaxSize(),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.Center
                    ) {
                        Text(
                            text = group.theme.uppercase(),
                            style = Typography.titleSmall.copy(fontWeight = FontWeight.Bold),
                            color = Color.Black
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = group.words.joinToString(", ").uppercase(),
                            style = Typography.labelMedium,
                            color = Color.Black.copy(alpha = 0.8f)
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            // Active Board
            LazyVerticalGrid(
                columns = GridCells.Fixed(4),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                items(boardWords, key = { it }) { word ->
                    val isSelected = selectedWords.contains(word)
                    Surface(
                        color = if (isSelected) FaithFeedColors.TextTertiary else FaithFeedColors.BackgroundSecondary,
                        shape = RoundedCornerShape(8.dp),
                        modifier = Modifier
                            .aspectRatio(1.2f)
                            .clickable(enabled = gameStatus == "PLAYING") {
                                viewModel.toggleWordSelection(word)
                            }
                    ) {
                        Box(contentAlignment = Alignment.Center) {
                            Text(
                                text = word.uppercase(),
                                style = Typography.labelMedium.copy(fontWeight = FontWeight.Bold),
                                color = if (isSelected) FaithFeedColors.BackgroundPrimary else FaithFeedColors.TextPrimary,
                                textAlign = TextAlign.Center,
                                modifier = Modifier.padding(4.dp)
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.weight(1f))

            if (gameStatus == "PLAYING") {
                // Mistakes indicator
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = "Mistakes remaining:",
                        style = Typography.bodyMedium,
                        color = FaithFeedColors.TextSecondary
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                        repeat(4) { index ->
                            Box(
                                modifier = Modifier
                                    .size(12.dp)
                                    .clip(CircleShape)
                                    .background(if (index < mistakesRemaining) FaithFeedColors.GoldAccent else FaithFeedColors.GlassBorder)
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(24.dp))

                // Action Buttons
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceEvenly
                ) {
                    OutlinedButton(
                        onClick = { viewModel.shuffleBoard() },
                        colors = ButtonDefaults.outlinedButtonColors(contentColor = FaithFeedColors.TextPrimary)
                    ) {
                        Text("Shuffle")
                    }
                    OutlinedButton(
                        onClick = { viewModel.deselectAll() },
                        enabled = selectedWords.isNotEmpty(),
                        colors = ButtonDefaults.outlinedButtonColors(contentColor = FaithFeedColors.TextPrimary)
                    ) {
                        Text("Deselect")
                    }
                    FaithFeedButton(
                        text = "Submit",
                        onClick = { viewModel.submitSelection() },
                        style = ButtonStyle.Primary,
                        enabled = selectedWords.size == 4,
                        modifier = Modifier.width(120.dp)
                    )
                }
            } else {
                // Game Over State
                Text(
                    text = if (gameStatus == "WON") "Great Job!" else "Better luck next time!",
                    style = Typography.titleLarge.copy(fontWeight = FontWeight.Bold),
                    color = if (gameStatus == "WON") Color(0xFF4CAF50) else FaithFeedColors.GoldAccent
                )
                Spacer(modifier = Modifier.height(24.dp))
                FaithFeedButton(
                    text = "Play Again",
                    onClick = { viewModel.restart() },
                    style = ButtonStyle.Primary,
                    modifier = Modifier.fillMaxWidth(0.6f)
                )
            }
            
            Spacer(modifier = Modifier.height(32.dp))
        }
    }
}
