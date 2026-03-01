package com.faithfeed.app.navigation

import kotlinx.serialization.Serializable

/**
 * Typed, serializable route definitions for Navigation Compose 2.8+.
 * Each leaf class is independently @Serializable — the sealed class is just namespacing.
 * Navigate with: navController.navigate(Route.Login)
 * Navigate with args: navController.navigate(Route.Profile("user-id"))
 */
sealed class Route {

    // ── Splash ─────────────────────────────────────────────────────────────
    @Serializable data object Splash : Route()

    // ── Auth ───────────────────────────────────────────────────────────────
    @Serializable data object Login : Route()
    @Serializable data object SignUp : Route()
    @Serializable data object ForgotPassword : Route()
    @Serializable data object PhoneLogin : Route()
    @Serializable data class VerifyOtp(val phone: String) : Route()

    // ── Main shell (hosts inner NavHost + BottomNavBar) ────────────────────
    @Serializable data class Main(val needsProfileSetup: Boolean = false) : Route()

    // ── Bottom tab roots ───────────────────────────────────────────────────
    @Serializable data object Home : Route()
    @Serializable data object BibleReader : Route()
    @Serializable data object Explore : Route()
    @Serializable data object Marketplace : Route()
    @Serializable data object PrayerWall : Route()

    // ── Posts ──────────────────────────────────────────────────────────────
    @Serializable data object CreatePost : Route()
    @Serializable data class PostDetail(val postId: String) : Route()

    // ── Stories ────────────────────────────────────────────────────────────
    @Serializable data class StoryViewer(val userId: String) : Route()
    @Serializable data object CreateStory : Route()

    // ── Bible / AI tools ───────────────────────────────────────────────────
    @Serializable data class BibleChapter(val book: String, val chapter: Int) : Route()
    @Serializable data class ConcordanceResults(val strongsTag: String) : Route()
    @Serializable data object SemanticSearch : Route()
    @Serializable data object AIStudyPartner : Route()
    @Serializable data object ChapterSummarizer : Route()
    @Serializable data object DevotionalGenerator : Route()
    @Serializable data object ThematicGuidance : Route()
    @Serializable data object TopicalStudies : Route()
    @Serializable data object CustomStudyPlan : Route()
    @Serializable data class VerseCommentary(val verseRef: String) : Route()
    @Serializable data class RelatedVerses(val verseRef: String) : Route()
    @Serializable data object SermonRecorder : Route()
    @Serializable data object AILibrary : Route()

    // ── Profile ────────────────────────────────────────────────────────────
    @Serializable data class MyProfile(val userId: String) : Route()
    @Serializable data class UserProfile(val userId: String) : Route()
    @Serializable data object EditProfile : Route()
    @Serializable data object ProfileSettings : Route()
    @Serializable data object AccountSettings : Route()

    // ── Friends ────────────────────────────────────────────────────────────
    @Serializable data object FriendsList : Route()

    // ── Chat ───────────────────────────────────────────────────────────────
    @Serializable data object ChatList : Route()
    @Serializable data class Chat(val conversationId: String, val otherUserName: String) : Route()

    // ── Notifications ──────────────────────────────────────────────────────
    @Serializable data object Notifications : Route()

    // ── Groups ─────────────────────────────────────────────────────────────
    @Serializable data object Groups : Route()
    @Serializable data class GroupDetail(val groupId: String) : Route()
    @Serializable data object CreateGroup : Route()

    // ── Notes ──────────────────────────────────────────────────────────────
    @Serializable data object Notes : Route()
    @Serializable data class NoteDetail(val noteId: String, val prefilledVerseRef: String = "") : Route()

    // ── Marketplace ────────────────────────────────────────────────────────
    @Serializable data class MarketplaceDetail(val itemId: String) : Route()
    @Serializable data object CreateListing : Route()
    @Serializable data class MarketplaceChat(val conversationId: String) : Route()

    // ── Games ──────────────────────────────────────────────────────────────
    @Serializable data object BibleTrivia : Route()
    @Serializable data object BibleConnections : Route()
    @Serializable data object TheWalk : Route()
    @Serializable data object Leaderboard : Route()

    // ── Business pages ─────────────────────────────────────────────────────
    @Serializable data class BusinessPage(val pageId: String) : Route()
    @Serializable data object CreateBusinessPage : Route()

    // ── Premium ────────────────────────────────────────────────────────────
    @Serializable data object Premium : Route()

    // ── Prayer ─────────────────────────────────────────────────────────────
    @Serializable data object CreatePrayer : Route()
}
