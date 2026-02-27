package com.faithfeed.app.ui.screens.explore

import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
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
import com.faithfeed.app.data.model.BibleVerse
import com.faithfeed.app.ui.components.SimpleTopBar
import com.faithfeed.app.ui.theme.FaithFeedColors
import com.faithfeed.app.ui.theme.Nunito
import com.faithfeed.app.ui.theme.Typography

@Composable
fun RelatedVersesScreen(
    verseRef: String,
    navController: NavController,
    viewModel: RelatedVersesViewModel = hiltViewModel()
) {
    val relatedVerses by viewModel.relatedVerses.collectAsStateWithLifecycle()
    val isLoading by viewModel.isLoading.collectAsStateWithLifecycle()
    val error by viewModel.error.collectAsStateWithLifecycle()

    LaunchedEffect(verseRef) { viewModel.load(verseRef) }

    Scaffold(
        containerColor = FaithFeedColors.BackgroundPrimary,
        topBar = {
            SimpleTopBar(title = "Related Verses", onBack = { navController.popBackStack() })
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(horizontal = 16.dp, vertical = 12.dp)
        ) {
            // Verse ref chip
            Surface(
                color = FaithFeedColors.PurpleDark,
                shape = RoundedCornerShape(12.dp),
                modifier = Modifier
                    .fillMaxWidth()
                    .border(1.dp, FaithFeedColors.GoldAccent.copy(alpha = 0.5f), RoundedCornerShape(12.dp))
            ) {
                Text(
                    text = "Passages related to $verseRef",
                    style = Typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                    color = FaithFeedColors.GoldAccent,
                    modifier = Modifier.padding(horizontal = 20.dp, vertical = 14.dp)
                )
            }

            Spacer(Modifier.height(16.dp))

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
                    relatedVerses.isEmpty() -> Text(
                        "No related verses found.",
                        style = Typography.bodyMedium,
                        color = FaithFeedColors.TextTertiary
                    )
                    else -> LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        verticalArrangement = Arrangement.spacedBy(12.dp),
                        contentPadding = PaddingValues(bottom = 24.dp)
                    ) {
                        items(relatedVerses, key = { "${it.book}${it.chapter}${it.verse}" }) { verse ->
                            RelatedVerseCard(verse = verse)
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun RelatedVerseCard(verse: BibleVerse) {
    Surface(
        color = FaithFeedColors.BackgroundSecondary,
        shape = RoundedCornerShape(14.dp),
        modifier = Modifier
            .fillMaxWidth()
            .border(1.dp, FaithFeedColors.GlassBorder, RoundedCornerShape(14.dp))
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                text = "${verse.book} ${verse.chapter}:${verse.verse}",
                style = Typography.labelMedium.copy(fontWeight = FontWeight.Bold),
                color = FaithFeedColors.GoldAccent
            )
            Spacer(Modifier.height(8.dp))
            Text(
                text = verse.text,
                style = Typography.bodyMedium.copy(lineHeight = 22.sp),
                color = FaithFeedColors.TextPrimary,
                fontFamily = Nunito
            )
        }
    }
}
