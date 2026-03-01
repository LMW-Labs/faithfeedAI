package com.faithfeed.app.ui.screens.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import androidx.paging.PagingData
import androidx.paging.cachedIn
import com.faithfeed.app.data.model.DailyVerse
import com.faithfeed.app.data.model.Post
import com.faithfeed.app.data.model.Story
import com.faithfeed.app.data.repository.AuthRepository
import com.faithfeed.app.data.repository.PostRepository
import com.faithfeed.app.data.repository.StoryRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.query.Columns
import io.github.jan.supabase.postgrest.query.Order
import java.time.LocalDate
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import javax.inject.Inject

@Serializable
private data class BibleVerseFallback(
    @SerialName("book_name") val bookName: String = "",
    @SerialName("chapter_number") val chapter: Int = 0,
    @SerialName("verse_number") val verse: Int = 0,
    val text: String = ""
)

@HiltViewModel
class HomeViewModel @Inject constructor(
    private val postRepository: PostRepository,
    private val storyRepository: StoryRepository,
    private val authRepository: AuthRepository,
    private val supabase: SupabaseClient
) : ViewModel() {

    private val _currentUserId = MutableStateFlow("")
    val currentUserId: StateFlow<String> = _currentUserId.asStateFlow()

    val feedPager: Flow<PagingData<Post>> = postRepository
        .getFeedPager()
        .cachedIn(viewModelScope)

    private val _stories = MutableStateFlow<List<Story>>(emptyList())
    val stories: StateFlow<List<Story>> = _stories.asStateFlow()

    private val _dailyVerse = MutableStateFlow<DailyVerse?>(null)
    val dailyVerse: StateFlow<DailyVerse?> = _dailyVerse.asStateFlow()

    init {
        loadCurrentUser()
        loadStories()
        loadDailyVerse()
    }

    private fun loadCurrentUser() {
        viewModelScope.launch {
            _currentUserId.value = authRepository.currentUser()?.id ?: ""
        }
    }

    private fun loadStories() {
        viewModelScope.launch {
            storyRepository.getActiveStories().onSuccess { _stories.value = it }
        }
    }

    private fun loadDailyVerse() {
        viewModelScope.launch {
            try {
                // 1. Try curated daily_verses (only entries up to today)
                val curated = supabase.from("daily_verses")
                    .select {
                        filter { lte("display_date", LocalDate.now().toString()) }
                        order("display_date", Order.DESCENDING)
                        limit(1)
                    }.decodeSingleOrNull<DailyVerse>()

                if (curated != null) {
                    _dailyVerse.value = curated
                    return@launch
                }

                // 2. Fallback: pick a verse from bible_verses using day-of-year
                //    so it's consistent for all users on the same day
                val dayOffset = (LocalDate.now().dayOfYear * 127L) % 31102L
                val fallback = supabase.from("bible_verses")
                    .select(Columns.raw("book_name,chapter_number,verse_number,text")) {
                        range(dayOffset, dayOffset)
                    }.decodeSingleOrNull<BibleVerseFallback>()

                fallback?.let {
                    _dailyVerse.value = DailyVerse(
                        reference = "${it.bookName} ${it.chapter}:${it.verse}",
                        text = it.text,
                        book = it.bookName,
                        chapter = it.chapter,
                        verse = it.verse
                    )
                }
            } catch (_: Exception) { /* non-fatal */ }
        }
    }

    fun likePost(postId: String) {
        viewModelScope.launch { postRepository.likePost(postId) }
    }

    fun prayPost(postId: String) {
        viewModelScope.launch { postRepository.prayPost(postId) }
    }

    fun sharePost(postId: String) {
        viewModelScope.launch { postRepository.sharePost(postId) }
    }

    fun refresh() {
        loadStories()
        loadDailyVerse()
    }
}
