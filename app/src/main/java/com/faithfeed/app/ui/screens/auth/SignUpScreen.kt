package com.faithfeed.app.ui.screens.auth

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.systemBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Email
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material.icons.outlined.Visibility
import androidx.compose.material.icons.outlined.VisibilityOff
import androidx.compose.material3.Checkbox
import androidx.compose.material3.CheckboxDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.faithfeed.app.R
import com.faithfeed.app.ui.components.ButtonStyle
import com.faithfeed.app.ui.components.FaithFeedButton
import com.faithfeed.app.ui.components.GlassCard
import com.faithfeed.app.ui.theme.Cinzel
import com.faithfeed.app.ui.theme.FaithFeedColors
import com.faithfeed.app.ui.theme.FaithFeedGradients
import com.faithfeed.app.ui.theme.Nunito
import com.faithfeed.app.ui.theme.Typography

@Composable
fun SignUpScreen(
    onSignUpSuccess: () -> Unit,
    onNavigateToLogin: () -> Unit,
    viewModel: SignUpViewModel = hiltViewModel()
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
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(Modifier.height(40.dp))

            Image(
                painter = painterResource(R.drawable.omega),
                contentDescription = "FaithFeed",
                modifier = Modifier.size(60.dp)
            )
            Spacer(Modifier.height(12.dp))
            Text(
                text = "Join FaithFeed",
                fontFamily = Cinzel,
                fontWeight = FontWeight.Bold,
                fontSize = 28.sp,
                color = FaithFeedColors.GoldAccent
            )
            Text(
                text = "Your faith community awaits",
                style = Typography.bodyMedium,
                color = FaithFeedColors.TextTertiary,
                textAlign = TextAlign.Center
            )

            Spacer(Modifier.height(32.dp))

            GlassCard(modifier = Modifier.fillMaxWidth()) {
                Column {
                    Text("Create Account", style = Typography.titleLarge)
                    Spacer(Modifier.height(20.dp))

                    AuthTextField(
                        value = uiState.displayName,
                        onValueChange = viewModel::onDisplayNameChange,
                        label = "Full Name",
                        leadingIcon = { Icon(Icons.Outlined.Person, null, tint = FaithFeedColors.GoldAccent) },
                        keyboardOptions = KeyboardOptions(imeAction = ImeAction.Next)
                    )
                    Spacer(Modifier.height(14.dp))
                    AuthTextField(
                        value = uiState.email,
                        onValueChange = viewModel::onEmailChange,
                        label = "Email",
                        leadingIcon = { Icon(Icons.Outlined.Email, null, tint = FaithFeedColors.GoldAccent) },
                        keyboardOptions = KeyboardOptions(
                            keyboardType = KeyboardType.Email,
                            imeAction = ImeAction.Next
                        )
                    )
                    Spacer(Modifier.height(14.dp))
                    AuthTextField(
                        value = uiState.password,
                        onValueChange = viewModel::onPasswordChange,
                        label = "Password",
                        leadingIcon = { Icon(Icons.Outlined.Lock, null, tint = FaithFeedColors.GoldAccent) },
                        visualTransformation = if (uiState.passwordVisible)
                            VisualTransformation.None else PasswordVisualTransformation(),
                        trailingIcon = {
                            IconButton(onClick = viewModel::togglePasswordVisibility) {
                                Icon(
                                    imageVector = if (uiState.passwordVisible)
                                        Icons.Outlined.VisibilityOff else Icons.Outlined.Visibility,
                                    contentDescription = null,
                                    tint = FaithFeedColors.TextTertiary
                                )
                            }
                        },
                        keyboardOptions = KeyboardOptions(
                            keyboardType = KeyboardType.Password,
                            imeAction = ImeAction.Next
                        )
                    )
                    Spacer(Modifier.height(14.dp))
                    AuthTextField(
                        value = uiState.confirmPassword,
                        onValueChange = viewModel::onConfirmPasswordChange,
                        label = "Confirm Password",
                        leadingIcon = { Icon(Icons.Outlined.Lock, null, tint = FaithFeedColors.GoldAccent) },
                        visualTransformation = PasswordVisualTransformation(),
                        keyboardOptions = KeyboardOptions(
                            keyboardType = KeyboardType.Password,
                            imeAction = ImeAction.Done
                        )
                    )

                    Spacer(Modifier.height(16.dp))
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Checkbox(
                            checked = uiState.termsAccepted,
                            onCheckedChange = { viewModel.onTermsToggle() },
                            colors = CheckboxDefaults.colors(
                                checkedColor = FaithFeedColors.GoldAccent,
                                uncheckedColor = FaithFeedColors.TextTertiary
                            )
                        )
                        Text(
                            text = "I agree to the Terms of Service and Community Guidelines",
                            fontFamily = Nunito,
                            fontSize = 12.sp,
                            color = FaithFeedColors.TextSecondary
                        )
                    }

                    if (uiState.error != null) {
                        Spacer(Modifier.height(8.dp))
                        Text(
                            text = uiState.error!!,
                            fontFamily = Nunito,
                            fontSize = 13.sp,
                            color = androidx.compose.ui.graphics.Color(0xFFFF6B6B)
                        )
                    }

                    Spacer(Modifier.height(20.dp))

                    Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                        if (uiState.isLoading) {
                            CircularProgressIndicator(color = FaithFeedColors.GoldAccent, modifier = Modifier.size(40.dp))
                        } else {
                            FaithFeedButton(
                                text = "Create Account",
                                onClick = { viewModel.signUp(onSignUpSuccess) },
                                modifier = Modifier.fillMaxWidth(),
                                style = ButtonStyle.Primary
                            )
                        }
                    }
                }
            }

            Spacer(Modifier.height(20.dp))
            Row(horizontalArrangement = Arrangement.Center) {
                Text("Already have an account? ", fontFamily = Nunito, fontSize = 14.sp, color = FaithFeedColors.TextSecondary)
                Text(
                    "Sign In",
                    fontFamily = Nunito,
                    fontWeight = FontWeight.Bold,
                    fontSize = 14.sp,
                    color = FaithFeedColors.GoldAccent,
                    modifier = Modifier.clickable(onClick = onNavigateToLogin)
                )
            }
            Spacer(Modifier.height(40.dp))
        }
    }
}
