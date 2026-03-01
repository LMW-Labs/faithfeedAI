package com.faithfeed.app.data.repository

import com.faithfeed.app.data.model.StrongsEntry
import com.faithfeed.app.data.model.StrongsLexiconEntry
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.query.Columns
import io.github.jan.supabase.postgrest.query.Order
import javax.inject.Inject

interface ConcordanceRepository {
    /** Returns all Strongs-tagged words for a verse reference (e.g. "Gen 1:1"). */
    suspend fun getStrongsForVerse(reference: String): Result<List<StrongsEntry>>

    /** Returns all verse references tagged with a given Strongs number, ordered by position. */
    suspend fun getVersesByStrongs(strongsTag: String): Result<List<String>>

    /** Returns the lexicon entry for a Strongs number (null if not found). */
    suspend fun getLexiconEntry(strongsTag: String): Result<StrongsLexiconEntry?>

    /** Bulk-fetches lexicon entries for a set of Strongs tags — one round-trip. */
    suspend fun getLexiconEntries(tags: List<String>): Result<List<StrongsLexiconEntry>>
}

class ConcordanceRepositoryImpl @Inject constructor(
    private val supabase: SupabaseClient
) : ConcordanceRepository {

    override suspend fun getStrongsForVerse(reference: String): Result<List<StrongsEntry>> =
        runCatching {
            supabase.from("verse_strongs")
                .select(Columns.raw("reference, strongs_tag, word_position")) {
                    filter { eq("reference", reference) }
                    order("word_position", Order.ASCENDING)
                }
                .decodeList<StrongsEntry>()
        }

    override suspend fun getVersesByStrongs(strongsTag: String): Result<List<String>> =
        runCatching {
            supabase.from("verse_strongs")
                .select(Columns.raw("reference")) {
                    filter { eq("strongs_tag", strongsTag) }
                    order("reference", Order.ASCENDING)
                    limit(200)
                }
                .decodeList<StrongsEntry>()
                .map { it.reference }
                .distinct()
        }

    override suspend fun getLexiconEntry(strongsTag: String): Result<StrongsLexiconEntry?> =
        runCatching {
            supabase.from("strongs_lexicon")
                .select(Columns.raw("*")) {
                    filter { eq("strongs_tag", strongsTag) }
                    limit(1)
                }
                .decodeSingleOrNull<StrongsLexiconEntry>()
        }

    override suspend fun getLexiconEntries(tags: List<String>): Result<List<StrongsLexiconEntry>> =
        runCatching {
            if (tags.isEmpty()) return@runCatching emptyList()
            supabase.from("strongs_lexicon")
                .select(Columns.raw("*")) {
                    filter { isIn("strongs_tag", tags) }
                }
                .decodeList<StrongsLexiconEntry>()
        }
}
