package com.faithfeed.app.data.local

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "verse_highlights")
data class VerseHighlightEntity(
    @PrimaryKey val reference: String,  // e.g. "Gen 1:1"
    val colorHex: String                // e.g. "#C9A84C"
)
