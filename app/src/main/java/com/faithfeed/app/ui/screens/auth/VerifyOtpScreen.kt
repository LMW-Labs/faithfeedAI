package com.faithfeed.app.ui.screens.auth

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.systemBarsPadding
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
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
fun VerifyOtpScreen(
    phone: String,
    onVerified: (needsSetup: Boolean) -> Unit,
    onBack: () -> Unit,
    viewModel: VerifyOtpViewModel = hiltViewModel()
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
                .imePadding()
        ) {
            SimpleTopBar(title = "Verify Code", onBack = onBack)

            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(24.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Spacer(Modifier.height(32.dp))

                GlassCard(modifier = Modifier.fillMaxWidth()) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(
                            text = "Verification Code",
                            style = Typography.titleLarge,
                            color = FaithFeedColors.TextPrimary
                        )
                        Spacer(Modifier.height(8.dp))
                        Text(
                            text = "Code sent to $phone",
                            style = Typography.bodyMedium,
                            color = FaithFeedColors.TextTertiary,
                            textAlign = TextAlign.Center
                        )

                        Spacer(Modifier.height(24.dp))

                        AuthTextField(
                            value = uiState.token,
                            onValueChange = viewModel::onTokenChange,
                            label = "6-digit code",
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.NumberPassword)
                        )

                        if (uiState.error != null) {
                            Spacer(Modifier.height(8.dp))
                            Text(
                                text = uiState.error!!,
                                style = Typography.bodySmall,
                                color = Color(0xFFFF6B6B)
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
                                    text = "Verify",
                                    onClick = { viewModel.verify(phone) { onVerified(false) } },
                                    modifier = Modifier.fillMaxWidth(),
                                    style = ButtonStyle.Primary
                                )
                            }
                        }

                        Spacer(Modifier.height(8.dp))

                        TextButton(
                            onClick = { viewModel.resend(phone) },
                            enabled = !uiState.isResending
                        ) {
                            if (uiState.isResending) {
                                CircularProgressIndicator(
                                    color = FaithFeedColors.GoldAccent,
                                    modifier = Modifier.size(16.dp),
                                    strokeWidth = 2.dp
                                )
                            } else {
                                Text(
                                    text = "Resend Code",
                                    fontFamily = Nunito,
                                    fontWeight = FontWeight.SemiBold,
                                    color = FaithFeedColors.GoldAccent
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}
