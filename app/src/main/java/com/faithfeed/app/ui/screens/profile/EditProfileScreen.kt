package com.faithfeed.app.ui.screens.profile

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.CameraAlt
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavController
import coil3.compose.AsyncImage
import com.faithfeed.app.ui.components.ButtonStyle
import com.faithfeed.app.ui.components.FaithFeedButton
import com.faithfeed.app.ui.components.SimpleTopBar
import com.faithfeed.app.ui.theme.FaithFeedColors
import com.faithfeed.app.ui.theme.Typography

@Composable
fun EditProfileScreen(
    navController: NavController,
    viewModel: EditProfileViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val context = LocalContext.current

    val photoPickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.PickVisualMedia()
    ) { uri ->
        uri?.let { viewModel.onAvatarSelected(it, context) }
    }

    if (uiState.isLoading) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(FaithFeedColors.BackgroundPrimary),
            contentAlignment = Alignment.Center
        ) {
            CircularProgressIndicator(color = FaithFeedColors.GoldAccent)
        }
        return
    }

    val screenTitle = if (uiState.isNewUser) "Set Up Your Profile" else "Edit Profile"
    val saveLabel = when {
        uiState.isSaving -> "Saving..."
        uiState.isNewUser -> "Complete Setup"
        else -> "Save Changes"
    }

    Scaffold(
        containerColor = FaithFeedColors.BackgroundPrimary,
        topBar = {
            SimpleTopBar(
                title = screenTitle,
                onBack = if (uiState.isNewUser) null else ({ navController.popBackStack() })
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 24.dp, vertical = 20.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {

            // -- Avatar ---------------------------------------------------
            Box(contentAlignment = Alignment.BottomEnd) {
                // Avatar circle: photo if available, else gold initial on purple
                Box(
                    modifier = Modifier
                        .size(96.dp)
                        .clip(CircleShape)
                        .background(FaithFeedColors.PurpleDark)
                        .border(2.dp, FaithFeedColors.GoldAccent, CircleShape),
                    contentAlignment = Alignment.Center
                ) {
                    if (uiState.avatarUrl != null) {
                        AsyncImage(
                            model = uiState.avatarUrl,
                            contentDescription = null,
                            modifier = Modifier
                                .size(96.dp)
                                .clip(CircleShape),
                            contentScale = ContentScale.Crop
                        )
                    } else {
                        Text(
                            text = uiState.displayName.firstOrNull()?.uppercaseChar()?.toString() ?: "?",
                            fontSize = 36.sp,
                            fontWeight = FontWeight.Bold,
                            color = FaithFeedColors.GoldAccent
                        )
                    }

                    // Upload progress overlay
                    if (uiState.isUploadingAvatar) {
                        Box(
                            modifier = Modifier
                                .size(96.dp)
                                .clip(CircleShape)
                                .background(FaithFeedColors.BackgroundPrimary.copy(alpha = 0.65f)),
                            contentAlignment = Alignment.Center
                        ) {
                            CircularProgressIndicator(
                                color = FaithFeedColors.GoldAccent,
                                modifier = Modifier.size(28.dp),
                                strokeWidth = 2.5.dp
                            )
                        }
                    }
                }

                // Camera button overlay: bottom-end corner of the avatar circle
                Surface(
                    shape = CircleShape,
                    color = FaithFeedColors.GoldAccent,
                    modifier = Modifier
                        .size(32.dp)
                        .clickable(enabled = !uiState.isUploadingAvatar) {
                            photoPickerLauncher.launch(
                                PickVisualMediaRequest(
                                    ActivityResultContracts.PickVisualMedia.ImageOnly
                                )
                            )
                        }
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Icon(
                            imageVector = Icons.Outlined.CameraAlt,
                            contentDescription = "Change photo",
                            tint = FaithFeedColors.BackgroundPrimary,
                            modifier = Modifier.size(16.dp)
                        )
                    }
                }
            }

            Spacer(Modifier.height(4.dp))

            // -- Form fields ----------------------------------------------

            ProfileTextField(
                value = uiState.displayName,
                onValueChange = viewModel::onDisplayNameChange,
                label = "Display Name *",
                singleLine = true
            )

            ProfileTextField(
                value = uiState.username,
                onValueChange = viewModel::onUsernameChange,
                label = "Username",
                singleLine = true
            )

            ProfileTextField(
                value = uiState.bio,
                onValueChange = viewModel::onBioChange,
                label = "Bio",
                singleLine = false,
                minLines = 3,
                maxLines = 5
            )

            ProfileTextField(
                value = uiState.location,
                onValueChange = viewModel::onLocationChange,
                label = "Location",
                singleLine = true
            )

            ProfileTextField(
                value = uiState.website,
                onValueChange = viewModel::onWebsiteChange,
                label = "Website",
                singleLine = true,
                keyboardType = KeyboardType.Uri
            )

            ProfileTextField(
                value = uiState.denomination,
                onValueChange = viewModel::onDenominationChange,
                label = "Denomination",
                singleLine = true
            )

            ProfileTextField(
                value = uiState.phone,
                onValueChange = viewModel::onPhoneChange,
                label = "Phone",
                singleLine = true,
                keyboardType = KeyboardType.Phone
            )

            // -- Error message --------------------------------------------
            if (uiState.error != null) {
                Text(
                    text = uiState.error!!,
                    style = Typography.bodySmall,
                    color = MaterialTheme.colorScheme.error
                )
            }

            Spacer(Modifier.height(8.dp))

            // -- Save button ----------------------------------------------
            FaithFeedButton(
                text = saveLabel,
                onClick = { viewModel.save { navController.popBackStack() } },
                style = ButtonStyle.Primary,
                enabled = !uiState.isSaving && !uiState.isUploadingAvatar,
                modifier = Modifier.fillMaxWidth()
            )

            Spacer(Modifier.height(32.dp))
        }
    }
}

@Composable
private fun ProfileTextField(
    value: String,
    onValueChange: (String) -> Unit,
    label: String,
    singleLine: Boolean,
    minLines: Int = 1,
    maxLines: Int = 1,
    keyboardType: KeyboardType = KeyboardType.Text
) {
    OutlinedTextField(
        value = value,
        onValueChange = onValueChange,
        label = { Text(label, color = FaithFeedColors.TextSecondary) },
        singleLine = singleLine,
        minLines = minLines,
        maxLines = if (singleLine) 1 else maxLines,
        keyboardOptions = KeyboardOptions(
            capitalization = if (keyboardType == KeyboardType.Text) {
                KeyboardCapitalization.Sentences
            } else {
                KeyboardCapitalization.None
            },
            keyboardType = keyboardType
        ),
        modifier = Modifier.fillMaxWidth(),
        colors = OutlinedTextFieldDefaults.colors(
            focusedTextColor = FaithFeedColors.TextPrimary,
            unfocusedTextColor = FaithFeedColors.TextPrimary,
            focusedBorderColor = FaithFeedColors.GoldAccent,
            unfocusedBorderColor = FaithFeedColors.GlassBorder,
            focusedLabelColor = FaithFeedColors.GoldAccent,
            cursorColor = FaithFeedColors.GoldAccent,
            focusedContainerColor = FaithFeedColors.GlassBackground,
            unfocusedContainerColor = FaithFeedColors.GlassBackground
        ),
        shape = RoundedCornerShape(12.dp)
    )
}
