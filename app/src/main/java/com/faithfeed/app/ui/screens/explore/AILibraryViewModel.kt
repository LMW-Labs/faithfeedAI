package com.faithfeed.app.ui.screens.explore

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.faithfeed.app.data.model.AIInteraction
import com.faithfeed.app.data.repository.AILibraryRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class AILibraryViewModel @Inject constructor(
    private val repo: AILibraryRepository
) : ViewModel() {

    private val _items = MutableStateFlow<List<AIInteraction>>(emptyList())
    private val _filter = MutableStateFlow("all")
    val filter: StateFlow<String> = _filter.asStateFlow()

    val filtered: StateFlow<List<AIInteraction>> = combine(_items, _filter) { list, f ->
        if (f == "all") list else list.filter { it.type == f }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    init {
        loadItems()
    }

    fun loadItems() {
        viewModelScope.launch {
            repo.getInteractionsFlow().collect { _items.value = it }
        }
    }

    fun setFilter(f: String) { _filter.value = f }

    fun delete(id: String) {
        viewModelScope.launch {
            repo.deleteInteraction(id)
            _items.value = _items.value.filter { it.id != id }
        }
    }
}
