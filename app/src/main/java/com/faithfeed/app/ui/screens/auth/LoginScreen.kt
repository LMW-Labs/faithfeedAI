package com.faithfeed.app.ui.screens.auth

import android.net.Uri
import androidx.browser.customtabs.CustomTabsIntent
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Email
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material.icons.outlined.Phone
import androidx.compose.material.icons.outlined.Visibility
import androidx.compose.material.icons.outlined.VisibilityOff
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusDirection
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.credentials.CredentialManager
import androidx.credentials.GetCredentialRequest
import androidx.credentials.exceptions.GetCredentialException
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.faithfeed.app.BuildConfig
import com.faithfeed.app.R
import com.faithfeed.app.ui.components.ButtonStyle
import com.faithfeed.app.ui.components.FaithFeedButton
import com.faithfeed.app.ui.components.GlassCard
import com.faithfeed.app.ui.theme.Cinzel
import com.faithfeed.app.ui.theme.FaithFeedColors
import com.faithfeed.app.ui.theme.FaithFeedGradients
import com.faithfeed.app.ui.theme.Nunito
import com.faithfeed.app.ui.theme.Typography
import com.google.android.libraries.identity.googleid.GetGoogleIdOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import kotlinx.coroutines.launch

@Composable
fun LoginScreen(
    onLoginSuccess: (Boolean) -> Unit,
    onNavigateToSignUp: () -> Unit,
    onNavigateToForgotPassword: () -> Unit,
    onNavigateToPhoneLogin: () -> Unit = {},
    viewModel: LoginViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val focusManager = LocalFocusManager.current
    val context = LocalContext.current
    val scope = rememberCoroutineScope()

    // Collect nav events from OAuth callbacks (Facebook etc.)
    LaunchedEffect(viewModel) {
        viewModel.navEvents.collect { event ->
            when (event) {
                is LoginNavEvent.LoginSuccess -> onLoginSuccess(event.needsSetup)
            }
        }
    }

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
            Spacer(Modifier.height(48.dp))

            // Logo + Brand
            Image(
                painter = painterResource(R.drawable.omega),
                contentDescription = "FaithFeed",
                modifier = Modifier.size(72.dp)
            )
            Spacer(Modifier.height(16.dp))
            Text(
                text = "FaithFeed",
                fontFamily = Cinzel,
                fontWeight = FontWeight.Bold,
                fontSize = 36.sp,
                color = FaithFeedColors.GoldAccent
            )
            Text(
                text = "Where Scripture Meets Scroll",
                style = Typography.bodyMedium,
                color = FaithFeedColors.TextTertiary,
                textAlign = TextAlign.Center
            )

            Spacer(Modifier.height(40.dp))

            GlassCard(modifier = Modifier.fillMaxWidth()) {
                Column {
                    Text(
                        text = "Welcome Back",
                        style = Typography.titleLarge,
                        color = FaithFeedColors.TextPrimary
                    )
                    Spacer(Modifier.height(4.dp))
                    Text(
                        text = "Sign in to your account",
                        style = Typography.bodyMedium,
                        color = FaithFeedColors.TextTertiary
                    )

                    Spacer(Modifier.height(24.dp))

                    // Email field
                    AuthTextField(
                        value = uiState.email,
                        onValueChange = viewModel::onEmailChange,
                        label = "Email",
                        leadingIcon = { Icon(Icons.Outlined.Email, null, tint = FaithFeedColors.GoldAccent) },
                        keyboardOptions = KeyboardOptions(
                            keyboardType = KeyboardType.Email,
                            imeAction = ImeAction.Next
                        ),
                        keyboardActions = KeyboardActions(
                            onNext = { focusManager.moveFocus(FocusDirection.Down) }
                        )
                    )

                    Spacer(Modifier.height(16.dp))

                    // Password field
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
                                    contentDescription = "Toggle password",
                                    tint = FaithFeedColors.TextTertiary
                                )
                            }
                        },
                        keyboardOptions = KeyboardOptions(
                            keyboardType = KeyboardType.Password,
                            imeAction = ImeAction.Done
                        ),
                        keyboardActions = KeyboardActions(
                            onDone = {
                                focusManager.clearFocus()
                                viewModel.signIn(onLoginSuccess)
                            }
                        )
                    )

                    // Error message
                    if (uiState.error != null) {
                        Spacer(Modifier.height(12.dp))
                        Text(
                            text = uiState.error!!,
                            fontFamily = Nunito,
                            fontSize = 13.sp,
                            color = androidx.compose.ui.graphics.Color(0xFFFF6B6B)
                        )
                    }

                    Spacer(Modifier.height(8.dp))
                    Text(
                        text = "Forgot password?",
                        fontFamily = Nunito,
                        fontWeight = FontWeight.SemiBold,
                        fontSize = 13.sp,
                        color = FaithFeedColors.GoldAccent,
                        modifier = Modifier
                            .align(Alignment.End)
                            .clickable(onClick = onNavigateToForgotPassword)
                    )

                    Spacer(Modifier.height(24.dp))

                    // Sign in button
                    Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                        if (uiState.isLoading) {
                            CircularProgressIndicator(
                                color = FaithFeedColors.GoldAccent,
                                modifier = Modifier.size(40.dp)
                            )
                        } else {
                            FaithFeedButton(
                                text = "Sign In",
                                onClick = { viewModel.signIn(onLoginSuccess) },
                                modifier = Modifier.fillMaxWidth(),
                                style = ButtonStyle.Primary
                            )
                        }
                    }

                    Spacer(Modifier.height(16.dp))
                    HorizontalDivider(color = FaithFeedColors.GlassBorder)
                    Spacer(Modifier.height(16.dp))

                    // Google Sign-In button
                    OutlinedButton(
                        onClick = {
                            scope.launch {
                                try {
                                    val cm = CredentialManager.create(context)
                                    val option = GetGoogleIdOption.Builder()
                                        .setFilterByAuthorizedAccounts(false)
                                        .setServerClientId(BuildConfig.GOOGLE_WEB_CLIENT_ID)
                                        .build()
                                    val result = cm.getCredential(
                                        context,
                                        GetCredentialRequest.Builder()
                                            .addCredentialOption(option)
                                            .build()
                                    )
                                    val idToken = GoogleIdTokenCredential
                                        .createFrom(result.credential.data).idToken
                                    viewModel.signInWithGoogle(idToken, onLoginSuccess)
                                } catch (_: GetCredentialException) {
                                    // User cancelled or no accounts — silent fail
                                }
                            }
                        },
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(16.dp),
                        border = androidx.compose.foundation.BorderStroke(
                            1.dp, FaithFeedColors.GlassBorder
                        )
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.Center
                        ) {
                            Text(
                                text = "G  Continue with Google",
                                fontFamily = Nunito,
                                fontWeight = FontWeight.SemiBold,
                                fontSize = 14.sp,
                                color = FaithFeedColors.TextPrimary
                            )
                        }
                    }

                    Spacer(Modifier.height(12.dp))

                    // Facebook Sign-In button (browser OAuth)
                    OutlinedButton(
                        onClick = {
                            try {
                                val url = viewModel.getFacebookSignInUrl()
                                CustomTabsIntent.Builder().build()
                                    .launchUrl(context, Uri.parse(url))
                            } catch (_: Exception) { /* no-op */ }
                        },
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(16.dp),
                        border = androidx.compose.foundation.BorderStroke(
                            1.dp, FaithFeedColors.GlassBorder
                        )
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.Center
                        ) {
                            Text(
                                text = "f  Continue with Facebook",
                                fontFamily = Nunito,
                                fontWeight = FontWeight.SemiBold,
                                fontSize = 14.sp,
                                color = FaithFeedColors.TextPrimary
                            )
                        }
                    }
                }
            }

            Spacer(Modifier.height(24.dp))

            // Sign up link
            Row(
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Don't have an account? ",
                    fontFamily = Nunito,
                    fontSize = 14.sp,
                    color = FaithFeedColors.TextSecondary
                )
                Text(
                    text = "Sign Up",
                    fontFamily = Nunito,
                    fontWeight = FontWeight.Bold,
                    fontSize = 14.sp,
                    color = FaithFeedColors.GoldAccent,
                    modifier = Modifier.clickable(onClick = onNavigateToSignUp)
                )
            }

            Spacer(Modifier.height(48.dp))
        }
    }
}

@Composable
fun AuthTextField(
    value: String,
    onValueChange: (String) -> Unit,
    label: String,
    modifier: Modifier = Modifier,
    leadingIcon: @Composable (() -> Unit)? = null,
    trailingIcon: @Composable (() -> Unit)? = null,
    visualTransformation: VisualTransformation = VisualTransformation.None,
    keyboardOptions: KeyboardOptions = KeyboardOptions.Default,
    keyboardActions: KeyboardActions = KeyboardActions.Default
) {
    OutlinedTextField(
        value = value,
        onValueChange = onValueChange,
        label = {
            Text(
                label,
                fontFamily = Nunito,
                color = FaithFeedColors.TextTertiary
            )
        },
        leadingIcon = leadingIcon,
        trailingIcon = trailingIcon,
        visualTransformation = visualTransformation,
        keyboardOptions = keyboardOptions,
        keyboardActions = keyboardActions,
        singleLine = true,
        colors = OutlinedTextFieldDefaults.colors(
            focusedBorderColor = FaithFeedColors.GoldAccent,
            unfocusedBorderColor = FaithFeedColors.GlassBorder,
            focusedTextColor = FaithFeedColors.TextPrimary,
            unfocusedTextColor = FaithFeedColors.TextPrimary,
            cursorColor = FaithFeedColors.GoldAccent,
            focusedContainerColor = FaithFeedColors.GlassBackground,
            unfocusedContainerColor = FaithFeedColors.GlassBackground
        ),
        shape = RoundedCornerShape(12.dp),
        modifier = modifier.fillMaxWidth()
    )
}
