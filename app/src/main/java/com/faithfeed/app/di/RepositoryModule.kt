package com.faithfeed.app.di

import com.faithfeed.app.data.repository.AILibraryRepository
import com.faithfeed.app.data.repository.AILibraryRepositoryImpl
import com.faithfeed.app.data.repository.ConcordanceRepository
import com.faithfeed.app.data.repository.ConcordanceRepositoryImpl
import com.faithfeed.app.data.repository.AIRepository
import com.faithfeed.app.data.repository.AIRepositoryImpl
import com.faithfeed.app.data.repository.AuthRepository
import com.faithfeed.app.data.repository.AuthRepositoryImpl
import com.faithfeed.app.data.repository.BibleRepository
import com.faithfeed.app.data.repository.BibleRepositoryImpl
import com.faithfeed.app.data.repository.BusinessPageRepository
import com.faithfeed.app.data.repository.BusinessPageRepositoryImpl
import com.faithfeed.app.data.repository.ChatRepository
import com.faithfeed.app.data.repository.ChatRepositoryImpl
import com.faithfeed.app.data.repository.GroupRepository
import com.faithfeed.app.data.repository.GroupRepositoryImpl
import com.faithfeed.app.data.repository.MarketplaceRepository
import com.faithfeed.app.data.repository.MarketplaceRepositoryImpl
import com.faithfeed.app.data.repository.NotificationRepository
import com.faithfeed.app.data.repository.NotificationRepositoryImpl
import com.faithfeed.app.data.repository.PostRepository
import com.faithfeed.app.data.repository.PostRepositoryImpl
import com.faithfeed.app.data.repository.PrayerRepository
import com.faithfeed.app.data.repository.PrayerRepositoryImpl
import com.faithfeed.app.data.repository.StoryRepository
import com.faithfeed.app.data.repository.StoryRepositoryImpl
import com.faithfeed.app.data.repository.UserRepository
import com.faithfeed.app.data.repository.UserRepositoryImpl
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
abstract class RepositoryModule {

    @Binds @Singleton
    abstract fun bindAuthRepository(impl: AuthRepositoryImpl): AuthRepository

    @Binds @Singleton
    abstract fun bindPostRepository(impl: PostRepositoryImpl): PostRepository

    @Binds @Singleton
    abstract fun bindStoryRepository(impl: StoryRepositoryImpl): StoryRepository

    @Binds @Singleton
    abstract fun bindPrayerRepository(impl: PrayerRepositoryImpl): PrayerRepository

    @Binds @Singleton
    abstract fun bindChatRepository(impl: ChatRepositoryImpl): ChatRepository

    @Binds @Singleton
    abstract fun bindBibleRepository(impl: BibleRepositoryImpl): BibleRepository

    @Binds @Singleton
    abstract fun bindAIRepository(impl: AIRepositoryImpl): AIRepository

    @Binds @Singleton
    abstract fun bindUserRepository(impl: UserRepositoryImpl): UserRepository

    @Binds @Singleton
    abstract fun bindMarketplaceRepository(impl: MarketplaceRepositoryImpl): MarketplaceRepository

    @Binds @Singleton
    abstract fun bindGroupRepository(impl: GroupRepositoryImpl): GroupRepository

    @Binds @Singleton
    abstract fun bindNotificationRepository(impl: NotificationRepositoryImpl): NotificationRepository

    @Binds @Singleton
    abstract fun bindBusinessPageRepository(impl: BusinessPageRepositoryImpl): BusinessPageRepository

    @Binds @Singleton
    abstract fun bindAILibraryRepository(impl: AILibraryRepositoryImpl): AILibraryRepository

    @Binds @Singleton
    abstract fun bindConcordanceRepository(impl: ConcordanceRepositoryImpl): ConcordanceRepository
}
