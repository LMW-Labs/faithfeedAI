package com.faithfeed.app.ui.screens.chat

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.faithfeed.app.data.model.Message
import com.faithfeed.app.data.repository.AuthRepository
import com.faithfeed.app.data.repository.ChatRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class ChatViewModel @Inject constructor(
    private val chatRepository: ChatRepository,
    private val authRepository: AuthRepository
) : ViewModel() {

    private val _chatId = MutableStateFlow("")
    private val _inputText = MutableStateFlow("")
    val inputText: StateFlow<String> = _inputText.asStateFlow()

    private val _currentUserId = MutableStateFlow("")
    val currentUserId: StateFlow<String> = _currentUserId.asStateFlow()

    init {
        viewModelScope.launch {
            _currentUserId.value = authRepository.currentUser()?.id ?: ""
        }
    }

    val messages: StateFlow<List<Message>> = _chatId
        .flatMapLatest { id -> chatRepository.getMessagesFlow(id) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    fun init(chatId: String) {
        _chatId.value = chatId
        viewModelScope.launch { chatRepository.markRead(chatId) }
    }

    fun onInputChange(v: String) { _inputText.value = v }

    fun sendMessage() {
        val chatId = _chatId.value
        val content = _inputText.value.trim()
        if (content.isEmpty() || chatId.isEmpty()) return
        _inputText.value = ""
        viewModelScope.launch {
            chatRepository.sendMessage(chatId, content, null)
        }
    }
}
