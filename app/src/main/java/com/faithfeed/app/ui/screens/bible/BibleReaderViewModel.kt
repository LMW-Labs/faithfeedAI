package com.faithfeed.app.ui.screens.bible

import android.content.Context
import android.speech.tts.TextToSpeech
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.faithfeed.app.data.local.VerseHighlightEntity
import com.faithfeed.app.data.local.dao.VerseHighlightDao
import com.faithfeed.app.data.model.BibleVerse
import com.faithfeed.app.data.model.Note
import com.faithfeed.app.data.model.StrongsEntry
import com.faithfeed.app.data.model.StrongsLexiconEntry
import com.faithfeed.app.data.repository.BibleRepository
import com.faithfeed.app.data.repository.ConcordanceRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.util.Locale
import javax.inject.Inject

@OptIn(ExperimentalCoroutinesApi::class)
@HiltViewModel
class BibleReaderViewModel @Inject constructor(
    @ApplicationContext private val context: Context,
    private val bibleRepository: BibleRepository,
    private val concordanceRepository: ConcordanceRepository,
    private val verseHighlightDao: VerseHighlightDao
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

    val chapters: StateFlow<List<Int>> = _currentBook
        .flatMapLatest { book -> bibleRepository.getChapters(book) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    private val _selectedVerse = MutableStateFlow<BibleVerse?>(null)
    val selectedVerse: StateFlow<BibleVerse?> = _selectedVerse.asStateFlow()

    private val _isSpeaking = MutableStateFlow(false)
    val isSpeaking: StateFlow<Boolean> = _isSpeaking.asStateFlow()

    /** Index in [verses] of the verse currently being read aloud; -1 when silent */
    private val _speakingVerseIndex = MutableStateFlow(-1)
    val speakingVerseIndex: StateFlow<Int> = _speakingVerseIndex.asStateFlow()

    private val _scrollSpeed = MutableStateFlow(1.0f)
    val scrollSpeed: StateFlow<Float> = _scrollSpeed.asStateFlow()

    private val _isAutoScrolling = MutableStateFlow(false)
    val isAutoScrolling: StateFlow<Boolean> = _isAutoScrolling.asStateFlow()

    private val _verseNotes = MutableStateFlow<List<Note>>(emptyList())
    val verseNotes: StateFlow<List<Note>> = _verseNotes.asStateFlow()

    // Strongs concordance for selected verse
    private val _verseStrongs = MutableStateFlow<List<StrongsEntry>>(emptyList())
    val verseStrongs: StateFlow<List<StrongsEntry>> = _verseStrongs.asStateFlow()

    private val _strongsLexicon = MutableStateFlow<Map<String, StrongsLexiconEntry>>(emptyMap())
    val strongsLexicon: StateFlow<Map<String, StrongsLexiconEntry>> = _strongsLexicon.asStateFlow()

    private val _strongsLoading = MutableStateFlow(false)
    val strongsLoading: StateFlow<Boolean> = _strongsLoading.asStateFlow()

    // Verse highlights: reference → colorHex (e.g. "Gen 1:1" → "#C9A84C")
    val highlights: StateFlow<Map<String, String>> = verseHighlightDao
        .getAllFlow()
        .map { list -> list.associate { it.reference to it.colorHex } }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyMap())

    private var tts: TextToSpeech? = null

    init {
        viewModelScope.launch {
            android.util.Log.d("BibleReaderVM", "Starting verse sync…")
            val result = bibleRepository.syncVersesIfNeeded()
            result.onSuccess { android.util.Log.d("BibleReaderVM", "Verse sync complete") }
            result.onFailure { android.util.Log.e("BibleReaderVM", "Verse sync FAILED: ${it::class.simpleName} — ${it.message}") }
        }
        tts = TextToSpeech(context) { status ->
            if (status == TextToSpeech.SUCCESS) {
                tts?.language = Locale.US
                tts?.setOnUtteranceProgressListener(object : android.speech.tts.UtteranceProgressListener() {
                    override fun onStart(utteranceId: String?) {}
                    override fun onDone(utteranceId: String?) {
                        val nextIndex = (utteranceId?.toIntOrNull() ?: return) + 1
                        viewModelScope.launch(Dispatchers.Main) {
                            _speakingVerseIndex.value = nextIndex
                            speakVerseAtIndex(nextIndex)
                        }
                    }
                    @Suppress("OVERRIDE_DEPRECATION")
                    override fun onError(utteranceId: String?) {
                        viewModelScope.launch(Dispatchers.Main) {
                            _isSpeaking.value = false
                            _speakingVerseIndex.value = -1
                        }
                    }
                })
            }
        }
    }

    fun selectBook(book: String) {
        stopSpeaking()
        _currentBook.value = book
        _currentChapter.value = 1
    }

    fun selectChapter(chapter: Int) {
        stopSpeaking()
        _currentChapter.value = chapter
    }

    fun nextChapter() {
        stopSpeaking()
        _currentChapter.value++
    }

    fun previousChapter() {
        stopSpeaking()
        if (_currentChapter.value > 1) _currentChapter.value--
    }

    fun onVerseClick(verse: BibleVerse) {
        _selectedVerse.value = verse
        val verseRef = "${verse.book} ${verse.chapter}:${verse.verse}"
        viewModelScope.launch {
            _verseNotes.value = bibleRepository.getNotesByVerse(verseRef)
            loadStrongs(verseRef)
        }
    }

    fun onDismissVerse() {
        _selectedVerse.value = null
        _verseNotes.value = emptyList()
        _verseStrongs.value = emptyList()
        _strongsLexicon.value = emptyMap()
        stopSpeaking()
    }

    private suspend fun loadStrongs(verseRef: String) {
        _strongsLoading.value = true
        val entries = concordanceRepository.getStrongsForVerse(verseRef).getOrElse { emptyList() }
        _verseStrongs.value = entries
        if (entries.isNotEmpty()) {
            val tags = entries.map { it.strongsTag }.distinct()
            val lexicon = concordanceRepository.getLexiconEntries(tags).getOrElse { emptyList() }
            _strongsLexicon.value = lexicon.associateBy { it.strongsTag }
        }
        _strongsLoading.value = false
    }

    fun highlightVerse(reference: String, colorHex: String) {
        viewModelScope.launch {
            verseHighlightDao.upsert(VerseHighlightEntity(reference, colorHex))
        }
    }

    fun removeHighlight(reference: String) {
        viewModelScope.launch {
            verseHighlightDao.delete(reference)
        }
    }

    /** Single-verse playback used by the verse action sheet Listen button */
    fun speakVerse(text: String) {
        stopSpeaking()
        tts?.speak(text, TextToSpeech.QUEUE_FLUSH, null, "single")
        _isSpeaking.value = true
    }

    /** Start chained TTS from [startIndex] in the current chapter, continuing verse-by-verse */
    fun speakFromVerse(startIndex: Int) {
        stopSpeaking()
        val verseList = verses.value
        if (startIndex < 0 || startIndex >= verseList.size) return
        _speakingVerseIndex.value = startIndex
        speakVerseAtIndex(startIndex)
    }

    private fun speakVerseAtIndex(index: Int) {
        val verseList = verses.value
        if (index < 0 || index >= verseList.size) {
            _isSpeaking.value = false
            _speakingVerseIndex.value = -1
            return
        }
        _isSpeaking.value = true
        tts?.speak(verseList[index].text, TextToSpeech.QUEUE_FLUSH, null, index.toString())
    }

    fun stopSpeaking() {
        tts?.stop()
        _isSpeaking.value = false
        _speakingVerseIndex.value = -1
    }

    fun setScrollSpeed(speed: Float) {
        _scrollSpeed.value = speed
        tts?.setSpeechRate(speed)
    }

    fun onToggleAutoScroll() {
        _isAutoScrolling.value = !_isAutoScrolling.value
    }

    override fun onCleared() {
        super.onCleared()
        tts?.shutdown()
    }
}
