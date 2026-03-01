package com.faithfeed.app.data.local

import androidx.room.Database
import androidx.room.RoomDatabase
import com.faithfeed.app.data.local.dao.BibleVerseDao
import com.faithfeed.app.data.local.dao.DraftPostDao
import com.faithfeed.app.data.local.dao.DraftPostEntity
import com.faithfeed.app.data.local.dao.VerseHighlightDao
import com.faithfeed.app.data.model.BibleVerseEntity

@Database(
    entities = [BibleVerseEntity::class, DraftPostEntity::class, VerseHighlightEntity::class],
    version = 3,
    exportSchema = false
)
abstract class FaithFeedDatabase : RoomDatabase() {
    abstract fun bibleVerseDao(): BibleVerseDao
    abstract fun draftPostDao(): DraftPostDao
    abstract fun verseHighlightDao(): VerseHighlightDao
}
