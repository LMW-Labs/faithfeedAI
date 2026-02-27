package com.faithfeed.app.ui.screens.friends

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.MoreVert
import androidx.compose.material.icons.outlined.People
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.ScrollableTabRow
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRowDefaults
import androidx.compose.material3.TabRowDefaults.tabIndicatorOffset
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import coil3.compose.AsyncImage
import com.faithfeed.app.data.model.User
import com.faithfeed.app.navigation.Route
import com.faithfeed.app.ui.components.ButtonStyle
import com.faithfeed.app.ui.components.EmptyState
import com.faithfeed.app.ui.components.SimpleTopBar
import com.faithfeed.app.ui.theme.FaithFeedColors
import com.faithfeed.app.ui.theme.FaithFeedGradients
import com.faithfeed.app.ui.theme.Nunito

@Composable
fun FriendsScreen(
    navController: NavController,
    viewModel: FriendsViewModel = hiltViewModel()
) {
    val requests    by viewModel.requests.collectAsState()
    val suggestions by viewModel.suggestions.collectAsState()
    val friends     by viewModel.friends.collectAsState()

    var selectedTab by rememberSaveable { mutableIntStateOf(0) }

    val tabs = listOf(
        "Requests (${requests.size})",
        "Suggestions",
        "Friends (${friends.size})"
    )

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(FaithFeedColors.BackgroundPrimary)
    ) {
        SimpleTopBar(title = "Friends", onBack = { navController.popBackStack() })

        ScrollableTabRow(
            selectedTabIndex = selectedTab,
            containerColor = FaithFeedColors.BackgroundPrimary,
            contentColor = FaithFeedColors.GoldAccent,
            edgePadding = 16.dp,
            indicator = { tabPositions ->
                TabRowDefaults.SecondaryIndicator(
                    modifier = Modifier.tabIndicatorOffset(tabPositions[selectedTab]),
                    color = FaithFeedColors.GoldAccent
                )
            },
            divider = {}
        ) {
            tabs.forEachIndexed { index, label ->
                Tab(
                    selected = selectedTab == index,
                    onClick = { selectedTab = index },
                    text = {
                        Text(
                            text = label,
                            fontFamily = Nunito,
                            fontSize = 14.sp,
                            fontWeight = if (selectedTab == index) FontWeight.SemiBold else FontWeight.Normal,
                            color = if (selectedTab == index) FaithFeedColors.GoldAccent
                            else FaithFeedColors.TextTertiary
                        )
                    }
                )
            }
        }

        Spacer(Modifier.height(4.dp))

        when (selectedTab) {
            0 -> FriendsTabContent(
                users = requests,
                emptyTitle = "No friend requests",
                emptySubtitle = "When someone sends you a request, it will appear here"
            ) { user ->
                RequestUserRow(
                    user = user,
                    onAccept = { viewModel.acceptRequest(user.id) },
                    onDecline = { viewModel.declineRequest(user.id) }
                )
            }

            1 -> FriendsTabContent(
                users = suggestions,
                emptyTitle = "No suggestions yet",
                emptySubtitle = "We'll suggest people you may know as your network grows"
            ) { user ->
                SuggestionUserRow(
                    user = user,
                    onAddFriend = { viewModel.sendRequest(user.id) }
                )
            }

            2 -> FriendsTabContent(
                users = friends,
                emptyTitle = "No friends yet",
                emptySubtitle = "Accept requests or add people from Suggestions"
            ) { user ->
                FriendUserRow(
                    user = user,
                    onMessage = { navController.navigate(Route.ChatList) },
                    onRemove = { viewModel.removeFriend(user.id) }
                )
            }
        }
    }
}

// ── Tab content shell ─────────────────────────────────────────────────────────

@Composable
private fun FriendsTabContent(
    users: List<User>,
    emptyTitle: String,
    emptySubtitle: String,
    rowContent: @Composable (User) -> Unit
) {
    if (users.isEmpty()) {
        Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            EmptyState(
                icon = Icons.Outlined.People,
                title = emptyTitle,
                subtitle = emptySubtitle
            )
        }
    } else {
        LazyColumn(modifier = Modifier.fillMaxSize()) {
            items(users, key = { it.id }) { user ->
                rowContent(user)
            }
        }
    }
}

// ── Row variants per tab ──────────────────────────────────────────────────────

@Composable
private fun RequestUserRow(user: User, onAccept: () -> Unit, onDecline: () -> Unit) {
    UserRowBase(user = user) {
        SmallButton(text = "Accept", onClick = onAccept, style = ButtonStyle.Primary)
        Spacer(Modifier.width(8.dp))
        SmallButton(text = "Decline", onClick = onDecline, style = ButtonStyle.Ghost)
    }
}

@Composable
private fun SuggestionUserRow(user: User, onAddFriend: () -> Unit) {
    UserRowBase(user = user) {
        SmallButton(text = "Add Friend", onClick = onAddFriend, style = ButtonStyle.Secondary)
    }
}

@Composable
private fun FriendUserRow(user: User, onMessage: () -> Unit, onRemove: () -> Unit) {
    var showMenu by remember { mutableStateOf(false) }
    UserRowBase(user = user) {
        SmallButton(text = "Message", onClick = onMessage, style = ButtonStyle.Ghost)
        Spacer(Modifier.width(4.dp))
        Box {
            Icon(
                imageVector = Icons.Outlined.MoreVert,
                contentDescription = "More options",
                tint = FaithFeedColors.TextTertiary,
                modifier = Modifier
                    .size(32.dp)
                    .clip(CircleShape)
                    .clickable(
                        onClick = { showMenu = true },
                        indication = null,
                        interactionSource = remember { MutableInteractionSource() }
                    )
                    .padding(4.dp)
            )
            DropdownMenu(
                expanded = showMenu,
                onDismissRequest = { showMenu = false },
                modifier = Modifier.background(FaithFeedColors.BackgroundSecondary)
            ) {
                DropdownMenuItem(
                    text = {
                        Text(
                            text = "Remove friend",
                            fontFamily = Nunito,
                            fontSize = 14.sp,
                            color = FaithFeedColors.TextPrimary
                        )
                    },
                    onClick = { showMenu = false; onRemove() }
                )
            }
        }
    }
}

// ── Shared composables ────────────────────────────────────────────────────────

/** Compact styled button used in friend list rows. */
@Composable
private fun SmallButton(text: String, onClick: () -> Unit, style: ButtonStyle) {
    val shape = RoundedCornerShape(10.dp)
    val mod = when (style) {
        ButtonStyle.Primary -> Modifier
            .clip(shape)
            .background(FaithFeedGradients.GoldAccent)
        ButtonStyle.Secondary -> Modifier
            .clip(shape)
            .background(FaithFeedColors.BackgroundSecondary)
            .border(1.dp, FaithFeedColors.GoldAccent, shape)
        ButtonStyle.Ghost -> Modifier
            .clip(shape)
    }
    Box(
        modifier = mod
            .clickable(onClick = onClick)
            .padding(horizontal = 12.dp, vertical = 7.dp),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = text,
            fontFamily = Nunito,
            fontSize = 13.sp,
            fontWeight = FontWeight.SemiBold,
            color = when (style) {
                ButtonStyle.Primary -> FaithFeedColors.BackgroundPrimary
                ButtonStyle.Secondary, ButtonStyle.Ghost -> FaithFeedColors.GoldHighlight
            }
        )
    }
}

/** Avatar + display name + username + trailing actions slot. */
@Composable
private fun UserRowBase(user: User, actions: @Composable () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .size(48.dp)
                .clip(CircleShape)
                .background(FaithFeedColors.PurpleDark)
                .border(1.dp, FaithFeedColors.GlassBorder, CircleShape),
            contentAlignment = Alignment.Center
        ) {
            if (!user.avatarUrl.isNullOrBlank()) {
                AsyncImage(
                    model = user.avatarUrl,
                    contentDescription = null,
                    modifier = Modifier.size(48.dp).clip(CircleShape),
                    contentScale = ContentScale.Crop
                )
            } else {
                Icon(
                    imageVector = Icons.Outlined.Person,
                    contentDescription = null,
                    tint = FaithFeedColors.GoldAccent.copy(alpha = 0.6f),
                    modifier = Modifier.size(24.dp)
                )
            }
        }

        Spacer(Modifier.width(12.dp))

        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = user.displayName.takeIf { it.isNotBlank() } ?: user.username,
                fontFamily = Nunito,
                fontSize = 15.sp,
                fontWeight = FontWeight.SemiBold,
                color = FaithFeedColors.TextPrimary,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            if (user.username.isNotBlank()) {
                Text(
                    text = "@${user.username}",
                    fontFamily = Nunito,
                    fontSize = 13.sp,
                    color = FaithFeedColors.TextTertiary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }
        }

        Spacer(Modifier.width(8.dp))

        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.End
        ) {
            actions()
        }
    }
}
