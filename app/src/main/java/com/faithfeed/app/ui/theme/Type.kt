package com.faithfeed.app.ui.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import com.faithfeed.app.R

val Cinzel = FontFamily(
    Font(R.font.cinzel)
)

val Nunito = FontFamily(
    Font(R.font.nunito)
)

val Typography = Typography(
    displayLarge = TextStyle(
        fontFamily = Cinzel,
        fontWeight = FontWeight.Bold,
        fontSize = 57.sp,
        color = FaithFeedColors.TextPrimary
    ),
    headlineLarge = TextStyle(
        fontFamily = Cinzel,
        fontWeight = FontWeight.SemiBold,
        fontSize = 32.sp,
        color = FaithFeedColors.TextPrimary
    ),
    titleLarge = TextStyle(
        fontFamily = Cinzel,
        fontWeight = FontWeight.Medium,
        fontSize = 22.sp,
        color = FaithFeedColors.TextPrimary
    ),
    bodyLarge = TextStyle(
        fontFamily = Nunito,
        fontWeight = FontWeight.Normal,
        fontSize = 16.sp,
        color = FaithFeedColors.TextSecondary
    ),
    bodyMedium = TextStyle(
        fontFamily = Nunito,
        fontWeight = FontWeight.Normal,
        fontSize = 14.sp,
        color = FaithFeedColors.TextSecondary
    ),
    labelLarge = TextStyle(
        fontFamily = Nunito,
        fontWeight = FontWeight.Medium,
        fontSize = 14.sp,
        color = FaithFeedColors.GoldAccent
    )
)
