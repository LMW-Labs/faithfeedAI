package com.faithfeed.app.ui.theme

import android.app.Activity
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

private val DarkColorScheme = darkColorScheme(
    primary = FaithFeedColors.GoldAccent,
    secondary = FaithFeedColors.PurpleDark,
    tertiary = FaithFeedColors.IndigoDark,
    background = FaithFeedColors.BackgroundPrimary,
    surface = FaithFeedColors.BackgroundSecondary,
    onPrimary = FaithFeedColors.BackgroundPrimary,
    onSecondary = FaithFeedColors.TextPrimary,
    onTertiary = FaithFeedColors.TextPrimary,
    onBackground = FaithFeedColors.TextPrimary,
    onSurface = FaithFeedColors.TextPrimary,
)

@Composable
fun FaithFeedTheme(content: @Composable () -> Unit) {
    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            // enableEdgeToEdge() in MainActivity manages bar colors; only set icon appearance here
            WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = false
            WindowCompat.getInsetsController(window, view).isAppearanceLightNavigationBars = false
        }
    }

    MaterialTheme(
        colorScheme = DarkColorScheme,
        typography = Typography,
        content = content
    )
}
