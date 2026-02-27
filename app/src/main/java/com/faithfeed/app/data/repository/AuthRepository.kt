package com.faithfeed.app.data.repository

import com.faithfeed.app.data.model.User
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.auth.providers.builtin.Email
import javax.inject.Inject

interface AuthRepository {
    suspend fun signInWithEmail(email: String, password: String): Result<User>
    suspend fun signUpWithEmail(email: String, password: String, displayName: String): Result<User>
    suspend fun signInWithGoogle(idToken: String): Result<User>
    suspend fun sendPasswordReset(email: String): Result<Unit>
    suspend fun signOut()
    suspend fun currentUser(): User?
    fun isLoggedIn(): Boolean
}

class AuthRepositoryImpl @Inject constructor(
    private val supabase: SupabaseClient
) : AuthRepository {

    override suspend fun signInWithEmail(email: String, password: String): Result<User> {
        return try {
            supabase.auth.signInWith(Email) {
                this.email = email
                this.password = password
            }
            val userId = supabase.auth.currentUserOrNull()?.id ?: return Result.failure(Exception("No user"))
            Result.success(User(id = userId, username = email))
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun signUpWithEmail(email: String, password: String, displayName: String): Result<User> {
        return try {
            supabase.auth.signUpWith(Email) {
                this.email = email
                this.password = password
            }
            val userId = supabase.auth.currentUserOrNull()?.id ?: return Result.failure(Exception("No user"))
            Result.success(User(id = userId, displayName = displayName, username = email))
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun signInWithGoogle(idToken: String): Result<User> {
        // TODO: Implement Google sign-in via Credential Manager + Supabase
        return Result.failure(NotImplementedError("Google sign-in coming soon"))
    }

    override suspend fun sendPasswordReset(email: String): Result<Unit> {
        return try {
            supabase.auth.resetPasswordForEmail(email)
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun signOut() {
        supabase.auth.signOut()
    }

    override suspend fun currentUser(): User? {
        val session = supabase.auth.currentUserOrNull() ?: return null
        return User(id = session.id, username = session.email ?: "")
    }

    override fun isLoggedIn(): Boolean =
        supabase.auth.currentSessionOrNull() != null
}
