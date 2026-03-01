package com.faithfeed.app.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.faithfeed.app.data.model.BibleVerseEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface BibleVerseDao {

    @Query("SELECT * FROM bible_verses WHERE book = :book AND chapter = :chapter ORDER BY verse ASC")
    fun getChapter(book: String, chapter: Int): Flow<List<BibleVerseEntity>>

    @Query("SELECT * FROM bible_verses WHERE id = :id")
    suspend fun getById(id: Long): BibleVerseEntity?

    @Query("SELECT book FROM bible_verses GROUP BY book ORDER BY MIN(id) ASC")
    fun getAllBooks(): Flow<List<String>>

    @Query("SELECT DISTINCT chapter FROM bible_verses WHERE book = :book ORDER BY chapter ASC")
    fun getChapters(book: String): Flow<List<Int>>

    @Query("SELECT * FROM bible_verses WHERE text LIKE '%' || :query || '%' LIMIT 50")
    fun searchLocal(query: String): Flow<List<BibleVerseEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(verses: List<BibleVerseEntity>)

    @Query("SELECT COUNT(*) FROM bible_verses")
    suspend fun count(): Int
}
