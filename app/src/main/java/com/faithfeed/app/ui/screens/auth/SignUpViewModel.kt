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

data class SignUpUiState(
    val displayName: String = "",
    val email: String = "",
    val password: String = "",
    val confirmPassword: String = "",
    val termsAccepted: Boolean = false,
    val passwordVisible: Boolean = false,
    val isLoading: Boolean = false,
    val error: String? = null
)

@HiltViewModel
class SignUpViewModel @Inject constructor(
    private val authRepository: AuthRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(SignUpUiState())
    val uiState: StateFlow<SignUpUiState> = _uiState.asStateFlow()

    fun onDisplayNameChange(v: String) { _uiState.value = _uiState.value.copy(displayName = v, error = null) }
    fun onEmailChange(v: String) { _uiState.value = _uiState.value.copy(email = v, error = null) }
    fun onPasswordChange(v: String) { _uiState.value = _uiState.value.copy(password = v, error = null) }
    fun onConfirmPasswordChange(v: String) { _uiState.value = _uiState.value.copy(confirmPassword = v, error = null) }
    fun onTermsToggle() { _uiState.value = _uiState.value.copy(termsAccepted = !_uiState.value.termsAccepted) }
    fun togglePasswordVisibility() { _uiState.value = _uiState.value.copy(passwordVisible = !_uiState.value.passwordVisible) }

    fun signUp(onSuccess: () -> Unit) {
        val state = _uiState.value
        val error = when {
            state.displayName.isBlank() -> "Please enter your name."
            state.email.isBlank() -> "Please enter your email."
            state.password.length < 8 -> "Password must be at least 8 characters."
            state.password != state.confirmPassword -> "Passwords do not match."
            !state.termsAccepted -> "Please accept the terms to continue."
            else -> null
        }
        if (error != null) {
            _uiState.value = state.copy(error = error)
            return
        }
        viewModelScope.launch {
            _uiState.value = state.copy(isLoading = true, error = null)
            val result = authRepository.signUpWithEmail(state.email.trim(), state.password, state.displayName.trim())
            result.fold(
                onSuccess = { onSuccess() },
                onFailure = { e ->
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        error = e.message ?: "Sign up failed. Please try again."
                    )
                }
            )
        }
    }
}
