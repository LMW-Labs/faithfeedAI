package com.faithfeed.app.ui.screens.explore

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.faithfeed.app.data.repository.AIRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class TopicalStudiesViewModel @Inject constructor(
    private val aiRepository: AIRepository
) : ViewModel() {
    private val _topic = MutableStateFlow("")
    val topic: StateFlow<String> = _topic.asStateFlow()
    
    private val _studyPlan = MutableStateFlow("")
    val studyPlan: StateFlow<String> = _studyPlan.asStateFlow()
    
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    fun generateStudy(topicName: String) {
        if (topicName.isBlank()) return
        
        _topic.value = topicName
        _isLoading.value = true
        _studyPlan.value = ""
        
        viewModelScope.launch {
            // Hardcode 7 days for the basic topical study.
            val result = aiRepository.generateStudyPlan(topicName, 7)
            result.onSuccess { 
                _studyPlan.value = it
            }
            _isLoading.value = false
        }
    }
}