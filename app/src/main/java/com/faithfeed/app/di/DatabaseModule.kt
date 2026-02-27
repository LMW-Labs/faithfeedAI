package com.faithfeed.app.di

import android.content.Context
import androidx.room.Room
import com.faithfeed.app.data.local.FaithFeedDatabase
import com.faithfeed.app.data.local.dao.BibleVerseDao
import com.faithfeed.app.data.local.dao.DraftPostDao
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {

    @Provides
    @Singleton
    fun provideDatabase(@ApplicationContext context: Context): FaithFeedDatabase =
        Room.databaseBuilder(
            context,
            FaithFeedDatabase::class.java,
            "faithfeed.db"
        ).build()

    @Provides
    fun provideBibleVerseDao(db: FaithFeedDatabase): BibleVerseDao = db.bibleVerseDao()

    @Provides
    fun provideDraftPostDao(db: FaithFeedDatabase): DraftPostDao = db.draftPostDao()
}
