import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../onboarding/welcome_intent_screen.dart';
import '../terms_of_use_screen.dart';
import 'dart:io' show Platform;

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  bool _acceptedTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate() && _acceptedTerms) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final authService = Provider.of<AuthService>(context, listen: false);
      final success = await authService.signUpWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _displayNameController.text.trim(),
      );

      if (success) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const WelcomeIntentScreen(),
            ),
          );
        }
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Failed to create account. Please try again.';
          _isLoading = false;
        });
      }
    } else if (!_acceptedTerms) {
      setState(() {
        _errorMessage = 'Please accept the Terms of Service and Privacy Policy.';
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.signInWithGoogle();

    if (success) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const WelcomeIntentScreen(),
          ),
        );
      }
    } else if (mounted) {
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

    if (success) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const WelcomeIntentScreen(),
          ),
        );
      }
    } else if (mounted) {
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

    if (success) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const WelcomeIntentScreen(),
          ),
        );
      }
    } else if (mounted) {
      setState(() {
        _errorMessage = 'Facebook sign in failed. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // AppBar now uses the theme automatically
      appBar: AppBar(
        // The back arrow will now use the theme's icon color
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // Title
              Text(
                'join faithfeed',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryTeal,
                    ) ??
                    const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryTeal,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Become part of our faith community',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 48),

              // Signup Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Display Name Field (uses theme styling)
                    TextFormField(
                      controller: _displayNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email Field (uses theme styling)
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || !value.contains('@') || !value.contains('.')) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password Field (uses theme styling)
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password Field (uses theme styling)
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                          tooltip: _obscureConfirmPassword ? 'Show password' : 'Hide password',
                        ),
                      ),
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Terms and Conditions Checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: _acceptedTerms,
                          onChanged: (value) {
                            setState(() {
                              _acceptedTerms = value ?? false;
                              if (_acceptedTerms) _errorMessage = '';
                            });
                          },
                          // Uses theme's primary color
                          activeColor: theme.colorScheme.primary,
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TermsOfUseScreen(),
                                ),
                              );
                            },
                            child: RichText(
                              text: TextSpan(
                                style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.onSurface),
                                children: [
                                  const TextSpan(text: 'I agree to the '),
                                  TextSpan(
                                    text: 'Terms of Service',
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Error Message
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          _errorMessage,
                          style: TextStyle(color: theme.colorScheme.error),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // Create Account Button (uses theme styling)
                    ElevatedButton(
                      onPressed: _isLoading ? null : _signUp,
                      child: _isLoading
                          ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.onPrimary,
                        ),
                      )
                          : const Text('Create Account'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

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
              const SizedBox(height: 24),

              // Already have account link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account? ",
                    style: theme.textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Sign In',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
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
