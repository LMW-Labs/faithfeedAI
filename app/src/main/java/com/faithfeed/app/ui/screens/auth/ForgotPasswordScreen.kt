package com.faithfeed.app.ui.screens.auth

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.systemBarsPadding
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Email
import androidx.compose.material.icons.outlined.MarkEmailRead
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.faithfeed.app.ui.components.ButtonStyle
import com.faithfeed.app.ui.components.FaithFeedButton
import com.faithfeed.app.ui.components.GlassCard
import com.faithfeed.app.ui.components.SimpleTopBar
import com.faithfeed.app.ui.theme.FaithFeedColors
import com.faithfeed.app.ui.theme.FaithFeedGradients
import com.faithfeed.app.ui.theme.Nunito
import com.faithfeed.app.ui.theme.Typography

@Composable
fun ForgotPasswordScreen(
    onBack: () -> Unit,
    viewModel: ForgotPasswordViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(FaithFeedGradients.PrimaryBackground)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .systemBarsPadding()
        ) {
            SimpleTopBar(title = "Reset Password", onBack = onBack)

            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(horizontal = 24.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Spacer(Modifier.height(40.dp))

                if (uiState.isSent) {
                    // Success state
                    GlassCard(modifier = Modifier.fillMaxWidth()) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Icon(
                                imageVector = Icons.Outlined.MarkEmailRead,
                                contentDescription = null,
                                tint = FaithFeedColors.GoldAccent,
                                modifier = Modifier.size(64.dp)
                            )
                            Spacer(Modifier.height(16.dp))
                            Text("Check Your Email", style = Typography.titleLarge)
                            Spacer(Modifier.height(8.dp))
                            Text(
                                text = "We sent a password reset link to ${uiState.email}",
                                style = Typography.bodyMedium,
                                textAlign = TextAlign.Center,
                                color = FaithFeedColors.TextTertiary
                            )
                            Spacer(Modifier.height(24.dp))
                            FaithFeedButton(
                                text = "Back to Sign In",
                                onClick = onBack,
                                modifier = Modifier.fillMaxWidth(),
                                style = ButtonStyle.Secondary
                            )
                        }
                    }
                } else {
                    GlassCard(modifier = Modifier.fillMaxWidth()) {
                        Column {
                            Text("Forgot Password", style = Typography.titleLarge)
                            Spacer(Modifier.height(8.dp))
                            Text(
                                "Enter your email and we'll send you a reset link.",
                                style = Typography.bodyMedium,
                                color = FaithFeedColors.TextTertiary
                            )
                            Spacer(Modifier.height(24.dp))

                            AuthTextField(
                                value = uiState.email,
                                onValueChange = viewModel::onEmailChange,
                                label = "Email Address",
                                leadingIcon = {
                                    Icon(Icons.Outlined.Email, null, tint = FaithFeedColors.GoldAccent)
                                },
                                keyboardOptions = KeyboardOptions(
                                    keyboardType = KeyboardType.Email,
                                    imeAction = ImeAction.Done
                                )
                            )

                            if (uiState.error != null) {
                                Spacer(Modifier.height(12.dp))
                                Text(
                                    text = uiState.error!!,
                                    fontFamily = Nunito,
                                    color = androidx.compose.ui.graphics.Color(0xFFFF6B6B)
                                )
                            }

                            Spacer(Modifier.height(24.dp))
                            Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                                if (uiState.isLoading) {
                                    CircularProgressIndicator(
                                        color = FaithFeedColors.GoldAccent,
                                        modifier = Modifier.size(40.dp)
                                    )
                                } else {
                                    FaithFeedButton(
                                        text = "Send Reset Link",
                                        onClick = viewModel::sendReset,
                                        modifier = Modifier.fillMaxWidth(),
                                        style = ButtonStyle.Primary
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
