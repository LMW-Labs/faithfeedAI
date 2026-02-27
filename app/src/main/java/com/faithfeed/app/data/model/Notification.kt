package com.faithfeed.app.data.model

import androidx.compose.runtime.Immutable
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Immutable
@Serializable
data class Notification(
    val id: String = "",
    @SerialName("user_id") val userId: String = "",
    val type: String = "",          // "like","comment","friend_request","prayer","mention"
    @SerialName("actor_id") val actorId: String = "",
    @SerialName("post_id") val postId: String? = null,
    @SerialName("is_read") val isRead: Boolean = false,
    @SerialName("created_at") val createdAt: String = "",
    val actor: User? = null
)
