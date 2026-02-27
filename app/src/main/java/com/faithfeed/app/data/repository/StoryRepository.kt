package com.faithfeed.app.data.repository

import com.faithfeed.app.data.model.Story
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.query.Columns
import io.github.jan.supabase.postgrest.query.Order
import io.github.jan.supabase.storage.storage
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import java.time.Instant
import javax.inject.Inject

interface StoryRepository {
    suspend fun getActiveStories(): Result<List<Story>>
    suspend fun createStory(mediaUrl: String, mediaType: String, caption: String?): Result<Story>
    suspend fun uploadStoryMedia(bytes: ByteArray, mimeType: String): Result<String>
    suspend fun markStoryViewed(storyId: String): Result<Unit>
    suspend fun deleteStory(storyId: String): Result<Unit>
}

class StoryRepositoryImpl @Inject constructor(
    private val supabase: SupabaseClient
) : StoryRepository {

    private fun currentUserId() = supabase.auth.currentUserOrNull()?.id

    override suspend fun getActiveStories(): Result<List<Story>> = try {
        val now = Instant.now().toString()
        val stories = supabase.from("stories")
            .select(Columns.raw("*, author:profiles(id,full_name,username,avatar_url,is_verified)")) {
                filter { gt("expires_at", now) }
                order("created_at", Order.DESCENDING)
                limit(100)
            }.decodeList<Story>()
        Result.success(stories)
    } catch (e: Exception) {
        Result.failure(e)
    }

    override suspend fun uploadStoryMedia(bytes: ByteArray, mimeType: String): Result<String> = try {
        val uid = currentUserId() ?: return Result.failure(Exception("Not authenticated"))
        val ext = when {
            mimeType.contains("png", ignoreCase = true) -> "png"
            mimeType.startsWith("video", ignoreCase = true) -> "mp4"
            else -> "jpg"
        }
        val path = "$uid/${System.currentTimeMillis()}.$ext"
        supabase.storage.from("stories").upload(path, bytes) { upsert = false }
        val url = supabase.storage.from("stories").publicUrl(path)
        Result.success(url)
    } catch (e: Exception) {
        Result.failure(e)
    }

    override suspend fun createStory(mediaUrl: String, mediaType: String, caption: String?): Result<Story> = try {
        val uid = currentUserId() ?: return Result.failure(Exception("Not authenticated"))
        val expiresAt = Instant.now().plusSeconds(86_400).toString() // 24 hours
        val body = buildJsonObject {
            put("user_id", uid)
            put("media_url", mediaUrl)
            put("media_type", mediaType)
            if (caption != null) put("caption", caption)
            put("expires_at", expiresAt)
        }
        val story = supabase.from("stories").insert(body) {
            select(Columns.raw("*, author:profiles(id,full_name,username,avatar_url,is_verified)"))
        }.decodeSingle<Story>()
        Result.success(story)
    } catch (e: Exception) {
        Result.failure(e)
    }

    override suspend fun markStoryViewed(storyId: String): Result<Unit> = try {
        val uid = currentUserId() ?: return Result.success(Unit)
        supabase.from("story_views").insert(buildJsonObject {
            put("story_id", storyId)
            put("viewer_id", uid)
        })
        Result.success(Unit)
    } catch (_: Exception) {
        Result.success(Unit) // Non-fatal — duplicate views etc.
    }

    override suspend fun deleteStory(storyId: String): Result<Unit> = try {
        supabase.from("stories").delete {
            filter { eq("id", storyId) }
        }
        Result.success(Unit)
    } catch (e: Exception) {
        Result.failure(e)
    }
}
