package com.faithfeed.app.data.repository

import android.net.Uri
import com.faithfeed.app.data.model.User
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.auth.OtpType
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.auth.providers.Facebook
import io.github.jan.supabase.auth.providers.Google
import io.github.jan.supabase.auth.providers.builtin.Email
import io.github.jan.supabase.auth.providers.builtin.IDToken
import io.github.jan.supabase.auth.providers.builtin.OTP
import javax.inject.Inject

interface AuthRepository {
    suspend fun signInWithEmail(email: String, password: String): Result<User>
    suspend fun signUpWithEmail(email: String, password: String, displayName: String): Result<User>
    suspend fun signInWithGoogle(idToken: String): Result<User>
    suspend fun sendPhoneOtp(phone: String): Result<Unit>
    suspend fun verifyPhoneOtp(phone: String, token: String): Result<User>
    suspend fun sendPasswordReset(email: String): Result<Unit>
    suspend fun signOut()
    suspend fun currentUser(): User?
    fun isLoggedIn(): Boolean
    fun getFacebookSignInUrl(): String
    suspend fun handleOAuthCallback(uri: String): Result<User>
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

    override suspend fun signInWithGoogle(idToken: String): Result<User> = try {
        supabase.auth.signInWith(IDToken) {
            this.idToken = idToken
            provider = Google
        }
        val userId = supabase.auth.currentUserOrNull()?.id ?: return Result.failure(Exception("No user"))
        Result.success(User(id = userId, username = ""))
    } catch (e: Exception) {
        Result.failure(e)
    }

    override suspend fun sendPhoneOtp(phone: String): Result<Unit> = try {
        supabase.auth.signInWith(OTP) { this.phone = phone }
        Result.success(Unit)
    } catch (e: Exception) {
        Result.failure(e)
    }

    override suspend fun verifyPhoneOtp(phone: String, token: String): Result<User> = try {
        supabase.auth.verifyPhoneOtp(type = OtpType.Phone.SMS, phone = phone, token = token)
        val userId = supabase.auth.currentUserOrNull()?.id ?: return Result.failure(Exception("No user"))
        Result.success(User(id = userId, username = phone))
    } catch (e: Exception) {
        Result.failure(e)
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

    /** Returns the Supabase OAuth URL to open in a browser for Facebook sign-in (PKCE flow). */
    override fun getFacebookSignInUrl(): String {
        val base = supabase.auth.getOAuthUrl(Facebook, "faithfeed://login-callback") { }
        // supabase-kt does not embed the apikey in browser-opened URLs; append it manually
        // so Supabase's /auth/v1/authorize doesn't reject the request with "api key not found"
        return if ("apikey=" in base) base else "$base&apikey=${supabase.supabaseKey}"
    }

    /**
     * Exchanges the OAuth authorization code in [uri] for a session (PKCE flow).
     * Called after the Chrome Custom Tab redirects back to faithfeed://login-callback?code=...
     */
    override suspend fun handleOAuthCallback(uri: String): Result<User> = try {
        val code = Uri.parse(uri).getQueryParameter("code")
            ?: return Result.failure(Exception("Invalid OAuth callback: missing code"))
        val session = supabase.auth.exchangeCodeForSession(code, true)
        val userId = session.user?.id ?: supabase.auth.currentUserOrNull()?.id
            ?: return Result.failure(Exception("No user in session"))
        Result.success(User(id = userId, username = session.user?.email ?: ""))
    } catch (e: Exception) {
        Result.failure(e)
    }
}
