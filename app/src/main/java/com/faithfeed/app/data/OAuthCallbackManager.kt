package com.faithfeed.app.data

import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Bridges MainActivity.onNewIntent() → LoginViewModel for OAuth browser callbacks.
 * Buffer of 1 ensures the emission survives until the ViewModel starts collecting.
 */
@Singleton
class OAuthCallbackManager @Inject constructor() {
    private val _pendingUri = MutableSharedFlow<String>(extraBufferCapacity = 1)
    val pendingUri: SharedFlow<String> = _pendingUri.asSharedFlow()

    fun emit(uri: String) {
        _pendingUri.tryEmit(uri)
    }
}
