package com.faithfeed.app.ui.screens.auth

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.faithfeed.app.data.OAuthCallbackManager
import com.faithfeed.app.data.repository.AuthRepository
import com.faithfeed.app.data.repository.UserRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class LoginUiState(
    val email: String = "",
    val password: String = "",
    val isLoading: Boolean = false,
    val error: String? = null,
    val passwordVisible: Boolean = false
)

sealed class LoginNavEvent {
    data class LoginSuccess(val needsSetup: Boolean) : LoginNavEvent()
}

@HiltViewModel
class LoginViewModel @Inject constructor(
    private val authRepository: AuthRepository,
    private val userRepository: UserRepository,
    private val oauthCallbackManager: OAuthCallbackManager
) : ViewModel() {

    private val _uiState = MutableStateFlow(LoginUiState())
    val uiState: StateFlow<LoginUiState> = _uiState.asStateFlow()

    private val _navEvents = MutableSharedFlow<LoginNavEvent>(extraBufferCapacity = 1)
    val navEvents: SharedFlow<LoginNavEvent> = _navEvents.asSharedFlow()

    init {
        // Collect OAuth deep-link callbacks (Facebook / future browser-based providers)
        viewModelScope.launch {
            oauthCallbackManager.pendingUri.collect { uri ->
                handleOAuthCallback(uri)
            }
        }
    }

    fun onEmailChange(value: String) {
        _uiState.value = _uiState.value.copy(email = value, error = null)
    }

    fun onPasswordChange(value: String) {
        _uiState.value = _uiState.value.copy(password = value, error = null)
    }

    fun togglePasswordVisibility() {
        _uiState.value = _uiState.value.copy(passwordVisible = !_uiState.value.passwordVisible)
    }

    fun signIn(onSuccess: (Boolean) -> Unit) {
        val state = _uiState.value
        if (state.email.isBlank() || state.password.isBlank()) {
            _uiState.value = state.copy(error = "Please enter your email and password.")
            return
        }
        viewModelScope.launch {
            _uiState.value = state.copy(isLoading = true, error = null)
            val result = authRepository.signInWithEmail(state.email.trim(), state.password)
            result.fold(
                onSuccess = { user ->
                    val profileResult = userRepository.getProfile(user.id)
                    val needsSetup = profileResult.isFailure
                    onSuccess(needsSetup)
                },
                onFailure = { e ->
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        error = e.message ?: "Sign in failed. Please try again."
                    )
                }
            )
        }
    }

    fun signInWithGoogle(idToken: String, onSuccess: (Boolean) -> Unit) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }
            authRepository.signInWithGoogle(idToken)
                .onSuccess { user ->
                    val profile = userRepository.getProfile(user.id)
                    onSuccess(profile.isFailure || profile.getOrNull() == null)
                }
                .onFailure { e ->
                    _uiState.update { it.copy(isLoading = false, error = e.message ?: "Google sign-in failed") }
                }
        }
    }

    /** Returns the Supabase OAuth URL to launch in Chrome Custom Tab for Facebook sign-in. */
    fun getFacebookSignInUrl(): String = authRepository.getFacebookSignInUrl()

    private suspend fun handleOAuthCallback(uri: String) {
        _uiState.update { it.copy(isLoading = true, error = null) }
        authRepository.handleOAuthCallback(uri)
            .onSuccess { user ->
                val profile = userRepository.getProfile(user.id)
                _navEvents.tryEmit(
                    LoginNavEvent.LoginSuccess(profile.isFailure || profile.getOrNull() == null)
                )
                _uiState.update { it.copy(isLoading = false) }
            }
            .onFailure { e ->
                _uiState.update { it.copy(isLoading = false, error = e.message ?: "Sign-in failed") }
            }
    }
}
