package com.faithfeed.app.ui.screens.bible

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavController
import com.faithfeed.app.navigation.Route
import com.faithfeed.app.ui.theme.FaithFeedColors
import com.faithfeed.app.ui.theme.Nunito
import com.faithfeed.app.ui.theme.Typography

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ConcordanceResultsScreen(
    strongsTag: String,
    navController: NavController,
    viewModel: ConcordanceResultsViewModel = hiltViewModel()
) {
    val lexiconEntry by viewModel.lexiconEntry.collectAsStateWithLifecycle()
    val references by viewModel.references.collectAsStateWithLifecycle()
    val isLoading by viewModel.isLoading.collectAsStateWithLifecycle()
    val error by viewModel.error.collectAsStateWithLifecycle()

    LaunchedEffect(strongsTag) { viewModel.load(strongsTag) }

    Scaffold(
        containerColor = FaithFeedColors.BackgroundPrimary,
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = strongsTag,
                        style = Typography.titleMedium,
                        fontFamily = FontFamily.Monospace,
                        color = FaithFeedColors.GoldAccent
                    )
                },
                navigationIcon = {
                    IconButton(onClick = { navController.popBackStack() }) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back", tint = FaithFeedColors.GoldAccent)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = FaithFeedColors.BackgroundSecondary
                )
            )
        }
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding),
            contentPadding = PaddingValues(16.dp)
        ) {
            // Lexicon card
            lexiconEntry?.let { entry ->
                item {
                    Surface(
                        color = FaithFeedColors.BackgroundSecondary,
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Column(modifier = Modifier.padding(16.dp)) {
                            // Lemma + transliteration
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text(
                                    text = entry.lemma,
                                    fontSize = 22.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = FaithFeedColors.TextPrimary
                                )
                                if (entry.transliteration.isNotBlank()) {
                                    Spacer(Modifier.width(8.dp))
                                    Text(
                                        text = entry.transliteration,
                                        fontFamily = Nunito,
                                        fontStyle = FontStyle.Italic,
                                        fontSize = 14.sp,
                                        color = FaithFeedColors.TextSecondary
                                    )
                                }
                            }
                            if (entry.morph.isNotBlank()) {
                                Text(
                                    text = entry.morph,
                                    fontFamily = FontFamily.Monospace,
                                    fontSize = 11.sp,
                                    color = FaithFeedColors.TextTertiary,
                                    modifier = Modifier.padding(top = 2.dp)
                                )
                            }
                            if (entry.gloss.isNotBlank()) {
                                Spacer(Modifier.height(8.dp))
                                Text(
                                    text = entry.gloss,
                                    fontFamily = Nunito,
                                    fontWeight = FontWeight.SemiBold,
                                    fontSize = 15.sp,
                                    color = FaithFeedColors.GoldAccent
                                )
                            }
                            if (entry.definition.isNotBlank()) {
                                Spacer(Modifier.height(8.dp))
                                Text(
                                    text = entry.definition
                                        .replace(Regex("<br\\s*/?>", RegexOption.IGNORE_CASE), "\n")
                                        .replace(Regex("<[^>]+>"), "")
                                        .trim(),
                                    fontFamily = Nunito,
                                    fontSize = 13.sp,
                                    color = FaithFeedColors.TextSecondary
                                )
                            }
                        }
                    }
                    Spacer(Modifier.height(16.dp))
                }
            }

            // Reference count header
            if (!isLoading) {
                item {
                    Text(
                        text = "${references.size} occurrence${if (references.size != 1) "s" else ""}",
                        style = Typography.labelMedium,
                        color = FaithFeedColors.TextTertiary,
                        modifier = Modifier.padding(bottom = 8.dp)
                    )
                }
            }

            // Loading / error states
            if (isLoading) {
                item {
                    Box(Modifier.fillMaxWidth().padding(32.dp), contentAlignment = Alignment.Center) {
                        CircularProgressIndicator(color = FaithFeedColors.GoldAccent)
                    }
                }
            }
            error?.let {
                item {
                    Text(it, color = FaithFeedColors.TextTertiary, modifier = Modifier.padding(16.dp))
                }
            }

            // Reference list
            items(references) { ref ->
                // Parse "Gen 1:1" → book="Gen", chapter=1
                val spaceIdx = ref.lastIndexOf(' ')
                val colonIdx = ref.lastIndexOf(':')
                val book = if (spaceIdx > 0) ref.substring(0, spaceIdx) else ref
                val chapter = if (spaceIdx > 0 && colonIdx > spaceIdx)
                    ref.substring(spaceIdx + 1, colonIdx).toIntOrNull() ?: 1 else 1

                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable {
                            navController.navigate(Route.BibleChapter(book, chapter)) {
                                launchSingleTop = true
                            }
                        }
                        .padding(vertical = 10.dp, horizontal = 4.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = ref,
                        fontFamily = Nunito,
                        fontWeight = FontWeight.SemiBold,
                        fontSize = 14.sp,
                        color = FaithFeedColors.GoldAccent,
                        modifier = Modifier.width(100.dp)
                    )
                }
                HorizontalDivider(color = FaithFeedColors.GlassBorder, thickness = 0.5.dp)
            }

            item { Spacer(Modifier.navigationBarsPadding()) }
        }
    }
}
