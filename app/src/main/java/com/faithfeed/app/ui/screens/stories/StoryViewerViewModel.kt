package com.faithfeed.app.ui.screens.stories

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.faithfeed.app.data.model.Story
import com.faithfeed.app.data.repository.StoryRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class StoryViewerViewModel @Inject constructor(
    private val storyRepository: StoryRepository
) : ViewModel() {

    private val _stories = MutableStateFlow<List<Story>>(emptyList())
    val stories: StateFlow<List<Story>> = _stories.asStateFlow()

    private val _currentIndex = MutableStateFlow(0)
    val currentIndex: StateFlow<Int> = _currentIndex.asStateFlow()

    private val _isLoading = MutableStateFlow(true)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    fun loadStoriesForUser(userId: String) {
        viewModelScope.launch {
            _isLoading.value = true
            storyRepository.getActiveStories().onSuccess { all ->
                val userStories = all.filter { it.userId == userId }
                _stories.value = userStories
                _currentIndex.value = 0
                userStories.firstOrNull()?.let { story ->
                    storyRepository.markStoryViewed(story.id)
                }
            }
            _isLoading.value = false
        }
    }

    fun next() {
        val nextIdx = _currentIndex.value + 1
        if (nextIdx < _stories.value.size) {
            _currentIndex.value = nextIdx
            _stories.value.getOrNull(nextIdx)?.let { story ->
                viewModelScope.launch { storyRepository.markStoryViewed(story.id) }
            }
        }
    }

    fun previous() {
        if (_currentIndex.value > 0) _currentIndex.value--
    }

    fun hasNext(): Boolean = _currentIndex.value < _stories.value.size - 1
}
