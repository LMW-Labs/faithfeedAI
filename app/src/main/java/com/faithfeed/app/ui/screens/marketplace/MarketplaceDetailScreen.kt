package com.faithfeed.app.ui.screens.marketplace

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.outlined.LocationOn
import androidx.compose.material.icons.outlined.Message
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material.icons.outlined.Storefront
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavController
import coil3.compose.AsyncImage
import com.faithfeed.app.navigation.Route
import com.faithfeed.app.ui.components.SimpleTopBar
import com.faithfeed.app.ui.theme.Cinzel
import com.faithfeed.app.ui.theme.FaithFeedColors
import com.faithfeed.app.ui.theme.Nunito
import com.faithfeed.app.ui.theme.Typography

@Composable
fun MarketplaceDetailScreen(
    itemId: String,
    navController: NavController,
    viewModel: MarketplaceDetailViewModel = hiltViewModel()
) {
    LaunchedEffect(itemId) { viewModel.load(itemId) }

    val item by viewModel.item.collectAsStateWithLifecycle()
    val isLoading by viewModel.isLoading.collectAsStateWithLifecycle()
    val currentUserId by viewModel.currentUserId.collectAsStateWithLifecycle()
    val chatResult by viewModel.chatResult.collectAsStateWithLifecycle()
    val isDeleted by viewModel.isDeleted.collectAsStateWithLifecycle()
    val error by viewModel.error.collectAsStateWithLifecycle()

    // Navigate to chat once created
    LaunchedEffect(chatResult) {
        chatResult?.let { (chatId, sellerName) ->
            viewModel.clearChatResult()
            navController.navigate(Route.Chat(chatId, sellerName))
        }
    }

    // Pop back if deleted
    LaunchedEffect(isDeleted) {
        if (isDeleted) navController.popBackStack()
    }

    var showDeleteConfirm by remember { mutableStateOf(false) }

    val snackbarHostState = remember { SnackbarHostState() }
    LaunchedEffect(error) {
        error?.let {
            snackbarHostState.showSnackbar(it)
            viewModel.clearError()
        }
    }

    Scaffold(
        containerColor = FaithFeedColors.BackgroundPrimary,
        snackbarHost = { SnackbarHost(snackbarHostState) },
        topBar = {
            SimpleTopBar(
                title = item?.title ?: "Item",
                onBack = { navController.popBackStack() }
            )
        }
    ) { padding ->
        if (isLoading) {
            Box(
                modifier = Modifier.fillMaxSize().padding(padding),
                contentAlignment = Alignment.Center
            ) { CircularProgressIndicator(color = FaithFeedColors.GoldAccent) }
            return@Scaffold
        }

        val i = item ?: return@Scaffold

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
        ) {
            // Image carousel
            if (i.mediaUrls.isNotEmpty()) {
                val pagerState = rememberPagerState { i.mediaUrls.size }
                Box {
                    HorizontalPager(state = pagerState) { page ->
                        AsyncImage(
                            model = i.mediaUrls[page],
                            contentDescription = null,
                            contentScale = ContentScale.Crop,
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(300.dp)
                                .background(FaithFeedColors.GlassBackground)
                        )
                    }
                    if (i.mediaUrls.size > 1) {
                        Row(
                            modifier = Modifier
                                .align(Alignment.BottomCenter)
                                .padding(bottom = 8.dp),
                            horizontalArrangement = Arrangement.spacedBy(4.dp)
                        ) {
                            repeat(i.mediaUrls.size) { index ->
                                Box(
                                    modifier = Modifier
                                        .size(6.dp)
                                        .clip(CircleShape)
                                        .background(
                                            if (index == pagerState.currentPage)
                                                FaithFeedColors.GoldAccent
                                            else
                                                FaithFeedColors.GlassBackground
                                        )
                                )
                            }
                        }
                    }
                }
            } else {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(200.dp)
                        .background(FaithFeedColors.GlassBackground),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        Icons.Outlined.Storefront,
                        contentDescription = null,
                        tint = FaithFeedColors.TextTertiary,
                        modifier = Modifier.size(64.dp)
                    )
                }
            }

            Column(modifier = Modifier.padding(16.dp)) {
                // Type badge + price row
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Surface(
                        color = FaithFeedColors.PurpleDark,
                        shape = RoundedCornerShape(20.dp)
                    ) {
                        Text(
                            text = i.itemType.replaceFirstChar { it.uppercase() },
                            modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp),
                            color = FaithFeedColors.GoldAccent,
                            fontSize = 11.sp,
                            fontFamily = Nunito
                        )
                    }
                    Text(
                        text = i.priceDisplay,
                        fontFamily = Cinzel,
                        fontWeight = FontWeight.Bold,
                        fontSize = 22.sp,
                        color = FaithFeedColors.GoldAccent
                    )
                }

                Spacer(Modifier.height(12.dp))

                // Title
                Text(
                    text = i.title,
                    style = Typography.headlineSmall,
                    color = FaithFeedColors.TextPrimary,
                    fontFamily = Cinzel,
                    fontWeight = FontWeight.SemiBold
                )

                // Condition & location
                Row(
                    modifier = Modifier.padding(top = 6.dp),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    if (i.condition.isNotBlank()) {
                        Text(
                            text = "Condition: ${i.condition.replaceFirstChar { it.uppercase() }}",
                            style = Typography.bodySmall,
                            color = FaithFeedColors.TextTertiary
                        )
                    }
                    if (i.location.isNotBlank()) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(
                                Icons.Outlined.LocationOn,
                                contentDescription = null,
                                tint = FaithFeedColors.TextTertiary,
                                modifier = Modifier.size(12.dp)
                            )
                            Text(
                                text = i.location,
                                style = Typography.bodySmall,
                                color = FaithFeedColors.TextTertiary
                            )
                        }
                    }
                }

                HorizontalDivider(
                    modifier = Modifier.padding(vertical = 12.dp),
                    color = FaithFeedColors.GlassBorder
                )

                // Description
                if (i.description.isNotBlank()) {
                    Text(
                        text = "Description",
                        style = Typography.labelLarge,
                        color = FaithFeedColors.TextSecondary,
                        fontFamily = Cinzel
                    )
                    Spacer(Modifier.height(6.dp))
                    Text(
                        text = i.description,
                        style = Typography.bodyMedium,
                        color = FaithFeedColors.TextPrimary,
                        fontFamily = Nunito
                    )
                    HorizontalDivider(
                        modifier = Modifier.padding(vertical = 12.dp),
                        color = FaithFeedColors.GlassBorder
                    )
                }

                // Seller row
                i.seller?.let { seller ->
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Box(
                            modifier = Modifier
                                .size(40.dp)
                                .clip(CircleShape)
                                .background(FaithFeedColors.PurpleDark),
                            contentAlignment = Alignment.Center
                        ) {
                            if (!seller.avatarUrl.isNullOrBlank()) {
                                AsyncImage(
                                    model = seller.avatarUrl,
                                    contentDescription = null,
                                    contentScale = ContentScale.Crop,
                                    modifier = Modifier.fillMaxSize().clip(CircleShape)
                                )
                            } else {
                                Icon(
                                    Icons.Outlined.Person,
                                    contentDescription = null,
                                    tint = FaithFeedColors.GoldAccent,
                                    modifier = Modifier.size(20.dp)
                                )
                            }
                        }
                        Spacer(Modifier.width(10.dp))
                        Column {
                            Text(
                                text = seller.displayName,
                                style = Typography.bodyMedium,
                                color = FaithFeedColors.TextPrimary,
                                fontWeight = FontWeight.SemiBold
                            )
                            Text(
                                text = "@${seller.username}",
                                style = Typography.bodySmall,
                                color = FaithFeedColors.TextTertiary
                            )
                        }
                    }
                    Spacer(Modifier.height(16.dp))
                }

                // Action buttons
                if (currentUserId != i.sellerId) {
                    Button(
                        onClick = viewModel::messageSellerClick,
                        modifier = Modifier.fillMaxWidth(),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = FaithFeedColors.GoldAccent,
                            contentColor = FaithFeedColors.BackgroundPrimary
                        ),
                        shape = RoundedCornerShape(12.dp)
                    ) {
                        Icon(Icons.Outlined.Message, contentDescription = null, modifier = Modifier.size(18.dp))
                        Spacer(Modifier.width(8.dp))
                        Text("Message Seller", fontFamily = Nunito, fontWeight = FontWeight.SemiBold)
                    }
                } else {
                    OutlinedButton(
                        onClick = { showDeleteConfirm = true },
                        modifier = Modifier.fillMaxWidth(),
                        colors = ButtonDefaults.outlinedButtonColors(contentColor = MaterialTheme.colorScheme.error),
                        border = androidx.compose.foundation.BorderStroke(1.dp, MaterialTheme.colorScheme.error),
                        shape = RoundedCornerShape(12.dp)
                    ) {
                        Icon(Icons.Default.Delete, contentDescription = null, modifier = Modifier.size(18.dp))
                        Spacer(Modifier.width(8.dp))
                        Text("Delete Listing", fontFamily = Nunito)
                    }
                }
            }
        }
    }

    if (showDeleteConfirm) {
        AlertDialog(
            onDismissRequest = { showDeleteConfirm = false },
            title = { Text("Delete listing?", color = FaithFeedColors.TextPrimary) },
            text = { Text("This cannot be undone.", color = FaithFeedColors.TextSecondary) },
            confirmButton = {
                TextButton(onClick = {
                    showDeleteConfirm = false
                    viewModel.deleteListing()
                }) { Text("Delete", color = MaterialTheme.colorScheme.error) }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteConfirm = false }) {
                    Text("Cancel", color = FaithFeedColors.GoldAccent)
                }
            },
            containerColor = FaithFeedColors.BackgroundSecondary
        )
    }
}
