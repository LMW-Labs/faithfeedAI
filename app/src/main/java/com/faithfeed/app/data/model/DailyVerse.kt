package com.faithfeed.app.data.model

import androidx.compose.runtime.Immutable
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Immutable
@Serializable
data class DailyVerse(
    val id: String = "",
    val reference: String = "",
    val text: String = "",
    val book: String = "",
    val chapter: Int = 0,
    val verse: Int = 0,
    val reflection: String? = null,
    @SerialName("display_date") val displayDate: String = ""
)
