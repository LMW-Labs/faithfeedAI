import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'dart:io' show Platform;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final authService = Provider.of<AuthService>(context, listen: false);
      final success = await authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!success && mounted) {
        setState(() {
          _errorMessage = 'Invalid email or password. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.signInWithGoogle();

    if (!success && mounted) {
      setState(() {
        _errorMessage = 'Google sign in failed. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.signInWithApple();

    if (!success && mounted) {
      setState(() {
        _errorMessage = 'Apple sign in failed. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithFacebook() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.signInWithFacebook();

    if (!success && mounted) {
      setState(() {
        _errorMessage = 'Facebook sign in failed. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with solid background
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.lightSurface,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // App Name
                Text(
                  'faithfeed',
                  style: theme.textTheme.headlineLarge?.copyWith(
                        fontSize: 44,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryTeal,
                      ) ??
                      const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryTeal,
                      ),
                ),
                const SizedBox(height: 8),

                // Tagline
                Text(
                  'Where scripture meets scroll',
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Login Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter your email';
                          if (!value.contains('@')) return 'Please enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() { _obscurePassword = !_obscurePassword; });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter your password';
                          if (value.length < 6) return 'Password must be at least 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Error Message Display
                      if (_errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            _errorMessage,
                            style: TextStyle(color: theme.colorScheme.error, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      // Sign In Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signIn,
                          child: _isLoading
                              ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.onPrimary),
                          )
                              : const Text('Sign In'),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // --- CORRECTED WIDGET ---
                      // Forgot Password
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                          );
                        },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(color: AppTheme.primaryTeal), // Style is now on the Text
                        ),
                      ),
                    ],
                  ),
                ), // End of Form

                const SizedBox(height: 32),

                // Or divider
                Row(
                  children: [
                    Expanded(child: Divider(color: theme.colorScheme.onSurface.withValues(alpha: 0.3))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: theme.colorScheme.onSurface.withValues(alpha: 0.3))),
                  ],
                ),
                const SizedBox(height: 24),

                // Social Login Buttons
                _buildSocialButton(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  icon: FaIcon(FontAwesomeIcons.google, size: 20),
                  label: 'Continue with Google',
                  backgroundColor: Colors.white,
                  textColor: Colors.black87,
                ),
                const SizedBox(height: 12),

                if (Platform.isIOS) ...[
                  _buildSocialButton(
                    onPressed: _isLoading ? null : _signInWithApple,
                    icon: FaIcon(FontAwesomeIcons.apple, size: 20, color: Colors.white),
                    label: 'Continue with Apple',
                    backgroundColor: Colors.black,
                    textColor: Colors.white,
                  ),
                  const SizedBox(height: 12),
                ],

                _buildSocialButton(
                  onPressed: _isLoading ? null : _signInWithFacebook,
                  icon: FaIcon(FontAwesomeIcons.facebook, size: 20, color: Colors.white),
                  label: 'Continue with Facebook',
                  backgroundColor: Color(0xFF1877F2),
                  textColor: Colors.white,
                ),

                const SizedBox(height: 32),

                // Sign Up Link
                Text("Don't have an account?", style: theme.textTheme.bodyMedium),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpScreen()));
                  },
                  child: const Text('Join Our Community'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required VoidCallback? onPressed,
    required Widget icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: BorderSide(color: backgroundColor == Colors.white ? Colors.grey.shade300 : backgroundColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
