package com.faithfeed.app.data.model

import androidx.compose.runtime.Immutable
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Immutable
@Serializable
data class PrayerRequest(
    val id: String = "",
    @SerialName("user_id") val userId: String = "",
    val title: String = "",
    val content: String = "",
    @SerialName("is_anonymous") val isAnonymous: Boolean = false,
    @SerialName("prayer_count") val prayerCount: Int = 0,
    @SerialName("is_answered") val isAnswered: Boolean = false,
    @SerialName("created_at") val createdAt: String = "",
    val author: User? = null,
    @SerialName("has_prayed") val hasPrayed: Boolean = false,
    @SerialName("origin_post_id") val originPostId: Long? = null
)
