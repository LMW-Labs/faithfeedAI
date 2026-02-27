package com.faithfeed.app.ui.screens.post

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.faithfeed.app.data.model.Comment
import com.faithfeed.app.data.model.Post
import com.faithfeed.app.data.repository.AuthRepository
import com.faithfeed.app.data.repository.PostRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class PostDetailUiState(
    val post: Post? = null,
    val comments: List<Comment> = emptyList(),
    val isLoading: Boolean = false,
    val commentText: String = "",
    val isCommenting: Boolean = false,
    val currentUserId: String = ""
)

@HiltViewModel
class PostDetailViewModel @Inject constructor(
    private val postRepository: PostRepository,
    private val authRepository: AuthRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(PostDetailUiState())
    val uiState: StateFlow<PostDetailUiState> = _uiState.asStateFlow()

    // Keep the legacy single-field StateFlows the existing Screen already observes
    val post: StateFlow<Post?> get() = MutableStateFlow(_uiState.value.post)
    val isLoading: StateFlow<Boolean> get() = MutableStateFlow(_uiState.value.isLoading)

    init {
        viewModelScope.launch {
            val userId = authRepository.currentUser()?.id ?: ""
            _uiState.update { it.copy(currentUserId = userId) }
        }
    }

    fun loadPost(postId: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            postRepository.getPost(postId).onSuccess { post ->
                _uiState.update { it.copy(post = post) }
            }
            _uiState.update { it.copy(isLoading = false) }
            loadComments(postId)
        }
    }

    private fun loadComments(postId: String) {
        viewModelScope.launch {
            postRepository.getComments(postId).onSuccess { comments ->
                _uiState.update { it.copy(comments = comments) }
            }
        }
    }

    fun onCommentTextChange(value: String) {
        _uiState.update { it.copy(commentText = value) }
    }

    fun submitComment() {
        val state = _uiState.value
        val postId = state.post?.id ?: return
        val text = state.commentText.trim()
        if (text.isBlank() || state.isCommenting) return

        _uiState.update { it.copy(isCommenting = true, commentText = "") }
        viewModelScope.launch {
            postRepository.addComment(postId, text).onSuccess { comment ->
                _uiState.update { it.copy(comments = it.comments + comment) }
            }.onFailure {
                // Restore text on failure so user can retry
                _uiState.update { it.copy(commentText = text) }
            }
            _uiState.update { it.copy(isCommenting = false) }
        }
    }

    fun likePost(postId: String) {
        viewModelScope.launch { postRepository.likePost(postId) }
    }

    fun prayPost(postId: String) {
        viewModelScope.launch { postRepository.prayPost(postId) }
    }
}
