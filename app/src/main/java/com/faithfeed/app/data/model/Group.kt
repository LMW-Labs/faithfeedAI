package com.faithfeed.app.data.model

import androidx.compose.runtime.Immutable
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Immutable
@Serializable
data class Group(
    val id: String = "",
    val name: String = "",
    val description: String = "",
    @SerialName("cover_url") val coverUrl: String? = null,
    @SerialName("member_count") val memberCount: Int = 0,
    @SerialName("is_private") val isPrivate: Boolean = false,
    @SerialName("created_by") val createdBy: String = "",
    @SerialName("created_at") val createdAt: String = "",
    @SerialName("is_member") val isMember: Boolean = false
)
