package com.faithfeed.app.data.paging

import androidx.paging.PagingSource
import androidx.paging.PagingState
import com.faithfeed.app.data.model.Post
import io.github.jan.supabase.SupabaseClient
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
            val posts = supabase.from("posts")
                .select(Columns.raw("*, author:profiles(id,full_name,username,avatar_url,is_verified)")) {
                    order("lfs_score", Order.DESCENDING)
                    range(from, to)
                    filter {
                        eq("is_public", true)
                    }
                }.decodeList<Post>()
            LoadResult.Page(
                data = posts,
                prevKey = if (page == 0) null else page - 1,
                nextKey = if (posts.size < PAGE_SIZE) null else page + 1
            )
        } catch (e: Exception) {
            LoadResult.Error(e)
        }
    }
}
