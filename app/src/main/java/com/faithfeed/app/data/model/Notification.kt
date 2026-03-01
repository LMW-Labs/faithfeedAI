package com.faithfeed.app.data.model

import androidx.compose.runtime.Immutable
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonObject

@Immutable
@Serializable
data class Notification(
    val id: String = "",
    @SerialName("user_id") val userId: String = "",
    val type: String = "",
    val title: String = "",
    val body: String = "",
    val data: JsonObject? = null,
    @SerialName("is_read") val isRead: Boolean = false,
    @SerialName("created_at") val createdAt: String = "",
    // Optional actor join (present only when notifications table has actor_id FK)
    val actor: User? = null
) {
    /** Friendly display text — uses DB title if available, falls back to type-based string */
    fun displayText(): String = when {
        title.isNotBlank() -> title
        else -> when (type) {
            "like"           -> "Someone liked your post"
            "comment"        -> "Someone commented on your post"
            "friend_request" -> "You have a new friend request"
            "prayer"         -> "Someone prayed for you"
            "mention"        -> "Someone mentioned you"
            else             -> "New notification"
        }
    }
}
