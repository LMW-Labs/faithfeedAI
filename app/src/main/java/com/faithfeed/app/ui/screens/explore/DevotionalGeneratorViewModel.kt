package com.faithfeed.app.ui.screens.explore

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.faithfeed.app.data.repository.AILibraryRepository
import com.faithfeed.app.data.repository.AIRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class DevotionalGeneratorViewModel @Inject constructor(
    private val aiRepository: AIRepository,
    private val aiLibraryRepository: AILibraryRepository
) : ViewModel() {
    private val _devotional = MutableStateFlow("")
    val devotional: StateFlow<String> = _devotional.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    fun generateDevotional(topic: String) {
        if (topic.isBlank()) return
        _isLoading.value = true
        _devotional.value = ""
        viewModelScope.launch {
            val result = aiRepository.generateDevotional(
                verseRef = topic,
                verseText = topic
            )
            result.onSuccess { content ->
                _devotional.value = content
                aiLibraryRepository.saveInteraction("devotional", "Devotional: $topic", content)
            }
            _isLoading.value = false
        }
    }
}
