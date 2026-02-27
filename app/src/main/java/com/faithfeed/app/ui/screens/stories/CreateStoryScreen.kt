package com.faithfeed.app.ui.screens.stories

import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.AddAPhoto
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavController
import coil3.compose.AsyncImage
import com.faithfeed.app.ui.components.SimpleTopBar
import com.faithfeed.app.ui.theme.FaithFeedColors
import com.faithfeed.app.ui.theme.Typography

@Composable
fun CreateStoryScreen(
    navController: NavController,
    viewModel: CreateStoryViewModel = hiltViewModel()
) {
    val imageUri by viewModel.imageUri.collectAsStateWithLifecycle()
    val caption by viewModel.caption.collectAsStateWithLifecycle()
    val isUploading by viewModel.isUploading.collectAsStateWithLifecycle()
    val isDone by viewModel.isDone.collectAsStateWithLifecycle()
    val error by viewModel.error.collectAsStateWithLifecycle()
    val context = LocalContext.current

    LaunchedEffect(isDone) {
        if (isDone) navController.popBackStack()
    }

    val mediaPicker = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.PickVisualMedia()
    ) { uri: Uri? -> viewModel.onImageSelected(uri) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(FaithFeedColors.BackgroundPrimary)
    ) {
        SimpleTopBar(title = "New Story", onBack = { navController.popBackStack() })

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Image preview / picker
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(360.dp)
                    .clip(RoundedCornerShape(16.dp))
                    .background(FaithFeedColors.BackgroundSecondary)
                    .border(
                        1.dp,
                        if (imageUri != null) FaithFeedColors.GoldAccent.copy(alpha = 0.4f)
                        else FaithFeedColors.GlassBorder,
                        RoundedCornerShape(16.dp)
                    )
                    .clickable(enabled = !isUploading) {
                        mediaPicker.launch(
                            PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)
                        )
                    },
                contentAlignment = Alignment.Center
            ) {
                if (imageUri != null) {
                    AsyncImage(
                        model = imageUri,
                        contentDescription = "Story preview",
                        contentScale = ContentScale.Crop,
                        modifier = Modifier.fillMaxSize().clip(RoundedCornerShape(16.dp))
                    )
                    // Overlay to re-pick
                    Box(
                        modifier = Modifier
                            .align(Alignment.BottomEnd)
                            .padding(12.dp)
                            .background(
                                FaithFeedColors.BackgroundPrimary.copy(alpha = 0.7f),
                                RoundedCornerShape(8.dp)
                            )
                            .padding(horizontal = 10.dp, vertical = 6.dp)
                    ) {
                        Text(
                            "Change",
                            style = Typography.labelSmall,
                            color = FaithFeedColors.GoldAccent
                        )
                    }
                } else {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(
                            imageVector = Icons.Outlined.AddAPhoto,
                            contentDescription = null,
                            tint = FaithFeedColors.GoldAccent,
                            modifier = Modifier.size(48.dp)
                        )
                        Spacer(Modifier.height(12.dp))
                        Text(
                            "Tap to choose a photo",
                            style = Typography.bodyMedium,
                            color = FaithFeedColors.TextSecondary
                        )
                    }
                }
            }

            // Caption input
            OutlinedTextField(
                value = caption,
                onValueChange = viewModel::onCaptionChange,
                placeholder = {
                    Text("Add a caption...", color = FaithFeedColors.TextTertiary)
                },
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = FaithFeedColors.GoldAccent,
                    unfocusedBorderColor = FaithFeedColors.GlassBorder,
                    cursorColor = FaithFeedColors.GoldAccent,
                    focusedTextColor = FaithFeedColors.TextPrimary,
                    unfocusedTextColor = FaithFeedColors.TextPrimary,
                    focusedContainerColor = FaithFeedColors.BackgroundSecondary,
                    unfocusedContainerColor = FaithFeedColors.BackgroundSecondary
                ),
                maxLines = 3,
                textStyle = Typography.bodyMedium.copy(color = FaithFeedColors.TextPrimary)
            )

            if (error != null) {
                Text(
                    text = error!!,
                    color = MaterialTheme.colorScheme.error,
                    style = Typography.bodySmall
                )
            }

            Spacer(Modifier.weight(1f))

            // Share button
            Button(
                onClick = { viewModel.postStory(context) },
                enabled = imageUri != null && !isUploading,
                modifier = Modifier.fillMaxWidth().height(52.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = FaithFeedColors.GoldAccent,
                    contentColor = FaithFeedColors.BackgroundPrimary,
                    disabledContainerColor = FaithFeedColors.GoldAccent.copy(alpha = 0.4f),
                    disabledContentColor = FaithFeedColors.BackgroundPrimary.copy(alpha = 0.5f)
                ),
                shape = RoundedCornerShape(12.dp)
            ) {
                if (isUploading) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(20.dp),
                        color = FaithFeedColors.BackgroundPrimary,
                        strokeWidth = 2.dp
                    )
                } else {
                    Text(
                        "Share Story",
                        style = Typography.titleSmall.copy(fontWeight = FontWeight.Bold)
                    )
                }
            }
        }
    }
}
