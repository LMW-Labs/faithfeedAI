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
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import javax.inject.Inject

@Serializable
private data class PostPrayData(
    val id: String = "",
    @SerialName("user_id") val userId: String = "",
    val content: String = "",
    @SerialName("verse_ref") val verseRef: String? = null,
    val author: PostAuthorPrivacy? = null
)

@Serializable
private data class PostAuthorPrivacy(
    @SerialName("is_private") val isPrivate: Boolean = false
)

interface PostRepository {
    fun getFeedPager(): Flow<PagingData<Post>>
    suspend fun getPost(postId: String): Result<Post>
    suspend fun createPost(content: String, mediaUrls: List<String>, verseRef: String?, audience: String): Result<Post>
    suspend fun likePost(postId: String): Result<Unit>
    suspend fun unlikePost(postId: String): Result<Unit>
    suspend fun prayPost(postId: String): Result<Unit>
    suspend fun deletePost(postId: String): Result<Unit>
    suspend fun getPostsByUser(userId: String): Result<List<Post>>
    suspend fun sharePost(postId: String): Result<Unit>
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
        // LFS event: verse share scores higher than a plain post
        val eventType = if (verseRef != null) "verse_share" else "post"
        val points = if (verseRef != null) 7 else 3
        supabase.from("lfs_events").insert(buildJsonObject {
            put("post_id", post.id)
            put("user_id", userId)
            put("event_type", eventType)
            put("points", points)
        })
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
        // Increment prayer_count on the post
        try {
            supabase.postgrest.rpc("increment_prayer_count", buildJsonObject {
                put("p_post_id", postId)
            })
        } catch (_: Exception) {}

        // Cross-post to Prayer Wall for public/community profiles only
        try {
            val post = supabase.from("posts")
                .select(Columns.raw("id,user_id,content,verse_ref,author:profiles!user_id(is_private)")) {
                    filter { eq("id", postId) }
                    limit(1)
                }.decodeSingleOrNull<PostPrayData>()

            if (post != null && post.author?.isPrivate == false) {
                val postIdLong = postId.toLongOrNull()
                if (postIdLong != null) {
                    val title = post.content.take(80).trimEnd().let {
                        if (post.content.length > 80) "$it…" else it
                    }
                    // Create prayer_request if not already cross-posted from this post
                    supabase.from("prayer_requests").upsert(
                        buildJsonObject {
                            put("user_id", post.userId)
                            put("title", title)
                            put("content", post.content)
                            put("origin_post_id", postIdLong)
                        }
                    ) {
                        onConflict = "origin_post_id"
                        ignoreDuplicates = true
                    }
                    // Increment prayer_count on the prayer_request entry
                    supabase.postgrest.rpc("increment_prayer_count_by_origin", buildJsonObject {
                        put("p_post_id", postIdLong)
                    })
                }
            }
        } catch (_: Exception) { /* best-effort cross-post */ }

        Result.success(Unit)
    } catch (e: Exception) {
        Result.success(Unit) // prayer is non-fatal
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

    override suspend fun sharePost(postId: String): Result<Unit> = try {
        val userId = currentUserId() ?: return Result.failure(Exception("Not authenticated"))
        supabase.from("lfs_events").insert(buildJsonObject {
            put("post_id", postId)
            put("user_id", userId)
            put("event_type", "share")
            put("points", 5)
        })
        // Best-effort counter increment — same pattern as prayer count
        try {
            supabase.postgrest.rpc("increment_share_count", buildJsonObject {
                put("p_post_id", postId)
            })
        } catch (_: Exception) { }
        Result.success(Unit)
    } catch (e: Exception) {
        Result.success(Unit) // non-fatal — share sheet already opened
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
        // LFS event: comments are worth +7
        supabase.from("lfs_events").insert(buildJsonObject {
            put("post_id", postId)
            put("user_id", userId)
            put("event_type", "comment")
            put("points", 7)
        })
        Result.success(comment)
    } catch (e: Exception) {
        Result.failure(e)
    }
}
