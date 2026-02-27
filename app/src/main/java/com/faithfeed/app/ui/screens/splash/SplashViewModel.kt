package com.faithfeed.app.ui.screens.splash

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.faithfeed.app.data.repository.AuthRepository
import com.faithfeed.app.data.repository.UserRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class SplashViewModel @Inject constructor(
    private val authRepository: AuthRepository,
    private val userRepository: UserRepository
) : ViewModel() {

    fun checkAuthAndNavigate(onAuthFound: (Boolean) -> Unit, onNoAuth: () -> Unit) {
        viewModelScope.launch {
            delay(800) // Brief splash display
            if (authRepository.isLoggedIn()) {
                val user = authRepository.currentUser()
                if (user != null) {
                    val profileResult = userRepository.getProfile(user.id)
                    // Only force profile setup if profile is confirmed missing.
                    // Network errors default to false so existing users still reach Home.
                    val needsSetup = profileResult.isSuccess && profileResult.getOrNull() == null
                    onAuthFound(needsSetup)
                } else {
                    onNoAuth()
                }
            } else {
                onNoAuth()
            }
        }
    }
}
