package com.faithfeed.app.ui.screens.splash

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.faithfeed.app.R
import com.faithfeed.app.ui.theme.FaithFeedColors
import com.faithfeed.app.ui.theme.FaithFeedGradients
import com.faithfeed.app.ui.theme.Typography

@Composable
fun SplashScreen(
    onAuthFound: (Boolean) -> Unit,
    onNoAuth: () -> Unit,
    viewModel: SplashViewModel = hiltViewModel()
) {
    LaunchedEffect(Unit) {
        viewModel.checkAuthAndNavigate(
            onAuthFound = onAuthFound,
            onNoAuth = onNoAuth
        )
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(FaithFeedGradients.PrimaryBackground),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Image(
            painter = painterResource(R.drawable.omega),
            contentDescription = "FaithFeed",
            modifier = Modifier.size(96.dp)
        )
        Spacer(Modifier.height(24.dp))
        Text(
            text = "FaithFeed",
            style = Typography.headlineLarge,
            color = FaithFeedColors.GoldAccent
        )
        Spacer(Modifier.height(8.dp))
        Text(
            text = "Where Scripture Meets Scroll",
            style = Typography.bodyLarge,
            color = FaithFeedColors.TextTertiary
        )
    }
}
