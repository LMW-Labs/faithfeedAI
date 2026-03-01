package com.faithfeed.app.data.repository

import com.faithfeed.app.data.model.PrayerRequest
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.query.Columns
import io.github.jan.supabase.postgrest.query.Order
import io.github.jan.supabase.realtime.PostgresAction
import io.github.jan.supabase.realtime.channel
import io.github.jan.supabase.realtime.postgresChangeFlow
import io.github.jan.supabase.realtime.realtime
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.launch
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import javax.inject.Inject

interface PrayerRepository {
    /** Realtime-backed flow — updates as new prayers arrive via Supabase Realtime */
    fun getPrayerWallFlow(): Flow<List<PrayerRequest>>
    suspend fun createPrayer(title: String, content: String, isAnonymous: Boolean): Result<PrayerRequest>
    suspend fun prayForRequest(prayerRequestId: String): Result<Unit>
    suspend fun markAnswered(prayerRequestId: String): Result<Unit>
}

class PrayerRepositoryImpl @Inject constructor(
    private val supabase: SupabaseClient
) : PrayerRepository {

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val _prayers = MutableStateFlow<List<PrayerRequest>>(emptyList())
    private var channelInitialized = false

    private fun ensureChannelStarted() {
        if (channelInitialized) return
        channelInitialized = true

        // Initial load
        scope.launch {
            try {
                val initial = supabase.from("prayer_requests")
                    .select(Columns.raw("*, author:profiles(id,full_name,username,avatar_url)")) {
                        filter { eq("is_answered", false) }
                        order("prayer_count", Order.DESCENDING)
                        order("created_at", Order.DESCENDING)
                        limit(50)
                    }.decodeList<PrayerRequest>()
                _prayers.value = initial
            } catch (_: Exception) {}
        }

        // Realtime INSERT subscription
        val channel = supabase.channel("prayer_wall")
        channel.postgresChangeFlow<PostgresAction.Insert>(schema = "public") {
            table = "prayer_requests"
        }.onEach { change ->
            try {
                val newPrayer = supabase.from("prayer_requests")
                    .select(Columns.raw("*, author:profiles(id,full_name,username,avatar_url)")) {
                        filter { eq("id", change.record["id"]?.toString()?.trim('"') ?: "") }
                        limit(1)
                    }.decodeSingleOrNull<PrayerRequest>()
                if (newPrayer != null) {
                    _prayers.value = listOf(newPrayer) + _prayers.value
                }
            } catch (_: Exception) {}
        }.launchIn(scope)

        scope.launch {
            try { supabase.realtime.connect() } catch (_: Exception) {}
            try { channel.subscribe() } catch (_: Exception) {}
        }
    }

    override fun getPrayerWallFlow(): Flow<List<PrayerRequest>> {
        ensureChannelStarted()
        return _prayers.asStateFlow()
    }

    override suspend fun createPrayer(title: String, content: String, isAnonymous: Boolean): Result<PrayerRequest> {
        return try {
            val userId = supabase.auth.currentUserOrNull()?.id
                ?: return Result.failure(Exception("Not authenticated"))
            val body = buildJsonObject {
                put("user_id", userId)
                put("title", title)
                put("content", content)
                put("is_anonymous", isAnonymous)
            }
            val prayer = supabase.from("prayer_requests")
                .insert(body) {
                    select(Columns.raw("*, author:profiles(id,full_name,username,avatar_url)"))
                }.decodeSingle<PrayerRequest>()
            Result.success(prayer)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun prayForRequest(prayerRequestId: String): Result<Unit> {
        return try {
            val userId = supabase.auth.currentUserOrNull()?.id
                ?: return Result.failure(Exception("Not authenticated"))
            supabase.from("prayer_responses").insert(buildJsonObject {
                put("prayer_request_id", prayerRequestId)
                put("user_id", userId)
            })
            // Optimistically update local state
            _prayers.value = _prayers.value.map { prayer ->
                if (prayer.id == prayerRequestId) {
                    prayer.copy(prayerCount = prayer.prayerCount + 1, hasPrayed = true)
                } else prayer
            }
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun markAnswered(prayerRequestId: String): Result<Unit> {
        return try {
            supabase.from("prayer_requests").update(buildJsonObject {
                put("is_answered", true)
            }) {
                filter { eq("id", prayerRequestId) }
            }
            _prayers.value = _prayers.value.filter { it.id != prayerRequestId }
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
