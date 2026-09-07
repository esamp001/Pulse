import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_app/features/auth/models/user_model.dart';
import 'package:pulse_app/features/matches/models/match_model.dart';
import 'package:pulse_app/features/auth/presentation/screens/get_started_screen.dart';
import 'package:pulse_app/features/auth/presentation/screens/login_screen.dart';
import 'package:pulse_app/features/auth/presentation/screens/register_screen.dart';
import 'package:pulse_app/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:pulse_app/features/home/presentation/screens/home_screen.dart';
import 'package:pulse_app/features/rankings/presentation/screens/rankings_screen.dart';
import 'package:pulse_app/features/profile/presentation/screens/account_settings_screen.dart';
import 'package:pulse_app/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:pulse_app/features/help/presentation/screens/help_rules_screen.dart';
import 'package:pulse_app/features/matches/presentation/screens/create_match_screen.dart';
import 'package:pulse_app/features/matches/presentation/screens/match_lobby_screen.dart';
import 'package:pulse_app/features/matches/presentation/screens/scorer_screen.dart';
import 'package:pulse_app/features/notifications/presentation/widgets/notification_side_drawer.dart';
import 'package:pulse_app/features/matches/presentation/widgets/invite_user_modal.dart';
import 'package:pulse_app/features/matches/presentation/screens/post_match_screen.dart';
import 'package:latlong2/latlong.dart';
import 'package:pulse_app/features/home/presentation/widgets/share_victory_modal.dart';
import 'package:pulse_app/features/matches/presentation/widgets/signal_recovery_banner.dart';
import 'package:pulse_app/features/courts/presentation/widgets/suggest_court_modal.dart';
import 'package:pulse_app/features/courts/models/court_model.dart';
import 'package:pulse_app/features/courts/presentation/widgets/court_reviews_sheet.dart';
import 'package:pulse_app/features/courts/presentation/widgets/court_map_pin.dart';
import 'package:pulse_app/features/courts/presentation/widgets/pulse_map_center_pin.dart';
import 'package:pulse_app/features/courts/presentation/screens/court_finder_screen.dart';
import 'package:pulse_app/features/courts/presentation/widgets/court_card.dart';

/// Helper to configure test surface viewport size to small 280x520 resolution
void setSmallestScreen280x520(WidgetTester tester) {
  tester.view.physicalSize = const Size(280, 520);
  tester.view.devicePixelRatio = 1.0;
}

/// Reset viewport surface size after test execution
void resetViewport(WidgetTester tester) {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

final UserModel mockUser = UserModel(
  id: 'user-1',
  email: 'player@rallypulse.com',
  name: 'Rally Player',
  rating: 1200,
  isOnboarded: true,
  primarySport: 'Pickleball',
);

final MatchModel mockMatch = MatchModel(
  id: 'match-101',
  creatorId: 'user-1',
  player1Id: 'user-1',
  player2Id: 'user-2',
  player2Accepted: true,
  scorerId: 'user-3',
  scorerAccepted: true,
  sport: 'pickleball',
  venueName: 'Central Pickleball Court 1',
  scheduledAt: DateTime.now(),
  status: 'READY',
  player1: MatchParticipantModel(
    id: 'user-1',
    name: 'Player One',
    email: 'p1@test.com',
    rating: 1200,
  ),
  player2: MatchParticipantModel(
    id: 'user-2',
    name: 'Player Two',
    email: 'p2@test.com',
    rating: 1250,
  ),
  scorer: MatchParticipantModel(
    id: 'user-3',
    name: 'Ref Scorer',
    email: 'ref@test.com',
    rating: 1100,
  ),
);

void main() {
  group(
    'Smallest Mobile Viewport (280x520) Responsive Overflow Protection Tests',
    () {
      testWidgets(
        'GetStartedScreen renders without pixel overflow on 280x520',
        (WidgetTester tester) async {
          setSmallestScreen280x520(tester);
          await tester.pumpWidget(const MaterialApp(home: GetStartedScreen()));
          await tester.pump();
          resetViewport(tester);
        },
      );

      testWidgets('LoginScreen renders without pixel overflow on 280x520', (
        WidgetTester tester,
      ) async {
        setSmallestScreen280x520(tester);
        await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
        await tester.pump();
        resetViewport(tester);
      });

      testWidgets('RegisterScreen renders without pixel overflow on 280x520', (
        WidgetTester tester,
      ) async {
        setSmallestScreen280x520(tester);
        await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
        await tester.pump();
        resetViewport(tester);
      });

      testWidgets(
        'OnboardingScreen renders without pixel overflow on 280x520',
        (WidgetTester tester) async {
          setSmallestScreen280x520(tester);
          await tester.pumpWidget(
            MaterialApp(home: OnboardingScreen(user: mockUser)),
          );
          await tester.pump();
          resetViewport(tester);
        },
      );

      testWidgets('HomeScreen renders without pixel overflow on 280x520', (
        WidgetTester tester,
      ) async {
        setSmallestScreen280x520(tester);
        await tester.pumpWidget(MaterialApp(home: HomeScreen(user: mockUser)));
        await tester.pump();
        resetViewport(tester);
      });

      testWidgets('RankingsScreen renders without pixel overflow on 280x520', (
        WidgetTester tester,
      ) async {
        setSmallestScreen280x520(tester);
        await tester.pumpWidget(const MaterialApp(home: RankingsScreen()));
        await tester.pump();
        resetViewport(tester);
      });

      testWidgets(
        'EditProfileScreen renders without pixel overflow on 280x520',
        (WidgetTester tester) async {
          setSmallestScreen280x520(tester);
          await tester.pumpWidget(
            MaterialApp(
              home: EditProfileScreen(user: mockUser, isDarkMode: true),
            ),
          );
          await tester.pump();
          resetViewport(tester);
        },
      );

      testWidgets('HelpRulesScreen renders without pixel overflow on 280x520', (
        WidgetTester tester,
      ) async {
        setSmallestScreen280x520(tester);
        await tester.pumpWidget(
          const MaterialApp(home: HelpRulesScreen(isDarkMode: true)),
        );
        await tester.pump();
        resetViewport(tester);
      });

      testWidgets(
        'CreateMatchScreen renders without pixel overflow on 280x520',
        (WidgetTester tester) async {
          setSmallestScreen280x520(tester);
          await tester.pumpWidget(const MaterialApp(home: CreateMatchScreen()));
          await tester.pump();
          resetViewport(tester);
        },
      );

      testWidgets(
        'MatchLobbyScreen renders without pixel overflow on 280x520',
        (WidgetTester tester) async {
          setSmallestScreen280x520(tester);
          await tester.pumpWidget(
            MaterialApp(home: MatchLobbyScreen(match: mockMatch)),
          );
          await tester.pump();
          resetViewport(tester);
        },
      );

      testWidgets('ScorerScreen renders without pixel overflow on 280x520', (
        WidgetTester tester,
      ) async {
        setSmallestScreen280x520(tester);
        await tester.pumpWidget(
          MaterialApp(home: ScorerScreen(match: mockMatch)),
        );
        await tester.pump();
        resetViewport(tester);
      });

      testWidgets(
        'NotificationSideDrawer renders without pixel overflow on 280x520',
        (WidgetTester tester) async {
          setSmallestScreen280x520(tester);
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                drawer: NotificationSideDrawer(
                  isDarkMode: true,
                  user: mockUser,
                  activeMatch: null,
                  isInvitationPending: false,
                  historyMatches: const [],
                  onAcceptMatchInvitation: () {},
                  onDeclineMatchInvitation: () {},
                ),
              ),
            ),
          );
          await tester.pump();
          resetViewport(tester);
        },
      );

      testWidgets('InviteUserModal renders without pixel overflow on 280x520', (
        WidgetTester tester,
      ) async {
        setSmallestScreen280x520(tester);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: InviteUserModal(
                role: 'player2',
                isDarkMode: true,
                onUserSelected: (user) {},
              ),
            ),
          ),
        );
        await tester.pump();
        resetViewport(tester);
      });

      testWidgets('PostMatchScreen renders without pixel overflow on 280x520', (
        WidgetTester tester,
      ) async {
        setSmallestScreen280x520(tester);
        final finishedMatch = MatchModel(
          id: 'match-finished',
          creatorId: 'user-1',
          player1Id: 'user-1',
          player2Id: 'user-2',
          player2Accepted: true,
          scorerId: 'user-3',
          scorerAccepted: true,
          sport: 'pickleball',
          venueName: 'Central Court',
          scheduledAt: DateTime.now(),
          status: 'FINISHED',
          winnerId: 'user-1',
          player1: MatchParticipantModel(
            id: 'user-1',
            name: 'Player One',
            email: 'p1@test.com',
            rating: 1200,
          ),
          player2: MatchParticipantModel(
            id: 'user-2',
            name: 'Player Two',
            email: 'p2@test.com',
            rating: 1250,
          ),
          scorer: MatchParticipantModel(
            id: 'user-3',
            name: 'Ref Scorer',
            email: 'ref@test.com',
            rating: 1100,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: PostMatchScreen(
              match: finishedMatch,
              currentUserId: 'user-1',
            ),
          ),
        );
        await tester.pump();
        resetViewport(tester);
      });

      testWidgets(
        'AccountSettingsScreen with Delete Account Modal renders without pixel overflow on 280x520',
        (WidgetTester tester) async {
          setSmallestScreen280x520(tester);
          await tester.pumpWidget(
            MaterialApp(
              home: AccountSettingsScreen(user: mockUser, isDarkMode: true),
            ),
          );
          await tester.pump();

          // Trigger Delete Account modal
          final deleteBtn = find.text('Delete Account');
          if (deleteBtn.evaluate().isNotEmpty) {
            await tester.tap(deleteBtn.first, warnIfMissed: false);
            await tester.pumpAndSettle();
          }

          resetViewport(tester);
        },
      );

      testWidgets(
        'ShareVictoryModal renders without pixel overflow on 280x520',
        (WidgetTester tester) async {
          setSmallestScreen280x520(tester);
          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: ShareVictoryModal(
                  userName: 'Rally Champ',
                  currentElo: 1250,
                  sportName: 'Pickleball',
                  isDarkMode: true,
                ),
              ),
            ),
          );
          await tester.pump();
          resetViewport(tester);
        },
      );

      testWidgets(
        'SignalRecoveryBanner renders without pixel overflow on 280x520',
        (WidgetTester tester) async {
          setSmallestScreen280x520(tester);
          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: SignalRecoveryBanner(
                  status: SignalConnectionStatus.offline,
                  pendingQueueCount: 4,
                  isDarkMode: true,
                ),
              ),
            ),
          );
          await tester.pump();
          resetViewport(tester);
        },
      );

      testWidgets(
        'SuggestCourtModal renders without pixel overflow on 280x520',
        (WidgetTester tester) async {
          setSmallestScreen280x520(tester);
          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: SuggestCourtModal(
                  initialLocation: LatLng(14.5995, 120.9842),
                  initialAddress: 'Ayala Ave',
                  initialCity: 'Makati',
                  isDarkMode: true,
                ),
              ),
            ),
          );
          await tester.pump();
          resetViewport(tester);
        },
      );

      testWidgets(
        'CourtReviewsSheet renders without pixel overflow on 280x520',
        (WidgetTester tester) async {
          setSmallestScreen280x520(tester);
          final court = CourtModel(
            id: 'court-test-1',
            name: 'Test Court Viewport Overflow',
            latitude: 14.5,
            longitude: 121.0,
            sports: const ['pickleball'],
          );
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: CourtReviewsSheet(court: court, isDarkMode: true),
              ),
            ),
          );
          await tester.pump();
          resetViewport(tester);
        },
      );

      testWidgets('CourtMapPin renders without pixel overflow on 280x520', (
        WidgetTester tester,
      ) async {
        setSmallestScreen280x520(tester);
        final courtWithImage = CourtModel(
          id: 'court-test-pin-1',
          name: 'Pin Court with Image',
          latitude: 14.5,
          longitude: 121.0,
          sports: const ['tennis'],
          imageUrl: 'https://example.com/court.jpg',
        );
        final courtFallback = CourtModel(
          id: 'court-test-pin-2',
          name: 'Pin Court without Image',
          latitude: 14.5,
          longitude: 121.0,
          sports: const ['badminton'],
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Row(
                children: [
                  CourtMapPin(court: courtWithImage, isSelected: true),
                  CourtMapPin(court: courtFallback, isSelected: false),
                ],
              ),
            ),
          ),
        );
        await tester.pump();
        resetViewport(tester);
      });

      testWidgets(
        'CourtFinderScreen renders without pixel overflow on 280x520',
        (WidgetTester tester) async {
          setSmallestScreen280x520(tester);
          await tester.pumpWidget(const MaterialApp(home: CourtFinderScreen()));
          await tester.pump();
          resetViewport(tester);
        },
      );

      testWidgets(
        'PulseMapCenterPin renders without pixel overflow on 280x520 (idle and dragging)',
        (WidgetTester tester) async {
          setSmallestScreen280x520(tester);
          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PulseMapCenterPin(
                        sport: 'Pickleball',
                        isDragging: false,
                        isDark: false,
                      ),
                      SizedBox(height: 30),
                      PulseMapCenterPin(
                        sport: 'Tennis',
                        isDragging: true,
                        isDark: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          resetViewport(tester);
        },
      );

      testWidgets(
        'CourtCard with full-bleed image and black gradient renders without pixel overflow on 280x520',
        (WidgetTester tester) async {
          setSmallestScreen280x520(tester);
          final court = CourtModel(
            id: 'court-test-1',
            name: 'Gulod Court - Metro Sports Arena',
            address: 'Quirino Highway, Novaliches, Quezon City',
            city: 'Quezon City',
            latitude: 14.7,
            longitude: 121.0,
            sports: const ['pickleball', 'tennis', 'table tennis', 'badminton'],
            hasLighting: true,
            isIndoor: true,
            distanceKm: 14.5,
            imageUrl: 'https://example.com/court.jpg',
            likesCount: 5,
            dislikesCount: 1,
          );

          final courtWithoutImage = CourtModel(
            id: 'court-test-2',
            name: 'Gulod Court - Metro Sports Arena',
            address: 'Quirino Highway, Novaliches, Quezon City',
            city: 'Quezon City',
            latitude: 14.7,
            longitude: 121.0,
            sports: const ['pickleball', 'tennis', 'table tennis', 'badminton'],
            hasLighting: true,
            isIndoor: true,
            distanceKm: 14.5,
            likesCount: 5,
            dislikesCount: 1,
          );

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        CourtCard(
                          court: court,
                          isDarkMode: true,
                          onHostMatch: () {},
                        ),
                        CourtCard(
                          court: courtWithoutImage,
                          isDarkMode: false,
                          onHostMatch: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          resetViewport(tester);
        },
      );
    },
  );
}
