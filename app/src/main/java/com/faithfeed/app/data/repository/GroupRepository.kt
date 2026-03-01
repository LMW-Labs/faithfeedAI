package com.faithfeed.app.data.repository

import com.faithfeed.app.data.model.Group
import com.faithfeed.app.data.model.User
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.query.Columns
import io.github.jan.supabase.postgrest.query.Order
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import javax.inject.Inject

interface GroupRepository {
    fun getMyGroupsFlow(): Flow<List<Group>>
    fun getDiscoverGroupsFlow(): Flow<List<Group>>
    fun getGroupFlow(groupId: String): Flow<Group?>
    suspend fun createGroup(name: String, description: String, isPrivate: Boolean): Result<Group>
    suspend fun joinGroup(groupId: String): Result<Unit>
    suspend fun leaveGroup(groupId: String): Result<Unit>
    suspend fun getGroupMembers(groupId: String): List<User>
}

private val GROUP_COLUMNS = "id,name,description,cover_url,member_count,is_private,created_by,created_at"

@Serializable
private data class GroupIdRow(@SerialName("group_id") val groupId: String = "")

@Serializable
private data class GroupMemberRow(val profiles: MemberProfile? = null)

@Serializable
private data class MemberProfile(
    val id: String = "",
    @SerialName("full_name") val fullName: String = "",
    val username: String = "",
    @SerialName("avatar_url") val avatarUrl: String? = null,
    @SerialName("is_verified") val isVerified: Boolean = false
)

class GroupRepositoryImpl @Inject constructor(
    private val supabase: SupabaseClient
) : GroupRepository {

    private fun currentUserId(): String? = supabase.auth.currentUserOrNull()?.id

    override fun getMyGroupsFlow(): Flow<List<Group>> = flow {
        val uid = currentUserId() ?: run { emit(emptyList()); return@flow }
        val ids = supabase.from("group_members")
            .select(Columns.raw("group_id")) {
                filter { eq("user_id", uid) }
            }.decodeList<GroupIdRow>().map { it.groupId }
        if (ids.isEmpty()) { emit(emptyList()); return@flow }
        val groups = supabase.from("groups")
            .select(Columns.raw(GROUP_COLUMNS)) {
                filter { isIn("id", ids) }
                order("created_at", Order.DESCENDING)
            }.decodeList<Group>().map { it.copy(isMember = true) }
        emit(groups)
    }

    override fun getDiscoverGroupsFlow(): Flow<List<Group>> = flow {
        val groups = supabase.from("groups")
            .select(Columns.raw(GROUP_COLUMNS)) {
                filter { eq("is_private", false) }
                order("member_count", Order.DESCENDING)
                limit(50)
            }.decodeList<Group>()
        emit(groups)
    }

    override fun getGroupFlow(groupId: String): Flow<Group?> = flow {
        if (groupId.isEmpty()) { emit(null); return@flow }
        val uid = currentUserId()
        val group = supabase.from("groups")
            .select(Columns.raw(GROUP_COLUMNS)) {
                filter { eq("id", groupId) }
                limit(1)
            }.decodeSingleOrNull<Group>() ?: run { emit(null); return@flow }
        val isMember = uid != null && supabase.from("group_members")
            .select(Columns.raw("group_id")) {
                filter {
                    eq("group_id", groupId)
                    eq("user_id", uid)
                }
                limit(1)
            }.decodeList<GroupIdRow>().isNotEmpty()
        emit(group.copy(isMember = isMember))
    }

    override suspend fun createGroup(name: String, description: String, isPrivate: Boolean): Result<Group> = runCatching {
        val uid = currentUserId() ?: error("Not authenticated")
        val group = supabase.from("groups").insert(buildJsonObject {
            put("name", name)
            put("description", description)
            put("is_private", isPrivate)
            put("created_by", uid)
        }) {
            select(Columns.raw(GROUP_COLUMNS))
        }.decodeSingle<Group>()
        supabase.from("group_members").insert(buildJsonObject {
            put("group_id", group.id)
            put("user_id", uid)
            put("role", "admin")
        })
        group.copy(isMember = true)
    }

    override suspend fun joinGroup(groupId: String): Result<Unit> = runCatching {
        val uid = currentUserId() ?: error("Not authenticated")
        supabase.from("group_members").insert(buildJsonObject {
            put("group_id", groupId)
            put("user_id", uid)
            put("role", "member")
        })
    }

    override suspend fun leaveGroup(groupId: String): Result<Unit> = runCatching {
        val uid = currentUserId() ?: error("Not authenticated")
        supabase.from("group_members").delete {
            filter {
                eq("group_id", groupId)
                eq("user_id", uid)
            }
        }
    }

    override suspend fun getGroupMembers(groupId: String): List<User> = try {
        supabase.from("group_members")
            .select(Columns.raw("profiles(id,full_name,username,avatar_url,is_verified)")) {
                filter { eq("group_id", groupId) }
                limit(50)
            }.decodeList<GroupMemberRow>()
            .mapNotNull { row ->
                row.profiles?.let { p ->
                    User(
                        id = p.id,
                        displayName = p.fullName,
                        username = p.username,
                        avatarUrl = p.avatarUrl,
                        isVerified = p.isVerified
                    )
                }
            }
    } catch (_: Exception) {
        emptyList()
    }
}
