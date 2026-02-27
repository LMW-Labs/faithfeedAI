package com.faithfeed.app.ui.screens.marketplace

import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.outlined.AddPhotoAlternate
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavController
import coil3.compose.AsyncImage
import com.faithfeed.app.ui.components.SimpleTopBar
import com.faithfeed.app.ui.theme.FaithFeedColors
import com.faithfeed.app.ui.theme.Nunito
import com.faithfeed.app.ui.theme.Typography

@Composable
fun CreateListingScreen(
    navController: NavController,
    viewModel: CreateListingViewModel = hiltViewModel()
) {
    val context = LocalContext.current
    val isDone by viewModel.isDone.collectAsStateWithLifecycle()
    val isSubmitting by viewModel.isSubmitting.collectAsStateWithLifecycle()
    val error by viewModel.error.collectAsStateWithLifecycle()
    val imageUris by viewModel.imageUris.collectAsStateWithLifecycle()
    val title by viewModel.title.collectAsStateWithLifecycle()
    val description by viewModel.description.collectAsStateWithLifecycle()
    val price by viewModel.price.collectAsStateWithLifecycle()
    val itemType by viewModel.itemType.collectAsStateWithLifecycle()
    val category by viewModel.category.collectAsStateWithLifecycle()
    val condition by viewModel.condition.collectAsStateWithLifecycle()
    val location by viewModel.location.collectAsStateWithLifecycle()

    LaunchedEffect(isDone) { if (isDone) navController.popBackStack() }

    val snackbarHostState = remember { SnackbarHostState() }
    LaunchedEffect(error) {
        error?.let { snackbarHostState.showSnackbar(it); viewModel.clearError() }
    }

    val imagePicker = rememberLauncherForActivityResult(
        ActivityResultContracts.PickVisualMedia()
    ) { uri: Uri? -> uri?.let { viewModel.addImage(it) } }

    Scaffold(
        containerColor = FaithFeedColors.BackgroundPrimary,
        snackbarHost = { SnackbarHost(snackbarHostState) },
        topBar = {
            SimpleTopBar(title = "Create Listing", onBack = { navController.popBackStack() })
        },
        bottomBar = {
            Surface(
                color = FaithFeedColors.BackgroundSecondary,
                tonalElevation = 4.dp
            ) {
                Button(
                    onClick = { viewModel.submit(context) },
                    enabled = !isSubmitting,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp)
                        .navigationBarsPadding(),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = FaithFeedColors.GoldAccent,
                        contentColor = FaithFeedColors.BackgroundPrimary,
                        disabledContainerColor = FaithFeedColors.GlassBackground
                    ),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    if (isSubmitting) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(18.dp),
                            color = FaithFeedColors.BackgroundPrimary,
                            strokeWidth = 2.dp
                        )
                        Spacer(Modifier.width(8.dp))
                    }
                    Text(
                        "Post Listing",
                        fontFamily = Nunito,
                        fontWeight = FontWeight.Bold,
                        fontSize = 16.sp
                    )
                }
            }
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            // Image picker row
            Text("Photos (up to 5)", style = Typography.labelLarge, color = FaithFeedColors.TextSecondary)
            LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                items(imageUris) { uri ->
                    Box(modifier = Modifier.size(80.dp)) {
                        AsyncImage(
                            model = uri,
                            contentDescription = null,
                            contentScale = ContentScale.Crop,
                            modifier = Modifier
                                .fillMaxSize()
                                .clip(RoundedCornerShape(8.dp))
                                .background(FaithFeedColors.GlassBackground)
                        )
                        IconButton(
                            onClick = { viewModel.removeImage(uri) },
                            modifier = Modifier
                                .size(20.dp)
                                .align(Alignment.TopEnd)
                                .clip(CircleShape)
                                .background(FaithFeedColors.BackgroundPrimary.copy(alpha = 0.8f))
                        ) {
                            Icon(
                                Icons.Default.Close,
                                contentDescription = "Remove",
                                tint = FaithFeedColors.TextPrimary,
                                modifier = Modifier.size(12.dp)
                            )
                        }
                    }
                }
                if (imageUris.size < 5) {
                    item {
                        Box(
                            modifier = Modifier
                                .size(80.dp)
                                .clip(RoundedCornerShape(8.dp))
                                .background(FaithFeedColors.GlassBackground)
                                .border(1.dp, FaithFeedColors.GlassBorder, RoundedCornerShape(8.dp))
                                .clickable {
                                    imagePicker.launch(
                                        PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)
                                    )
                                },
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                Icons.Outlined.AddPhotoAlternate,
                                contentDescription = "Add photo",
                                tint = FaithFeedColors.TextTertiary,
                                modifier = Modifier.size(28.dp)
                            )
                        }
                    }
                }
            }

            // Title
            ListingTextField(
                value = title,
                onValueChange = { viewModel.title.value = it },
                label = "Title *"
            )

            // Description
            ListingTextField(
                value = description,
                onValueChange = { viewModel.description.value = it },
                label = "Description",
                minLines = 3,
                maxLines = 6
            )

            // Item type selector
            Text("Type", style = Typography.labelLarge, color = FaithFeedColors.TextSecondary)
            val types = listOf("physical", "digital", "service", "donation")
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                types.forEach { type ->
                    FilterChip(
                        selected = itemType == type,
                        onClick = { viewModel.itemType.value = type },
                        label = {
                            Text(
                                type.replaceFirstChar { it.uppercase() },
                                fontSize = 12.sp,
                                fontFamily = Nunito
                            )
                        },
                        colors = FilterChipDefaults.filterChipColors(
                            selectedContainerColor = FaithFeedColors.GoldAccent,
                            selectedLabelColor = FaithFeedColors.BackgroundPrimary,
                            containerColor = FaithFeedColors.GlassBackground,
                            labelColor = FaithFeedColors.TextSecondary
                        )
                    )
                }
            }

            // Price (hide for donation)
            if (itemType != "donation") {
                ListingTextField(
                    value = price,
                    onValueChange = { viewModel.price.value = it },
                    label = "Price (USD) *",
                    keyboardType = KeyboardType.Decimal
                )
            }

            // Category
            ListingTextField(
                value = category,
                onValueChange = { viewModel.category.value = it },
                label = "Category (e.g. Books, Music, Jewelry)"
            )

            // Condition (physical only)
            if (itemType == "physical") {
                Text("Condition", style = Typography.labelLarge, color = FaithFeedColors.TextSecondary)
                val conditions = listOf("new", "like new", "good", "fair")
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    conditions.forEach { c ->
                        FilterChip(
                            selected = condition == c,
                            onClick = { viewModel.condition.value = c },
                            label = {
                                Text(
                                    c.replaceFirstChar { it.uppercase() },
                                    fontSize = 12.sp,
                                    fontFamily = Nunito
                                )
                            },
                            colors = FilterChipDefaults.filterChipColors(
                                selectedContainerColor = FaithFeedColors.GoldAccent,
                                selectedLabelColor = FaithFeedColors.BackgroundPrimary,
                                containerColor = FaithFeedColors.GlassBackground,
                                labelColor = FaithFeedColors.TextSecondary
                            )
                        )
                    }
                }
            }

            // Location
            ListingTextField(
                value = location,
                onValueChange = { viewModel.location.value = it },
                label = "Location (city, state)"
            )

            Spacer(Modifier.height(8.dp))
        }
    }
}

@Composable
private fun ListingTextField(
    value: String,
    onValueChange: (String) -> Unit,
    label: String,
    minLines: Int = 1,
    maxLines: Int = 1,
    keyboardType: KeyboardType = KeyboardType.Text
) {
    OutlinedTextField(
        value = value,
        onValueChange = onValueChange,
        label = { Text(label, color = FaithFeedColors.TextTertiary, fontSize = 13.sp) },
        modifier = Modifier.fillMaxWidth(),
        minLines = minLines,
        maxLines = maxLines,
        keyboardOptions = KeyboardOptions(keyboardType = keyboardType),
        colors = OutlinedTextFieldDefaults.colors(
            focusedBorderColor = FaithFeedColors.GoldAccent,
            unfocusedBorderColor = FaithFeedColors.GlassBorder,
            cursorColor = FaithFeedColors.GoldAccent,
            focusedTextColor = FaithFeedColors.TextPrimary,
            unfocusedTextColor = FaithFeedColors.TextPrimary,
            focusedContainerColor = FaithFeedColors.BackgroundSecondary,
            unfocusedContainerColor = FaithFeedColors.BackgroundSecondary,
            focusedLabelColor = FaithFeedColors.GoldAccent
        ),
        shape = RoundedCornerShape(10.dp),
        textStyle = Typography.bodyMedium.copy(fontFamily = Nunito)
    )
}
