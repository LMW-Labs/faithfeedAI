package com.faithfeed.app.ui.theme

import androidx.compose.ui.graphics.Brush

object FaithFeedGradients {
    val PrimaryBackground = Brush.verticalGradient(
        colors = listOf(FaithFeedColors.BackgroundPrimary, FaithFeedColors.PurpleDark, FaithFeedColors.BackgroundPrimary)
    )
    
    val GoldAccent = Brush.horizontalGradient(
        colors = listOf(FaithFeedColors.GoldAccent, FaithFeedColors.GoldHighlight)
    )
    
    val PurpleUndertone = Brush.linearGradient(
        colors = listOf(FaithFeedColors.PurpleDark, FaithFeedColors.IndigoDark)
    )
    
    val GlassOverlay = Brush.linearGradient(
        colors = listOf(FaithFeedColors.GlassBackground, FaithFeedColors.GlassBackground.copy(alpha = 0.02f))
    )
}
