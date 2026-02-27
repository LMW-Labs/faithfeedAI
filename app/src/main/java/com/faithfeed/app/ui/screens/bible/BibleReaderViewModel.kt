package com.faithfeed.app.ui.screens.bible

import android.content.Context
import android.speech.tts.TextToSpeech
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.faithfeed.app.data.model.BibleVerse
import com.faithfeed.app.data.repository.BibleRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.util.Locale
import javax.inject.Inject

@HiltViewModel
class BibleReaderViewModel @Inject constructor(
    @ApplicationContext private val context: Context,
    private val bibleRepository: BibleRepository
) : ViewModel() {

    private val _currentBook = MutableStateFlow("Genesis")
    val currentBook: StateFlow<String> = _currentBook.asStateFlow()

    private val _currentChapter = MutableStateFlow(1)
    val currentChapter: StateFlow<Int> = _currentChapter.asStateFlow()

    val verses: StateFlow<List<BibleVerse>> = _currentBook
        .flatMapLatest { book ->
            _currentChapter.flatMapLatest { chapter ->
                bibleRepository.getChapter(book, chapter)
            }
        }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    val allBooks: StateFlow<List<String>> = bibleRepository
        .getAllBooks()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    private val _selectedVerse = MutableStateFlow<BibleVerse?>(null)
    val selectedVerse: StateFlow<BibleVerse?> = _selectedVerse.asStateFlow()

    private val _isSpeaking = MutableStateFlow(false)
    val isSpeaking: StateFlow<Boolean> = _isSpeaking.asStateFlow()

    private val _isAutoScrolling = MutableStateFlow(false)
    val isAutoScrolling: StateFlow<Boolean> = _isAutoScrolling.asStateFlow()

    private var tts: TextToSpeech? = null

    init {
        viewModelScope.launch { bibleRepository.syncVersesIfNeeded() }
        tts = TextToSpeech(context) { status ->
            if (status == TextToSpeech.SUCCESS) {
                tts?.language = Locale.US
            }
        }
    }

    fun selectBook(book: String) {
        _currentBook.value = book
        _currentChapter.value = 1
    }

    fun selectChapter(chapter: Int) {
        _currentChapter.value = chapter
    }

    fun nextChapter() { _currentChapter.value++ }
    fun previousChapter() { if (_currentChapter.value > 1) _currentChapter.value-- }

    fun onVerseClick(verse: BibleVerse) {
        _selectedVerse.value = verse
    }

    fun onDismissVerse() {
        _selectedVerse.value = null
        stopSpeaking()
    }

    fun speakVerse(text: String) {
        tts?.speak(text, TextToSpeech.QUEUE_FLUSH, null, "verse")
        _isSpeaking.value = true
    }

    fun stopSpeaking() {
        tts?.stop()
        _isSpeaking.value = false
    }

    fun onToggleAutoScroll() {
        _isAutoScrolling.value = !_isAutoScrolling.value
    }

    override fun onCleared() {
        super.onCleared()
        tts?.shutdown()
    }
}
