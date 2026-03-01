package com.faithfeed.app.ui.screens.bible

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.faithfeed.app.data.model.StrongsLexiconEntry
import com.faithfeed.app.data.repository.ConcordanceRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class ConcordanceResultsViewModel @Inject constructor(
    private val concordanceRepository: ConcordanceRepository
) : ViewModel() {

    private val _lexiconEntry = MutableStateFlow<StrongsLexiconEntry?>(null)
    val lexiconEntry: StateFlow<StrongsLexiconEntry?> = _lexiconEntry.asStateFlow()

    private val _references = MutableStateFlow<List<String>>(emptyList())
    val references: StateFlow<List<String>> = _references.asStateFlow()

    private val _isLoading = MutableStateFlow(true)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()

    fun load(strongsTag: String) {
        viewModelScope.launch {
            _isLoading.value = true
            _error.value = null
            concordanceRepository.getLexiconEntry(strongsTag)
                .onSuccess { _lexiconEntry.value = it }
                .onFailure { /* non-fatal */ }
            concordanceRepository.getVersesByStrongs(strongsTag)
                .onSuccess { _references.value = it }
                .onFailure { _error.value = it.message ?: "Failed to load verses" }
            _isLoading.value = false
        }
    }
}
