package com.faithfeed.app.data.repository

import com.faithfeed.app.BuildConfig
import com.faithfeed.app.data.model.AIMessage
import io.github.jan.supabase.SupabaseClient
import io.ktor.client.HttpClient
import io.ktor.client.call.body
import io.ktor.client.request.bearerAuth
import io.ktor.client.request.post
import io.ktor.client.request.setBody
import io.ktor.http.ContentType
import io.ktor.http.contentType
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import java.util.UUID
import javax.inject.Inject

// ── OpenAI wire types ──────────────────────────────────────────────────────────

@Serializable
private data class OAIMessage(val role: String, val content: String)

@Serializable
private data class OAIRequest(
    val model: String = "gpt-4o-mini",
    val messages: List<OAIMessage>,
    val temperature: Double = 0.7,
    @SerialName("max_tokens") val maxTokens: Int = 1024
)

@Serializable
private data class OAIChoice(val message: OAIMessage)

@Serializable
private data class OAIResponse(val choices: List<OAIChoice>)

// ── Interface (unchanged) ──────────────────────────────────────────────────────

interface AIRepository {
    /** Chat completion with Bible context injected via pgvector semantic search */
    suspend fun chat(conversationHistory: List<AIMessage>, userMessage: String): Result<AIMessage>
    /** Single-call summarizer for a Bible chapter */
    suspend fun summarizeChapter(book: String, chapter: Int, verseTexts: List<String>): Result<String>
    /** Generate a daily devotional for a given verse */
    suspend fun generateDevotional(verseRef: String, verseText: String): Result<String>
    /** Get thematic verse guidance for a topic */
    suspend fun getThematicGuidance(topic: String): Result<List<AIMessage>>
    /** Generate a personal study plan */
    suspend fun generateStudyPlan(topic: String, durationDays: Int): Result<String>
    /** Commentary on a specific verse */
    suspend fun getVerseCommentary(verseRef: String, verseText: String): Result<String>
    /** Transcribe sermon audio and extract verse references */
    suspend fun transcribeAndExtractVerses(audioPath: String): Result<Pair<String, List<String>>>
}

// ── Implementation ─────────────────────────────────────────────────────────────

class AIRepositoryImpl @Inject constructor(
    private val supabase: SupabaseClient,
    private val httpClient: HttpClient
) : AIRepository {

    private val openAiUrl = "https://api.openai.com/v1/chat/completions"

    private suspend fun complete(messages: List<OAIMessage>, maxTokens: Int = 1024): Result<String> {
        return try {
            val key = BuildConfig.OPENAI_API_KEY
            if (key.isBlank()) return Result.failure(Exception("OpenAI API key not configured. Add OPENAI_API_KEY to local.properties."))
            val response = httpClient.post(openAiUrl) {
                bearerAuth(key)
                contentType(ContentType.Application.Json)
                setBody(OAIRequest(messages = messages, maxTokens = maxTokens))
            }
            val body = response.body<OAIResponse>()
            val content = body.choices.firstOrNull()?.message?.content
                ?: return Result.failure(Exception("Empty response from OpenAI"))
            Result.success(content.trim())
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun chat(
        conversationHistory: List<AIMessage>,
        userMessage: String
    ): Result<AIMessage> {
        val system = OAIMessage(
            role = "system",
            content = """You are a knowledgeable and compassionate Bible study partner on the FaithFeed app.
Answer questions from a Christian perspective, citing relevant scripture where appropriate.
Keep responses warm, concise, and spiritually grounding. Format for mobile reading — short paragraphs."""
        )
        val history = conversationHistory.map { OAIMessage(role = it.role, content = it.content) }
        val user = OAIMessage(role = "user", content = userMessage)
        return complete(listOf(system) + history + user, maxTokens = 512).map { content ->
            AIMessage(id = UUID.randomUUID().toString(), role = "assistant", content = content)
        }
    }

    override suspend fun summarizeChapter(
        book: String,
        chapter: Int,
        verseTexts: List<String>
    ): Result<String> {
        val verseContent = if (verseTexts.isNotEmpty())
            "\n\nVerse texts:\n${verseTexts.joinToString("\n")}"
        else ""
        val messages = listOf(
            OAIMessage(
                role = "system",
                content = "You are a Bible scholar summarizing scripture for a Christian mobile app. Be concise, insightful, and devotional."
            ),
            OAIMessage(
                role = "user",
                content = "Summarize $book chapter $chapter. Cover: key themes, main characters or events, and one practical takeaway for modern believers.$verseContent"
            )
        )
        return complete(messages, maxTokens = 600)
    }

    override suspend fun generateDevotional(verseRef: String, verseText: String): Result<String> {
        val messages = listOf(
            OAIMessage(
                role = "system",
                content = "You are a devotional writer for a Christian app. Write warm, personal, scripture-grounded devotionals of 200–300 words."
            ),
            OAIMessage(
                role = "user",
                content = """Write a daily devotional based on this theme or verse: "$verseText"

Structure it as:
1. Opening reflection (2–3 sentences)
2. Scripture connection
3. Personal application
4. Closing prayer (1–2 sentences)

If a specific verse was given, reference it. Keep the tone intimate and encouraging."""
            )
        )
        return complete(messages, maxTokens = 512)
    }

    override suspend fun getThematicGuidance(topic: String): Result<List<AIMessage>> {
        val messages = listOf(
            OAIMessage(
                role = "system",
                content = "You are a biblical counselor providing scripture-based guidance. Be practical, compassionate, and grounded in God's Word."
            ),
            OAIMessage(
                role = "user",
                content = """Provide biblical guidance on the topic: "$topic"

Include:
- 2–3 relevant Bible verses (with references)
- A brief explanation of how each verse applies
- One practical step the reader can take today

Format clearly for mobile reading."""
            )
        )
        return complete(messages, maxTokens = 600).map { content ->
            listOf(AIMessage(id = UUID.randomUUID().toString(), role = "assistant", content = content))
        }
    }

    override suspend fun generateStudyPlan(topic: String, durationDays: Int): Result<String> {
        val messages = listOf(
            OAIMessage(
                role = "system",
                content = "You are a Bible curriculum designer creating structured study plans for Christians. Be thorough but accessible."
            ),
            OAIMessage(
                role = "user",
                content = """Create a $durationDays-day Bible study plan on: "$topic"

For each day include:
- Day number and title
- Scripture reading (book, chapter, and verses)
- One key truth to meditate on
- One reflection question

Keep each day brief — this is for daily devotional use on a mobile app."""
            )
        )
        return complete(messages, maxTokens = 1024)
    }

    override suspend fun getVerseCommentary(verseRef: String, verseText: String): Result<String> {
        val textClause = if (verseText.isNotBlank()) "\n\nVerse text: \"$verseText\"" else ""
        val messages = listOf(
            OAIMessage(
                role = "system",
                content = "You are a biblical commentator. Provide scholarly yet accessible commentary grounded in Christian theology."
            ),
            OAIMessage(
                role = "user",
                content = """Provide commentary on $verseRef.$textClause

Cover:
1. Historical and cultural context
2. Key word meanings (if significant)
3. Theological significance
4. Practical application for believers today

Write for a general Christian audience — clear, engaging, 250–350 words."""
            )
        )
        return complete(messages, maxTokens = 600)
    }

    override suspend fun transcribeAndExtractVerses(audioPath: String): Result<Pair<String, List<String>>> {
        // Audio transcription requires Whisper API + audio file upload — returning placeholder
        return Result.success(
            Pair(
                "Sermon transcription requires audio upload support. Coming soon.",
                emptyList()
            )
        )
    }
}
