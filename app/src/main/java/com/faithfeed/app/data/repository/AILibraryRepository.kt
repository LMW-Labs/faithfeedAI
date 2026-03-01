package com.faithfeed.app.data.repository

import com.faithfeed.app.data.model.AIInteraction
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.query.Columns
import io.github.jan.supabase.postgrest.query.Order
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import javax.inject.Inject

interface AILibraryRepository {
    fun getInteractionsFlow(): Flow<List<AIInteraction>>
    suspend fun saveInteraction(type: String, title: String, content: String): Result<AIInteraction>
    suspend fun deleteInteraction(id: String): Result<Unit>
}

class AILibraryRepositoryImpl @Inject constructor(
    private val supabase: SupabaseClient
) : AILibraryRepository {

    private fun currentUserId(): String? = supabase.auth.currentUserOrNull()?.id

    override fun getInteractionsFlow(): Flow<List<AIInteraction>> = flow {
        val uid = currentUserId() ?: run { emit(emptyList()); return@flow }
        val items = supabase.from("ai_interactions")
            .select(Columns.raw("id,user_id,type,title,content,created_at")) {
                filter { eq("user_id", uid) }
                order("created_at", Order.DESCENDING)
                limit(100)
            }.decodeList<AIInteraction>()
        emit(items)
    }

    override suspend fun saveInteraction(type: String, title: String, content: String): Result<AIInteraction> = runCatching {
        val uid = currentUserId() ?: error("Not authenticated")
        supabase.from("ai_interactions").insert(buildJsonObject {
            put("user_id", uid)
            put("type", type)
            put("title", title)
            put("content", content)
        }) {
            select(Columns.raw("id,user_id,type,title,content,created_at"))
        }.decodeSingle<AIInteraction>()
    }

    override suspend fun deleteInteraction(id: String): Result<Unit> = runCatching {
        supabase.from("ai_interactions").delete {
            filter { eq("id", id) }
        }
    }
}
