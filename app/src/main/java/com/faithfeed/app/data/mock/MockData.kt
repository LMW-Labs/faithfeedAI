package com.faithfeed.app.data.mock

import com.faithfeed.app.data.model.Group
import com.faithfeed.app.data.model.MarketplaceItem
import com.faithfeed.app.data.model.Post
import com.faithfeed.app.data.model.PrayerRequest
import com.faithfeed.app.data.model.Story
import com.faithfeed.app.data.model.User
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

object MockData {

    private fun now(): String = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US).format(Date())

    val users = listOf(
        User(id = "user1", username = "johndoe", displayName = "John Doe", avatarUrl = "https://i.pravatar.cc/150?u=user1", bio = "Follower of Christ.", followerCount = 120, followingCount = 45, postCount = 10, createdAt = now()),
        User(id = "user2", username = "sarahsmith", displayName = "Sarah Smith", avatarUrl = "https://i.pravatar.cc/150?u=user2", bio = "Saved by grace.", followerCount = 300, followingCount = 150, postCount = 25, createdAt = now()),
        User(id = "user3", username = "pastormike", displayName = "Pastor Mike", avatarUrl = "https://i.pravatar.cc/150?u=user3", bio = "Leading with faith and love.", followerCount = 1500, followingCount = 300, postCount = 120, isVerified = true, createdAt = now())
    )

    val posts = listOf(
        Post(
            id = "post1",
            userId = "user1",
            content = "Just finished my morning devotional. Feeling so blessed today!",
            verseRef = "Psalms 118:24",
            verseText = "This is the day the Lord has made; we will rejoice and be glad in it.",
            likeCount = 24,
            commentCount = 5,
            prayerCount = 12,
            createdAt = now(),
            author = users[0]
        ),
        Post(
            id = "post2",
            userId = "user3",
            content = "Join us this Sunday as we explore the book of Romans. God is doing amazing things in our community.",
            mediaUrls = listOf("https://images.unsplash.com/photo-1438232992991-995b7058bbb3?w=800"),
            likeCount = 156,
            commentCount = 23,
            shareCount = 45,
            createdAt = now(),
            author = users[2]
        ),
        Post(
            id = "post3",
            userId = "user2",
            content = "In need of prayer today. Going through a tough season.",
            likeCount = 8,
            commentCount = 14,
            prayerCount = 45,
            createdAt = now(),
            author = users[1]
        )
    )

    val stories = listOf(
        Story(
            id = "story1",
            userId = "user2",
            mediaUrl = "https://images.unsplash.com/photo-1504052434569-70ad5836ab65?w=400",
            caption = "Morning worship 🙏",
            expiresAt = now(),
            createdAt = now(),
            author = users[1]
        ),
        Story(
            id = "story2",
            userId = "user3",
            mediaUrl = "https://images.unsplash.com/photo-1437603568260-1950d3ca6eab?w=400",
            caption = "Preparing for Sunday!",
            expiresAt = now(),
            createdAt = now(),
            author = users[2]
        )
    )

    val prayers = listOf(
        PrayerRequest(
            id = "prayer1",
            userId = "user2",
            title = "Family member in hospital",
            content = "Please pray for my grandmother who was just admitted to the ICU.",
            prayerCount = 84,
            createdAt = now(),
            author = users[1]
        ),
        PrayerRequest(
            id = "prayer2",
            userId = "user1",
            title = "Job interview tomorrow",
            content = "I have a very important interview. Praying for peace and clarity.",
            prayerCount = 32,
            createdAt = now(),
            author = users[0]
        )
    )

    val marketplaceItems = listOf(
        MarketplaceItem(
            id = "item1",
            sellerId = "user1",
            title = "Study Bible - ESV",
            description = "Lightly used ESV Study Bible. Great for group study.",
            price = 25.0,
            mediaUrls = listOf("https://images.unsplash.com/photo-1507692049790-de58290a4334?w=600"),
            condition = "good",
            createdAt = now(),
            seller = users[0]
        ),
        MarketplaceItem(
            id = "item2",
            sellerId = "user3",
            title = "Youth Ministry Resources",
            description = "A collection of youth ministry games and lessons.",
            itemType = "donation",
            createdAt = now(),
            seller = users[2]
        )
    )

    val groups = listOf(
        Group(
            id = "group1",
            name = "Young Adults Fellowship",
            description = "A place for young adults to connect and grow together.",
            memberCount = 145,
            createdBy = "user3",
            createdAt = now()
        ),
        Group(
            id = "group2",
            name = "Women's Bible Study",
            description = "Weekly study group focusing on the women of the Bible.",
            memberCount = 42,
            createdBy = "user2",
            createdAt = now()
        )
    )

    val bibleVerses = listOf(
        com.faithfeed.app.data.model.BibleVerse(id = 1, book = "Genesis", chapter = 1, verse = 1, text = "In the beginning God created the heavens and the earth."),
        com.faithfeed.app.data.model.BibleVerse(id = 2, book = "Genesis", chapter = 1, verse = 2, text = "And the earth was waste and void; and darkness was upon the face of the deep: and the Spirit of God moved upon the face of the waters."),
        com.faithfeed.app.data.model.BibleVerse(id = 3, book = "Genesis", chapter = 1, verse = 3, text = "And God said, Let there be light: and there was light."),
        com.faithfeed.app.data.model.BibleVerse(id = 4, book = "John", chapter = 3, verse = 16, text = "For God so loved the world, that he gave his only begotten Son, that whosoever believeth on him should not perish, but have eternal life.")
    )
}