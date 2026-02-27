package com.faithfeed.app.ui.screens.marketplace

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.faithfeed.app.data.model.MarketplaceItem
import com.faithfeed.app.data.repository.AuthRepository
import com.faithfeed.app.data.repository.ChatRepository
import com.faithfeed.app.data.repository.MarketplaceRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class MarketplaceDetailViewModel @Inject constructor(
    private val marketplaceRepository: MarketplaceRepository,
    private val chatRepository: ChatRepository,
    private val authRepository: AuthRepository
) : ViewModel() {

    private val _item = MutableStateFlow<MarketplaceItem?>(null)
    val item: StateFlow<MarketplaceItem?> = _item.asStateFlow()

    private val _isLoading = MutableStateFlow(true)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()

    private val _currentUserId = MutableStateFlow("")
    val currentUserId: StateFlow<String> = _currentUserId.asStateFlow()

    private val _chatResult = MutableStateFlow<Pair<String, String>?>(null) // chatId, sellerName
    val chatResult: StateFlow<Pair<String, String>?> = _chatResult.asStateFlow()

    private val _isDeleted = MutableStateFlow(false)
    val isDeleted: StateFlow<Boolean> = _isDeleted.asStateFlow()

    fun load(itemId: String) {
        viewModelScope.launch {
            _currentUserId.value = authRepository.currentUser()?.id ?: ""
            _isLoading.value = true
            marketplaceRepository.getItem(itemId)
                .onSuccess { _item.value = it }
                .onFailure { _error.value = it.message }
            _isLoading.value = false
        }
    }

    fun messageSellerClick() {
        val seller = _item.value?.seller ?: return
        viewModelScope.launch {
            chatRepository.createDirectChat(seller.id, seller.displayName)
                .onSuccess { chat -> _chatResult.value = chat.id to seller.displayName }
                .onFailure { _error.value = it.message }
        }
    }

    fun deleteListing() {
        val id = _item.value?.id ?: return
        viewModelScope.launch {
            marketplaceRepository.deleteListing(id)
                .onSuccess { _isDeleted.value = true }
                .onFailure { _error.value = it.message }
        }
    }

    fun clearChatResult() { _chatResult.value = null }
    fun clearError() { _error.value = null }
}
