import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/theme/pulse_colors.dart';
import '../../../home/presentation/screens/home_screen.dart';
import 'onboarding_screen.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? '254427635301-o7l406affi0gq1j3ae9k63duq0mna3k3.apps.googleusercontent.com' : null,
    serverClientId: kIsWeb ? null : '254427635301-o7l406affi0gq1j3ae9k63duq0mna3k3.apps.googleusercontent.com',
    scopes: ['email'],
  );
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Creating account for ${_nameController.text}...'),
          backgroundColor: PulseColors.primary,
        ),
      );
    }
  }

  Future<void> _handleGoogleSignUp() async {
    setState(() => _isLoading = true);
    try {
      final googleAccount = await _googleSignIn.signIn();
      if (googleAccount == null) {
        // User cancelled the sign in flow
        setState(() => _isLoading = false);
        return;
      }

      final email = googleAccount.email;
      final name = googleAccount.displayName ?? email.split('@')[0];

      final result = await _authService.googleAuthenticate(
        email: email,
        name: name,
      );

      if (!mounted) return;

      final userData = result['data']['user'];
      final user = UserModel.fromJson(userData);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => user.isOnboarded
              ? HomeScreen(user: user)
              : OnboardingScreen(user: user),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google Sign-In failed: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleAppleSignUp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Apple Sign-Up tapped (Frontend Mock)'),
        backgroundColor: PulseColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimaryColor = PulseColors.getTextPrimary(isDark);
    final textSecondaryColor = PulseColors.getTextSecondary(isDark);
    final surfaceColor = PulseColors.getSurface(isDark);
    final borderTileColor = PulseColors.getBorder(isDark);
    final accentLinkColor = isDark ? PulseColors.secondary : PulseColors.primary;

    return Scaffold(
      backgroundColor: PulseColors.getBackground(isDark),
      appBar: AppBar(
        backgroundColor: PulseColors.getBackground(isDark),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimaryColor),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    'Create Account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Join Rally to track and verify your matches',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ---------------- Social Auth Buttons ----------------
                  // Google Sign-Up Button
                  OutlinedButton.icon(
                    onPressed: _handleGoogleSignUp,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: borderTileColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: surfaceColor,
                    ),
                    icon: Icon(
                      Icons.g_mobiledata_rounded,
                      size: 28,
                      color: accentLinkColor,
                    ),
                    label: Text(
                      'Sign up with Google',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textPrimaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Apple Sign-Up Button
                  OutlinedButton.icon(
                    onPressed: _handleAppleSignUp,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: borderTileColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: surfaceColor,
                    ),
                    icon: Icon(
                      Icons.apple,
                      size: 24,
                      color: textPrimaryColor,
                    ),
                    label: Text(
                      'Sign up with Apple',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textPrimaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Divider with "OR" text
                  Row(
                    children: [
                      Expanded(child: Divider(color: borderTileColor)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Text(
                          'OR EMAIL',
                          style: TextStyle(
                            color: textSecondaryColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: borderTileColor)),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ---------------- Email/Password Form ----------------
                  // Full Name Field
                  TextFormField(
                    controller: _nameController,
                    keyboardType: TextInputType.name,
                    style: TextStyle(color: textPrimaryColor),
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'John Doe',
                      prefixIcon: const Icon(Icons.person_outline),
                      fillColor: surfaceColor,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your full name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: textPrimaryColor),
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      hintText: 'player@example.com',
                      prefixIcon: const Icon(Icons.email_outlined),
                      fillColor: surfaceColor,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    style: TextStyle(color: textPrimaryColor),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: '••••••••',
                      prefixIcon: const Icon(Icons.lock_outline),
                      fillColor: surfaceColor,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Submit Register Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('CREATE ACCOUNT'),
                  ),
                  const SizedBox(height: 24),

                  // Already have an account navigation
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(color: textSecondaryColor),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Log In',
                          style: TextStyle(
                            color: accentLinkColor,
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
        ),
      ),
    );
  }
}
