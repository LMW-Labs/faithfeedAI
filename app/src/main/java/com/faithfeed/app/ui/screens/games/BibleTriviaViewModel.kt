package com.faithfeed.app.ui.screens.games

import androidx.lifecycle.ViewModel
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject

data class TriviaQuestion(
    val id: String = "",
    val question: String = "",
    val options: List<String> = emptyList(),
    val correctIndex: Int = 0,
    val verseRef: String = ""
)

@HiltViewModel
class BibleTriviaViewModel @Inject constructor() : ViewModel() {
    
    // Mock Data for the prototype
    private val mockQuestions = listOf(
        TriviaQuestion(
            id = "q1",
            question = "Who was swallowed by a great fish?",
            options = listOf("Moses", "Jonah", "Elijah", "Noah"),
            correctIndex = 1,
            verseRef = "Jonah 1:17"
        ),
        TriviaQuestion(
            id = "q2",
            question = "Which disciple denied Jesus three times?",
            options = listOf("John", "James", "Peter", "Judas"),
            correctIndex = 2,
            verseRef = "Luke 22:34"
        ),
        TriviaQuestion(
            id = "q3",
            question = "What is the longest book in the Bible?",
            options = listOf("Genesis", "Isaiah", "Jeremiah", "Psalms"),
            correctIndex = 3,
            verseRef = "Psalms"
        )
    )

    private val _questions = MutableStateFlow(mockQuestions)
    val questions: StateFlow<List<TriviaQuestion>> = _questions.asStateFlow()

    private val _currentIndex = MutableStateFlow(0)
    val currentIndex: StateFlow<Int> = _currentIndex.asStateFlow()

    private val _score = MutableStateFlow(0)
    val score: StateFlow<Int> = _score.asStateFlow()

    private val _selectedAnswer = MutableStateFlow<Int?>(null)
    val selectedAnswer: StateFlow<Int?> = _selectedAnswer.asStateFlow()

    private val _isFinished = MutableStateFlow(false)
    val isFinished: StateFlow<Boolean> = _isFinished.asStateFlow()

    fun onAnswerSelected(index: Int) {
        if (_selectedAnswer.value != null) return // Already answered
        
        val current = _questions.value.getOrNull(_currentIndex.value) ?: return
        _selectedAnswer.value = index
        if (index == current.correctIndex) {
            _score.value++
        }
    }

    fun onNextQuestion() {
        val nextIndex = _currentIndex.value + 1
        if (nextIndex >= _questions.value.size) {
            _isFinished.value = true
        } else {
            _currentIndex.value = nextIndex
            _selectedAnswer.value = null
        }
    }

    fun restart() {
        _currentIndex.value = 0
        _score.value = 0
        _selectedAnswer.value = null
        _isFinished.value = false
    }
}
