package com.faithfeed.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoStories
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Storefront
import androidx.compose.material.icons.outlined.AutoStories
import androidx.compose.material.icons.outlined.Explore
import androidx.compose.material.icons.outlined.Home
import androidx.compose.material.icons.outlined.Storefront
import androidx.compose.material.icons.outlined.VolunteerActivism
import androidx.compose.material.icons.filled.Explore
import androidx.compose.material.icons.filled.VolunteerActivism
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.faithfeed.app.navigation.Route
import com.faithfeed.app.ui.theme.FaithFeedColors
import com.faithfeed.app.ui.theme.FaithFeedGradients
import com.faithfeed.app.ui.theme.Nunito

private data class NavItem(
    val route: Route,
    val label: String,
    val selectedIcon: ImageVector,
    val unselectedIcon: ImageVector
)

private val navItems = listOf(
    NavItem(Route.Home, "Home", Icons.Filled.Home, Icons.Outlined.Home),
    NavItem(Route.BibleReader, "Bible", Icons.Filled.AutoStories, Icons.Outlined.AutoStories),
    NavItem(Route.Explore, "Explore", Icons.Filled.Explore, Icons.Outlined.Explore),
    NavItem(Route.Marketplace, "Market", Icons.Filled.Storefront, Icons.Outlined.Storefront),
    NavItem(Route.PrayerWall, "Prayer", Icons.Filled.VolunteerActivism, Icons.Outlined.VolunteerActivism)
)

@Composable
fun BottomNavBar(
    currentRoute: Route,
    onNavigate: (Route) -> Unit,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .background(FaithFeedColors.BackgroundPrimary)
            .border(
                width = 1.dp,
                color = FaithFeedColors.GlassBorder,
                shape = RoundedCornerShape(topStart = 20.dp, topEnd = 20.dp)
            )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .navigationBarsPadding()
                .height(64.dp)
                .padding(horizontal = 8.dp),
            horizontalArrangement = Arrangement.SpaceEvenly,
            verticalAlignment = Alignment.CenterVertically
        ) {
            navItems.forEach { item ->
                val isSelected = currentRoute::class == item.route::class
                NavTab(
                    item = item,
                    isSelected = isSelected,
                    onClick = { onNavigate(item.route) }
                )
            }
        }
    }
}

@Composable
private fun NavTab(
    item: NavItem,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    Column(
        modifier = Modifier
            .clip(RoundedCornerShape(12.dp))
            .clickable(onClick = onClick)
            .padding(horizontal = 12.dp, vertical = 8.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(2.dp)
    ) {
        Box(contentAlignment = Alignment.Center) {
            if (isSelected) {
                Box(
                    modifier = Modifier
                        .size(36.dp)
                        .clip(CircleShape)
                        .background(FaithFeedColors.GoldAccent.copy(alpha = 0.15f))
                )
            }
            Icon(
                imageVector = if (isSelected) item.selectedIcon else item.unselectedIcon,
                contentDescription = item.label,
                modifier = Modifier.size(22.dp),
                tint = if (isSelected) FaithFeedColors.GoldAccent else FaithFeedColors.TextTertiary
            )
        }
        Text(
            text = item.label,
            fontFamily = Nunito,
            fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal,
            fontSize = 10.sp,
            color = if (isSelected) FaithFeedColors.GoldAccent else FaithFeedColors.TextTertiary
        )
    }
}
