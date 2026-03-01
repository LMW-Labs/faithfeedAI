package com.faithfeed.app.ui.screens.groups

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.faithfeed.app.data.repository.GroupRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class CreateGroupViewModel @Inject constructor(
    private val groupRepository: GroupRepository
) : ViewModel() {
    private val _name = MutableStateFlow("")
    val name: StateFlow<String> = _name.asStateFlow()

    private val _description = MutableStateFlow("")
    val description: StateFlow<String> = _description.asStateFlow()

    private val _isPrivate = MutableStateFlow(false)
    val isPrivate: StateFlow<Boolean> = _isPrivate.asStateFlow()

    private val _isSubmitting = MutableStateFlow(false)
    val isSubmitting: StateFlow<Boolean> = _isSubmitting.asStateFlow()

    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()

    fun onNameChange(v: String) { _name.value = v; _error.value = null }
    fun onDescriptionChange(v: String) { _description.value = v }
    fun onPrivacyChange(v: Boolean) { _isPrivate.value = v }

    fun createGroup(onSuccess: (String) -> Unit) {
        if (_name.value.isBlank()) {
            _error.value = "Group name is required"
            return
        }
        viewModelScope.launch {
            _isSubmitting.value = true
            groupRepository.createGroup(_name.value.trim(), _description.value.trim(), _isPrivate.value)
                .onSuccess { group -> onSuccess(group.id) }
                .onFailure { _error.value = it.message ?: "Failed to create group" }
            _isSubmitting.value = false
        }
    }
}
