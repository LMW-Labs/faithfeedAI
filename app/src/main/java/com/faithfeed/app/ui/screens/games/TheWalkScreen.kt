package com.faithfeed.app.ui.screens.games

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontStyle
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
fun TheWalkScreen(
    navController: NavController,
    viewModel: TheWalkViewModel = hiltViewModel()
) {
    val state by viewModel.state.collectAsStateWithLifecycle()

    Scaffold(
        containerColor = FaithFeedColors.BackgroundPrimary,
        topBar = {
            SimpleTopBar(title = "The Walk", onBack = { navController.popBackStack() })
        }
    ) { padding ->
        AnimatedContent(
            targetState = state.isComplete,
            transitionSpec = { fadeIn() togetherWith fadeOut() },
            modifier = Modifier
                .fillMaxSize()
                .padding(padding),
            label = "walk_content"
        ) { isComplete ->
            if (isComplete) {
                EndingScreen(
                    state = state,
                    tierLabel = viewModel.tierLabel(state.faithPoints),
                    onRestart = { viewModel.restart() }
                )
            } else {
                SceneScreen(
                    state = state,
                    onChoice = { viewModel.onChoiceSelected(it) },
                    onToggleScripture = { viewModel.onToggleScripture() }
                )
            }
        }
    }
}

@Composable
private fun SceneScreen(
    state: TheWalkState,
    onChoice: (StoryChoice) -> Unit,
    onToggleScripture: () -> Unit
) {
    val scene = state.currentScene

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Faith points chip
        Surface(
            color = FaithFeedColors.BackgroundSecondary,
            shape = RoundedCornerShape(20.dp),
            modifier = Modifier.border(1.dp, FaithFeedColors.GoldAccent.copy(alpha = 0.4f), RoundedCornerShape(20.dp))
        ) {
            Text(
                text = "Faith Points: ${state.faithPoints}",
                style = Typography.labelMedium,
                color = FaithFeedColors.GoldAccent,
                modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
            )
        }

        Spacer(Modifier.height(32.dp))

        Text(text = scene.emoji, fontSize = 56.sp)
        Spacer(Modifier.height(16.dp))

        Text(
            text = scene.title,
            style = Typography.headlineMedium.copy(fontWeight = FontWeight.Bold),
            color = FaithFeedColors.TextPrimary,
            textAlign = TextAlign.Center
        )
        Spacer(Modifier.height(20.dp))

        // Narrative
        Surface(
            color = FaithFeedColors.BackgroundSecondary,
            shape = RoundedCornerShape(16.dp),
            modifier = Modifier.fillMaxWidth()
        ) {
            Text(
                text = scene.text,
                style = Typography.bodyLarge.copy(lineHeight = 28.sp),
                color = FaithFeedColors.TextSecondary,
                modifier = Modifier.padding(20.dp)
            )
        }

        // Scripture toggle
        if (scene.scripture != null) {
            Spacer(Modifier.height(8.dp))
            TextButton(onClick = onToggleScripture) {
                Text(
                    text = if (state.showScripture) "Hide ${scene.scripture.ref}" else "Show ${scene.scripture.ref}",
                    style = Typography.labelMedium,
                    color = FaithFeedColors.GoldAccent
                )
            }
            if (state.showScripture) {
                Surface(
                    color = FaithFeedColors.PurpleDark.copy(alpha = 0.6f),
                    shape = RoundedCornerShape(16.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .border(1.dp, FaithFeedColors.GoldAccent.copy(alpha = 0.3f), RoundedCornerShape(16.dp))
                ) {
                    Column(modifier = Modifier.padding(20.dp)) {
                        Text(
                            text = scene.scripture.text,
                            style = Typography.bodyMedium.copy(fontStyle = FontStyle.Italic),
                            color = FaithFeedColors.TextPrimary
                        )
                        Spacer(Modifier.height(8.dp))
                        Text(
                            text = "— ${scene.scripture.ref}",
                            style = Typography.labelSmall,
                            color = FaithFeedColors.GoldAccent
                        )
                    }
                }
            }
        }

        Spacer(Modifier.height(32.dp))

        // Choices
        scene.choices.forEach { choice ->
            FaithFeedButton(
                text = choice.text,
                onClick = { onChoice(choice) },
                style = ButtonStyle.Secondary,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 12.dp)
            )
        }

        Spacer(Modifier.height(32.dp))
    }
}

@Composable
private fun EndingScreen(
    state: TheWalkState,
    tierLabel: String,
    onRestart: () -> Unit
) {
    val scene = state.currentScene
    val tierEmoji = when (tierLabel) {
        "Righteous" -> "\uD83D\uDC51"  // 👑
        "Faithful"  -> "\u2728"         // ✨
        else        -> "\uD83C\uDF31"   // 🌱
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text(text = scene.emoji, fontSize = 64.sp)
        Spacer(Modifier.height(24.dp))

        Text(
            text = scene.title,
            style = Typography.headlineMedium.copy(fontWeight = FontWeight.Bold),
            color = FaithFeedColors.TextPrimary,
            textAlign = TextAlign.Center
        )
        Spacer(Modifier.height(16.dp))

        Text(
            text = scene.text,
            style = Typography.bodyLarge,
            color = FaithFeedColors.TextSecondary,
            textAlign = TextAlign.Center
        )

        if (scene.endingMessage != null) {
            Spacer(Modifier.height(24.dp))
            Surface(
                color = FaithFeedColors.BackgroundSecondary,
                shape = RoundedCornerShape(16.dp),
                modifier = Modifier
                    .fillMaxWidth()
                    .border(1.dp, FaithFeedColors.GoldAccent.copy(alpha = 0.4f), RoundedCornerShape(16.dp))
            ) {
                Text(
                    text = "\u201C${scene.endingMessage}\u201D",
                    style = Typography.bodyMedium.copy(fontStyle = FontStyle.Italic),
                    color = FaithFeedColors.GoldAccent,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.padding(20.dp)
                )
            }
        }

        Spacer(Modifier.height(32.dp))

        // Tier badge
        Surface(
            color = FaithFeedColors.PurpleDark,
            shape = RoundedCornerShape(20.dp),
            modifier = Modifier.border(1.dp, FaithFeedColors.GoldAccent, RoundedCornerShape(20.dp))
        ) {
            Row(
                modifier = Modifier.padding(horizontal = 24.dp, vertical = 14.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Text(text = tierEmoji, fontSize = 24.sp)
                Column {
                    Text(
                        text = tierLabel,
                        style = Typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                        color = FaithFeedColors.GoldHighlight
                    )
                    Text(
                        text = "${state.faithPoints} faith points earned",
                        style = Typography.bodySmall,
                        color = FaithFeedColors.TextSecondary
                    )
                }
            }
        }

        Spacer(Modifier.height(48.dp))

        FaithFeedButton(
            text = "Play Again",
            onClick = onRestart,
            style = ButtonStyle.Primary,
            modifier = Modifier.fillMaxWidth()
        )
    }
}
