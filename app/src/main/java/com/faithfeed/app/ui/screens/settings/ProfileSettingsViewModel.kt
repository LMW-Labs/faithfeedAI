package com.faithfeed.app.ui.screens.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.faithfeed.app.data.model.ProfilePrivacy
import com.faithfeed.app.data.repository.AuthRepository
import com.faithfeed.app.data.repository.UserRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class ProfileSettingsUiState(
    val privacy: ProfilePrivacy = ProfilePrivacy(),
    val isLoading: Boolean = true,
    val isSaving: Boolean = false,
    val showActivityStatus: Boolean = true,
    val allowFriendRequests: Boolean = true,
    val showInSearchResults: Boolean = true,
    // Retained for Content Preferences section
    val contentLanguage: String = "English",
    val feedContentFilter: String = "All"
)

@HiltViewModel
class ProfileSettingsViewModel @Inject constructor(
    private val userRepository: UserRepository,
    private val authRepository: AuthRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(ProfileSettingsUiState())
    val uiState: StateFlow<ProfileSettingsUiState> = _uiState.asStateFlow()

    // Cached for save calls
    private var cachedUserId: String? = null

    init {
        loadPrivacySettings()
    }

    private fun loadPrivacySettings() {
        viewModelScope.launch {
            val userId = authRepository.currentUser()?.id ?: return@launch
            cachedUserId = userId
            userRepository.getPrivacySettings(userId)
                .onSuccess { privacy ->
                    _uiState.value = _uiState.value.copy(privacy = privacy, isLoading = false)
                }
                .onFailure {
                    _uiState.value = _uiState.value.copy(isLoading = false)
                }
        }
    }

    fun updatePrivacy(field: String, level: String) {
        val p = _uiState.value.privacy
        _uiState.value = _uiState.value.copy(
            privacy = when (field) {
                "bio"      -> p.copy(bioVisibility = level)
                "location" -> p.copy(locationVisibility = level)
                "phone"    -> p.copy(phoneVisibility = level)
                "posts"    -> p.copy(postsVisibility = level)
                "friends"  -> p.copy(friendsVisibility = level)
                "activity" -> p.copy(activityVisibility = level)
                "email"    -> p.copy(emailVisibility = level)
                else       -> p
            }
        )
        savePrivacy()
    }

    fun toggleActivityStatus(enabled: Boolean) {
        _uiState.value = _uiState.value.copy(showActivityStatus = enabled)
    }

    fun toggleFriendRequests(enabled: Boolean) {
        _uiState.value = _uiState.value.copy(allowFriendRequests = enabled)
    }

    fun toggleSearchVisibility(enabled: Boolean) {
        _uiState.value = _uiState.value.copy(showInSearchResults = enabled)
    }

    private fun savePrivacy() {
        val userId = cachedUserId ?: return
        val privacy = _uiState.value.privacy
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isSaving = true)
            userRepository.updatePrivacySettings(userId, privacy)
            _uiState.value = _uiState.value.copy(isSaving = false)
        }
    }
}
