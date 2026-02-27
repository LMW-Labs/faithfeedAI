package com.faithfeed.app.ui.screens.business

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.faithfeed.app.data.model.BusinessPage
import com.faithfeed.app.data.repository.BusinessPageRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class BusinessPageViewModel @Inject constructor(
    private val businessPageRepository: BusinessPageRepository
) : ViewModel() {
    private val _pageId = MutableStateFlow("")
    val page: StateFlow<BusinessPage?> = _pageId
        .flatMapLatest { id -> businessPageRepository.getPageFlow(id) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), null)

    private val _isFollowing = MutableStateFlow(false)
    val isFollowing: StateFlow<Boolean> = _isFollowing.asStateFlow()

    fun init(pageId: String) { _pageId.value = pageId }

    fun toggleFollow() {
        viewModelScope.launch {
            // TODO: call businessPageRepository.toggleFollow(pageId)
            _isFollowing.value = !_isFollowing.value
        }
    }
}
