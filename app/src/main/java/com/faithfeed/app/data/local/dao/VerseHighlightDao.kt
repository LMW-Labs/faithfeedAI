package com.faithfeed.app.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.faithfeed.app.data.local.VerseHighlightEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface VerseHighlightDao {
    @Query("SELECT * FROM verse_highlights")
    fun getAllFlow(): Flow<List<VerseHighlightEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(highlight: VerseHighlightEntity)

    @Query("DELETE FROM verse_highlights WHERE reference = :reference")
    suspend fun delete(reference: String)
}
