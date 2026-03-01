package com.faithfeed.app.ui.screens.auth

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.faithfeed.app.data.repository.AuthRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class PhoneLoginUiState(
    val phone: String = "",
    val isLoading: Boolean = false,
    val error: String? = null
)

@HiltViewModel
class PhoneLoginViewModel @Inject constructor(
    private val authRepository: AuthRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(PhoneLoginUiState())
    val uiState: StateFlow<PhoneLoginUiState> = _uiState.asStateFlow()

    fun onPhoneChange(v: String) {
        _uiState.value = _uiState.value.copy(phone = v, error = null)
    }

    fun sendOtp(onSuccess: () -> Unit) {
        val phone = _uiState.value.phone.trim()
        if (phone.isBlank()) {
            _uiState.value = _uiState.value.copy(error = "Enter your phone number")
            return
        }
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            authRepository.sendPhoneOtp(phone)
                .onSuccess { onSuccess() }
                .onFailure { _uiState.value = _uiState.value.copy(isLoading = false, error = it.message ?: "Failed to send code") }
        }
    }
}
