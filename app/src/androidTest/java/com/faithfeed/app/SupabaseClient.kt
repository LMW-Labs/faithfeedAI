package com.faithfeed.app

import io.github.jan.supabase.createSupabaseClient
import io.github.jan.supabase.auth.Auth
import io.github.jan.supabase.postgrest.Postgrest

val supabase = createSupabaseClient(
    supabaseUrl = "https://byrqbwsgwhljpagphwqy.supabase.co",
    supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ5cnFid3Nnd2hsanBhZ3Bod3F5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE4MTA1MTgsImV4cCI6MjA4NzM4NjUxOH0.9_XXH4zSFT-pOqkJO1u12X8tJMHRvoxK2z-MG-zrL_c"
) {
    install(Auth)
    install(Postgrest)
}