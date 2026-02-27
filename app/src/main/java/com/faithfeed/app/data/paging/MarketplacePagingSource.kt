package com.faithfeed.app.data.paging

import androidx.paging.PagingSource
import androidx.paging.PagingState
import com.faithfeed.app.data.model.MarketplaceItem
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.query.Columns
import io.github.jan.supabase.postgrest.query.Order

private const val MARKETPLACE_PAGE_SIZE = 20

class MarketplacePagingSource(
    private val supabase: SupabaseClient,
    private val category: String? = null,
    private val query: String? = null
) : PagingSource<Int, MarketplaceItem>() {

    override fun getRefreshKey(state: PagingState<Int, MarketplaceItem>): Int? {
        return state.anchorPosition?.let { anchor ->
            state.closestPageToPosition(anchor)?.prevKey?.plus(1)
                ?: state.closestPageToPosition(anchor)?.nextKey?.minus(1)
        }
    }

    override suspend fun load(params: LoadParams<Int>): LoadResult<Int, MarketplaceItem> {
        val page = params.key ?: 0
        val from = (page * MARKETPLACE_PAGE_SIZE).toLong()
        val to = from + MARKETPLACE_PAGE_SIZE - 1
        return try {
            val items = supabase.from("marketplace_items")
                .select(Columns.raw("*, seller:profiles(id,full_name,username,avatar_url)")) {
                    order("created_at", Order.DESCENDING)
                    range(from, to)
                    filter {
                        eq("is_available", true)
                        if (!category.isNullOrBlank()) eq("item_type", category)
                        if (!query.isNullOrBlank()) ilike("title", "%$query%")
                    }
                }.decodeList<MarketplaceItem>()
            LoadResult.Page(
                data = items,
                prevKey = if (page == 0) null else page - 1,
                nextKey = if (items.size < MARKETPLACE_PAGE_SIZE) null else page + 1
            )
        } catch (e: Exception) {
            LoadResult.Error(e)
        }
    }
}
