package com.faithfeed.app.ui.screens.prayer

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.faithfeed.app.data.model.PrayerRequest
import com.faithfeed.app.data.repository.AuthRepository
import com.faithfeed.app.data.repository.PrayerRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class PrayerWallViewModel @Inject constructor(
    private val prayerRepository: PrayerRepository,
    private val authRepository: AuthRepository
) : ViewModel() {

    private val _currentUserId = MutableStateFlow("")
    val currentUserId: StateFlow<String> = _currentUserId.asStateFlow()

    init {
        viewModelScope.launch {
            _currentUserId.value = authRepository.currentUser()?.id ?: ""
        }
    }
    val prayers: StateFlow<List<PrayerRequest>> = prayerRepository
        .getPrayerWallFlow()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    fun prayForRequest(requestId: String) {
        viewModelScope.launch {
            prayerRepository.prayForRequest(requestId)
        }
    }
}
