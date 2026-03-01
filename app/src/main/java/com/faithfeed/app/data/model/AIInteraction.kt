package com.faithfeed.app.data.model

import androidx.compose.runtime.Immutable
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Immutable
@Serializable
data class AIInteraction(
    val id: String = "",
    @SerialName("user_id") val userId: String = "",
    val type: String = "",
    val title: String = "",
    val content: String = "",
    @SerialName("created_at") val createdAt: String = ""
)
