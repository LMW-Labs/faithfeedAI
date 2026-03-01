package com.faithfeed.app.navigation

import androidx.navigation.NavGraphBuilder
import androidx.navigation.NavHostController
import androidx.navigation.compose.composable
import androidx.navigation.toRoute
import com.faithfeed.app.ui.screens.bible.BibleReaderScreen
import com.faithfeed.app.ui.screens.bible.ConcordanceResultsScreen
import com.faithfeed.app.ui.screens.bible.SemanticSearchScreen
import com.faithfeed.app.ui.screens.business.BusinessPageScreen
import com.faithfeed.app.ui.screens.business.CreateBusinessPageScreen
import com.faithfeed.app.ui.screens.chat.ChatListScreen
import com.faithfeed.app.ui.screens.chat.ChatScreen
import com.faithfeed.app.ui.screens.explore.AILibraryScreen
import com.faithfeed.app.ui.screens.explore.AIStudyPartnerScreen
import com.faithfeed.app.ui.screens.explore.ChapterSummarizerScreen
import com.faithfeed.app.ui.screens.explore.CustomStudyPlanScreen
import com.faithfeed.app.ui.screens.explore.DevotionalGeneratorScreen
import com.faithfeed.app.ui.screens.explore.ExploreScreen
import com.faithfeed.app.ui.screens.explore.RelatedVersesScreen
import com.faithfeed.app.ui.screens.explore.ThematicGuidanceScreen
import com.faithfeed.app.ui.screens.explore.TopicalStudiesScreen
import com.faithfeed.app.ui.screens.explore.VerseCommentaryScreen
import com.faithfeed.app.ui.screens.friends.FriendsScreen
import com.faithfeed.app.ui.screens.games.BibleConnectionsScreen

import com.faithfeed.app.ui.screens.games.BibleTriviaScreen
import com.faithfeed.app.ui.screens.games.LeaderboardScreen
import com.faithfeed.app.ui.screens.games.TheWalkScreen
import com.faithfeed.app.ui.screens.groups.CreateGroupScreen
import com.faithfeed.app.ui.screens.groups.GroupDetailScreen
import com.faithfeed.app.ui.screens.groups.GroupsScreen
import com.faithfeed.app.ui.screens.home.HomeScreen
import com.faithfeed.app.ui.screens.marketplace.CreateListingScreen
import com.faithfeed.app.ui.screens.marketplace.MarketplaceChatScreen
import com.faithfeed.app.ui.screens.marketplace.MarketplaceDetailScreen
import com.faithfeed.app.ui.screens.marketplace.MarketplaceScreen
import com.faithfeed.app.ui.screens.notes.NoteDetailScreen
import com.faithfeed.app.ui.screens.notes.NotesScreen
import com.faithfeed.app.ui.screens.notifications.NotificationsScreen
import com.faithfeed.app.ui.screens.post.CreatePostScreen
import com.faithfeed.app.ui.screens.post.PostDetailScreen
import com.faithfeed.app.ui.screens.prayer.CreatePrayerScreen
import com.faithfeed.app.ui.screens.prayer.PrayerWallScreen
import com.faithfeed.app.ui.screens.premium.PremiumScreen
import com.faithfeed.app.ui.screens.settings.AccountSettingsScreen
import com.faithfeed.app.ui.screens.profile.EditProfileScreen
import com.faithfeed.app.ui.screens.profile.MyProfileScreen
import com.faithfeed.app.ui.screens.settings.ProfileSettingsScreen
import com.faithfeed.app.ui.screens.profile.UserProfileScreen
import com.faithfeed.app.ui.screens.stories.CreateStoryScreen
import com.faithfeed.app.ui.screens.stories.StoryViewerScreen

/**
 * Registers all in-app destinations into the inner NavHostController
 * that lives inside MainScreen's Scaffold.
 *
 * Organized by feature — bottom tabs first, then secondary screens.
 */
fun NavGraphBuilder.mainNavGraph(
    navController: NavHostController,
    onLogout: () -> Unit
) {
    // ── Bottom tab roots ───────────────────────────────────────────────────
    composable<Route.Home> {
        HomeScreen(navController = navController)
    }

    composable<Route.BibleReader> {
        BibleReaderScreen(navController = navController)
    }

    composable<Route.Explore> {
        ExploreScreen(navController = navController)
    }

    composable<Route.Marketplace> {
        MarketplaceScreen(navController = navController)
    }

    composable<Route.PrayerWall> {
        PrayerWallScreen(navController = navController)
    }

    // ── Posts ──────────────────────────────────────────────────────────────
    composable<Route.CreatePost> {
        CreatePostScreen(navController = navController)
    }

    composable<Route.PostDetail> { entry ->
        val route = entry.toRoute<Route.PostDetail>()
        PostDetailScreen(postId = route.postId, navController = navController)
    }

    // ── Stories ────────────────────────────────────────────────────────────
    composable<Route.StoryViewer> { entry ->
        val route = entry.toRoute<Route.StoryViewer>()
        StoryViewerScreen(userId = route.userId, navController = navController)
    }

    composable<Route.CreateStory> {
        CreateStoryScreen(navController = navController)
    }

    // ── Bible tools ────────────────────────────────────────────────────────
    composable<Route.BibleChapter> { entry ->
        val route = entry.toRoute<Route.BibleChapter>()
        BibleReaderScreen(
            navController = navController,
            initialBook = route.book,
            initialChapter = route.chapter
        )
    }

    composable<Route.ConcordanceResults> { entry ->
        val route = entry.toRoute<Route.ConcordanceResults>()
        ConcordanceResultsScreen(strongsTag = route.strongsTag, navController = navController)
    }

    composable<Route.SemanticSearch> {
        SemanticSearchScreen(navController = navController)
    }

    composable<Route.AIStudyPartner> {
        AIStudyPartnerScreen(navController = navController)
    }

    composable<Route.ChapterSummarizer> {
        ChapterSummarizerScreen(navController = navController)
    }

    composable<Route.DevotionalGenerator> {
        DevotionalGeneratorScreen(navController = navController)
    }

    composable<Route.ThematicGuidance> {
        ThematicGuidanceScreen(navController = navController)
    }

    composable<Route.TopicalStudies> {
        TopicalStudiesScreen(navController = navController)
    }

    composable<Route.CustomStudyPlan> {
        CustomStudyPlanScreen(navController = navController)
    }

    composable<Route.VerseCommentary> { entry ->
        val route = entry.toRoute<Route.VerseCommentary>()
        VerseCommentaryScreen(verseRef = route.verseRef, navController = navController)
    }

    composable<Route.RelatedVerses> { entry ->
        val route = entry.toRoute<Route.RelatedVerses>()
        RelatedVersesScreen(verseRef = route.verseRef, navController = navController)
    }

    composable<Route.AILibrary> {
        AILibraryScreen(navController = navController)
    }

    // ── Profile ────────────────────────────────────────────────────────────
    composable<Route.MyProfile> { entry ->
        val route = entry.toRoute<Route.MyProfile>()
        MyProfileScreen(userId = route.userId, navController = navController)
    }

    composable<Route.UserProfile> { entry ->
        val route = entry.toRoute<Route.UserProfile>()
        UserProfileScreen(userId = route.userId, navController = navController)
    }

    composable<Route.EditProfile> {
        EditProfileScreen(navController = navController)
    }

    composable<Route.ProfileSettings> {
        ProfileSettingsScreen(navController = navController)
    }

    composable<Route.AccountSettings> {
        AccountSettingsScreen(navController = navController, onLogout = onLogout)
    }

    // ── Friends ────────────────────────────────────────────────────────────
    composable<Route.FriendsList> {
        FriendsScreen(navController = navController)
    }

    // ── Chat ───────────────────────────────────────────────────────────────
    composable<Route.ChatList> {
        ChatListScreen(navController = navController)
    }

    composable<Route.Chat> { entry ->
        val route = entry.toRoute<Route.Chat>()
        ChatScreen(
            conversationId = route.conversationId,
            otherUserName = route.otherUserName,
            navController = navController
        )
    }

    // ── Notifications ──────────────────────────────────────────────────────
    composable<Route.Notifications> {
        NotificationsScreen(navController = navController)
    }

    // ── Groups ─────────────────────────────────────────────────────────────
    composable<Route.Groups> {
        GroupsScreen(navController = navController)
    }

    composable<Route.GroupDetail> { entry ->
        val route = entry.toRoute<Route.GroupDetail>()
        GroupDetailScreen(groupId = route.groupId, navController = navController)
    }

    composable<Route.CreateGroup> {
        CreateGroupScreen(navController = navController)
    }

    // ── Notes ──────────────────────────────────────────────────────────────
    composable<Route.Notes> {
        NotesScreen(navController = navController)
    }

    composable<Route.NoteDetail> { entry ->
        val route = entry.toRoute<Route.NoteDetail>()
        NoteDetailScreen(noteId = route.noteId, prefilledVerseRef = route.prefilledVerseRef, navController = navController)
    }

    // ── Marketplace detail / create / chat ─────────────────────────────────
    composable<Route.MarketplaceDetail> { entry ->
        val route = entry.toRoute<Route.MarketplaceDetail>()
        MarketplaceDetailScreen(itemId = route.itemId, navController = navController)
    }

    composable<Route.CreateListing> {
        CreateListingScreen(navController = navController)
    }

    composable<Route.MarketplaceChat> { entry ->
        val route = entry.toRoute<Route.MarketplaceChat>()
        MarketplaceChatScreen(conversationId = route.conversationId, navController = navController)
    }

    // ── Games ──────────────────────────────────────────────────────────────
    composable<Route.BibleTrivia> {
        BibleTriviaScreen(navController = navController)
    }

    composable<Route.BibleConnections> {
        BibleConnectionsScreen(navController = navController)
    }

    composable<Route.TheWalk> {
        TheWalkScreen(navController = navController)
    }

    composable<Route.Leaderboard> {
        LeaderboardScreen(navController = navController)
    }

    // ── Business pages ─────────────────────────────────────────────────────
    composable<Route.BusinessPage> { entry ->
        val route = entry.toRoute<Route.BusinessPage>()
        BusinessPageScreen(pageId = route.pageId, navController = navController)
    }

    composable<Route.CreateBusinessPage> {
        CreateBusinessPageScreen(navController = navController)
    }

    // ── Premium ────────────────────────────────────────────────────────────
    composable<Route.Premium> {
        PremiumScreen(navController = navController)
    }

    // ── Prayer sub-screen ──────────────────────────────────────────────────
    composable<Route.CreatePrayer> {
        CreatePrayerScreen(navController = navController)
    }
}
