import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pulse_app/features/courts/models/court_model.dart';
import 'package:pulse_app/features/matches/models/match_model.dart';
import 'package:pulse_app/features/matches/presentation/widgets/match_radar_pin.dart';
import 'package:pulse_app/features/matches/presentation/widgets/open_match_card.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final mockCourt = CourtModel(
    id: 'court-101',
    name: 'BGC Pickleball Club',
    latitude: 14.5500,
    longitude: 121.0500,
    sports: ['pickleball'],
    distanceKm: 2.4,
  );

  final mockHost = MatchParticipantModel(
    id: 'host-1',
    name: 'Rafael Nadal',
    email: 'rafa@rally.com',
    rating: 1500,
  );

  final mockMatch = MatchModel(
    id: 'match-radar-1',
    creatorId: 'host-1',
    player1Id: 'host-1',
    sport: 'pickleball',
    venueName: 'BGC Pickleball Club',
    scheduledAt: DateTime.now(),
    status: 'WAITING',
    player1: mockHost,
    court: mockCourt,
    courtId: 'court-101',
  );

  group('Match Radar Widgets Unit & Smoke Tests', () {
    testWidgets('MatchRadarPin renders without throwing exceptions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: MatchRadarPin(
                match: mockMatch,
                isSelected: false,
                isDarkMode: true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(MatchRadarPin), findsOneWidget);
      expect(find.text('RN'), findsOneWidget);
    });

    testWidgets('OpenMatchCard renders host and match info cleanly', (tester) async {
      bool joinPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 340,
                child: OpenMatchCard(
                  match: mockMatch,
                  isDarkMode: true,
                  onJoin: () {
                    joinPressed = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('BGC Pickleball Club'), findsOneWidget);
      expect(find.text('Rafael Nadal'), findsOneWidget);
      expect(find.textContaining('1500'), findsOneWidget);
      expect(find.text('Join Match'), findsOneWidget);

      await tester.tap(find.text('Join Match'));
      await tester.pump();
      expect(joinPressed, isTrue);
    });
  });
}
