package com.faithfeed.app.ui.screens.main

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.Image
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Surface
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import com.faithfeed.app.R
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavDestination
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.faithfeed.app.navigation.mainNavGraph
import com.faithfeed.app.navigation.Route
import com.faithfeed.app.ui.components.BottomNavBar
import com.faithfeed.app.ui.theme.FaithFeedColors

/** Routes that show the bottom navigation bar */
private val bottomNavRoutes = setOf(
    Route.Home::class,
    Route.BibleReader::class,
    Route.Explore::class,
    Route.Marketplace::class,
    Route.PrayerWall::class
)

@Composable
fun MainScreen(
    needsProfileSetup: Boolean = false,
    onLogout: () -> Unit,
    viewModel: MainViewModel = hiltViewModel()
) {
    val innerNavController = rememberNavController()

    LaunchedEffect(needsProfileSetup) {
        if (needsProfileSetup) {
            innerNavController.navigate(Route.EditProfile) {
                popUpTo(Route.Home) { inclusive = false }
            }
        }
    }

    val navBackStackEntry by innerNavController.currentBackStackEntryAsState()
    val currentDestination = navBackStackEntry?.destination

    val showBottomBar = remember(currentDestination) {
        bottomNavRoutes.any { routeClass ->
            currentDestination?.route?.contains(routeClass.simpleName ?: "") == true
        }
    }

    val currentRoute = remember(currentDestination) {
        resolveBottomNavRoute(currentDestination)
    }

    Scaffold(
        topBar = { /* No top bar */ },
        containerColor = FaithFeedColors.BackgroundPrimary,
        contentWindowInsets = WindowInsets(0),
        floatingActionButton = {
            if (showBottomBar) {
                Surface(
                    onClick = { innerNavController.navigate(Route.AIStudyPartner) },
                    modifier = Modifier.size(56.dp),
                    shape = CircleShape,
                    color = Color.Black,
                    shadowElevation = 6.dp,
                    tonalElevation = 0.dp
                ) {
                    Box(
                        contentAlignment = Alignment.Center,
                        modifier = Modifier.fillMaxSize()
                    ) {
                        Image(
                            painter = painterResource(R.drawable.negspace_omega),
                            contentDescription = "AI Study Partner",
                            modifier = Modifier.size(34.dp)
                        )
                    }
                }
            }
        },
        bottomBar = {
            if (showBottomBar) {
                BottomNavBar(
                    currentRoute = currentRoute,
                    onNavigate = { route ->
                        innerNavController.navigate(route) {
                            // Preserve back stack + tab state when switching tabs
                            popUpTo(Route.Home) { saveState = true }
                            launchSingleTop = true
                            restoreState = true
                        }
                    }
                )
            }
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(FaithFeedColors.BackgroundPrimary)
                .padding(paddingValues)
        ) {
            NavHost(
                navController = innerNavController,
                startDestination = Route.Home
            ) {
                mainNavGraph(
                    navController = innerNavController,
                    onLogout = onLogout
                )
            }
        }
    }
}

private fun resolveBottomNavRoute(destination: NavDestination?): Route {
    val route = destination?.route ?: return Route.Home
    return when {
        route.contains("BibleReader") -> Route.BibleReader
        route.contains("Explore") -> Route.Explore
        route.contains("Marketplace") -> Route.Marketplace
        route.contains("PrayerWall") -> Route.PrayerWall
        else -> Route.Home
    }
}
