import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/theme/pulse_colors.dart';
import '../../../../core/widgets/pulse_logo.dart';
import '../../../../core/widgets/google_logo_widget.dart';
import '../../../../core/widgets/pulse_toast.dart';
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

  Future<void> _loadSavedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('saved_email');
      if (savedEmail != null && savedEmail.isNotEmpty) {
        setState(() {
          _emailController.text = savedEmail;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveEmail(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_email', email);
    } catch (_) {}
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
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
        PulseToast.show(
          context,
          e.toString().replaceAll('Exception: ', ''),
          isError: true,
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
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
      PulseToast.show(
        context,
        'Google Sign-In failed: ${e.toString().replaceAll('Exception: ', '')}',
        isError: true,
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
    final backgroundColor = PulseColors.getBackground(isDark);
    final primaryColor = PulseColors.primary;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // 1. Top Hero Sports Background Image Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 240,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/cover_photo_login.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'assets/images/cover_photo_login.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: isDark ? const Color(0xFF142225) : const Color(0xFF2A525A),
                      ),
                    );
                  },
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.black.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Overlapping Curved Surface Form Card
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 170), // Push card down over hero image
                  Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height - 170,
                    ),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Official Brand Mascot Logo
                            const Center(
                              child: PulseLogo(size: 90),
                            ),
                            const SizedBox(height: 16),

                                // Title & Subtitle
                                Text(
                                  'Welcome Back!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: textPrimaryColor,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Log in to keep the rally going, find matches, book courts, and meet players near you.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                    color: textSecondaryColor,
                                  ),
                                ),
                                const SizedBox(height: 28),

                                // Email Input Labeled
                                Text(
                                  'Username or Email',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: textPrimaryColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                            TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: TextStyle(color: textPrimaryColor, fontSize: 14),
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(
                                      Icons.alternate_email_rounded,
                                      color: textSecondaryColor.withValues(alpha: 0.7),
                                      size: 20,
                                    ),
                                    hintText: 'playersname@gmail.com',
                                    hintStyle: TextStyle(
                                      color: textSecondaryColor.withValues(alpha: 0.6),
                                      fontSize: 14,
                                    ),
                                    filled: true,
                                    fillColor: backgroundColor,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: PulseColors.accent,
                                        width: 1.8,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter your email or username';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 18),

                                // Password Input Labeled
                                Text(
                                  'Password',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: textPrimaryColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: !_isPasswordVisible,
                                style: TextStyle(color: textPrimaryColor, fontSize: 14),
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(
                                      Icons.lock_outline_rounded,
                                      color: textSecondaryColor.withValues(alpha: 0.7),
                                      size: 20,
                                    ),
                                    hintText: '••••••••••••••••',
                                  hintStyle: TextStyle(
                                    color: textSecondaryColor.withValues(alpha: 0.6),
                                    fontSize: 14,
                                  ),
                                  filled: true,
                                  fillColor: backgroundColor,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: PulseColors.accent,
                                      width: 1.8,
                                    ),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: textSecondaryColor,
                                      size: 20,
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
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 8),

                                // Forgot Password Right-Aligned Link
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      PulseToast.show(context, 'Password reset link sent to email.');
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? PulseColors.accent : PulseColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Primary Login Pill Button (No Drop Shadows)
                                SizedBox(
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            'Login',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 20),

// Social Auth Options (Google & Apple)
                                OutlinedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : _handleGoogleSignIn,
                                  style: OutlinedButton.styleFrom(
                                    // 1. Controls the exact height (Width, Height)
                                    // double.infinity makes it stretch to fill the width of its parent
                                    minimumSize: const Size(
                                      double.infinity,
                                      50,
                                    ),

                                    // You can remove or reduce the vertical padding now that you have a fixed height
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),

                                    backgroundColor: backgroundColor,

                                    // 2. Removes the border entirely
                                    side: BorderSide.none,

                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const GoogleLogoWidget(size: 20),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Login with Google',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: textPrimaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                             OutlinedButton(
                                  onPressed: () {
                                    PulseToast.show(
                                      context,
                                      'Apple Sign-In available on iOS devices.',
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(
                                      double.infinity,
                                      50,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    backgroundColor: backgroundColor,
                                    side: BorderSide.none,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.apple_rounded,
                                          size: 22,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Login with Apple ID',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: textPrimaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 28),

                                // Footer Sign Up Link
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      "Don't have an account? ",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: textSecondaryColor,
                                      ),
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
                                        'Register here',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: isDark ? PulseColors.accent : PulseColors.primary,
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
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }
