package com.faithfeed.app.ui.screens.marketplace

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material.icons.outlined.Storefront
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavController
import androidx.paging.LoadState
import androidx.paging.compose.collectAsLazyPagingItems
import coil3.compose.AsyncImage
import com.faithfeed.app.data.model.MarketplaceItem
import com.faithfeed.app.navigation.Route
import com.faithfeed.app.ui.components.EmptyState
import com.faithfeed.app.ui.components.FaithFeedTopBar
import com.faithfeed.app.ui.theme.FaithFeedColors
import com.faithfeed.app.ui.theme.Nunito
import com.faithfeed.app.ui.theme.Typography

private val ITEM_TYPES = listOf(null, "physical", "digital", "service", "donation")
private val ITEM_TYPE_LABELS = listOf("All", "Physical", "Digital", "Service", "Donation")

@Composable
fun MarketplaceScreen(
    navController: NavController,
    viewModel: MarketplaceViewModel = hiltViewModel()
) {
    val items = viewModel.items.collectAsLazyPagingItems()
    val category by viewModel.category.collectAsStateWithLifecycle()
    val searchQuery by viewModel.searchQuery.collectAsStateWithLifecycle()
    val currentUserId by viewModel.currentUserId.collectAsStateWithLifecycle()
    var showSearch by remember { mutableStateOf(false) }

    Scaffold(
        containerColor = FaithFeedColors.BackgroundPrimary,
        topBar = {
            FaithFeedTopBar(
                title = "Marketplace",
                onSearchClick = { showSearch = !showSearch },
                onNotificationsClick = { navController.navigate(Route.Notifications) },
                onProfileClick = {
                    if (currentUserId.isNotBlank()) navController.navigate(Route.MyProfile(currentUserId))
                },
                onCreatePost = { navController.navigate(Route.CreatePost) },
                onCreateStory = { navController.navigate(Route.CreateStory) },
                onCreateListing = { navController.navigate(Route.CreateListing) },
                onCreatePrayer = { navController.navigate(Route.CreatePrayer) }
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // Search bar (animated reveal)
            if (showSearch) {
                OutlinedTextField(
                    value = searchQuery,
                    onValueChange = viewModel::onSearchQueryChange,
                    placeholder = { Text("Search listings...", color = FaithFeedColors.TextTertiary, fontSize = 14.sp) },
                    leadingIcon = {
                        Icon(Icons.Outlined.Search, contentDescription = null, tint = FaithFeedColors.TextTertiary)
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 8.dp),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = FaithFeedColors.GoldAccent,
                        unfocusedBorderColor = FaithFeedColors.GlassBorder,
                        cursorColor = FaithFeedColors.GoldAccent,
                        focusedTextColor = FaithFeedColors.TextPrimary,
                        unfocusedTextColor = FaithFeedColors.TextPrimary,
                        focusedContainerColor = FaithFeedColors.BackgroundSecondary,
                        unfocusedContainerColor = FaithFeedColors.BackgroundSecondary
                    ),
                    shape = RoundedCornerShape(24.dp),
                    singleLine = true
                )
            }

            // Category chips
            LazyRow(
                contentPadding = PaddingValues(horizontal = 16.dp, vertical = 6.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(ITEM_TYPES.size) { index ->
                    FilterChip(
                        selected = category == ITEM_TYPES[index],
                        onClick = { viewModel.onCategoryChange(ITEM_TYPES[index]) },
                        label = {
                            Text(
                                ITEM_TYPE_LABELS[index],
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

            Box(modifier = Modifier.fillMaxSize()) {
                if (items.itemCount == 0 && items.loadState.refresh !is LoadState.Loading) {
                    EmptyState(
                        icon = Icons.Outlined.Storefront,
                        title = "No Listings",
                        subtitle = "Be the first to post a Christian good or service"
                    )
                } else {
                    LazyVerticalGrid(
                        columns = GridCells.Fixed(2),
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(16.dp),
                        horizontalArrangement = Arrangement.spacedBy(16.dp),
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        items(items.itemCount) { index ->
                            val item = items[index]
                            if (item != null) {
                                MarketplaceItemCard(
                                    item = item,
                                    onClick = { navController.navigate(Route.MarketplaceDetail(item.id)) }
                                )
                            }
                        }
                        if (items.loadState.append is LoadState.Loading ||
                            items.loadState.refresh is LoadState.Loading) {
                            item {
                                Box(
                                    modifier = Modifier.fillMaxWidth().padding(16.dp),
                                    contentAlignment = Alignment.Center
                                ) {
                                    CircularProgressIndicator(color = FaithFeedColors.GoldAccent)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun MarketplaceItemCard(item: MarketplaceItem, onClick: () -> Unit) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onClick() },
        colors = CardDefaults.cardColors(containerColor = FaithFeedColors.BackgroundSecondary),
        shape = RoundedCornerShape(12.dp)
    ) {
        Column {
            if (item.mediaUrls.isNotEmpty()) {
                AsyncImage(
                    model = item.mediaUrls.first(),
                    contentDescription = item.title,
                    contentScale = ContentScale.Crop,
                    modifier = Modifier
                        .fillMaxWidth()
                        .aspectRatio(1f)
                        .clip(RoundedCornerShape(topStart = 12.dp, topEnd = 12.dp))
                        .background(FaithFeedColors.GlassBackground)
                )
            } else {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .aspectRatio(1f)
                        .background(FaithFeedColors.GlassBackground),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        Icons.Outlined.Storefront,
                        contentDescription = null,
                        tint = FaithFeedColors.TextTertiary,
                        modifier = Modifier.size(48.dp)
                    )
                }
            }
            Column(modifier = Modifier.padding(12.dp)) {
                Text(
                    text = item.title,
                    style = Typography.titleSmall.copy(fontWeight = FontWeight.Bold),
                    color = FaithFeedColors.TextPrimary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = item.priceDisplay,
                    style = Typography.bodyMedium.copy(fontWeight = FontWeight.Bold),
                    color = FaithFeedColors.GoldAccent
                )
            }
        }
    }
}
