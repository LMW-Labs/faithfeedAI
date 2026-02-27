package com.faithfeed.app.ui.screens.explore

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.faithfeed.app.data.model.AIMessage
import com.faithfeed.app.data.repository.AIRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class ThematicGuidanceViewModel @Inject constructor(
    private val aiRepository: AIRepository
) : ViewModel() {
    private val _selectedTheme = MutableStateFlow("")
    val selectedTheme: StateFlow<String> = _selectedTheme.asStateFlow()
    
    private val _guidance = MutableStateFlow<List<AIMessage>>(emptyList())
    val guidance: StateFlow<List<AIMessage>> = _guidance.asStateFlow()
    
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    fun onThemeSelect(t: String) { 
        _selectedTheme.value = t
        if (t.isNotBlank()) {
            fetchGuidance(t)
        }
    }

    private fun fetchGuidance(topic: String) {
        _isLoading.value = true
        _guidance.value = emptyList()
        viewModelScope.launch {
            val result = aiRepository.getThematicGuidance(topic)
            result.onSuccess { 
                _guidance.value = it
            }
            _isLoading.value = false
        }
    }
}