package com.faithfeed.app.data.model

import androidx.compose.runtime.Immutable
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Immutable
@Serializable
data class Message(
    val id: String = "",
    @SerialName("chat_id") val chatId: String = "",
    @SerialName("sender_id") val senderId: String = "",
    val content: String = "",
    @SerialName("media_url") val mediaUrl: String? = null,
    @SerialName("is_read") val isRead: Boolean = false,
    @SerialName("created_at") val createdAt: String = "",
    val sender: User? = null
)
