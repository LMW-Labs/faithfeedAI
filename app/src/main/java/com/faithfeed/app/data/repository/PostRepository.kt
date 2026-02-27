package com.faithfeed.app.data.repository

import androidx.paging.Pager
import androidx.paging.PagingConfig
import androidx.paging.PagingData
import com.faithfeed.app.data.model.Comment
import com.faithfeed.app.data.model.Post
import com.faithfeed.app.data.paging.FeedPagingSource
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.postgrest
import io.github.jan.supabase.postgrest.query.Columns
import io.github.jan.supabase.postgrest.query.Order
import kotlinx.coroutines.flow.Flow
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import javax.inject.Inject

interface PostRepository {
    fun getFeedPager(): Flow<PagingData<Post>>
    suspend fun getPost(postId: String): Result<Post>
    suspend fun createPost(content: String, mediaUrls: List<String>, verseRef: String?, audience: String): Result<Post>
    suspend fun likePost(postId: String): Result<Unit>
    suspend fun unlikePost(postId: String): Result<Unit>
    suspend fun prayPost(postId: String): Result<Unit>
    suspend fun deletePost(postId: String): Result<Unit>
    suspend fun getPostsByUser(userId: String): Result<List<Post>>
    suspend fun getComments(postId: String): Result<List<Comment>>
    suspend fun addComment(postId: String, content: String): Result<Comment>
}

class PostRepositoryImpl @Inject constructor(
    private val supabase: SupabaseClient
) : PostRepository {

    private fun currentUserId(): String? = supabase.auth.currentUserOrNull()?.id

    override fun getFeedPager(): Flow<PagingData<Post>> {
        val viewerId = currentUserId() ?: ""
        return Pager(
            config = PagingConfig(pageSize = 20, enablePlaceholders = false),
            pagingSourceFactory = { FeedPagingSource(supabase, viewerId) }
        ).flow
    }

    override suspend fun getPost(postId: String): Result<Post> = try {
        val post = supabase.from("posts")
            .select(Columns.raw("*, author:profiles(id,full_name,username,avatar_url,is_verified)")) {
                filter { eq("id", postId) }
                limit(1)
            }.decodeSingle<Post>()
        Result.success(post)
    } catch (e: Exception) {
        Result.failure(e)
    }

    override suspend fun createPost(
        content: String,
        mediaUrls: List<String>,
        verseRef: String?,
        audience: String
    ): Result<Post> = try {
        val userId = currentUserId() ?: return Result.failure(Exception("Not authenticated"))
        val body = buildJsonObject {
            put("user_id", userId)
            put("content", content)
            put("audience", audience)
            if (verseRef != null) put("verse_ref", verseRef)
        }
        val post = supabase.from("posts").insert(body) {
            select(Columns.raw("*, author:profiles(id,full_name,username,avatar_url,is_verified)"))
        }.decodeSingle<Post>()
        Result.success(post)
    } catch (e: Exception) {
        Result.failure(e)
    }

    override suspend fun likePost(postId: String): Result<Unit> = try {
        val userId = currentUserId() ?: return Result.failure(Exception("Not authenticated"))
        supabase.from("post_likes").insert(buildJsonObject {
            put("post_id", postId)
            put("user_id", userId)
        })
        // Record LFS event
        supabase.from("lfs_events").insert(buildJsonObject {
            put("post_id", postId)
            put("user_id", userId)
            put("event_type", "like")
            put("points", 1)
        })
        Result.success(Unit)
    } catch (e: Exception) {
        Result.failure(e)
    }

    override suspend fun unlikePost(postId: String): Result<Unit> = try {
        val userId = currentUserId() ?: return Result.failure(Exception("Not authenticated"))
        supabase.from("post_likes").delete {
            filter {
                eq("post_id", postId)
                eq("user_id", userId)
            }
        }
        Result.success(Unit)
    } catch (e: Exception) {
        Result.failure(e)
    }

    override suspend fun prayPost(postId: String): Result<Unit> = try {
        val userId = currentUserId() ?: return Result.failure(Exception("Not authenticated"))
        supabase.from("lfs_events").insert(buildJsonObject {
            put("post_id", postId)
            put("user_id", userId)
            put("event_type", "prayer")
            put("points", 10)
        })
        // Increment prayer_count on the post — best-effort RPC call
        supabase.postgrest.rpc("increment_prayer_count", buildJsonObject {
            put("p_post_id", postId)
        })
        Result.success(Unit)
    } catch (e: Exception) {
        // Non-fatal — prayer count update is best-effort
        Result.success(Unit)
    }

    override suspend fun deletePost(postId: String): Result<Unit> = try {
        supabase.from("posts").delete {
            filter { eq("id", postId) }
        }
        Result.success(Unit)
    } catch (e: Exception) {
        Result.failure(e)
    }

    override suspend fun getPostsByUser(userId: String): Result<List<Post>> = try {
        val posts = supabase.from("posts")
            .select(Columns.raw("*, author:profiles(id,full_name,username,avatar_url,is_verified)")) {
                filter { eq("user_id", userId) }
                order("created_at", Order.DESCENDING)
            }.decodeList<Post>()
        Result.success(posts)
    } catch (e: Exception) {
        Result.failure(e)
    }

    override suspend fun getComments(postId: String): Result<List<Comment>> = try {
        val comments = supabase.from("post_comments")
            .select(Columns.raw("*, author:profiles(id,full_name,username,avatar_url)")) {
                filter { eq("post_id", postId) }
                order("created_at", Order.ASCENDING)
            }.decodeList<Comment>()
        Result.success(comments)
    } catch (e: Exception) {
        Result.failure(e)
    }

    override suspend fun addComment(postId: String, content: String): Result<Comment> = try {
        val userId = currentUserId() ?: return Result.failure(Exception("Not authenticated"))
        val comment = supabase.from("post_comments").insert(buildJsonObject {
            put("post_id", postId)
            put("user_id", userId)
            put("content", content)
        }) {
            select(Columns.raw("*, author:profiles(id,full_name,username,avatar_url)"))
        }.decodeSingle<Comment>()
        Result.success(comment)
    } catch (e: Exception) {
        Result.failure(e)
    }
}
