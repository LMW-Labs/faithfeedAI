package com.faithfeed.app.data.repository

import com.faithfeed.app.data.model.Notification
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

interface NotificationRepository {
    fun getNotificationsFlow(): Flow<List<Notification>>
    suspend fun markAllRead(): Result<Unit>
    suspend fun markRead(notificationId: String): Result<Unit>
    suspend fun getUnreadCount(): Int
}

class NotificationRepositoryImpl @Inject constructor(
    private val supabase: SupabaseClient
) : NotificationRepository {

    private fun currentUserId(): String? = supabase.auth.currentUserOrNull()?.id

    /**
     * Cold flow — fetches once on collection. Notifications are low-volume so a
     * simple fetch-on-demand pattern is appropriate (no Realtime subscription needed).
     * Caller can re-collect (e.g. pull-to-refresh) to get fresh data.
     */
    override fun getNotificationsFlow(): Flow<List<Notification>> = flow {
        val uid = currentUserId() ?: run { emit(emptyList()); return@flow }
        val result = runCatching {
            supabase.from("notifications")
                .select(Columns.raw("*, actor:profiles!actor_id(id,full_name,username,avatar_url)")) {
                    filter { eq("user_id", uid) }
                    order("created_at", Order.DESCENDING)
                    limit(50)
                }.decodeList<Notification>()
        }
        emit(result.getOrDefault(emptyList()))
    }

    override suspend fun markAllRead(): Result<Unit> = runCatching {
        val uid = currentUserId() ?: error("Not authenticated")
        supabase.from("notifications").update(buildJsonObject { put("is_read", true) }) {
            filter {
                eq("user_id", uid)
                eq("is_read", false)
            }
        }
    }

    override suspend fun markRead(notificationId: String): Result<Unit> = runCatching {
        supabase.from("notifications").update(buildJsonObject { put("is_read", true) }) {
            filter { eq("id", notificationId) }
        }
    }

    override suspend fun getUnreadCount(): Int {
        val uid = currentUserId() ?: return 0
        return runCatching {
            // COUNT query — decode as list and take size; avoids custom wrapper type
            supabase.from("notifications")
                .select(Columns.raw("id")) {
                    filter {
                        eq("user_id", uid)
                        eq("is_read", false)
                    }
                }.decodeList<Map<String, String>>().size
        }.getOrDefault(0)
    }
}
