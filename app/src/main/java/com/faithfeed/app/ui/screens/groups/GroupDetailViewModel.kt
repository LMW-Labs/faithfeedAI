package com.faithfeed.app.ui.screens.groups

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.faithfeed.app.data.model.Group
import com.faithfeed.app.data.model.User
import com.faithfeed.app.data.repository.GroupRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

@OptIn(ExperimentalCoroutinesApi::class)
@HiltViewModel
class GroupDetailViewModel @Inject constructor(
    private val groupRepository: GroupRepository
) : ViewModel() {

    private val _groupId = MutableStateFlow("")
    private val _refreshKey = MutableStateFlow(0)

    val group: StateFlow<Group?> = combine(_groupId, _refreshKey) { id, _ -> id }
        .flatMapLatest { id -> if (id.isEmpty()) flowOf(null) else groupRepository.getGroupFlow(id) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), null)

    private val _members = MutableStateFlow<List<User>>(emptyList())
    val members: StateFlow<List<User>> = _members.asStateFlow()

    private val _isJoining = MutableStateFlow(false)
    val isJoining: StateFlow<Boolean> = _isJoining.asStateFlow()

    fun init(groupId: String) {
        _groupId.value = groupId
        viewModelScope.launch {
            _members.value = groupRepository.getGroupMembers(groupId)
        }
    }

    fun toggleMembership(group: Group) = viewModelScope.launch {
        _isJoining.value = true
        if (group.isMember) {
            groupRepository.leaveGroup(group.id)
        } else {
            groupRepository.joinGroup(group.id)
        }
        _refreshKey.value++
        _members.value = groupRepository.getGroupMembers(group.id)
        _isJoining.value = false
    }
}
