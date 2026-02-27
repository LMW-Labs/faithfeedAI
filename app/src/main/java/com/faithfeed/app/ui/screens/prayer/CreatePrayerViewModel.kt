package com.faithfeed.app.ui.screens.prayer

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.faithfeed.app.data.repository.PrayerRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class CreatePrayerUiState(
    val title: String = "",
    val content: String = "",
    val isAnonymous: Boolean = false,
    val isSubmitting: Boolean = false,
    val error: String? = null
)

@HiltViewModel
class CreatePrayerViewModel @Inject constructor(
    private val prayerRepository: PrayerRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(CreatePrayerUiState())
    val uiState: StateFlow<CreatePrayerUiState> = _uiState.asStateFlow()

    fun onTitleChange(value: String) { _uiState.value = _uiState.value.copy(title = value, error = null) }
    fun onContentChange(value: String) { _uiState.value = _uiState.value.copy(content = value, error = null) }
    fun onAnonymousToggle(value: Boolean) { _uiState.value = _uiState.value.copy(isAnonymous = value) }

    fun submit(onSuccess: () -> Unit) {
        val state = _uiState.value
        if (state.title.isBlank()) {
            _uiState.value = state.copy(error = "Please enter a prayer title")
            return
        }
        if (state.content.isBlank()) {
            _uiState.value = state.copy(error = "Please describe your prayer request")
            return
        }
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isSubmitting = true, error = null)
            prayerRepository.createPrayer(
                title = state.title.trim(),
                content = state.content.trim(),
                isAnonymous = state.isAnonymous
            ).onSuccess {
                onSuccess()
            }.onFailure { e ->
                _uiState.value = _uiState.value.copy(
                    isSubmitting = false,
                    error = e.message ?: "Failed to submit prayer"
                )
            }
        }
    }
}
