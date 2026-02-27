package com.faithfeed.app.ui.screens.profile

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.faithfeed.app.data.model.Post
import com.faithfeed.app.data.model.User
import com.faithfeed.app.data.repository.AuthRepository
import com.faithfeed.app.data.repository.ChatRepository
import com.faithfeed.app.data.repository.PostRepository
import com.faithfeed.app.data.repository.UserRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class ProfileUiState(
    val user: User? = null,
    val posts: List<Post> = emptyList(),
    val isOwner: Boolean = false,
    val isLoading: Boolean = true,
    val isLoadingPosts: Boolean = false,
    val friendRequestSent: Boolean = false,
    val error: String? = null,
    val chatNav: Pair<String, String>? = null // chatId to userName
)

@HiltViewModel
class ProfileViewModel @Inject constructor(
    private val userRepository: UserRepository,
    private val postRepository: PostRepository,
    private val authRepository: AuthRepository,
    private val chatRepository: ChatRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(ProfileUiState())
    val uiState: StateFlow<ProfileUiState> = _uiState.asStateFlow()

    fun loadProfile(userId: String) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)

            val currentUser = authRepository.currentUser()
            val isOwner = currentUser?.id == userId

            userRepository.getProfile(userId)
                .onSuccess { user ->
                    _uiState.value = _uiState.value.copy(
                        user = user,
                        isOwner = isOwner,
                        isLoading = false
                    )
                    loadPosts(userId)
                }
                .onFailure { e ->
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        error = e.message ?: "Failed to load profile"
                    )
                }
        }
    }

    private fun loadPosts(userId: String) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoadingPosts = true)
            postRepository.getPostsByUser(userId)
                .onSuccess { posts ->
                    _uiState.value = _uiState.value.copy(
                        posts = posts,
                        isLoadingPosts = false
                    )
                }
                .onFailure {
                    _uiState.value = _uiState.value.copy(isLoadingPosts = false)
                }
        }
    }

    fun sendFriendRequest(targetUserId: String) {
        viewModelScope.launch {
            userRepository.sendFriendRequest(targetUserId)
                .onSuccess {
                    _uiState.value = _uiState.value.copy(friendRequestSent = true)
                }
        }
    }

    fun startDirectChat() {
        val user = _uiState.value.user ?: return
        viewModelScope.launch {
            chatRepository.createDirectChat(user.id, user.displayName)
                .onSuccess { chat ->
                    _uiState.value = _uiState.value.copy(chatNav = chat.id to user.displayName)
                }
                .onFailure { e ->
                    _uiState.value = _uiState.value.copy(error = e.message)
                }
        }
    }

    fun clearChatNav() { _uiState.value = _uiState.value.copy(chatNav = null) }
    fun clearError() { _uiState.value = _uiState.value.copy(error = null) }
}
