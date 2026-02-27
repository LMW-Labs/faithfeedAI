package com.faithfeed.app.ui.screens.games

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.outlined.Quiz
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
import com.faithfeed.app.ui.theme.Nunito
import com.faithfeed.app.ui.theme.Typography

@Composable
fun BibleTriviaScreen(
    navController: NavController,
    viewModel: BibleTriviaViewModel = hiltViewModel()
) {
    val questions by viewModel.questions.collectAsStateWithLifecycle()
    val currentIndex by viewModel.currentIndex.collectAsStateWithLifecycle()
    val score by viewModel.score.collectAsStateWithLifecycle()
    val selectedAnswer by viewModel.selectedAnswer.collectAsStateWithLifecycle()
    val isFinished by viewModel.isFinished.collectAsStateWithLifecycle()

    Scaffold(
        containerColor = FaithFeedColors.BackgroundPrimary,
        topBar = {
            SimpleTopBar(title = "Bible Trivia", onBack = { navController.popBackStack() })
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            if (questions.isEmpty()) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator(color = FaithFeedColors.GoldAccent)
                }
            } else if (isFinished) {
                // Results Screen
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(24.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center
                ) {
                    Icon(
                        imageVector = Icons.Outlined.Quiz,
                        contentDescription = "Quiz Complete",
                        tint = FaithFeedColors.GoldAccent,
                        modifier = Modifier.size(80.dp)
                    )
                    Spacer(modifier = Modifier.height(24.dp))
                    Text(
                        text = "Quiz Complete!",
                        style = Typography.headlineMedium.copy(fontWeight = FontWeight.Bold),
                        color = FaithFeedColors.TextPrimary
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    Text(
                        text = "You scored $score out of ${questions.size}",
                        style = Typography.titleLarge,
                        color = FaithFeedColors.TextSecondary
                    )
                    Spacer(modifier = Modifier.height(48.dp))
                    FaithFeedButton(
                        text = "Play Again",
                        onClick = { viewModel.restart() },
                        style = ButtonStyle.Primary,
                        modifier = Modifier.fillMaxWidth()
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    TextButton(onClick = { navController.popBackStack() }) {
                        Text("Back to Explore", color = FaithFeedColors.TextSecondary, style = Typography.labelLarge)
                    }
                }
            } else {
                // Active Question Screen
                val currentQuestion = questions[currentIndex]
                val hasAnswered = selectedAnswer != null
                val progress = (currentIndex.toFloat() / questions.size.toFloat())

                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(16.dp)
                ) {
                    // Progress Bar
                    LinearProgressIndicator(
                        progress = { progress },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(8.dp)
                            .clip(RoundedCornerShape(4.dp)),
                        color = FaithFeedColors.GoldAccent,
                        trackColor = FaithFeedColors.BackgroundSecondary
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    
                    Text(
                        text = "Question ${currentIndex + 1} of ${questions.size}",
                        style = Typography.labelMedium,
                        color = FaithFeedColors.TextTertiary
                    )
                    Spacer(modifier = Modifier.height(24.dp))

                    // Question
                    Text(
                        text = currentQuestion.question,
                        style = Typography.headlineSmall.copy(fontWeight = FontWeight.Bold, lineHeight = 32.sp),
                        color = FaithFeedColors.TextPrimary,
                        fontFamily = Nunito,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.fillMaxWidth()
                    )
                    Spacer(modifier = Modifier.height(32.dp))

                    // Options
                    currentQuestion.options.forEachIndexed { index, option ->
                        val isSelected = selectedAnswer == index
                        val isCorrect = currentQuestion.correctIndex == index
                        
                        val borderColor = when {
                            !hasAnswered -> FaithFeedColors.GlassBorder
                            isSelected && isCorrect -> Color(0xFF4CAF50) // Green
                            isSelected && !isCorrect -> Color(0xFFF44336) // Red
                            !isSelected && isCorrect -> Color(0xFF4CAF50) // Show correct answer
                            else -> FaithFeedColors.GlassBorder
                        }

                        val bgColor = when {
                            !hasAnswered -> FaithFeedColors.BackgroundSecondary
                            isSelected && isCorrect -> Color(0xFF4CAF50).copy(alpha = 0.1f)
                            isSelected && !isCorrect -> Color(0xFFF44336).copy(alpha = 0.1f)
                            !isSelected && isCorrect -> Color(0xFF4CAF50).copy(alpha = 0.1f)
                            else -> FaithFeedColors.BackgroundSecondary
                        }

                        Surface(
                            color = bgColor,
                            shape = RoundedCornerShape(12.dp),
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(bottom = 12.dp)
                                .border(1.dp, borderColor, RoundedCornerShape(12.dp))
                                .clickable(enabled = !hasAnswered) { viewModel.onAnswerSelected(index) }
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(16.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    text = option,
                                    style = Typography.bodyLarge,
                                    color = FaithFeedColors.TextPrimary
                                )
                                
                                if (hasAnswered) {
                                    if (isCorrect) {
                                        Icon(Icons.Default.CheckCircle, contentDescription = "Correct", tint = Color(0xFF4CAF50))
                                    } else if (isSelected) {
                                        Icon(Icons.Default.Close, contentDescription = "Incorrect", tint = Color(0xFFF44336))
                                    }
                                }
                            }
                        }
                    }

                    Spacer(modifier = Modifier.weight(1f))

                    // Feedback and Next Button
                    AnimatedVisibility(
                        visible = hasAnswered,
                        enter = fadeIn(animationSpec = tween(300)),
                        exit = fadeOut(animationSpec = tween(300))
                    ) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text(
                                text = "Reference: ${currentQuestion.verseRef}",
                                style = Typography.bodyMedium,
                                color = FaithFeedColors.TextSecondary,
                                fontStyle = androidx.compose.ui.text.font.FontStyle.Italic
                            )
                            Spacer(modifier = Modifier.height(16.dp))
                            FaithFeedButton(
                                text = if (currentIndex == questions.size - 1) "Finish Quiz" else "Next Question",
                                onClick = { viewModel.onNextQuestion() },
                                style = ButtonStyle.Primary,
                                modifier = Modifier.fillMaxWidth()
                            )
                        }
                    }
                }
            }
        }
    }
}
