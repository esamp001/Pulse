import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pulse_app/features/courts/models/court_model.dart';
import 'package:pulse_app/features/matches/models/match_model.dart';
import 'package:pulse_app/features/matches/presentation/screens/match_lobby_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final mockHost = MatchParticipantModel(
    id: 'user-host',
    name: 'Novak Djokovic',
    email: 'novak@rally.com',
    rating: 1550,
  );

  final mockCourt = CourtModel(
    id: 'court-ph-1',
    name: 'Ayala Malls Manila Bay Court 1',
    latitude: 14.5218,
    longitude: 120.9912,
    sports: ['pickleball'],
    distanceKm: 1.8,
  );

  testWidgets('MatchLobbyScreen does not display Navigate to Court button when court is null', (tester) async {
    final matchWithoutCourt = MatchModel(
      id: 'm-lobby-1',
      creatorId: 'user-host',
      player1Id: 'user-host',
      sport: 'pickleball',
      venueName: 'Private Court',
      scheduledAt: DateTime.now(),
      status: 'WAITING',
      player1: mockHost,
      court: null,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MatchLobbyScreen(match: matchWithoutCourt),
      ),
    );

    expect(find.byKey(const Key('navigate_to_court_button')), findsNothing);
  });

  testWidgets('MatchLobbyScreen displays Navigate to Court button when court is linked', (tester) async {
    final matchWithCourt = MatchModel(
      id: 'm-lobby-2',
      creatorId: 'user-host',
      player1Id: 'user-host',
      sport: 'pickleball',
      venueName: 'Ayala Malls Manila Bay Court 1',
      scheduledAt: DateTime.now(),
      status: 'WAITING',
      player1: mockHost,
      court: mockCourt,
      courtId: 'court-ph-1',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MatchLobbyScreen(match: matchWithCourt),
      ),
    );

    expect(find.byKey(const Key('navigate_to_court_button')), findsOneWidget);
    expect(find.text('Navigate to Court'), findsOneWidget);
  });
}
