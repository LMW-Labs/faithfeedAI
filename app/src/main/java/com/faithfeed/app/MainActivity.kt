package com.faithfeed.app

import android.os.Bundle
import android.view.Window
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.remember
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.navigation.compose.rememberNavController
import com.faithfeed.app.navigation.RootNavGraph
import com.faithfeed.app.ui.theme.FaithFeedTheme
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        requestWindowFeature(Window.FEATURE_NO_TITLE) // kills title bar before window is created
        installSplashScreen()
        setTheme(R.style.Theme_FaithfeedAI)
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        setContent {
            FaithFeedTheme {
                val rootNavController = rememberNavController()
                RootNavGraph(rootNavController = rootNavController)
            }
        }
    }
}
