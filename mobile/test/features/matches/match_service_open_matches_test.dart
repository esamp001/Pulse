import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_app/features/courts/models/court_model.dart';
import 'package:pulse_app/features/matches/models/match_model.dart';

void main() {
  group('MatchModel Court & Open Matches Serialization Tests', () {
    test('should parse court_id and nested court data from JSON correctly', () {
      final json = {
        'id': 'match-open-1',
        'creator_id': 'user-host-1',
        'player1_id': 'user-host-1',
        'sport': 'pickleball',
        'venue_name': 'Ayala Malls Manila Bay Court 1',
        'location': 'Parañaque City',
        'court_id': 'court-uuid-123',
        'scheduled_at': '2026-09-26T14:00:00.000Z',
        'status': 'WAITING',
        'total_sets': 3,
        'points_to_win_set': 11,
        'win_by_two': true,
        'player1': {
          'id': 'user-host-1',
          'name': 'Carlos Alcaraz',
          'email': 'carlos@rally.com',
          'rating': 1450,
          'primary_sport': 'pickleball',
        },
        'court': {
          'id': 'court-uuid-123',
          'name': 'Ayala Malls Manila Bay Court 1',
          'address': 'Diosdado Macapagal Blvd',
          'city': 'Parañaque',
          'latitude': 14.5218,
          'longitude': 120.9912,
          'sports': ['pickleball'],
          'distance_km': 3.2,
          'has_lighting': true,
          'is_indoor': true,
        },
      };

      final match = MatchModel.fromJson(json);

      expect(match.id, 'match-open-1');
      expect(match.courtId, 'court-uuid-123');
      expect(match.court, isNotNull);
      expect(match.court!.name, 'Ayala Malls Manila Bay Court 1');
      expect(match.court!.latitude, 14.5218);
      expect(match.court!.longitude, 120.9912);
      expect(match.court!.distanceKm, 3.2);
      expect(match.court!.formattedDistance, '3.2 km');
      expect(match.player1?.name, 'Carlos Alcaraz');
      expect(match.player1?.rating, 1450);

      // Verify toJson roundtrip
      final serialized = match.toJson();
      expect(serialized['court_id'], 'court-uuid-123');
      expect(serialized['court'], isNotNull);
      expect((serialized['court'] as Map)['id'], 'court-uuid-123');
    });

    test('should copyWith courtId and court model', () {
      final baseMatch = MatchModel(
        id: 'base-1',
        creatorId: 'u-1',
        player1Id: 'u-1',
        sport: 'tennis',
        venueName: 'Club Manila East',
        scheduledAt: DateTime.now(),
        status: 'WAITING',
      );

      final court = CourtModel(
        id: 'court-2',
        name: 'Club Manila East',
        latitude: 14.5800,
        longitude: 121.1200,
        sports: ['tennis'],
        distanceKm: 5.5,
      );

      final updatedMatch = baseMatch.copyWith(
        courtId: 'court-2',
        court: court,
      );

      expect(updatedMatch.courtId, 'court-2');
      expect(updatedMatch.court?.name, 'Club Manila East');
      expect(updatedMatch.court?.distanceKm, 5.5);
    });
  });
}
