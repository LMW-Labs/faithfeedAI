package com.faithfeed.app.data.model

import androidx.compose.runtime.Immutable
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/** One Strongs-tagged word occurrence in a verse (verse_strongs table). */
@Immutable
@Serializable
data class StrongsEntry(
    val reference: String = "",
    @SerialName("strongs_tag") val strongsTag: String = "",
    @SerialName("word_position") val wordPosition: Int = 0
)

/** Full lexicon entry for a Strongs number (strongs_lexicon table). */
@Immutable
@Serializable
data class StrongsLexiconEntry(
    @SerialName("strongs_tag") val strongsTag: String = "",
    val language: String = "",      // "H" or "G"
    val lemma: String = "",
    val transliteration: String = "",
    val morph: String = "",
    val gloss: String = "",
    val definition: String = ""     // HTML from BDB/LSJ
)
