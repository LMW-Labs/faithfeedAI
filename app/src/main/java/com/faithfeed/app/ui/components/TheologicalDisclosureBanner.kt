package com.faithfeed.app.ui.components

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.faithfeed.app.data.model.TheologicalLane
import com.faithfeed.app.ui.theme.FaithFeedColors
import com.faithfeed.app.ui.theme.Nunito
import com.faithfeed.app.ui.theme.Typography

// Severity → accent color mapping
private fun severityAccent(severity: String): Color = when (severity) {
    "high"     -> Color(0xFFE53935) // red
    "moderate" -> Color(0xFFFB8C00) // orange
    else       -> Color(0xFFF9A825) // yellow (low)
}

/**
 * Renders a dismissible disclosure card for each detected [TheologicalLane].
 * Appears above the AI response area; each card can be individually dismissed.
 *
 * @param lanes     Lanes detected by `detect_theological_lanes` RPC.
 * @param onDismiss Called with the [TheologicalLane.laneKey] when the user taps ✕.
 */
@Composable
fun TheologicalDisclosureBanner(
    lanes: List<TheologicalLane>,
    onDismiss: (laneKey: String) -> Unit,
    modifier: Modifier = Modifier
) {
    AnimatedVisibility(
        visible = lanes.isNotEmpty(),
        enter = fadeIn() + slideInVertically(initialOffsetY = { -it / 2 }),
        exit  = fadeOut() + slideOutVertically(targetOffsetY = { -it / 2 }),
        modifier = modifier
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 4.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            lanes.forEach { lane ->
                TheologicalDisclosureCard(lane = lane, onDismiss = { onDismiss(lane.laneKey) })
            }
        }
    }
}

@Composable
private fun TheologicalDisclosureCard(
    lane: TheologicalLane,
    onDismiss: () -> Unit
) {
    val accent = severityAccent(lane.severity)
    val shape  = RoundedCornerShape(12.dp)

    Surface(
        color = FaithFeedColors.BackgroundSecondary,
        shape = shape,
        modifier = Modifier
            .fillMaxWidth()
            .border(width = 1.dp, color = accent.copy(alpha = 0.55f), shape = shape)
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 10.dp),
            verticalAlignment = Alignment.Top
        ) {
            // Info icon — colored by severity
            Icon(
                imageVector = Icons.Outlined.Info,
                contentDescription = null,
                tint = accent,
                modifier = Modifier
                    .padding(top = 1.dp)
                    .size(17.dp)
            )
            Spacer(Modifier.width(10.dp))

            // Label + disclosure text
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = lane.label,
                    style = Typography.labelMedium.copy(fontWeight = FontWeight.Bold),
                    color = accent
                )
                if (lane.disclosureText.isNotBlank()) {
                    Spacer(Modifier.height(2.dp))
                    Text(
                        text = lane.disclosureText,
                        style = Typography.bodySmall,
                        color = FaithFeedColors.TextSecondary,
                        fontFamily = Nunito
                    )
                }
            }

            // Dismiss button
            IconButton(
                onClick = onDismiss,
                modifier = Modifier.size(28.dp)
            ) {
                Icon(
                    imageVector = Icons.Outlined.Close,
                    contentDescription = "Dismiss",
                    tint = FaithFeedColors.TextTertiary,
                    modifier = Modifier.size(15.dp)
                )
            }
        }
    }
}
