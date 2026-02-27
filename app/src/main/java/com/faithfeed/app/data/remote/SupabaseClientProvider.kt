package com.faithfeed.app.data.remote

import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.auth.Auth
import io.github.jan.supabase.createSupabaseClient
import io.github.jan.supabase.postgrest.Postgrest
import io.github.jan.supabase.realtime.Realtime
import io.github.jan.supabase.serializer.KotlinXSerializer
import io.github.jan.supabase.storage.Storage
import kotlinx.serialization.json.Json

/**
 * Supabase singleton factory.
 *
 * Credentials are injected via Hilt from BuildConfig (set in local.properties):
 *   SUPABASE_URL=https://yourproject.supabase.co
 *   SUPABASE_ANON_KEY=your-anon-key
 *
 * Do NOT call this directly — use the Hilt-provided instance from AppModule.
 */
object SupabaseClientProvider {

    fun create(url: String, key: String): SupabaseClient = createSupabaseClient(
        supabaseUrl = url,
        supabaseKey = key
    ) {
        // Lenient JSON: ignores unknown DB columns, coerces bigint→String for Post.id etc.
        defaultSerializer = KotlinXSerializer(Json {
            ignoreUnknownKeys = true
            isLenient = true
            coerceInputValues = true
        })
        install(Auth)
        install(Postgrest)
        install(Realtime)
        install(Storage)
    }
}
