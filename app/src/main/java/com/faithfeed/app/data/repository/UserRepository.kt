package com.faithfeed.app.data.repository

import android.util.Log
import com.faithfeed.app.data.model.ProfilePrivacy
import com.faithfeed.app.data.model.User
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.query.Columns
import io.github.jan.supabase.storage.storage
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.encodeToJsonElement
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.put
import javax.inject.Inject

private const val TAG = "UserRepository"

interface UserRepository {
    suspend fun getProfile(userId: String): Result<User>
    suspend fun getCurrentUserProfile(): Result<User>
    suspend fun updateProfile(user: User): Result<User>
    suspend fun uploadAvatar(userId: String, bytes: ByteArray, mimeType: String): Result<String>
    suspend fun getPrivacySettings(userId: String): Result<ProfilePrivacy>
    suspend fun updatePrivacySettings(userId: String, privacy: ProfilePrivacy): Result<Unit>
    suspend fun getFriends(userId: String): Result<List<User>>
    suspend fun getFriendRequests(): Result<List<User>>
    suspend fun getFriendSuggestions(): Result<List<User>>
    suspend fun sendFriendRequest(targetUserId: String): Result<Unit>
    suspend fun acceptFriendRequest(fromUserId: String): Result<Unit>
    suspend fun declineFriendRequest(fromUserId: String): Result<Unit>
    suspend fun removeFriend(userId: String): Result<Unit>
    suspend fun searchUsers(query: String): Result<List<User>>
}

// Thin wrapper to decode the privacy_settings JSONB column from a profiles row
@Serializable
private data class PrivacySettingsRow(
    @SerialName("privacy_settings") val privacySettings: JsonObject? = null
)

// Thin wrapper to decode requester_id / receiver_id from friendships rows
// DB columns: requester_id, receiver_id (not user_id / friend_id)
@Serializable
private data class FriendshipRow(
    @SerialName("requester_id") val requesterId: String = "",
    @SerialName("receiver_id") val receiverId: String = ""
)

// Thin wrapper to decode suggested_id from friend_suggestions
// DB column: suggested_id (not suggested_user_id)
@Serializable
private data class SuggestionRow(
    @SerialName("suggested_id") val suggestedUserId: String = ""
)

class UserRepositoryImpl @Inject constructor(
    private val supabase: SupabaseClient
) : UserRepository {

    private val json = Json { ignoreUnknownKeys = true; coerceInputValues = true }

    private fun currentUserId(): String? = supabase.auth.currentUserOrNull()?.id

    // ── Profile ──────────────────────────────────────────────────────────────

    override suspend fun getProfile(userId: String): Result<User> = try {
        val user = supabase.from("profiles")
            .select(Columns.raw(
                "id,username,full_name,avatar_url,cover_url,bio,location,website," +
                "denomination,home_church_name,home_church_id,phone," +
                "is_verified,is_premium,is_private,follower_count,following_count,post_count,lfs_total_score,created_at"
            )) {
                filter { eq("id", userId) }
                limit(1)
            }.decodeSingleOrNull<User>()
        if (user != null) Result.success(user)
        else Result.failure(Exception("Profile not found"))
    } catch (e: Exception) {
        Result.failure(e)
    }

    override suspend fun getCurrentUserProfile(): Result<User> {
        val uid = currentUserId() ?: return Result.failure(Exception("Not authenticated"))
        return getProfile(uid)
    }

    override suspend fun updateProfile(user: User): Result<User> = try {
        val body = buildJsonObject {
            put("full_name", user.displayName)
            put("username", user.username)
            user.bio?.let { put("bio", it) }
            user.avatarUrl?.let { put("avatar_url", it) }
            user.location?.let { put("location", it) }
            user.website?.let { put("website", it) }
            user.denomination?.let { put("denomination", it) }
            user.homechurchName?.let { put("home_church_name", it) }
            user.homechurchId?.let { put("home_church_id", it) }
            user.phone?.let { put("phone", it) }
        }
        supabase.from("profiles").update(body) {
            filter { eq("id", user.id) }
        }
        // Re-fetch to return the server-authoritative record
        getProfile(user.id).getOrThrow().let { Result.success(it) }
    } catch (e: Exception) {
        Result.failure(e)
    }

    // ── Avatar Storage ───────────────────────────────────────────────────────

    override suspend fun uploadAvatar(
        userId: String,
        bytes: ByteArray,
        mimeType: String
    ): Result<String> = try {
        val ext = if (mimeType.contains("png", ignoreCase = true)) "png" else "jpg"
        val path = "$userId/avatar.$ext"
        Log.d(TAG, "uploadAvatar: path=$path size=${bytes.size}")
        supabase.storage.from("avatars").upload(path, bytes) { upsert = true }
        val url = supabase.storage.from("avatars").publicUrl(path)
        Log.d(TAG, "uploadAvatar success: url=$url")
        Result.success(url)
    } catch (e: Exception) {
        Log.e(TAG, "uploadAvatar failed", e)
        Result.failure(e)
    }

    // ── Privacy Settings ─────────────────────────────────────────────────────

    override suspend fun getPrivacySettings(userId: String): Result<ProfilePrivacy> = try {
        val row = supabase.from("profiles")
            .select(Columns.raw("privacy_settings")) {
                filter { eq("id", userId) }
                limit(1)
            }.decodeSingleOrNull<PrivacySettingsRow>()
        val privacy = row?.privacySettings
            ?.let { json.decodeFromJsonElement(ProfilePrivacy.serializer(), it) }
            ?: ProfilePrivacy()
        Result.success(privacy)
    } catch (e: Exception) {
        // Default to safe/private settings on any decode error
        Result.success(ProfilePrivacy())
    }

    override suspend fun updatePrivacySettings(
        userId: String,
        privacy: ProfilePrivacy
    ): Result<Unit> = try {
        val privacyJson = json.encodeToJsonElement(privacy).jsonObject
        supabase.from("profiles").update(buildJsonObject {
            put("privacy_settings", privacyJson)
        }) {
            filter { eq("id", userId) }
        }
        Result.success(Unit)
    } catch (e: Exception) {
        Result.failure(e)
    }

    // ── Friends ───────────────────────────────────────────────────────────────

    override suspend fun getFriends(userId: String): Result<List<User>> {
        return try {
            val asRequester = supabase.from("friendships")
                .select(Columns.raw("requester_id,receiver_id")) {
                    filter {
                        eq("requester_id", userId)
                        eq("status", "accepted")
                    }
                }.decodeList<FriendshipRow>()
                .map { it.receiverId }

            val asRecipient = supabase.from("friendships")
                .select(Columns.raw("requester_id,receiver_id")) {
                    filter {
                        eq("receiver_id", userId)
                        eq("status", "accepted")
                    }
                }.decodeList<FriendshipRow>()
                .map { it.requesterId }

            val friendIds = (asRequester + asRecipient).distinct()
            if (friendIds.isEmpty()) return Result.success(emptyList())

            Result.success(fetchProfilesByIds(friendIds))
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun getFriendRequests(): Result<List<User>> {
        return try {
            val uid = currentUserId() ?: return Result.failure(Exception("Not authenticated"))
            val rows = supabase.from("friendships")
                .select(Columns.raw("requester_id,receiver_id")) {
                    filter {
                        eq("receiver_id", uid)
                        eq("status", "pending")
                    }
                }.decodeList<FriendshipRow>()
            val requestorIds = rows.map { it.requesterId }.distinct()
            if (requestorIds.isEmpty()) return Result.success(emptyList())
            Result.success(fetchProfilesByIds(requestorIds))
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun getFriendSuggestions(): Result<List<User>> {
        return try {
            val uid = currentUserId() ?: return Result.failure(Exception("Not authenticated"))
            val rows = supabase.from("friend_suggestions")
                .select(Columns.raw("suggested_id")) {
                    filter { eq("user_id", uid) }
                    limit(20)
                }.decodeList<SuggestionRow>()
            val suggestedIds = rows.map { it.suggestedUserId }.distinct()
            if (suggestedIds.isEmpty()) return Result.success(emptyList())
            Result.success(fetchProfilesByIds(suggestedIds))
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    // ── Friendship Mutations ─────────────────────────────────────────────────

    override suspend fun sendFriendRequest(targetUserId: String): Result<Unit> = try {
        val uid = currentUserId() ?: return Result.failure(Exception("Not authenticated"))
        supabase.from("friendships").insert(buildJsonObject {
            put("requester_id", uid)
            put("receiver_id", targetUserId)
            put("status", "pending")
        })
        Result.success(Unit)
    } catch (e: Exception) {
        Result.failure(e)
    }

    override suspend fun acceptFriendRequest(fromUserId: String): Result<Unit> = try {
        val uid = currentUserId() ?: return Result.failure(Exception("Not authenticated"))
        supabase.from("friendships").update(buildJsonObject {
            put("status", "accepted")
        }) {
            filter {
                eq("requester_id", fromUserId)
                eq("receiver_id", uid)
            }
        }
        Result.success(Unit)
    } catch (e: Exception) {
        Result.failure(e)
    }

    override suspend fun declineFriendRequest(fromUserId: String): Result<Unit> = try {
        val uid = currentUserId() ?: return Result.failure(Exception("Not authenticated"))
        supabase.from("friendships").delete {
            filter {
                eq("requester_id", fromUserId)
                eq("receiver_id", uid)
            }
        }
        Result.success(Unit)
    } catch (e: Exception) {
        Result.failure(e)
    }

    override suspend fun removeFriend(userId: String): Result<Unit> = try {
        val uid = currentUserId() ?: return Result.failure(Exception("Not authenticated"))
        supabase.from("friendships").delete {
            filter {
                eq("requester_id", uid)
                eq("receiver_id", userId)
            }
        }
        supabase.from("friendships").delete {
            filter {
                eq("requester_id", userId)
                eq("receiver_id", uid)
            }
        }
        Result.success(Unit)
    } catch (e: Exception) {
        Result.failure(e)
    }

    // ── Search ────────────────────────────────────────────────────────────────

    override suspend fun searchUsers(query: String): Result<List<User>> = try {
        val results = supabase.from("profiles")
            .select(Columns.raw(
                "id,username,full_name,avatar_url,cover_url,bio,location,website," +
                "denomination,home_church_name,home_church_id,phone," +
                "is_verified,is_premium,is_private,follower_count,following_count,post_count,lfs_total_score,created_at"
            )) {
                filter { ilike("full_name", "%$query%") }
                limit(30)
            }.decodeList<User>()
        Result.success(results)
    } catch (e: Exception) {
        Result.failure(e)
    }

    // ── Private Helpers ───────────────────────────────────────────────────────

    /** Batch-fetches full profile rows for the given list of user IDs. */
    private suspend fun fetchProfilesByIds(ids: List<String>): List<User> {
        if (ids.isEmpty()) return emptyList()
        // Use `in` filter via the CSV format Supabase PostgREST accepts
        val idCsv = ids.joinToString(",")
        return supabase.from("profiles")
            .select(Columns.raw(
                "id,username,full_name,avatar_url,cover_url,bio,location,website," +
                "denomination,home_church_name,home_church_id,phone," +
                "is_verified,is_premium,is_private,follower_count,following_count,post_count,lfs_total_score,created_at"
            )) {
                filter { isIn("id", ids) }
            }.decodeList<User>()
    }
}
