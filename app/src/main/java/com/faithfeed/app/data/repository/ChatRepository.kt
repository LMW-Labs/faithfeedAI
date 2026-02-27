package com.faithfeed.app.data.repository

import com.faithfeed.app.data.model.Chat
import com.faithfeed.app.data.model.Message
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
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import javax.inject.Inject

@Serializable
private data class ChatMemberRow(
    @SerialName("chat_id") val chatId: String = ""
)

interface ChatRepository {
    fun getConversationsFlow(): Flow<List<Chat>>
    fun getMessagesFlow(chatId: String): Flow<List<Message>>
    suspend fun sendMessage(chatId: String, content: String, mediaUrl: String?): Result<Message>
    suspend fun createDirectChat(otherUserId: String, otherUserName: String): Result<Chat>
    suspend fun markRead(chatId: String): Result<Unit>
}

class ChatRepositoryImpl @Inject constructor(
    private val supabase: SupabaseClient
) : ChatRepository {

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val _conversations = MutableStateFlow<List<Chat>>(emptyList())
    private val messageFlows = mutableMapOf<String, MutableStateFlow<List<Message>>>()
    private var conversationsReady = false

    private fun currentUserId() = supabase.auth.currentUserOrNull()?.id

    // ── Conversations ─────────────────────────────────────────────────────────

    private fun ensureConversationsLoaded() {
        if (conversationsReady) return
        conversationsReady = true
        scope.launch {
            val uid = currentUserId() ?: return@launch
            try {
                val chatIds = supabase.from("chat_members")
                    .select(Columns.raw("chat_id")) {
                        filter { eq("user_id", uid) }
                    }.decodeList<ChatMemberRow>()
                    .map { it.chatId }
                if (chatIds.isEmpty()) return@launch
                val chats = supabase.from("chats")
                    .select(Columns.raw("*")) {
                        filter { isIn("id", chatIds) }
                        order("last_message_at", Order.DESCENDING)
                    }.decodeList<Chat>()
                _conversations.value = chats
            } catch (_: Exception) {}
        }
    }

    override fun getConversationsFlow(): Flow<List<Chat>> {
        ensureConversationsLoaded()
        return _conversations.asStateFlow()
    }

    // ── Messages ──────────────────────────────────────────────────────────────

    private fun getOrCreateMessageFlow(chatId: String): MutableStateFlow<List<Message>> {
        return messageFlows.getOrPut(chatId) {
            MutableStateFlow(emptyList<Message>()).also { flow ->
                scope.launch { startMessageChannel(chatId, flow) }
            }
        }
    }

    private suspend fun startMessageChannel(chatId: String, flow: MutableStateFlow<List<Message>>) {
        // Initial load
        try {
            val msgs = supabase.from("chat_messages")
                .select(Columns.raw("*, sender:profiles(id,full_name,username,avatar_url)")) {
                    filter { eq("chat_id", chatId) }
                    order("created_at", Order.ASCENDING)
                }.decodeList<Message>()
            flow.value = msgs
        } catch (_: Exception) {}

        // Realtime INSERT subscription — filter by chatId in the onEach callback
        val channel = supabase.channel("chat-$chatId")
        channel.postgresChangeFlow<PostgresAction.Insert>(schema = "public") {
            table = "chat_messages"
        }.onEach { action ->
            try {
                val recordChatId = action.record["chat_id"]?.toString()?.trim('"') ?: return@onEach
                if (recordChatId != chatId) return@onEach
                val msgId = action.record["id"]?.toString()?.trim('"') ?: return@onEach
                val msg = supabase.from("chat_messages")
                    .select(Columns.raw("*, sender:profiles(id,full_name,username,avatar_url)")) {
                        filter { eq("id", msgId) }
                        limit(1)
                    }.decodeSingleOrNull<Message>()
                if (msg != null) {
                    flow.value = flow.value + msg
                }
            } catch (_: Exception) {}
        }.launchIn(scope)

        scope.launch {
            try { supabase.realtime.connect() } catch (_: Exception) {}
            try { channel.subscribe() } catch (_: Exception) {}
        }
    }

    override fun getMessagesFlow(chatId: String): Flow<List<Message>> {
        return getOrCreateMessageFlow(chatId).asStateFlow()
    }

    // ── Send ──────────────────────────────────────────────────────────────────

    override suspend fun sendMessage(chatId: String, content: String, mediaUrl: String?): Result<Message> = try {
        val uid = currentUserId() ?: return Result.failure(Exception("Not authenticated"))
        val body = buildJsonObject {
            put("chat_id", chatId)
            put("sender_id", uid)
            put("content", content)
            if (mediaUrl != null) put("media_url", mediaUrl)
        }
        val msg = supabase.from("chat_messages").insert(body) {
            select(Columns.raw("*, sender:profiles(id,full_name,username,avatar_url)"))
        }.decodeSingle<Message>()
        // Update last_message on chat
        supabase.from("chats").update(buildJsonObject {
            put("last_message", content)
            put("last_message_at", msg.createdAt)
        }) { filter { eq("id", chatId) } }
        // Refresh local conversation list
        _conversations.value = _conversations.value.map {
            if (it.id == chatId) it.copy(lastMessage = content, lastMessageAt = msg.createdAt) else it
        }
        Result.success(msg)
    } catch (e: Exception) {
        Result.failure(e)
    }

    // ── Create chat ───────────────────────────────────────────────────────────

    override suspend fun createDirectChat(otherUserId: String, otherUserName: String): Result<Chat> = try {
        val uid = currentUserId() ?: return Result.failure(Exception("Not authenticated"))
        val chat = supabase.from("chats").insert(buildJsonObject {
            put("is_group", false)
            put("name", otherUserName)
        }) {
            select(Columns.raw("*"))
        }.decodeSingle<Chat>()
        supabase.from("chat_members").insert(buildJsonObject {
            put("chat_id", chat.id)
            put("user_id", uid)
        })
        supabase.from("chat_members").insert(buildJsonObject {
            put("chat_id", chat.id)
            put("user_id", otherUserId)
        })
        _conversations.value = listOf(chat) + _conversations.value
        Result.success(chat)
    } catch (e: Exception) {
        Result.failure(e)
    }

    // ── Mark read ─────────────────────────────────────────────────────────────

    override suspend fun markRead(chatId: String): Result<Unit> = try {
        val uid = currentUserId() ?: return Result.failure(Exception("Not authenticated"))
        supabase.from("chat_messages").update(buildJsonObject {
            put("is_read", true)
        }) {
            filter {
                eq("chat_id", chatId)
                neq("sender_id", uid)
                eq("is_read", false)
            }
        }
        Result.success(Unit)
    } catch (e: Exception) {
        Result.failure(e)
    }
}
