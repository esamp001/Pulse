import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pulse_app/core/network/api_client.dart';
import 'package:pulse_app/features/matches/models/match_model.dart';
import 'package:pulse_app/features/matches/presentation/screens/match_lobby_screen.dart';
import 'package:pulse_app/features/matches/presentation/screens/scorer_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final mockParticipant1 = MatchParticipantModel(
    id: 'user-1',
    name: 'Player One',
    email: 'p1@rally.com',
    rating: 1200,
  );

  final mockParticipant2 = MatchParticipantModel(
    id: 'user-2',
    name: 'Player Two',
    email: 'p2@rally.com',
    rating: 1200,
  );

  final mockWaitingMatch = MatchModel(
    id: 'match-123',
    creatorId: 'user-1',
    sport: 'pickleball',
    venueName: 'Central Court',
    scheduledAt: DateTime.now(),
    totalSets: 3,
    pointsToWinSet: 11,
    winByTwo: true,
    status: 'WAITING',
    player1Id: 'user-1',
    player2Id: 'user-2',
    player1: mockParticipant1,
    player2: mockParticipant2,
  );

  final mockLiveMatch = MatchModel(
    id: 'match-123',
    creatorId: 'user-1',
    sport: 'pickleball',
    venueName: 'Central Court',
    scheduledAt: DateTime.now(),
    totalSets: 3,
    pointsToWinSet: 11,
    winByTwo: true,
    status: 'LIVE',
    player1Id: 'user-1',
    player2Id: 'user-2',
    player1: mockParticipant1,
    player2: mockParticipant2,
  );

  group('MatchLobbyScreen Auto-Transition Tests', () {
    testWidgets('MatchLobbyScreen renders properly for waiting match', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MatchLobbyScreen(match: mockWaitingMatch),
        ),
      );
      await tester.pump();

      expect(find.byType(MatchLobbyScreen), findsOneWidget);
      expect(find.text('Central Court'), findsOneWidget);
      expect(find.text('Player One'), findsOneWidget);
      expect(find.text('Player Two'), findsOneWidget);
    });

    testWidgets('Live match automatically navigates directly to ScorerScreen', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MatchLobbyScreen(match: mockLiveMatch),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify that when status is LIVE, it automatically transitions to ScorerScreen
      expect(find.byType(ScorerScreen), findsOneWidget);
    });
  });

  group('ApiClient BaseUrl Sanitization Unit Tests', () {
    test('ApiClient singleton returns a sanitized baseUrl without whitespace', () {
      final client = ApiClient();
      final url = client.baseUrl;
      expect(url.contains(' '), isFalse, reason: 'baseUrl should never contain space characters');
      expect(url.startsWith('http://') || url.startsWith('https://'), isTrue, reason: 'baseUrl must start with http or https');
      expect(url.endsWith('/auth'), isFalse, reason: 'baseUrl should not end with /auth');
      expect(url.endsWith('/'), isFalse, reason: 'baseUrl should not end with trailing slash');
    });
  });
}
