package com.faithfeed.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.faithfeed.app.ui.theme.FaithFeedColors
import com.faithfeed.app.ui.theme.FaithFeedGradients
import com.faithfeed.app.ui.theme.Typography

enum class ButtonStyle { Primary, Secondary, Ghost }

@Composable
fun FaithFeedButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    style: ButtonStyle = ButtonStyle.Primary,
    enabled: Boolean = true
) {
    val shape = RoundedCornerShape(16.dp)
    
    val baseModifier = modifier
        .clip(shape)
        .clickable(enabled = enabled, onClick = onClick)
    
    val styleModifier = when (style) {
        ButtonStyle.Primary -> baseModifier.background(FaithFeedGradients.GoldAccent)
        ButtonStyle.Secondary -> baseModifier
            .background(FaithFeedColors.BackgroundSecondary)
            .border(1.dp, FaithFeedColors.GoldAccent, shape)
        ButtonStyle.Ghost -> baseModifier
    }

    val textColor = when (style) {
        ButtonStyle.Primary -> FaithFeedColors.BackgroundPrimary
        ButtonStyle.Secondary, ButtonStyle.Ghost -> FaithFeedColors.GoldHighlight
    }

    Box(
        modifier = styleModifier.padding(horizontal = 32.dp, vertical = 16.dp),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = text,
            style = Typography.labelLarge.copy(
                fontWeight = FontWeight.Bold,
                color = if (enabled) textColor else textColor.copy(alpha = 0.4f)
            )
        )
    }
}
