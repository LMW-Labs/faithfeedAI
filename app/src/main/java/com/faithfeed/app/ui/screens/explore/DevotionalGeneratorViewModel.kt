package com.faithfeed.app.ui.screens.explore

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.faithfeed.app.data.repository.AIRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class DevotionalGeneratorViewModel @Inject constructor(
    private val aiRepository: AIRepository
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
            // using a mock verseRef and verseText for now
            val result = aiRepository.generateDevotional(
                verseRef = "Proverbs 3:5-6", 
                verseText = topic
            )
            result.onSuccess { 
                _devotional.value = it
            }
            _isLoading.value = false
        }
    }
}
