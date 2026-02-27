package com.faithfeed.app.data.model

import androidx.compose.runtime.Immutable
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Immutable
@Serializable
data class Story(
    val id: String = "",
    @SerialName("user_id") val userId: String = "",
    @SerialName("media_url") val mediaUrl: String = "",
    @SerialName("media_type") val mediaType: String = "image",
    val caption: String? = null,
    @SerialName("expires_at") val expiresAt: String = "",
    @SerialName("created_at") val createdAt: String = "",
    val author: User? = null,
    @SerialName("is_viewed") val isViewed: Boolean = false
)
