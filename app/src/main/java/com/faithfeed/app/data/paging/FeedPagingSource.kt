package com.faithfeed.app.data.paging

import androidx.paging.PagingSource
import androidx.paging.PagingState
import com.faithfeed.app.data.model.Post
import com.faithfeed.app.data.model.User
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.exceptions.RestException
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.query.Columns
import io.github.jan.supabase.postgrest.query.Order

private const val PAGE_SIZE = 20

class FeedPagingSource(
    private val supabase: SupabaseClient,
    private val viewerId: String
) : PagingSource<Int, Post>() {

    override fun getRefreshKey(state: PagingState<Int, Post>): Int? {
        return state.anchorPosition?.let { anchor ->
            state.closestPageToPosition(anchor)?.prevKey?.plus(1)
                ?: state.closestPageToPosition(anchor)?.nextKey?.minus(1)
        }
    }

    override suspend fun load(params: LoadParams<Int>): LoadResult<Int, Post> {
        val page = params.key ?: 0
        val from = (page * PAGE_SIZE).toLong()
        val to = (from + PAGE_SIZE - 1)
        return try {
            // Phase 1: fetch posts without embedded join (avoids FK dependency)
            val posts = supabase.from("posts")
                .select(Columns.raw("*")) {
                    order("lfs_score", Order.DESCENDING)
                    range(from, to)
                    filter { eq("is_public", true) }
                }.decodeList<Post>()

            // Phase 2: batch-fetch author profiles for this page
            val userIds = posts.map { it.userId }.distinct()
            val authors: Map<String, User> = if (userIds.isNotEmpty()) {
                runCatching {
                    supabase.from("profiles")
                        .select(Columns.raw("id,full_name,username,avatar_url,is_verified")) {
                            filter { isIn("id", userIds) }
                        }.decodeList<User>()
                        .associateBy { it.id }
                }.getOrElse { emptyMap() }
            } else emptyMap()

            val enriched = posts.map { post -> post.copy(author = authors[post.userId]) }

            LoadResult.Page(
                data = enriched,
                prevKey = if (page == 0) null else page - 1,
                nextKey = if (posts.size < PAGE_SIZE) null else page + 1
            )
        } catch (e: RestException) {
            android.util.Log.e("FeedPagingSource", "HTTP ${e.statusCode} ${e.error}: ${e.message}")
            LoadResult.Error(e)
        } catch (e: Exception) {
            android.util.Log.e("FeedPagingSource", "Feed load failed: ${e::class.simpleName} — ${e.message}")
            LoadResult.Error(e)
        }
    }
}
