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
class VerseCommentaryViewModel @Inject constructor(
    private val aiRepository: AIRepository
) : ViewModel() {

    private val _commentary = MutableStateFlow("")
    val commentary: StateFlow<String> = _commentary.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()

    fun load(verseRef: String) {
        if (_commentary.value.isNotEmpty() || _isLoading.value) return
        _isLoading.value = true
        viewModelScope.launch {
            aiRepository.getVerseCommentary(verseRef, "").onSuccess {
                _commentary.value = it
            }.onFailure {
                _error.value = it.message ?: "Failed to load commentary"
            }
            _isLoading.value = false
        }
    }
}
