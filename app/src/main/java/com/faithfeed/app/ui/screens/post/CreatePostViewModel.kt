package com.faithfeed.app.ui.screens.post

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.faithfeed.app.data.repository.PostRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class CreatePostUiState(
    val content: String = "",
    val verseRef: String = "",
    val verseText: String = "",
    val audience: String = "public",
    val isPosting: Boolean = false,
    val isDone: Boolean = false,
    val error: String? = null
)

@HiltViewModel
class CreatePostViewModel @Inject constructor(
    private val postRepository: PostRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(CreatePostUiState())
    val uiState: StateFlow<CreatePostUiState> = _uiState.asStateFlow()

    fun onContentChange(value: String) {
        _uiState.update { it.copy(content = value, error = null) }
    }

    fun onVerseRefChange(value: String) {
        _uiState.update { it.copy(verseRef = value) }
    }

    fun onVerseTextChange(value: String) {
        _uiState.update { it.copy(verseText = value) }
    }

    fun onAudienceChange(value: String) {
        _uiState.update { it.copy(audience = value) }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }

    fun post() {
        val state = _uiState.value
        if (state.content.isBlank()) {
            _uiState.update { it.copy(error = "Please write something before posting.") }
            return
        }
        viewModelScope.launch {
            _uiState.update { it.copy(isPosting = true, error = null) }
            val verseRef = state.verseRef.trim().takeIf { it.isNotEmpty() }
            val result = postRepository.createPost(
                content = state.content.trim(),
                mediaUrls = emptyList(),
                verseRef = verseRef,
                audience = state.audience
            )
            result.fold(
                onSuccess = { _uiState.update { it.copy(isPosting = false, isDone = true) } },
                onFailure = { e ->
                    _uiState.update {
                        it.copy(isPosting = false, error = e.message ?: "Failed to post. Try again.")
                    }
                }
            )
        }
    }
}
