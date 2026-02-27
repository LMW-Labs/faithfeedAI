package com.faithfeed.app.ui.screens.explore

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.faithfeed.app.data.model.AIMessage
import com.faithfeed.app.data.repository.AIRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.util.UUID
import javax.inject.Inject

@HiltViewModel
class AIStudyPartnerViewModel @Inject constructor(
    private val aiRepository: AIRepository
) : ViewModel() {
    private val _messages = MutableStateFlow<List<AIMessage>>(
        listOf(
            AIMessage(id = UUID.randomUUID().toString(), role = "assistant", content = "Hello! I am your AI Study Partner. How can I help you understand Scripture today?")
        )
    )
    val messages: StateFlow<List<AIMessage>> = _messages.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    fun sendMessage(text: String) {
        if (text.isBlank()) return

        val userMessage = AIMessage(
            id = UUID.randomUUID().toString(),
            role = "user",
            content = text.trim()
        )

        _messages.value = _messages.value + userMessage
        _isLoading.value = true

        viewModelScope.launch {
            val result = aiRepository.chat(_messages.value, userMessage.content)
            result.onSuccess { assistantMessage ->
                _messages.value = _messages.value + assistantMessage
            }
            _isLoading.value = false
        }
    }
}
