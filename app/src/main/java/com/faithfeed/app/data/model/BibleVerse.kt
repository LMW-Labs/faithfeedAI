package com.faithfeed.app.data.model

import androidx.compose.runtime.Immutable
import androidx.room.Entity
import androidx.room.PrimaryKey
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/** Remote DTO from Supabase bible_verses table
 *  Actual columns: id (bigint), book_name, chapter_number, verse_number, text, embedding
 */
@Immutable
@Serializable
data class BibleVerse(
    val id: Long = 0,
    @SerialName("book_name") val book: String = "",
    @SerialName("chapter_number") val chapter: Int = 0,
    @SerialName("verse_number") val verse: Int = 0,
    val text: String = ""
)

/** Room entity for local offline cache */
@Entity(tableName = "bible_verses")
data class BibleVerseEntity(
    @PrimaryKey val id: Long,
    val book: String,
    val chapter: Int,
    val verse: Int,
    val text: String
)

fun BibleVerse.toEntity() = BibleVerseEntity(
    id = id, book = book, chapter = chapter, verse = verse, text = text
)

fun BibleVerseEntity.toDomain() = BibleVerse(
    id = id, book = book, chapter = chapter, verse = verse, text = text
)
