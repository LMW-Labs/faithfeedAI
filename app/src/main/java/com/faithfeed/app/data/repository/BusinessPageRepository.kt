package com.faithfeed.app.data.repository

import com.faithfeed.app.data.model.BusinessPage
import io.github.jan.supabase.SupabaseClient
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flowOf
import javax.inject.Inject

interface BusinessPageRepository {
    fun getPageFlow(pageId: String): Flow<BusinessPage?>
    suspend fun createPage(page: BusinessPage): Result<BusinessPage>
    suspend fun toggleFollow(pageId: String): Result<Unit>
    suspend fun searchPages(query: String): Result<List<BusinessPage>>
}

class BusinessPageRepositoryImpl @Inject constructor(
    private val supabase: SupabaseClient
) : BusinessPageRepository {
    override fun getPageFlow(pageId: String): Flow<BusinessPage?> = flowOf(null)
    override suspend fun createPage(page: BusinessPage): Result<BusinessPage> = Result.failure(NotImplementedError())
    override suspend fun toggleFollow(pageId: String): Result<Unit> = Result.failure(NotImplementedError())
    override suspend fun searchPages(query: String): Result<List<BusinessPage>> = Result.success(emptyList())
}
