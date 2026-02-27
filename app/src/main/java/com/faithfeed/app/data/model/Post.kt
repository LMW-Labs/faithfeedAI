package com.faithfeed.app.data.model

import androidx.compose.runtime.Immutable
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Immutable
@Serializable
data class Post(
    val id: String = "",
    @SerialName("user_id") val userId: String = "",
    val content: String = "",
    @SerialName("media_urls") val mediaUrls: List<String> = emptyList(),
    @SerialName("verse_ref") val verseRef: String? = null,
    @SerialName("verse_text") val verseText: String? = null,
    @SerialName("like_count") val likeCount: Int = 0,
    @SerialName("comment_count") val commentCount: Int = 0,
    @SerialName("share_count") val shareCount: Int = 0,
    @SerialName("prayer_count") val prayerCount: Int = 0,
    @SerialName("report_count") val reportCount: Int = 0,
    @SerialName("is_liked") val isLiked: Boolean = false,
    @SerialName("is_flagged") val isFlagged: Boolean = false,
    @SerialName("is_public") val isPublic: Boolean = true,
    val audience: String = "public",
    // DB column is post_type — post_type_category added via migration
    @SerialName("post_type") val postType: String = "general",
    @SerialName("post_type_category") val postTypeCategory: String = "general",
    // LFS (Living Faith Score) — computed by calculate_lfs_score(post_id, viewer_id) Postgres RPC
    // Weights: prayer +10, comment +7, like +1, report -50
    // Relationship multipliers: friend 3x, home_church 2.5x
    @SerialName("lfs_score") val lfsScore: Double = 0.0,
    @SerialName("created_at") val createdAt: String = "",
    val author: User? = null
)
