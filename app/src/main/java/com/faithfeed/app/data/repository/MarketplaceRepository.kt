package com.faithfeed.app.data.repository

import androidx.paging.Pager
import androidx.paging.PagingConfig
import androidx.paging.PagingData
import com.faithfeed.app.data.model.MarketplaceItem
import com.faithfeed.app.data.paging.MarketplacePagingSource
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.query.Columns
import io.github.jan.supabase.postgrest.query.Order
import io.github.jan.supabase.storage.storage
import io.ktor.http.ContentType
import kotlinx.coroutines.flow.Flow
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import javax.inject.Inject

interface MarketplaceRepository {
    fun getItemsPager(category: String? = null, query: String? = null): Flow<PagingData<MarketplaceItem>>
    suspend fun getItem(itemId: String): Result<MarketplaceItem>
    suspend fun createListing(
        title: String,
        description: String,
        price: Double,
        itemType: String,
        category: String,
        condition: String,
        location: String,
        mediaUrls: List<String>
    ): Result<MarketplaceItem>
    suspend fun deleteListing(itemId: String): Result<Unit>
    suspend fun getMyListings(): Result<List<MarketplaceItem>>
    suspend fun uploadImage(bytes: ByteArray, mimeType: String): Result<String>
}

class MarketplaceRepositoryImpl @Inject constructor(
    private val supabase: SupabaseClient
) : MarketplaceRepository {

    private fun currentUserId() = supabase.auth.currentUserOrNull()?.id

    override fun getItemsPager(category: String?, query: String?): Flow<PagingData<MarketplaceItem>> =
        Pager(PagingConfig(pageSize = 20, enablePlaceholders = false)) {
            MarketplacePagingSource(supabase, category, query)
        }.flow

    override suspend fun getItem(itemId: String): Result<MarketplaceItem> = try {
        val item = supabase.from("marketplace_items")
            .select(Columns.raw("*, seller:profiles(id,full_name,username,avatar_url)")) {
                filter { eq("id", itemId) }
                limit(1)
            }.decodeSingle<MarketplaceItem>()
        Result.success(item)
    } catch (e: Exception) {
        Result.failure(e)
    }

    override suspend fun createListing(
        title: String,
        description: String,
        price: Double,
        itemType: String,
        category: String,
        condition: String,
        location: String,
        mediaUrls: List<String>
    ): Result<MarketplaceItem> = try {
        val uid = currentUserId() ?: return Result.failure(Exception("Not authenticated"))
        val body = buildJsonObject {
            put("seller_id", uid)
            put("title", title)
            put("description", description)
            put("price", price)
            put("item_type", itemType)
            put("category", category)
            put("condition", condition)
            put("location", location)
            put("is_available", true)
            put("media_urls", JsonArray(mediaUrls.map { JsonPrimitive(it) }))
        }
        val item = supabase.from("marketplace_items").insert(body) {
            select(Columns.raw("*, seller:profiles(id,full_name,username,avatar_url)"))
        }.decodeSingle<MarketplaceItem>()
        Result.success(item)
    } catch (e: Exception) {
        Result.failure(e)
    }

    override suspend fun deleteListing(itemId: String): Result<Unit> = try {
        supabase.from("marketplace_items").delete {
            filter { eq("id", itemId) }
        }
        Result.success(Unit)
    } catch (e: Exception) {
        Result.failure(e)
    }

    override suspend fun getMyListings(): Result<List<MarketplaceItem>> = try {
        val uid = currentUserId() ?: return Result.failure(Exception("Not authenticated"))
        val items = supabase.from("marketplace_items")
            .select(Columns.raw("*")) {
                filter { eq("seller_id", uid) }
                order("created_at", Order.DESCENDING)
            }.decodeList<MarketplaceItem>()
        Result.success(items)
    } catch (e: Exception) {
        Result.failure(e)
    }

    override suspend fun uploadImage(bytes: ByteArray, mimeType: String): Result<String> = try {
        val uid = currentUserId() ?: return Result.failure(Exception("Not authenticated"))
        val path = "$uid/${System.currentTimeMillis()}.jpg"
        supabase.storage.from("marketplace").upload(path, bytes) {
            upsert = true
            contentType = ContentType.parse(mimeType)
        }
        Result.success(supabase.storage.from("marketplace").publicUrl(path))
    } catch (e: Exception) {
        Result.failure(e)
    }
}
