package com.faithfeed.app.ui.screens.bible

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
class SemanticSearchViewModel @Inject constructor(
    private val bibleRepository: BibleRepository
) : ViewModel() {

    private val _query = MutableStateFlow("")
    val query: StateFlow<String> = _query.asStateFlow()

    private val _results = MutableStateFlow<List<BibleVerse>>(emptyList())
    val results: StateFlow<List<BibleVerse>> = _results.asStateFlow()

    private val _isSearching = MutableStateFlow(false)
    val isSearching: StateFlow<Boolean> = _isSearching.asStateFlow()

    fun onQueryChange(q: String) { _query.value = q }

    fun search() {
        val q = _query.value.trim()
        if (q.isBlank()) return
        viewModelScope.launch {
            _isSearching.value = true
            bibleRepository.semanticSearch(q).onSuccess { _results.value = it }
            _isSearching.value = false
        }
    }
}
