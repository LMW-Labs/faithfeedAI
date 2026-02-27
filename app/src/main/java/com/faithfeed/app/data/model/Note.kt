package com.faithfeed.app.data.model

import androidx.compose.runtime.Immutable
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Immutable
@Serializable
data class Note(
    val id: String = "",
    @SerialName("user_id") val userId: String = "",
    val title: String = "",
    val content: String = "",
    @SerialName("verse_ref") val verseRef: String? = null,
    val tags: List<String> = emptyList(),
    @SerialName("created_at") val createdAt: String = "",
    @SerialName("updated_at") val updatedAt: String = ""
)
