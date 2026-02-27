package com.faithfeed.app.navigation

import androidx.compose.runtime.Composable
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.toRoute
import com.faithfeed.app.ui.screens.auth.ForgotPasswordScreen
import com.faithfeed.app.ui.screens.auth.LoginScreen
import com.faithfeed.app.ui.screens.auth.SignUpScreen
import com.faithfeed.app.ui.screens.main.MainScreen
import com.faithfeed.app.ui.screens.splash.SplashScreen

/**
 * Root NavHost — manages the top-level app graph:
 *  Splash → Auth (Login / SignUp / ForgotPassword) → Main
 *
 * All in-app navigation (feed, bible, chat, profile, etc.) lives inside
 * MainScreen's inner NavHost (MainNavGraph.kt).
 */
@Composable
fun RootNavGraph(rootNavController: NavHostController) {
    NavHost(
        navController = rootNavController,
        startDestination = Route.Splash
    ) {
        // ── Splash ─────────────────────────────────────────────────────────
        composable<Route.Splash> {
            SplashScreen(
                onAuthFound = { needsProfileSetup ->
                    rootNavController.navigate(Route.Main(needsProfileSetup = needsProfileSetup)) {
                        popUpTo<Route.Splash> { inclusive = true }
                    }
                },
                onNoAuth = {
                    rootNavController.navigate(Route.Login) {
                        popUpTo<Route.Splash> { inclusive = true }
                    }
                }
            )
        }

        // ── Auth graph ─────────────────────────────────────────────────────
        composable<Route.Login> {
            LoginScreen(
                onLoginSuccess = { needsProfileSetup ->
                    rootNavController.navigate(Route.Main(needsProfileSetup = needsProfileSetup)) {
                        popUpTo<Route.Login> { inclusive = true }
                    }
                },
                onNavigateToSignUp = { rootNavController.navigate(Route.SignUp) },
                onNavigateToForgotPassword = { rootNavController.navigate(Route.ForgotPassword) }
            )
        }

        composable<Route.SignUp> {
            SignUpScreen(
                onSignUpSuccess = {
                    rootNavController.navigate(Route.Main(needsProfileSetup = true)) {
                        popUpTo<Route.Login> { inclusive = true }
                    }
                },
                onNavigateToLogin = { rootNavController.popBackStack() }
            )
        }

        composable<Route.ForgotPassword> {
            ForgotPasswordScreen(
                onBack = { rootNavController.popBackStack() }
            )
        }

        // ── Main shell ─────────────────────────────────────────────────────
        composable<Route.Main> { backStackEntry ->
            val args = backStackEntry.toRoute<Route.Main>()
            MainScreen(
                needsProfileSetup = args.needsProfileSetup,
                onLogout = {
                    rootNavController.navigate(Route.Login) {
                        popUpTo<Route.Main> { inclusive = true }
                    }
                }
            )
        }
    }
}
