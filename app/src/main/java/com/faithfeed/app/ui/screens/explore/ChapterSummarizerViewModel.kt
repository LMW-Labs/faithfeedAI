package com.faithfeed.app.ui.screens.explore

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.faithfeed.app.data.repository.AIRepository
import com.faithfeed.app.data.repository.BibleRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

@OptIn(ExperimentalCoroutinesApi::class)
@HiltViewModel
class ChapterSummarizerViewModel @Inject constructor(
    private val aiRepository: AIRepository,
    private val bibleRepository: BibleRepository
) : ViewModel() {

    private val _selectedBook = MutableStateFlow("Genesis")
    val selectedBook: StateFlow<String> = _selectedBook.asStateFlow()

    private val _selectedChapter = MutableStateFlow(1)
    val selectedChapter: StateFlow<Int> = _selectedChapter.asStateFlow()

    private val _summary = MutableStateFlow("")
    val summary: StateFlow<String> = _summary.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    val allBooks: StateFlow<List<String>> = bibleRepository
        .getAllBooks()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000),
            listOf("Genesis", "Exodus", "Psalms", "Proverbs", "John", "Romans"))

    val chaptersForBook: StateFlow<List<Int>> = _selectedBook
        .flatMapLatest { book -> bibleRepository.getChapters(book) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), (1..50).toList())

    fun selectBook(b: String) {
        _selectedBook.value = b
        _selectedChapter.value = 1
        _summary.value = ""
    }

    fun selectChapter(c: Int) {
        _selectedChapter.value = c
        _summary.value = ""
    }

    fun generateSummary() {
        val book = _selectedBook.value
        val chapter = _selectedChapter.value
        _isLoading.value = true
        _summary.value = ""
        viewModelScope.launch {
            val verses = try {
                bibleRepository.getChapter(book, chapter).first()
                    .map { "${it.verse}. ${it.text}" }
            } catch (_: Exception) {
                emptyList()
            }
            aiRepository.summarizeChapter(book, chapter, verses)
                .onSuccess { _summary.value = it }
            _isLoading.value = false
        }
    }
}
