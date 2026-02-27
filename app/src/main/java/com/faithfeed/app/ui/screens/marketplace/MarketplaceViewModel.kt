package com.faithfeed.app.ui.screens.marketplace

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import androidx.paging.PagingData
import androidx.paging.cachedIn
import com.faithfeed.app.data.model.MarketplaceItem
import com.faithfeed.app.data.repository.MarketplaceRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flatMapLatest
import javax.inject.Inject

@OptIn(ExperimentalCoroutinesApi::class)
@HiltViewModel
class MarketplaceViewModel @Inject constructor(
    private val marketplaceRepository: MarketplaceRepository
) : ViewModel() {

    private val _category = MutableStateFlow<String?>(null)
    val category: StateFlow<String?> = _category.asStateFlow()

    private val _searchQuery = MutableStateFlow("")
    val searchQuery: StateFlow<String> = _searchQuery.asStateFlow()

    val items: Flow<PagingData<MarketplaceItem>> =
        combine(_category, _searchQuery) { cat, q -> cat to q }
            .flatMapLatest { (cat, q) ->
                marketplaceRepository.getItemsPager(cat, q.ifBlank { null })
            }
            .cachedIn(viewModelScope)

    fun onCategoryChange(c: String?) { _category.value = c }
    fun onSearchQueryChange(q: String) { _searchQuery.value = q }
}
