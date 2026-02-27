package com.faithfeed.app.data.model

import androidx.compose.runtime.Immutable
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Immutable
@Serializable
data class BusinessPage(
    val id: String = "",
    val name: String = "",
    val category: String = "",
    val description: String = "",
    @SerialName("logo_url") val logoUrl: String? = null,
    @SerialName("cover_url") val coverUrl: String? = null,
    val website: String? = null,
    val location: String? = null,
    @SerialName("follower_count") val followerCount: Int = 0,
    @SerialName("is_verified") val isVerified: Boolean = false,
    @SerialName("is_following") val isFollowing: Boolean = false,
    @SerialName("created_at") val createdAt: String = ""
)
