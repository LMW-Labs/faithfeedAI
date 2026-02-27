package com.faithfeed.app.data.local.dao

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Entity
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.PrimaryKey
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

@Entity(tableName = "draft_posts")
data class DraftPostEntity(
    @PrimaryKey val id: String,
    val content: String,
    val mediaUris: String = "", // comma-separated local URIs
    val verseRef: String = "",
    val audience: String = "public",
    val savedAt: Long = System.currentTimeMillis()
)

@Dao
interface DraftPostDao {

    @Query("SELECT * FROM draft_posts ORDER BY savedAt DESC")
    fun getAllDrafts(): Flow<List<DraftPostEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun saveDraft(draft: DraftPostEntity)

    @Delete
    suspend fun deleteDraft(draft: DraftPostEntity)

    @Query("DELETE FROM draft_posts WHERE id = :id")
    suspend fun deleteDraftById(id: String)
}
