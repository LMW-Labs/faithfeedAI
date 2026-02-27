package com.faithfeed.app.ui.screens.explore

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.faithfeed.app.data.model.BibleVerse
import com.faithfeed.app.data.repository.BibleRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class RelatedVersesViewModel @Inject constructor(
    private val bibleRepository: BibleRepository
) : ViewModel() {

    private val _relatedVerses = MutableStateFlow<List<BibleVerse>>(emptyList())
    val relatedVerses: StateFlow<List<BibleVerse>> = _relatedVerses.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()

    fun load(verseRef: String) {
        if (_relatedVerses.value.isNotEmpty() || _isLoading.value) return
        _isLoading.value = true
        viewModelScope.launch {
            bibleRepository.semanticSearch(verseRef, limit = 10).onSuccess {
                _relatedVerses.value = it
            }.onFailure {
                _error.value = it.message ?: "Failed to load related verses"
            }
            _isLoading.value = false
        }
    }
}
