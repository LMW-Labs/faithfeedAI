package com.faithfeed.app.ui.screens.explore

import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavController
import com.faithfeed.app.ui.components.SimpleTopBar
import com.faithfeed.app.ui.theme.FaithFeedColors
import com.faithfeed.app.ui.theme.Nunito
import com.faithfeed.app.ui.theme.Typography

@Composable
fun VerseCommentaryScreen(
    verseRef: String,
    navController: NavController,
    viewModel: VerseCommentaryViewModel = hiltViewModel()
) {
    val commentary by viewModel.commentary.collectAsStateWithLifecycle()
    val isLoading by viewModel.isLoading.collectAsStateWithLifecycle()
    val error by viewModel.error.collectAsStateWithLifecycle()

    LaunchedEffect(verseRef) { viewModel.load(verseRef) }

    Scaffold(
        containerColor = FaithFeedColors.BackgroundPrimary,
        topBar = {
            SimpleTopBar(title = "Commentary", onBack = { navController.popBackStack() })
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(16.dp)
        ) {
            // Verse ref header
            Surface(
                color = FaithFeedColors.PurpleDark,
                shape = RoundedCornerShape(12.dp),
                modifier = Modifier
                    .fillMaxWidth()
                    .border(1.dp, FaithFeedColors.GoldAccent.copy(alpha = 0.5f), RoundedCornerShape(12.dp))
            ) {
                Text(
                    text = verseRef,
                    style = Typography.titleLarge.copy(fontWeight = FontWeight.Bold),
                    color = FaithFeedColors.GoldAccent,
                    modifier = Modifier.padding(horizontal = 20.dp, vertical = 14.dp)
                )
            }

            Spacer(Modifier.height(20.dp))

            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                when {
                    isLoading -> CircularProgressIndicator(color = FaithFeedColors.GoldAccent)
                    error != null -> Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(error!!, style = Typography.bodyMedium, color = FaithFeedColors.TextTertiary)
                        Spacer(Modifier.height(12.dp))
                        TextButton(onClick = { viewModel.load(verseRef) }) {
                            Text("Try Again", color = FaithFeedColors.GoldAccent, style = Typography.labelLarge)
                        }
                    }
                    commentary.isNotEmpty() -> Surface(
                        color = FaithFeedColors.BackgroundSecondary,
                        shape = RoundedCornerShape(16.dp),
                        modifier = Modifier
                            .fillMaxSize()
                            .border(1.dp, FaithFeedColors.GlassBorder, RoundedCornerShape(16.dp))
                    ) {
                        Text(
                            text = commentary,
                            style = Typography.bodyLarge.copy(lineHeight = 28.sp),
                            color = FaithFeedColors.TextPrimary,
                            fontFamily = Nunito,
                            modifier = Modifier
                                .verticalScroll(rememberScrollState())
                                .padding(20.dp)
                        )
                    }
                }
            }
        }
    }
}
