import 'package:flutter/material.dart';
import '../../../../core/theme/pulse_colors.dart';

class HomeScreen extends StatelessWidget {
  final String userName;
  final String userEmail;

  const HomeScreen({
    super.key,
    required this.userName,
    required this.userEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pulse Dashboard'),
        backgroundColor: PulseColors.primary,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: PulseColors.accent,
                child: Icon(Icons.person, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                'Welcome, $userName!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: PulseColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                userEmail,
                style: const TextStyle(
                  fontSize: 16,
                  color: PulseColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
