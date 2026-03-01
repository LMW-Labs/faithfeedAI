package com.faithfeed.app.ui.screens.notes

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.faithfeed.app.data.model.Note
import com.faithfeed.app.data.repository.BibleRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

@OptIn(ExperimentalCoroutinesApi::class)
@HiltViewModel
class NoteDetailViewModel @Inject constructor(
    private val bibleRepository: BibleRepository
) : ViewModel() {

    private val _noteId = MutableStateFlow("")
    val note: StateFlow<Note?> = _noteId
        .flatMapLatest { id -> bibleRepository.getNoteFlow(id) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), null)

    private val _title = MutableStateFlow("")
    val title: StateFlow<String> = _title.asStateFlow()

    private val _content = MutableStateFlow("")
    val content: StateFlow<String> = _content.asStateFlow()

    private val _verseRef = MutableStateFlow("")
    val verseRef: StateFlow<String> = _verseRef.asStateFlow()

    private val _tags = MutableStateFlow<List<String>>(emptyList())
    val tags: StateFlow<List<String>> = _tags.asStateFlow()

    private val _tagInput = MutableStateFlow("")
    val tagInput: StateFlow<String> = _tagInput.asStateFlow()

    private val _isNewNote = MutableStateFlow(true)
    val isNewNote: StateFlow<Boolean> = _isNewNote.asStateFlow()

    private val _isSaving = MutableStateFlow(false)
    val isSaving: StateFlow<Boolean> = _isSaving.asStateFlow()

    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()

    fun init(noteId: String, prefilledVerseRef: String = "") {
        _noteId.value = noteId
        _isNewNote.value = noteId == "new"
        if (noteId == "new") {
            if (prefilledVerseRef.isNotBlank()) _verseRef.value = prefilledVerseRef
        } else {
            viewModelScope.launch {
                note.collect { existingNote ->
                    if (existingNote != null && _title.value.isEmpty()) {
                        _title.value = existingNote.title
                        _content.value = existingNote.content
                        _verseRef.value = existingNote.verseRef ?: ""
                        _tags.value = existingNote.tags
                    }
                }
            }
        }
    }

    fun onTitleChange(v: String) { _title.value = v }
    fun onContentChange(v: String) { _content.value = v }
    fun onVerseRefChange(v: String) { _verseRef.value = v }
    fun onTagInputChange(v: String) { _tagInput.value = v }

    fun addTag() {
        val tag = _tagInput.value.trim()
        if (tag.isNotBlank() && !_tags.value.contains(tag)) {
            _tags.value = _tags.value + tag
        }
        _tagInput.value = ""
    }

    fun removeTag(tag: String) {
        _tags.value = _tags.value.filter { it != tag }
    }

    fun save(onSuccess: () -> Unit) {
        val t = _title.value.trim()
        val c = _content.value.trim()
        if (t.isBlank() && c.isBlank()) { _error.value = "Note is empty"; return }
        val verseRef = _verseRef.value.trim().ifBlank { null }
        _isSaving.value = true
        viewModelScope.launch {
            val result = if (_isNewNote.value) {
                bibleRepository.saveNote(t, c, verseRef, _tags.value)
            } else {
                bibleRepository.updateNote(_noteId.value, t, c, verseRef, _tags.value)
            }
            result.onSuccess { onSuccess() }
                .onFailure { _error.value = it.message ?: "Save failed" }
            _isSaving.value = false
        }
    }

    fun clearError() { _error.value = null }
}
