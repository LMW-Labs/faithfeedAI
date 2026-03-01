package com.faithfeed.app.data.repository

import com.faithfeed.app.BuildConfig
import com.faithfeed.app.data.local.dao.BibleVerseDao
import com.faithfeed.app.data.model.BibleVerse
import com.faithfeed.app.data.model.Note
import com.faithfeed.app.data.model.toDomain
import com.faithfeed.app.data.model.toEntity
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.postgrest
import io.github.jan.supabase.postgrest.query.Columns
import io.ktor.client.HttpClient
import io.ktor.client.call.body
import io.ktor.client.request.bearerAuth
import io.ktor.client.request.post
import io.ktor.client.request.setBody
import io.ktor.http.ContentType
import io.ktor.http.contentType
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.postgrest.query.Order
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import javax.inject.Inject

interface BibleRepository {
    fun getChapter(book: String, chapter: Int): Flow<List<BibleVerse>>
    fun getAllBooks(): Flow<List<String>>
    fun getChapters(book: String): Flow<List<Int>>
    fun searchLocal(query: String): Flow<List<BibleVerse>>
    fun getNotesFlow(): Flow<List<Note>>
    fun getNoteFlow(noteId: String): Flow<Note?>
    suspend fun saveNote(title: String, content: String, verseRef: String?, tags: List<String>): Result<Note>
    suspend fun updateNote(id: String, title: String, content: String, verseRef: String?, tags: List<String>): Result<Note>
    suspend fun deleteNote(noteId: String): Result<Unit>
    /** Returns user's own notes for a specific verse reference (e.g. "John 3:16") */
    suspend fun getNotesByVerse(verseRef: String): List<Note>
    /** pgvector semantic search — queries Supabase directly */
    suspend fun semanticSearch(query: String, limit: Int = 10): Result<List<BibleVerse>>
    /** Sync all 31K verses from Supabase into Room on first launch */
    suspend fun syncVersesIfNeeded(): Result<Unit>
}

// ── OpenAI wire types ──────────────────────────────────────────────────────

@Serializable
private data class EmbeddingRequest(
    val model: String,
    val input: String
)

@Serializable
private data class EmbeddingData(
    val embedding: List<Float>
)

@Serializable
private data class EmbeddingResponse(
    val data: List<EmbeddingData>
)

// ── Fallback book list ─────────────────────────────────────────────────────

private val ALL_BIBLE_BOOKS = listOf(
    "Genesis", "Exodus", "Leviticus", "Numbers", "Deuteronomy", "Joshua", "Judges", "Ruth",
    "1 Samuel", "2 Samuel", "1 Kings", "2 Kings", "1 Chronicles", "2 Chronicles", "Ezra",
    "Nehemiah", "Esther", "Job", "Psalms", "Proverbs", "Ecclesiastes", "Song of Solomon",
    "Isaiah", "Jeremiah", "Lamentations", "Ezekiel", "Daniel", "Hosea", "Joel", "Amos",
    "Obadiah", "Jonah", "Micah", "Nahum", "Habakkuk", "Zephaniah", "Haggai", "Zechariah",
    "Malachi", "Matthew", "Mark", "Luke", "John", "Acts", "Romans", "1 Corinthians",
    "2 Corinthians", "Galatians", "Ephesians", "Philippians", "Colossians",
    "1 Thessalonians", "2 Thessalonians", "1 Timothy", "2 Timothy", "Titus", "Philemon",
    "Hebrews", "James", "1 Peter", "2 Peter", "1 John", "2 John", "3 John", "Jude", "Revelation"
)

class BibleRepositoryImpl @Inject constructor(
    private val supabase: SupabaseClient,
    private val dao: BibleVerseDao,
    private val http: HttpClient
) : BibleRepository {

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val _notes = MutableStateFlow<List<Note>>(emptyList())
    private val _noteMap = mutableMapOf<String, MutableStateFlow<Note?>>()

    private fun currentUserId() = supabase.auth.currentUserOrNull()?.id

    private fun loadNotes() {
        scope.launch {
            val uid = currentUserId() ?: return@launch
            try {
                val notes = supabase.from("verse_notes")
                    .select(Columns.raw("*")) {
                        filter { eq("user_id", uid) }
                        order("updated_at", Order.DESCENDING)
                    }.decodeList<Note>()
                _notes.value = notes
                notes.forEach { note ->
                    _noteMap.getOrPut(note.id) { MutableStateFlow(null) }.value = note
                }
            } catch (_: Exception) {}
        }
    }

    override fun getChapter(book: String, chapter: Int): Flow<List<BibleVerse>> {
        return dao.getChapter(book, chapter).map { list -> list.map { it.toDomain() } }
    }

    override fun getAllBooks(): Flow<List<String>> {
        return dao.getAllBooks().map { books ->
            books.ifEmpty { ALL_BIBLE_BOOKS }
        }
    }

    override fun getChapters(book: String): Flow<List<Int>> {
        return dao.getChapters(book).map { chapters ->
            chapters.ifEmpty { (1..150).toList() }
        }
    }

    override fun searchLocal(query: String): Flow<List<BibleVerse>> {
        return dao.searchLocal(query).map { list -> list.map { it.toDomain() } }
    }

    override fun getNotesFlow(): Flow<List<Note>> {
        loadNotes()
        return _notes.asStateFlow()
    }

    override fun getNoteFlow(noteId: String): Flow<Note?> {
        if (noteId == "new") return flowOf(null)
        return _noteMap.getOrPut(noteId) {
            MutableStateFlow<Note?>(null).also {
                scope.launch {
                    try {
                        val note = supabase.from("verse_notes")
                            .select(Columns.raw("*")) {
                                filter { eq("id", noteId) }
                                limit(1)
                            }.decodeSingleOrNull<Note>()
                        _noteMap[noteId]?.value = note
                    } catch (_: Exception) {}
                }
            }
        }.asStateFlow()
    }

    override suspend fun saveNote(
        title: String, content: String, verseRef: String?, tags: List<String>
    ): Result<Note> = try {
        val uid = currentUserId() ?: return Result.failure(Exception("Not authenticated"))
        val body = buildJsonObject {
            put("user_id", uid)
            put("title", title)
            put("content", content)
            if (verseRef != null) put("verse_ref", verseRef)
            put("tags", JsonArray(tags.map { JsonPrimitive(it) }))
        }
        val note = supabase.from("verse_notes").insert(body) {
            select(Columns.raw("*"))
        }.decodeSingle<Note>()
        _notes.value = listOf(note) + _notes.value
        _noteMap[note.id] = MutableStateFlow(note)
        Result.success(note)
    } catch (e: Exception) {
        Result.failure(e)
    }

    override suspend fun updateNote(
        id: String, title: String, content: String, verseRef: String?, tags: List<String>
    ): Result<Note> = try {
        val body = buildJsonObject {
            put("title", title)
            put("content", content)
            if (verseRef != null) put("verse_ref", verseRef) else put("verse_ref", "")
            put("tags", JsonArray(tags.map { JsonPrimitive(it) }))
        }
        val note = supabase.from("verse_notes").update(body) {
            filter { eq("id", id) }
            select(Columns.raw("*"))
        }.decodeSingle<Note>()
        _notes.value = _notes.value.map { if (it.id == id) note else it }
        _noteMap[id]?.value = note
        Result.success(note)
    } catch (e: Exception) {
        Result.failure(e)
    }

    override suspend fun deleteNote(noteId: String): Result<Unit> = try {
        supabase.from("verse_notes").delete { filter { eq("id", noteId) } }
        _notes.value = _notes.value.filter { it.id != noteId }
        _noteMap.remove(noteId)
        Result.success(Unit)
    } catch (e: Exception) {
        Result.failure(e)
    }

    override suspend fun getNotesByVerse(verseRef: String): List<Note> {
        val uid = currentUserId() ?: return emptyList()
        return runCatching {
            supabase.from("verse_notes")
                .select(Columns.raw("*")) {
                    filter {
                        eq("user_id", uid)
                        eq("verse_ref", verseRef)
                    }
                    order("created_at", Order.DESCENDING)
                    limit(20)
                }.decodeList<Note>()
        }.getOrDefault(emptyList())
    }

    override suspend fun semanticSearch(query: String, limit: Int): Result<List<BibleVerse>> {
        val apiKey = BuildConfig.OPENAI_API_KEY
        if (apiKey.isBlank()) {
            // No API key configured — fall back to empty result rather than crashing
            return Result.success(emptyList())
        }
        return try {
            // 1. Generate embedding from OpenAI text-embedding-3-small (1536 dims)
            val embeddingResponse = http.post("https://api.openai.com/v1/embeddings") {
                bearerAuth(apiKey)
                contentType(ContentType.Application.Json)
                setBody(EmbeddingRequest(model = "text-embedding-3-small", input = query))
            }.body<EmbeddingResponse>()

            val embedding = embeddingResponse.data.firstOrNull()?.embedding
                ?: return Result.failure(Exception("No embedding returned from OpenAI"))

            // 2. Call Supabase RPC match_bible_verses with the pgvector embedding
            //    Postgres expects the vector as a bracket-delimited float string, e.g. [0.1,0.2,...]
            val verses = supabase.postgrest.rpc(
                "match_bible_verses",
                buildJsonObject {
                    put("query_embedding", embedding.joinToString(",", "[", "]"))
                    put("match_count", limit)
                }
            ).decodeList<BibleVerse>()

            Result.success(verses)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun syncVersesIfNeeded(): Result<Unit> {
        return try {
            if (dao.count() > 0) return Result.success(Unit)

            // Fetch in batches of 1000 — intentionally excludes the embedding column
            // (1536 floats per row would be ~24 MB for the full table)
            var offset = 0
            val batchSize = 1000
            while (true) {
                val batch = supabase.from("bible_verses")
                    .select(Columns.raw("id,book_name,chapter_number,verse_number,text")) {
                        range(offset.toLong(), (offset + batchSize - 1).toLong())
                    }.decodeList<BibleVerse>()

                if (batch.isEmpty()) break
                dao.insertAll(batch.map { it.toEntity() })
                offset += batchSize
                if (batch.size < batchSize) break
            }
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
