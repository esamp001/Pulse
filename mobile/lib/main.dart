import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/pulse_theme.dart';
import 'features/auth/presentation/screens/login_screen.dart';

/// Global Theme Mode Notifier for Pulse App
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const PulseApp());
}

class PulseApp extends StatelessWidget {
  const PulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          title: 'Pulse',
          debugShowCheckedModeBanner: false,
          themeAnimationDuration: Duration.zero,
          theme: PulseTheme.lightTheme,
          darkTheme: PulseTheme.darkTheme,
          themeMode: currentMode,
          home: const LoginScreen(),
        );
      },
    );
  }
}
