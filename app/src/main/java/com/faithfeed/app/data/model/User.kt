package com.faithfeed.app.data.model

import androidx.compose.runtime.Immutable
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Immutable
@Serializable
data class User(
    val id: String = "",
    val username: String = "",
    // DB column is full_name — keep displayName as the Kotlin property
    @SerialName("full_name") val displayName: String = "",
    @SerialName("avatar_url") val avatarUrl: String? = null,
    @SerialName("cover_url") val coverUrl: String? = null,
    val bio: String? = null,
    val location: String? = null,
    val website: String? = null,
    val denomination: String? = null,
    // home_church_name added via migration; home_church_id exists already
    @SerialName("home_church_name") val homechurchName: String? = null,
    @SerialName("home_church_id") val homechurchId: String? = null,
    val phone: String? = null,
    @SerialName("is_verified") val isVerified: Boolean = false,
    @SerialName("is_premium") val isPremium: Boolean = false,
    @SerialName("is_private") val isPrivate: Boolean = false,
    @SerialName("follower_count") val followerCount: Int = 0,
    @SerialName("following_count") val followingCount: Int = 0,
    @SerialName("post_count") val postCount: Int = 0,
    @SerialName("lfs_total_score") val lfsTotalScore: Double = 0.0,
    @SerialName("created_at") val createdAt: String = ""
)

/** Per-attribute visibility controls stored as JSONB in profiles.privacy_settings */
@Serializable
data class ProfilePrivacy(
    @SerialName("bio_visibility") val bioVisibility: String = "public",
    @SerialName("location_visibility") val locationVisibility: String = "community",
    @SerialName("phone_visibility") val phoneVisibility: String = "private",
    @SerialName("posts_visibility") val postsVisibility: String = "public",
    @SerialName("friends_visibility") val friendsVisibility: String = "community",
    @SerialName("activity_visibility") val activityVisibility: String = "friends",
    @SerialName("email_visibility") val emailVisibility: String = "private"
) {
    companion object {
        val LEVELS = listOf("public", "community", "friends", "private")
        val LEVEL_LABELS = mapOf(
            "public" to "Public",
            "community" to "Community",
            "friends" to "Friends",
            "private" to "Only Me"
        )
    }
}
