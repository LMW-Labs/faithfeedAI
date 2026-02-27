package com.faithfeed.app.ui.screens.profile

import android.content.Context
import android.net.Uri
import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.faithfeed.app.data.model.User
import com.faithfeed.app.data.repository.AuthRepository
import com.faithfeed.app.data.repository.UserRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

private const val TAG = "EditProfileVM"

data class EditProfileUiState(
    val userId: String = "",
    val displayName: String = "",
    val username: String = "",
    val bio: String = "",
    val location: String = "",
    val website: String = "",
    val denomination: String = "",
    val phone: String = "",
    val avatarUrl: String? = null,
    /** True when the user has no display name yet — renders "Set Up Your Profile" mode. */
    val isNewUser: Boolean = false,
    val isLoading: Boolean = true,
    val isSaving: Boolean = false,
    val isUploadingAvatar: Boolean = false,
    val error: String? = null
)

@HiltViewModel
class EditProfileViewModel @Inject constructor(
    private val authRepository: AuthRepository,
    private val userRepository: UserRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(EditProfileUiState())
    val uiState: StateFlow<EditProfileUiState> = _uiState.asStateFlow()

    init {
        loadProfile()
    }

    private fun loadProfile() {
        viewModelScope.launch {
            // Resolve the auth session first so we always have a userId in state.
            val authUser = authRepository.currentUser()
            if (authUser == null) {
                _uiState.value = _uiState.value.copy(isLoading = false, error = "Not signed in")
                return@launch
            }

            userRepository.getProfile(authUser.id)
                .onSuccess { profile ->
                    _uiState.value = _uiState.value.copy(
                        userId = profile.id,
                        displayName = profile.displayName,
                        username = profile.username,
                        bio = profile.bio ?: "",
                        location = profile.location ?: "",
                        website = profile.website ?: "",
                        denomination = profile.denomination ?: "",
                        phone = profile.phone ?: "",
                        avatarUrl = profile.avatarUrl,
                        isNewUser = profile.displayName.isBlank(),
                        isLoading = false
                    )
                }
                .onFailure {
                    // Profile row may not exist yet for brand-new sign-ups.
                    _uiState.value = _uiState.value.copy(
                        userId = authUser.id,
                        isNewUser = true,
                        isLoading = false
                    )
                }
        }
    }

    // -- Field change handlers -------------------------------------------------

    fun onDisplayNameChange(v: String) {
        _uiState.value = _uiState.value.copy(displayName = v, error = null)
    }

    fun onUsernameChange(v: String) {
        _uiState.value = _uiState.value.copy(username = v, error = null)
    }

    fun onBioChange(v: String) {
        _uiState.value = _uiState.value.copy(bio = v)
    }

    fun onLocationChange(v: String) {
        _uiState.value = _uiState.value.copy(location = v)
    }

    fun onWebsiteChange(v: String) {
        _uiState.value = _uiState.value.copy(website = v)
    }

    fun onDenominationChange(v: String) {
        _uiState.value = _uiState.value.copy(denomination = v)
    }

    fun onPhoneChange(v: String) {
        _uiState.value = _uiState.value.copy(phone = v)
    }

    // -- Avatar upload ---------------------------------------------------------

    fun onAvatarSelected(uri: Uri, context: Context) {
        val userId = _uiState.value.userId
        Log.d(TAG, "onAvatarSelected: userId='$userId' uri=$uri")
        if (userId.isBlank()) {
            Log.e(TAG, "onAvatarSelected: userId is blank — profile not loaded yet")
            _uiState.value = _uiState.value.copy(error = "Profile not loaded yet. Try again.")
            return
        }

        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isUploadingAvatar = true, error = null)

            val bytes = try {
                context.contentResolver.openInputStream(uri)?.use { it.readBytes() }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to read image bytes", e)
                null
            }

            if (bytes == null) {
                Log.e(TAG, "bytes null — contentResolver returned null stream for $uri")
                _uiState.value = _uiState.value.copy(
                    isUploadingAvatar = false,
                    error = "Could not read the selected image"
                )
                return@launch
            }

            val mimeType = context.contentResolver.getType(uri) ?: "image/jpeg"
            Log.d(TAG, "Uploading ${bytes.size} bytes, mimeType=$mimeType, userId=$userId")

            userRepository.uploadAvatar(userId, bytes, mimeType)
                .onSuccess { publicUrl ->
                    Log.d(TAG, "Upload success → avatarUrl=$publicUrl")
                    _uiState.value = _uiState.value.copy(
                        avatarUrl = publicUrl,
                        isUploadingAvatar = false
                    )
                }
                .onFailure { e ->
                    Log.e(TAG, "Upload failed: ${e.message}", e)
                    _uiState.value = _uiState.value.copy(
                        isUploadingAvatar = false,
                        error = e.message ?: "Avatar upload failed"
                    )
                }
        }
    }

    // -- Save ------------------------------------------------------------------

    fun save(onSuccess: () -> Unit) {
        val state = _uiState.value
        if (state.displayName.isBlank()) {
            _uiState.value = state.copy(error = "Display name is required")
            return
        }

        val updatedUser = User(
            id = state.userId,
            displayName = state.displayName.trim(),
            username = state.username.trim(),
            bio = state.bio.trim().takeIf { it.isNotBlank() },
            location = state.location.trim().takeIf { it.isNotBlank() },
            website = state.website.trim().takeIf { it.isNotBlank() },
            denomination = state.denomination.trim().takeIf { it.isNotBlank() },
            phone = state.phone.trim().takeIf { it.isNotBlank() },
            avatarUrl = state.avatarUrl
        )

        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isSaving = true, error = null)
            userRepository.updateProfile(updatedUser)
                .onSuccess {
                    _uiState.value = _uiState.value.copy(isSaving = false)
                    onSuccess()
                }
                .onFailure { e ->
                    _uiState.value = _uiState.value.copy(
                        isSaving = false,
                        error = e.message ?: "Failed to save profile"
                    )
                }
        }
    }
}
