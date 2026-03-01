package com.faithfeed.app

import android.content.Intent
import android.os.Bundle
import android.view.Window
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.navigation.compose.rememberNavController
import com.faithfeed.app.data.OAuthCallbackManager
import com.faithfeed.app.navigation.RootNavGraph
import com.faithfeed.app.ui.theme.FaithFeedTheme
import dagger.hilt.android.AndroidEntryPoint
import javax.inject.Inject

@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    @Inject lateinit var oauthCallbackManager: OAuthCallbackManager

    override fun onCreate(savedInstanceState: Bundle?) {
        requestWindowFeature(Window.FEATURE_NO_TITLE)
        installSplashScreen()
        setTheme(R.style.Theme_FaithfeedAI)
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        // Handle deep link if app was cold-started via OAuth callback
        intent.data?.let { uri ->
            if (uri.scheme == "faithfeed") oauthCallbackManager.emit(uri.toString())
        }

        setContent {
            FaithFeedTheme {
                val rootNavController = rememberNavController()
                RootNavGraph(rootNavController = rootNavController)
            }
        }
    }

    /** Called when a faithfeed://login-callback deep link arrives while the app is running. */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        intent.data?.let { uri ->
            if (uri.scheme == "faithfeed") oauthCallbackManager.emit(uri.toString())
        }
    }
}
