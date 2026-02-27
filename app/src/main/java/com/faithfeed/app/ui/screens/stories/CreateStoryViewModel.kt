package com.faithfeed.app.ui.screens.stories

import android.content.Context
import android.net.Uri
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.faithfeed.app.data.repository.StoryRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class CreateStoryViewModel @Inject constructor(
    private val storyRepository: StoryRepository
) : ViewModel() {

    private val _imageUri = MutableStateFlow<Uri?>(null)
    val imageUri: StateFlow<Uri?> = _imageUri.asStateFlow()

    private val _caption = MutableStateFlow("")
    val caption: StateFlow<String> = _caption.asStateFlow()

    private val _isUploading = MutableStateFlow(false)
    val isUploading: StateFlow<Boolean> = _isUploading.asStateFlow()

    private val _isDone = MutableStateFlow(false)
    val isDone: StateFlow<Boolean> = _isDone.asStateFlow()

    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()

    fun onImageSelected(uri: Uri?) {
        _imageUri.value = uri
        _error.value = null
    }

    fun onCaptionChange(text: String) {
        _caption.value = text
    }

    fun postStory(context: Context) {
        val uri = _imageUri.value ?: return
        viewModelScope.launch {
            _isUploading.value = true
            _error.value = null
            try {
                val bytes = context.contentResolver.openInputStream(uri)?.use { it.readBytes() }
                    ?: run { _error.value = "Could not read image"; return@launch }
                val mimeType = context.contentResolver.getType(uri) ?: "image/jpeg"
                val mediaType = if (mimeType.startsWith("video", ignoreCase = true)) "video" else "image"

                val uploadResult = storyRepository.uploadStoryMedia(bytes, mimeType)
                if (uploadResult.isFailure) {
                    _error.value = uploadResult.exceptionOrNull()?.message ?: "Upload failed"
                    return@launch
                }
                val url = uploadResult.getOrThrow()
                val createResult = storyRepository.createStory(
                    mediaUrl = url,
                    mediaType = mediaType,
                    caption = _caption.value.ifBlank { null }
                )
                if (createResult.isSuccess) {
                    _isDone.value = true
                } else {
                    _error.value = createResult.exceptionOrNull()?.message ?: "Failed to post story"
                }
            } catch (e: Exception) {
                _error.value = e.message ?: "An error occurred"
            } finally {
                _isUploading.value = false
            }
        }
    }
}
