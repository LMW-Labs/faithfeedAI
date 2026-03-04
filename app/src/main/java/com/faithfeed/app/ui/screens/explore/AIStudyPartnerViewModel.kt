package com.faithfeed.app.ui.screens.explore

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.faithfeed.app.data.model.AIMessage
import com.faithfeed.app.data.model.TheologicalLane
import com.faithfeed.app.data.repository.AIRepository
import com.faithfeed.app.data.service.OpenAITTSService
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.io.File
import java.util.UUID
import javax.inject.Inject

private val KEY_VOICE = stringPreferencesKey("study_partner_voice")
private val KEY_MUTED = booleanPreferencesKey("study_partner_muted")

@HiltViewModel
class AIStudyPartnerViewModel @Inject constructor(
    private val aiRepository: AIRepository,
    private val ttsService: OpenAITTSService,
    private val dataStore: DataStore<Preferences>,
    @ApplicationContext private val context: Context
) : ViewModel() {

    private val _messages = MutableStateFlow<List<AIMessage>>(
        listOf(
            AIMessage(
                id = UUID.randomUUID().toString(),
                role = "assistant",
                content = "Peace to you! I'm your AI Study Partner. Ask me anything about Scripture, theology, or your faith journey — and feel free to speak or type."
            )
        )
    )
    val messages: StateFlow<List<AIMessage>> = _messages.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _isListening = MutableStateFlow(false)
    val isListening: StateFlow<Boolean> = _isListening.asStateFlow()

    val isSpeaking: StateFlow<Boolean> = ttsService.isSpeaking

    val selectedVoice: StateFlow<String> = dataStore.data
        .map { it[KEY_VOICE] ?: "nova" }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), "nova")

    val isMuted: StateFlow<Boolean> = dataStore.data
        .map { it[KEY_MUTED] ?: false }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), false)

    private val _showVoiceSettings = MutableStateFlow(false)
    val showVoiceSettings: StateFlow<Boolean> = _showVoiceSettings.asStateFlow()

    /** Theological lanes detected for the most recent user message; cleared on each new send. */
    private val _detectedLanes = MutableStateFlow<List<TheologicalLane>>(emptyList())
    val detectedLanes: StateFlow<List<TheologicalLane>> = _detectedLanes.asStateFlow()

    // ── Mic ────────────────────────────────────────────────────────────────────

    /** Called when user taps the mic button. Toggles listening; stops TTS if speaking. */
    fun onMicTap() {
        if (_isListening.value) {
            _isListening.value = false
        } else {
            ttsService.stopPlayback()
            _isListening.value = true
        }
    }

    /** Called by screen when SpeechRecognizer delivers a final result. */
    fun onVoiceResult(text: String) {
        _isListening.value = false
        sendMessage(text)
    }

    /** Called by screen on STT error or timeout. */
    fun stopListening() {
        _isListening.value = false
    }

    // ── Chat ───────────────────────────────────────────────────────────────────

    fun sendMessage(text: String) {
        if (text.isBlank() || _isLoading.value) return
        val userMsg = AIMessage(id = UUID.randomUUID().toString(), role = "user", content = text.trim())
        _messages.value = _messages.value + userMsg
        _detectedLanes.value = emptyList()   // clear lanes from previous turn
        _isLoading.value = true

        viewModelScope.launch {
            // Detect theological lanes before sending to AI — non-blocking, never throws
            _detectedLanes.value = aiRepository.detectTheologicalLanes(userMsg.content)
                .getOrDefault(emptyList())

            val result = aiRepository.chat(_messages.value, userMsg.content)
            result.onSuccess { assistantMsg ->
                _messages.value = _messages.value + assistantMsg
                speakIfUnmuted(assistantMsg.content)
            }.onFailure { error ->
                val errMsg = AIMessage(
                    id = UUID.randomUUID().toString(),
                    role = "assistant",
                    content = "I'm sorry, I had trouble connecting. Please try again.",
                    isError = true
                )
                _messages.value = _messages.value + errMsg
                android.util.Log.e("StudyPartnerVM", "chat failed: ${error.message}")
            }
            _isLoading.value = false
        }
    }

    private fun speakIfUnmuted(text: String) {
        if (isMuted.value) return
        viewModelScope.launch {
            val voice = selectedVoice.value
            ttsService.speak(text, voice, context.cacheDir)
        }
    }

    // ── Controls ───────────────────────────────────────────────────────────────

    fun toggleMute() {
        viewModelScope.launch {
            val next = !isMuted.value
            dataStore.edit { it[KEY_MUTED] = next }
            if (next) ttsService.stopPlayback()
        }
    }

    fun setVoice(voice: String) {
        viewModelScope.launch {
            dataStore.edit { it[KEY_VOICE] = voice }
        }
    }

    fun toggleVoiceSettings() {
        _showVoiceSettings.value = !_showVoiceSettings.value
    }

    fun newConversation() {
        ttsService.stopPlayback()
        _isListening.value = false
        _detectedLanes.value = emptyList()
        _messages.value = listOf(
            AIMessage(
                id = UUID.randomUUID().toString(),
                role = "assistant",
                content = "Starting fresh! What would you like to explore in Scripture today?"
            )
        )
    }

    /** Remove a single disclosure banner the user has acknowledged. */
    fun dismissLane(laneKey: String) {
        _detectedLanes.value = _detectedLanes.value.filter { it.laneKey != laneKey }
    }

    override fun onCleared() {
        super.onCleared()
        ttsService.stopPlayback()
    }
}
