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

data class VerifyOtpUiState(
    val token: String = "",
    val isLoading: Boolean = false,
    val error: String? = null,
    val isResending: Boolean = false
)

@HiltViewModel
class VerifyOtpViewModel @Inject constructor(
    private val authRepository: AuthRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(VerifyOtpUiState())
    val uiState: StateFlow<VerifyOtpUiState> = _uiState.asStateFlow()

    fun onTokenChange(v: String) {
        if (v.length <= 6 && v.all { it.isDigit() }) {
            _uiState.value = _uiState.value.copy(token = v, error = null)
        }
    }

    fun verify(phone: String, onSuccess: () -> Unit) {
        val token = _uiState.value.token
        if (token.length != 6) {
            _uiState.value = _uiState.value.copy(error = "Enter the 6-digit code")
            return
        }
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            authRepository.verifyPhoneOtp(phone, token)
                .onSuccess { onSuccess() }
                .onFailure { _uiState.value = _uiState.value.copy(isLoading = false, error = it.message ?: "Invalid code") }
        }
    }

    fun resend(phone: String) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isResending = true)
            authRepository.sendPhoneOtp(phone)
            _uiState.value = _uiState.value.copy(isResending = false, token = "", error = null)
        }
    }
}
