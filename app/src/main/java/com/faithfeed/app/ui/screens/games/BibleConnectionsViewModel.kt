package com.faithfeed.app.ui.screens.games

import androidx.lifecycle.ViewModel
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject

data class ConnectionGroup(
    val id: String,
    val theme: String,
    val words: List<String>,
    val difficultyColor: String // Hex string: Yellow, Green, Blue, Purple
)

@HiltViewModel
class BibleConnectionsViewModel @Inject constructor() : ViewModel() {

    private val mockGroups = listOf(
        ConnectionGroup("1", "Sons of Jacob", listOf("Reuben", "Simeon", "Levi", "Judah"), "#F9DF6D"), // Yellow
        ConnectionGroup("2", "Fruits of the Spirit", listOf("Love", "Joy", "Peace", "Patience"), "#A0C35A"), // Green
        ConnectionGroup("3", "Plagues of Egypt", listOf("Frogs", "Gnats", "Hail", "Locusts"), "#B0C4DE"), // Blue
        ConnectionGroup("4", "Books by John", listOf("John", "Revelation", "1 John", "2 John"), "#BA55D3") // Purple
    )

    // Flat list of 16 words shuffled
    private val _boardWords = MutableStateFlow<List<String>>(mockGroups.flatMap { it.words }.shuffled())
    val boardWords: StateFlow<List<String>> = _boardWords.asStateFlow()

    private val _selectedWords = MutableStateFlow<Set<String>>(emptySet())
    val selectedWords: StateFlow<Set<String>> = _selectedWords.asStateFlow()

    private val _foundGroups = MutableStateFlow<List<ConnectionGroup>>(emptyList())
    val foundGroups: StateFlow<List<ConnectionGroup>> = _foundGroups.asStateFlow()

    private val _mistakesRemaining = MutableStateFlow(4)
    val mistakesRemaining: StateFlow<Int> = _mistakesRemaining.asStateFlow()

    private val _gameStatus = MutableStateFlow("PLAYING") // PLAYING, WON, LOST
    val gameStatus: StateFlow<String> = _gameStatus.asStateFlow()

    fun toggleWordSelection(word: String) {
        if (_gameStatus.value != "PLAYING") return
        
        val current = _selectedWords.value.toMutableSet()
        if (current.contains(word)) {
            current.remove(word)
        } else if (current.size < 4) {
            current.add(word)
        }
        _selectedWords.value = current
    }

    fun deselectAll() {
        _selectedWords.value = emptySet()
    }

    fun submitSelection() {
        if (_selectedWords.value.size != 4) return

        val selectedList = _selectedWords.value.toList()
        
        // Check if these 4 words form a valid group
        val matchedGroup = mockGroups.find { group -> 
            group.words.containsAll(selectedList) 
        }

        if (matchedGroup != null) {
            // Correct!
            val updatedFound = _foundGroups.value.toMutableList().apply { add(matchedGroup) }
            _foundGroups.value = updatedFound
            
            // Remove found words from the board
            val updatedBoard = _boardWords.value.filterNot { it in selectedList }
            _boardWords.value = updatedBoard
            
            // Clear selection
            _selectedWords.value = emptySet()

            // Check win condition
            if (updatedFound.size == 4) {
                _gameStatus.value = "WON"
            }
        } else {
            // Incorrect
            val newMistakes = _mistakesRemaining.value - 1
            _mistakesRemaining.value = newMistakes
            if (newMistakes <= 0) {
                _gameStatus.value = "LOST"
                // Reveal all groups
                _foundGroups.value = mockGroups
                _boardWords.value = emptyList()
            }
            // Clear selection on mistake
            _selectedWords.value = emptySet()
        }
    }

    fun shuffleBoard() {
        _boardWords.value = _boardWords.value.shuffled()
    }

    fun restart() {
        _foundGroups.value = emptyList()
        _boardWords.value = mockGroups.flatMap { it.words }.shuffled()
        _selectedWords.value = emptySet()
        _mistakesRemaining.value = 4
        _gameStatus.value = "PLAYING"
    }
}