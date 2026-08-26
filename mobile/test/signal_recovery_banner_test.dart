import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_app/features/matches/presentation/widgets/signal_recovery_banner.dart';

void main() {
  group('SignalRecoveryBanner Widget Tests', () {
    testWidgets('renders offline banner with pending queue count', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SignalRecoveryBanner(
              status: SignalConnectionStatus.offline,
              pendingQueueCount: 3,
              isDarkMode: false,
            ),
          ),
        ),
      );

      expect(find.text('OFFLINE'), findsOneWidget);
      expect(find.text('Scores saved locally (3 pending sync)'), findsOneWidget);
    });

    testWidgets('renders reconnecting status properly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SignalRecoveryBanner(
              status: SignalConnectionStatus.reconnecting,
              isDarkMode: true,
            ),
          ),
        ),
      );

      expect(find.text('RECONNECTING'), findsOneWidget);
      expect(find.text('Syncing with court room...'), findsOneWidget);
    });

    testWidgets('renders back online reconnected status', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SignalRecoveryBanner(
              status: SignalConnectionStatus.reconnected,
              isDarkMode: true,
            ),
          ),
        ),
      );

      expect(find.text('BACK ONLINE'), findsOneWidget);
      expect(find.text('All match points synchronized with court'), findsOneWidget);
    });

    testWidgets('renders nothing when status is online', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SignalRecoveryBanner(
              status: SignalConnectionStatus.online,
              isDarkMode: false,
            ),
          ),
        ),
      );

      expect(find.byType(SignalRecoveryBanner), findsOneWidget);
      expect(find.text('OFFLINE'), findsNothing);
      expect(find.text('RECONNECTING'), findsNothing);
      expect(find.text('BACK ONLINE'), findsNothing);
    });

    testWidgets('renders default offline text when pendingQueueCount is 0', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SignalRecoveryBanner(
              status: SignalConnectionStatus.offline,
              pendingQueueCount: 0,
              isDarkMode: false,
            ),
          ),
        ),
      );

      expect(find.text('OFFLINE'), findsOneWidget);
      expect(find.text('Scores saved locally • Auto-syncing on reconnect'), findsOneWidget);
    });

    testWidgets('triggers onRetry callback when Retry button is tapped', (WidgetTester tester) async {
      bool retryTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SignalRecoveryBanner(
              status: SignalConnectionStatus.offline,
              pendingQueueCount: 2,
              isDarkMode: false,
              onRetry: () => retryTapped = true,
            ),
          ),
        ),
      );

      final retryBtn = find.text('Retry');
      expect(retryBtn, findsOneWidget);
      await tester.tap(retryBtn);
      await tester.pump();

      expect(retryTapped, isTrue);
    });

    testWidgets('renders cleanly in dark mode without pixel overflow', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SignalRecoveryBanner(
              status: SignalConnectionStatus.offline,
              pendingQueueCount: 5,
              isDarkMode: true,
            ),
          ),
        ),
      );

      expect(find.text('OFFLINE'), findsOneWidget);
      expect(find.text('Scores saved locally (5 pending sync)'), findsOneWidget);
    });
  });
}
