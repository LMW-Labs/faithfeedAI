package com.faithfeed.app.data.model

import androidx.compose.runtime.Immutable
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Immutable
@Serializable
data class Chat(
    val id: String = "",
    val name: String? = null,
    @SerialName("is_group") val isGroup: Boolean = false,
    @SerialName("last_message") val lastMessage: String? = null,
    @SerialName("last_message_at") val lastMessageAt: String? = null,
    @SerialName("unread_count") val unreadCount: Int = 0,
    val members: List<User> = emptyList(),
    @SerialName("avatar_url") val avatarUrl: String? = null
)
