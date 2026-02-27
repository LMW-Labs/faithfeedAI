package com.faithfeed.app.ui.screens.friends

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.faithfeed.app.data.model.User
import com.faithfeed.app.data.repository.AuthRepository
import com.faithfeed.app.data.repository.UserRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.async
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class FriendsViewModel @Inject constructor(
    private val userRepository: UserRepository,
    private val authRepository: AuthRepository
) : ViewModel() {

    private val _requests = MutableStateFlow<List<User>>(emptyList())
    val requests: StateFlow<List<User>> = _requests.asStateFlow()

    private val _suggestions = MutableStateFlow<List<User>>(emptyList())
    val suggestions: StateFlow<List<User>> = _suggestions.asStateFlow()

    private val _friends = MutableStateFlow<List<User>>(emptyList())
    val friends: StateFlow<List<User>> = _friends.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    init {
        loadAll()
    }

    fun loadAll() {
        viewModelScope.launch {
            _isLoading.value = true
            val uid = authRepository.currentUser()?.id ?: ""

            val requestsDeferred    = async { userRepository.getFriendRequests() }
            val suggestionsDeferred = async { userRepository.getFriendSuggestions() }
            val friendsDeferred     = async { userRepository.getFriends(uid) }

            requestsDeferred.await().onSuccess    { _requests.value = it }
            suggestionsDeferred.await().onSuccess  { _suggestions.value = it }
            friendsDeferred.await().onSuccess      { _friends.value = it }

            _isLoading.value = false
        }
    }

    fun acceptRequest(userId: String) {
        viewModelScope.launch {
            userRepository.acceptFriendRequest(userId).onSuccess {
                // Move the accepted user from requests → friends (optimistic)
                val accepted = _requests.value.firstOrNull { it.id == userId } ?: return@onSuccess
                _requests.value = _requests.value.filter { it.id != userId }
                _friends.value = _friends.value + accepted
            }
        }
    }

    fun declineRequest(userId: String) {
        viewModelScope.launch {
            userRepository.declineFriendRequest(userId).onSuccess {
                _requests.value = _requests.value.filter { it.id != userId }
            }
        }
    }

    fun sendRequest(userId: String) {
        viewModelScope.launch {
            userRepository.sendFriendRequest(userId).onSuccess {
                // Remove from suggestions optimistically
                _suggestions.value = _suggestions.value.filter { it.id != userId }
            }
        }
    }

    fun removeFriend(userId: String) {
        viewModelScope.launch {
            userRepository.removeFriend(userId).onSuccess {
                _friends.value = _friends.value.filter { it.id != userId }
            }
        }
    }
}
