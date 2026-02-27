package com.faithfeed.app.data.model

import androidx.compose.runtime.Immutable
import androidx.room.Entity
import androidx.room.PrimaryKey
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/** Remote DTO from Supabase bible_verses table */
@Immutable
@Serializable
data class BibleVerse(
    val id: Int = 0,
    val book: String = "",
    val chapter: Int = 0,
    val verse: Int = 0,
    val text: String = "",
    val testament: String = "OT",
    @SerialName("book_order") val bookOrder: Int = 0
)

/** Room entity for local offline cache */
@Entity(tableName = "bible_verses")
data class BibleVerseEntity(
    @PrimaryKey val id: Int,
    val book: String,
    val chapter: Int,
    val verse: Int,
    val text: String,
    val testament: String,
    val bookOrder: Int
)

fun BibleVerse.toEntity() = BibleVerseEntity(
    id = id, book = book, chapter = chapter, verse = verse,
    text = text, testament = testament, bookOrder = bookOrder
)

fun BibleVerseEntity.toDomain() = BibleVerse(
    id = id, book = book, chapter = chapter, verse = verse,
    text = text, testament = testament, bookOrder = bookOrder
)
