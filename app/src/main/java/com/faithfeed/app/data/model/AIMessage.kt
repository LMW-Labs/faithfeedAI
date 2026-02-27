package com.faithfeed.app.data.model

import androidx.compose.runtime.Immutable
import kotlinx.serialization.Serializable

@Immutable
@Serializable
data class AIMessage(
    val id: String = "",
    val role: String = "user", // "user" or "assistant"
    val content: String = "",
    val timestamp: Long = System.currentTimeMillis(),
    val verses: List<BibleVerse> = emptyList() // Related verses attached by AI
)
