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
import io.github.jan.supabase.postgrest.query.Order
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

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
                val verse = supabase.from("daily_verses")
                    .select {
                        order("display_date", Order.DESCENDING)
                        limit(1)
                    }.decodeSingleOrNull<DailyVerse>()
                _dailyVerse.value = verse
            } catch (_: Exception) { /* non-fatal */ }
        }
    }

    fun likePost(postId: String) {
        viewModelScope.launch { postRepository.likePost(postId) }
    }

    fun prayPost(postId: String) {
        viewModelScope.launch { postRepository.prayPost(postId) }
    }

    fun refresh() {
        loadStories()
        loadDailyVerse()
    }
}
