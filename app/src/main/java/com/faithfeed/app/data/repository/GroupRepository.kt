package com.faithfeed.app.data.repository

import com.faithfeed.app.data.mock.MockData
import com.faithfeed.app.data.model.Group
import io.github.jan.supabase.SupabaseClient
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flowOf
import javax.inject.Inject

interface GroupRepository {
    fun getMyGroupsFlow(): Flow<List<Group>>
    fun getDiscoverGroupsFlow(): Flow<List<Group>>
    fun getGroupFlow(groupId: String): Flow<Group?>
    suspend fun createGroup(name: String, description: String, isPrivate: Boolean): Result<Group>
    suspend fun joinGroup(groupId: String): Result<Unit>
    suspend fun leaveGroup(groupId: String): Result<Unit>
}

class GroupRepositoryImpl @Inject constructor(
    private val supabase: SupabaseClient
) : GroupRepository {
    override fun getMyGroupsFlow(): Flow<List<Group>> = flowOf(MockData.groups)
    override fun getDiscoverGroupsFlow(): Flow<List<Group>> = flowOf(MockData.groups)
    override fun getGroupFlow(groupId: String): Flow<Group?> = flowOf(MockData.groups.find { it.id == groupId })
    override suspend fun createGroup(name: String, description: String, isPrivate: Boolean): Result<Group> = Result.success(MockData.groups.first())
    override suspend fun joinGroup(groupId: String): Result<Unit> = Result.success(Unit)
    override suspend fun leaveGroup(groupId: String): Result<Unit> = Result.success(Unit)
}
