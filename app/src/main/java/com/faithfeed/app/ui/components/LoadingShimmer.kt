package com.faithfeed.app.ui.components

import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.unit.dp
import com.faithfeed.app.ui.theme.FaithFeedColors

@Composable
fun shimmerBrush(): Brush {
    val shimmerColors = listOf(
        FaithFeedColors.GlassBackground,
        FaithFeedColors.GlassBorder,
        FaithFeedColors.GlassBackground
    )
    val transition = rememberInfiniteTransition(label = "shimmer")
    val translateAnim by transition.animateFloat(
        initialValue = 0f,
        targetValue = 1000f,
        animationSpec = infiniteRepeatable(
            animation = tween(1200, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "shimmerAnim"
    )
    return Brush.linearGradient(
        colors = shimmerColors,
        start = Offset.Zero,
        end = Offset(translateAnim, translateAnim)
    )
}

@Composable
fun PostCardShimmer() {
    val brush = shimmerBrush()
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp)
    ) {
        Box(
            modifier = Modifier
                .height(200.dp)
                .fillMaxWidth()
                .clip(RoundedCornerShape(16.dp))
                .background(brush)
        )
        Spacer(Modifier.height(12.dp))
        Box(
            modifier = Modifier
                .height(16.dp)
                .fillMaxWidth(0.7f)
                .clip(RoundedCornerShape(8.dp))
                .background(brush)
        )
        Spacer(Modifier.height(8.dp))
        Box(
            modifier = Modifier
                .height(12.dp)
                .fillMaxWidth(0.5f)
                .clip(RoundedCornerShape(8.dp))
                .background(brush)
        )
    }
}
