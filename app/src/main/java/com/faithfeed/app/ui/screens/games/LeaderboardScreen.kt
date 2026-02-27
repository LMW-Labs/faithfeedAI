package com.faithfeed.app.ui.screens.games

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.EmojiEvents
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import androidx.navigation.NavController
import coil3.compose.AsyncImage
import com.faithfeed.app.data.model.User
import com.faithfeed.app.ui.components.SimpleTopBar
import com.faithfeed.app.ui.theme.Cinzel
import com.faithfeed.app.ui.theme.FaithFeedColors
import com.faithfeed.app.ui.theme.Nunito
import com.faithfeed.app.ui.theme.Typography
import dagger.hilt.android.lifecycle.HiltViewModel
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.query.Columns
import io.github.jan.supabase.postgrest.query.Order
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class LeaderboardViewModel @Inject constructor(
    private val supabase: SupabaseClient
) : ViewModel() {

    private val _leaders = MutableStateFlow<List<User>>(emptyList())
    val leaders: StateFlow<List<User>> = _leaders.asStateFlow()

    private val _isLoading = MutableStateFlow(true)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    init {
        load()
    }

    private fun load() {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                val users = supabase.from("profiles")
                    .select(Columns.raw("id,full_name,username,avatar_url,lfs_total_score,is_verified")) {
                        order("lfs_total_score", Order.DESCENDING)
                        limit(50)
                    }.decodeList<User>()
                _leaders.value = users
            } catch (_: Exception) {}
            _isLoading.value = false
        }
    }
}

@Composable
fun LeaderboardScreen(
    navController: NavController,
    viewModel: LeaderboardViewModel = hiltViewModel()
) {
    val leaders by viewModel.leaders.collectAsStateWithLifecycle()
    val isLoading by viewModel.isLoading.collectAsStateWithLifecycle()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(FaithFeedColors.BackgroundPrimary)
    ) {
        SimpleTopBar(title = "Leaderboard", onBack = { navController.popBackStack() })

        if (isLoading) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                CircularProgressIndicator(color = FaithFeedColors.GoldAccent)
            }
            return@Column
        }

        // Top 3 podium
        if (leaders.size >= 3) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                horizontalArrangement = Arrangement.SpaceEvenly,
                verticalAlignment = Alignment.Bottom
            ) {
                // 2nd
                PodiumEntry(user = leaders[1], rank = 2, height = 80.dp)
                // 1st
                PodiumEntry(user = leaders[0], rank = 1, height = 110.dp)
                // 3rd
                PodiumEntry(user = leaders[2], rank = 3, height = 60.dp)
            }
            HorizontalDivider(
                modifier = Modifier.padding(horizontal = 16.dp),
                color = FaithFeedColors.GlassBorder
            )
        }

        LazyColumn(
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            itemsIndexed(leaders) { index, user ->
                LeaderRow(rank = index + 1, user = user)
            }
        }
    }
}

@Composable
private fun PodiumEntry(user: User, rank: Int, height: Dp) {
    val gold = listOf(FaithFeedColors.GoldAccent, FaithFeedColors.GoldAccent.copy(alpha = 0.7f), FaithFeedColors.GoldAccent.copy(alpha = 0.4f))
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Box(
            modifier = Modifier.size(52.dp).clip(CircleShape)
                .background(FaithFeedColors.PurpleDark),
            contentAlignment = Alignment.Center
        ) {
            if (!user.avatarUrl.isNullOrBlank()) {
                AsyncImage(
                    model = user.avatarUrl,
                    contentDescription = null,
                    contentScale = ContentScale.Crop,
                    modifier = Modifier.fillMaxSize().clip(CircleShape)
                )
            } else {
                Icon(Icons.Outlined.Person, contentDescription = null, tint = FaithFeedColors.GoldAccent, modifier = Modifier.size(24.dp))
            }
        }
        Spacer(Modifier.height(4.dp))
        Text(user.username.take(10), style = Typography.labelSmall, color = FaithFeedColors.TextSecondary)
        Spacer(Modifier.height(4.dp))
        Box(
            modifier = Modifier.width(70.dp).height(height)
                .clip(RoundedCornerShape(topStart = 8.dp, topEnd = 8.dp))
                .background(gold[rank - 1]),
            contentAlignment = Alignment.TopCenter
        ) {
            Text(
                text = rank.toString(),
                fontFamily = Cinzel,
                fontWeight = FontWeight.Bold,
                fontSize = 20.sp,
                color = FaithFeedColors.BackgroundPrimary,
                modifier = Modifier.padding(top = 8.dp)
            )
        }
    }
}

@Composable
private fun LeaderRow(rank: Int, user: User) {
    Surface(
        color = if (rank <= 3) FaithFeedColors.GoldAccent.copy(alpha = 0.07f)
        else FaithFeedColors.BackgroundSecondary,
        shape = RoundedCornerShape(10.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "$rank",
                fontFamily = Cinzel,
                fontWeight = FontWeight.Bold,
                fontSize = 14.sp,
                color = if (rank <= 3) FaithFeedColors.GoldAccent else FaithFeedColors.TextTertiary,
                modifier = Modifier.width(28.dp)
            )
            Box(
                modifier = Modifier.size(38.dp).clip(CircleShape).background(FaithFeedColors.PurpleDark),
                contentAlignment = Alignment.Center
            ) {
                if (!user.avatarUrl.isNullOrBlank()) {
                    AsyncImage(
                        model = user.avatarUrl,
                        contentDescription = null,
                        contentScale = ContentScale.Crop,
                        modifier = Modifier.fillMaxSize().clip(CircleShape)
                    )
                } else {
                    Icon(Icons.Outlined.Person, contentDescription = null, tint = FaithFeedColors.GoldAccent, modifier = Modifier.size(18.dp))
                }
            }
            Spacer(Modifier.width(10.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = user.displayName.ifBlank { user.username },
                    style = Typography.bodyMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = FaithFeedColors.TextPrimary
                )
                Text(
                    text = "@${user.username}",
                    style = Typography.bodySmall,
                    color = FaithFeedColors.TextTertiary
                )
            }
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    Icons.Outlined.EmojiEvents,
                    contentDescription = null,
                    tint = FaithFeedColors.GoldAccent,
                    modifier = Modifier.size(16.dp)
                )
                Spacer(Modifier.width(4.dp))
                Text(
                    text = "${user.lfsTotalScore.toLong()}",
                    fontFamily = Nunito,
                    fontWeight = FontWeight.Bold,
                    color = FaithFeedColors.GoldAccent,
                    fontSize = 13.sp
                )
            }
        }
    }
}
