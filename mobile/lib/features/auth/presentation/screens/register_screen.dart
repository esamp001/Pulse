import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/theme/pulse_colors.dart';
import '../../../../core/widgets/pulse_logo.dart';
import '../../../home/presentation/screens/home_screen.dart';
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
    scopes: ['email', 'profile'],
    serverClientId: '254427635301-o7l406affi0gq1j3ae9k63duq0mna3k3.apps.googleusercontent.com',
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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            userName: userData['name'] ?? 'User',
            userEmail: userData['email'] ?? email,
          ),
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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
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
                  // App Logo & Header
                  const Center(
                    child: PulseLogo(size: 70),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Create Account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: PulseColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Join Pulse to track and verify your matches',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: PulseColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ---------------- Social Auth Buttons ----------------
                  // Google Sign-Up Button
                  OutlinedButton.icon(
                    onPressed: _handleGoogleSignUp,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: PulseColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: PulseColors.surface,
                    ),
                    icon: const Icon(
                      Icons.g_mobiledata_rounded,
                      size: 28,
                      color: PulseColors.primary,
                    ),
                    label: const Text(
                      'Sign up with Google',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: PulseColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Apple Sign-Up Button
                  OutlinedButton.icon(
                    onPressed: _handleAppleSignUp,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: PulseColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: PulseColors.surface,
                    ),
                    icon: const Icon(
                      Icons.apple,
                      size: 24,
                      color: PulseColors.textPrimary,
                    ),
                    label: const Text(
                      'Sign up with Apple',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: PulseColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Divider with "OR" text
                  const Row(
                    children: [
                      Expanded(child: Divider(color: PulseColors.border)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.0),
                        child: Text(
                          'OR EMAIL',
                          style: TextStyle(
                            color: PulseColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: PulseColors.border)),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ---------------- Email/Password Form ----------------
                  // Full Name Field
                  TextFormField(
                    controller: _nameController,
                    keyboardType: TextInputType.name,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'John Doe',
                      prefixIcon: Icon(Icons.person_outline),
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
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      hintText: 'player@example.com',
                      prefixIcon: Icon(Icons.email_outlined),
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
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: '••••••••',
                      prefixIcon: const Icon(Icons.lock_outline),
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
                    onPressed: _handleRegister,
                    child: const Text('CREATE ACCOUNT'),
                  ),
                  const SizedBox(height: 24),

                  // Already have an account navigation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(color: PulseColors.textSecondary),
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
                        child: const Text(
                          'Log In',
                          style: TextStyle(
                            color: PulseColors.primary,
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
