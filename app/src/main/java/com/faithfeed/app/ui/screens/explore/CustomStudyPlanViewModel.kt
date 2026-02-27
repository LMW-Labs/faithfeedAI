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
class CustomStudyPlanViewModel @Inject constructor(
    private val aiRepository: AIRepository
) : ViewModel() {
    private val _topic = MutableStateFlow("")
    val topic: StateFlow<String> = _topic.asStateFlow()
    
    private val _durationDays = MutableStateFlow(30)
    val durationDays: StateFlow<Int> = _durationDays.asStateFlow()
    
    private val _plan = MutableStateFlow("")
    val plan: StateFlow<String> = _plan.asStateFlow()
    
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    fun onTopicChange(v: String) { _topic.value = v }
    
    fun onDurationChange(d: Int) { _durationDays.value = d }

    fun generatePlan() {
        if (_topic.value.isBlank()) return
        
        _isLoading.value = true
        _plan.value = ""
        
        viewModelScope.launch {
            val result = aiRepository.generateStudyPlan(_topic.value, _durationDays.value)
            result.onSuccess { 
                _plan.value = it
            }
            _isLoading.value = false
        }
    }
}