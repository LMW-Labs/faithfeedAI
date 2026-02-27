package com.faithfeed.app.ui.screens.marketplace

import android.content.Context
import android.net.Uri
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.faithfeed.app.data.repository.MarketplaceRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class CreateListingViewModel @Inject constructor(
    private val marketplaceRepository: MarketplaceRepository
) : ViewModel() {

    val title = MutableStateFlow("")
    val description = MutableStateFlow("")
    val price = MutableStateFlow("")
    val itemType = MutableStateFlow("physical") // physical / digital / service / donation
    val category = MutableStateFlow("")
    val condition = MutableStateFlow("new")
    val location = MutableStateFlow("")

    private val _imageUris = MutableStateFlow<List<Uri>>(emptyList())
    val imageUris: StateFlow<List<Uri>> = _imageUris.asStateFlow()

    private val _isSubmitting = MutableStateFlow(false)
    val isSubmitting: StateFlow<Boolean> = _isSubmitting.asStateFlow()

    private val _isDone = MutableStateFlow(false)
    val isDone: StateFlow<Boolean> = _isDone.asStateFlow()

    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()

    fun addImage(uri: Uri) {
        if (_imageUris.value.size < 5) {
            _imageUris.value = _imageUris.value + uri
        }
    }

    fun removeImage(uri: Uri) {
        _imageUris.value = _imageUris.value - uri
    }

    fun submit(context: Context) {
        val t = title.value.trim()
        if (t.isBlank()) { _error.value = "Title is required"; return }
        val parsedPrice = if (itemType.value == "donation") 0.0
        else price.value.toDoubleOrNull() ?: run { _error.value = "Enter a valid price"; return }

        viewModelScope.launch {
            _isSubmitting.value = true
            // Upload images
            val uploadedUrls = mutableListOf<String>()
            for (uri in _imageUris.value) {
                try {
                    val bytes = context.contentResolver.openInputStream(uri)?.readBytes() ?: continue
                    val mime = context.contentResolver.getType(uri) ?: "image/jpeg"
                    marketplaceRepository.uploadImage(bytes, mime)
                        .onSuccess { uploadedUrls.add(it) }
                } catch (_: Exception) {}
            }

            marketplaceRepository.createListing(
                title = t,
                description = description.value.trim(),
                price = parsedPrice,
                itemType = itemType.value,
                category = category.value.trim(),
                condition = condition.value,
                location = location.value.trim(),
                mediaUrls = uploadedUrls
            ).onSuccess {
                _isDone.value = true
            }.onFailure {
                _error.value = it.message ?: "Failed to create listing"
            }
            _isSubmitting.value = false
        }
    }

    fun clearError() { _error.value = null }
}
