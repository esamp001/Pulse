import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/theme/pulse_theme.dart';
import 'core/services/fcm_service.dart';
import 'core/theme/pulse_colors.dart';
import 'core/widgets/pulse_logo.dart';
import 'features/auth/models/user_model.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/onboarding_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';

/// Global Theme Mode Notifier for Rally App
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (err) {
    debugPrint('[Firebase Init Warning]: Failed to initialize Firebase Core/Messaging: $err');
  }

  runApp(const RallyApp());
}

class RallyApp extends StatelessWidget {
  const RallyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          title: 'Rally',
          debugShowCheckedModeBanner: false,
          themeAnimationDuration: Duration.zero,
          theme: PulseTheme.lightTheme,
          darkTheme: PulseTheme.darkTheme,
          themeMode: currentMode,
          home: const AuthWrapper(),
        );
      },
    );
  }
}

/// Authentication wrapper widget that restores saved session on boot
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  Widget? _initialScreen;

  @override
  void initState() {
    super.initState();
    _checkSavedSession();
  }

  Future<void> _checkSavedSession() async {
    try {
      final UserModel? savedUser = await AuthService.restoreSavedSession();
      if (!mounted) return;

      if (savedUser != null) {
        setState(() {
          _initialScreen = savedUser.isOnboarded
              ? HomeScreen(user: savedUser)
              : OnboardingScreen(user: savedUser);
        });
        return;
      }
    } catch (err) {
      debugPrint('[AuthWrapper Error]: Failed to restore saved session: $err');
    }

    if (mounted) {
      setState(() {
        _initialScreen = const LoginScreen();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initialScreen != null) {
      return _initialScreen!;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = PulseColors.getBackground(isDark);

    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const PulseLogo(size: 96),
            const SizedBox(height: 24),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                PulseColors.getPrimary(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
