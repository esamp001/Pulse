import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/theme/pulse_colors.dart';
import '../../../../core/widgets/rally_text_logo.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import 'onboarding_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
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
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  /// Load email address saved from previous login session
  Future<void> _loadSavedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('saved_email');
      if (savedEmail != null && savedEmail.isNotEmpty) {
        setState(() {
          _emailController.text = savedEmail;
        });
      }
    } catch (_) {
      // Ignore storage errors on startup
    }
  }

  /// Persist email address to local device storage
  Future<void> _saveEmail(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_email', email);
    } catch (_) {
      // Ignore storage write errors
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      await _saveEmail(email);

      try {
        final result = await _authService.login(email: email, password: password);
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
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: PulseColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final googleAccount = await _googleSignIn.signIn();
      
      if (googleAccount == null) {
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  const Center(
                    child: RallyTextLogo(fontSize: 44.0),
                  ),
                  const SizedBox(height: 32),

                  // Social Auth Buttons
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
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
                      'Sign in with Google',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textPrimaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(child: Divider(color: borderTileColor)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Text(
                          'OR LOG IN WITH EMAIL',
                          style: TextStyle(
                            color: textSecondaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: borderTileColor)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: textPrimaryColor),
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      hintText: 'player@example.com',
                      prefixIcon: const Icon(Icons.email_outlined),
                      fillColor: PulseColors.getSurface(isDark),
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
                  const SizedBox(height: 20),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    style: TextStyle(color: textPrimaryColor),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: '••••••••',
                      prefixIcon: const Icon(Icons.lock_outline),
                      fillColor: PulseColors.getSurface(isDark),
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
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Forgot Password Link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // TODO: Implement forgot password flow
                      },
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(color: textSecondaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Login Action Button
                  ElevatedButton(
                    onPressed: _handleLogin,
                    child: const Text('LOG IN'),
                  ),
                  const SizedBox(height: 24),

                  // Sign Up Navigation Link
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(color: textSecondaryColor),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Sign Up',
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
