package com.faithfeed.app.ui.screens.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.faithfeed.app.data.repository.AuthRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class AccountSettingsUiState(
    val email: String = "",
    val pushNotificationsEnabled: Boolean = true,
    val prayerNotificationsEnabled: Boolean = true,
    val commentNotificationsEnabled: Boolean = true,
    val messageNotificationsEnabled: Boolean = true,
    val isSigningOut: Boolean = false
)

@HiltViewModel
class AccountSettingsViewModel @Inject constructor(
    private val authRepository: AuthRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(AccountSettingsUiState())
    val uiState: StateFlow<AccountSettingsUiState> = _uiState.asStateFlow()

    init {
        viewModelScope.launch {
            val user = authRepository.currentUser()
            _uiState.value = _uiState.value.copy(email = user?.username ?: "")
        }
    }

    fun togglePushNotifications(enabled: Boolean) {
        _uiState.value = _uiState.value.copy(pushNotificationsEnabled = enabled)
    }

    fun togglePrayerNotifications(enabled: Boolean) {
        _uiState.value = _uiState.value.copy(prayerNotificationsEnabled = enabled)
    }

    fun toggleCommentNotifications(enabled: Boolean) {
        _uiState.value = _uiState.value.copy(commentNotificationsEnabled = enabled)
    }

    fun toggleMessageNotifications(enabled: Boolean) {
        _uiState.value = _uiState.value.copy(messageNotificationsEnabled = enabled)
    }

    fun signOut(onComplete: () -> Unit) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isSigningOut = true)
            authRepository.signOut()
            onComplete()
        }
    }
}
