# Match Players Radar & Open Play Implementation Plan

> **Execution Directive**: Execute this plan via `/executing-plans` in inline mode. Complete each task, run verification, and commit atomically before moving to the next.

**Goal**: Implement the "Match Players Radar" feature enabling players at home to discover nearby open matches on an interactive map, join with 1-tap, navigate directly to the court via live GPS directions, and start playing.  
**Target Branch**: `feature/match-players-radar`  
**Affected Tech Stack**: Flutter / Dart, Node.js TypeScript, Express, Knex (PostgreSQL), Socket.IO, Jest.

---

## Global & Architectural Constraints (`AGENTS.md`)
- **UI & Styling**: Strict **NO DROP SHADOWS** (`boxShadow`, `elevation`, `shadows`). Clean, borderless surface fills with `PulseColors`.
- **Responsive Layout & Overflow Protection**: Wrap horizontal row text, pill tags, and action buttons in `Expanded`, `Flexible`, or `FittedBox(fit: BoxFit.scaleDown)` with `TextOverflow.ellipsis` to strictly prevent `RenderFlex` pixel overflow errors down to 280x520 viewports.
- **Mandatory 280x520 Test**: Whenever a new screen, page, or modal component is created, register a corresponding widget test in `mobile/test/responsive_280x520_overflow_test.dart` using `setSmallestScreen280x520(tester)`.
- **Dynamic Light & Dark Mode**: Dynamic re-evaluation with `PulseColors.getBackground`, `getSurface`, `getCard`, `getTextPrimary`, `getTextSecondary`, `getBorder` across all themes.
- **Database & Migrations**: Mandatory indexes on `court_id` foreign key and query status/sport filter columns.
- **Error Handling**: Explicit logging in catch blocks (`console.error('[MatchRadar Error]:', err)`).
- **Backend Testing**: Mandatory Jest tests in adjacent `__tests__/` directory.

---

## Implementation Tasks

### Task 1: Database Migration — Link Matches to Courts & Performance Indexing
- **Target Files**:
  - `backend/src/database/migrations/20260926_add_court_id_to_matches.ts`
  - `backend/src/types/match.ts`
- **Action**:
  - Create Knex migration adding `court_id` (UUID nullable, references `courts(id)` with `onDelete('SET NULL')`) to `matches` table.
  - Define mandatory indexes per `AGENTS.md`:
    - `table.index(['court_id'])`
    - `table.index(['status', 'sport'])`
  - Update `backend/src/types/match.ts`:
    - Add `court_id?: string | null` to `Match` interface.
    - Add optional `court_id?: string | null` to `CreateMatchDTO`.
    - Add optional `court?: ICourtSummary | null` to `MatchWithDetails`.
- **Verification Command**:
  - `npx knex migrate:latest --knexfile knexfile.ts` (or backend test suite)
- **Commit**: `feat(db): add court_id and query indexes to matches table`

---

### Task 2: Backend Repository & Service — Open Matches Discovery & Instant Join
- **Target Files**:
  - `backend/src/repositories/match-repository.ts`
  - `backend/src/services/match-service.ts`
  - `backend/src/controllers/match-controller.ts`
  - `backend/src/routes/match-routes.ts`
  - `backend/src/repositories/__tests__/match-radar-repository.test.ts`
- **Action**:
  - In `MatchRepository`:
    - Implement `findOpenMatches({ sport, latitude, longitude, radiusKm, limit })`:
      - Query matches where `status = 'WAITING'` and `player2_id IS NULL`.
      - Left-join `users AS host` on `matches.player1_id = host.id` (selecting id, name, rating, avatar_url, primary_sport).
      - Left-join `courts` on `matches.court_id = courts.id` (selecting id, name, address, latitude, longitude, sports, image_url).
      - Filter by `sport` if provided.
      - Calculate Haversine distance if `latitude` & `longitude` are supplied, filtering by `radiusKm` (default 50km).
    - Implement `joinOpenMatch(matchId: string, userId: string)`:
      - Atomically update in a Knex transaction where `id = matchId`, `status = 'WAITING'`, and `player2_id IS NULL`:
        - `player2_id = userId`
        - `player2_accepted = true`
        - `status = 'READY'`
  - In `MatchService`:
    - Wire `findOpenMatches` and `joinOpenMatch`.
    - Emit Socket.IO room events: `match:participant_joined` and `match:status_changed` to `match:${matchId}` room.
  - In `MatchController` & `MatchRoutes`:
    - Add `router.get('/open', authenticateToken, matchController.getOpenMatches)` (**critical**: declare before `router.get('/:id')` to avoid parameter shadowing).
    - Add `router.post('/:id/join-open', authenticateToken, matchController.joinOpenMatch)`.
  - Add Jest unit/integration tests in `backend/src/repositories/__tests__/match-radar-repository.test.ts`.
- **Verification Command**:
  - `npx jest src/repositories/__tests__/match-radar-repository.test.ts`
- **Commit**: `feat(backend): add open matches discovery and atomic join endpoints`

---

### Task 3: Mobile Service & Model Updates
- **Target Files**:
  - `mobile/lib/features/matches/models/match_model.dart`
  - `mobile/lib/features/matches/services/match_service.dart`
  - `mobile/test/features/matches/match_service_open_matches_test.dart`
- **Action**:
  - Update `MatchModel`:
    - Add `final String? courtId;` and `final CourtModel? court;`.
    - Parse `courtId` from `json['court_id'] ?? json['courtId']`.
    - Parse `court` from `json['court'] != null ? CourtModel.fromJson(json['court']) : null`.
    - Include `courtId` and `court` in `toJson()` and `copyWith()`.
  - Update `MatchService`:
    - Add `Future<List<MatchModel>> fetchOpenMatches({String? sport, double? latitude, double? longitude, double? radiusKm})`.
    - Add `Future<MatchModel> joinOpenMatch(String matchId)`.
  - Write test in `mobile/test/features/matches/match_service_open_matches_test.dart` validating `MatchModel` parsing and mock service responses.
- **Verification Command**:
  - `flutter test test/features/matches/match_service_open_matches_test.dart`
- **Commit**: `feat(mobile): add open matches fetch and join methods to MatchService`

---

### Task 4: Match Radar Map Screen & Bottom Match Carousel
- **Target Files**:
  - `mobile/lib/features/matches/presentation/screens/match_radar_screen.dart`
  - `mobile/lib/features/matches/presentation/widgets/open_match_card.dart`
  - `mobile/lib/features/matches/presentation/widgets/match_radar_pin.dart`
  - `mobile/test/features/matches/match_radar_screen_test.dart`
- **Action**:
  - Build `MatchRadarPin`:
    - Map pin widget showing host avatar or sport icon with animated pulsating radar ring.
    - Custom pin marker callback triggering carousel scroll to that match.
  - Build `OpenMatchCard`:
    - Horizontal swipe card for open match.
    - Displays sport badge pill, host player name and rating, scheduled time, court name & distance, and "Join Match" button.
    - Adheres to **NO DROP SHADOWS** and **BORDERLESS** design rules with dark/light mode dynamic adaptation.
    - Uses `Expanded` / `Flexible` / `FittedBox` on all rows to prevent pixel overflows.
  - Build `MatchRadarScreen`:
    - `flutter_map` interactive map with OpenStreetMap / Mapbox tiles.
    - Top floating sport filter pills (`All`, `Pickleball`, `Tennis`, `Table Tennis`, `Badminton`).
    - Fetch GPS location via `Geolocator` with graceful fallback (e.g. Metro Manila 14.5995, 120.9842) if permission denied.
    - Bottom `PageView` carousel of `OpenMatchCard` items synced with map markers.
    - 1-tap "Join Match" triggers instant join confirmation, calls `matchService.joinOpenMatch`, and pushes `MatchLobbyScreen(match: updatedMatch)`.
  - Add widget test in `mobile/test/features/matches/match_radar_screen_test.dart`.
- **Verification Command**:
  - `flutter test test/features/matches/match_radar_screen_test.dart`
- **Commit**: `feat(matches): create MatchRadarScreen with map pins and carousel`

---

### Task 5: Court Route Navigation from Match Lobby
- **Target Files**:
  - `mobile/lib/features/matches/presentation/screens/match_lobby_screen.dart`
  - `mobile/test/features/matches/match_lobby_route_navigation_test.dart`
- **Action**:
  - In `MatchLobbyScreen` (around lines 1075–1115), inspect venue card:
    - If `_match.court != null` (or court coordinates exist):
      - Display a prominent, borderless **"Navigate to Court"** action pill/button with `Icons.directions_outlined`.
      - On tap, push `CourtRouteScreen(court: _match.court!, userLocation: _currentUserLocation)`.
      - Ensure all row elements are wrapped in `Flexible`/`Expanded` to prevent narrow screen overflow.
  - Add test verifying navigation action presence when court is linked.
- **Verification Command**:
  - `flutter test test/features/matches/match_lobby_route_navigation_test.dart`
- **Commit**: `feat(matches): integrate CourtRouteScreen navigation into MatchLobbyScreen`

---

### Task 6: Activate "Match Players" Card on Home Screen & Register 280x520 Overflow Test
- **Target Files**:
  - `mobile/lib/features/home/presentation/screens/home_screen.dart`
  - `mobile/test/responsive_280x520_overflow_test.dart`
- **Action**:
  - In `HomeScreen` (lines 954–964):
    - Remove `isComingSoon: true`.
    - Change `onTap` to navigate to `MatchRadarScreen()`.
  - In `mobile/test/responsive_280x520_overflow_test.dart`:
    - Register `MatchRadarScreen` and `OpenMatchCard` using `setSmallestScreen280x520(tester)` to verify zero pixel overflows on ultra-small legacy viewports.
- **Verification Command**:
  - `flutter test test/responsive_280x520_overflow_test.dart`
  - `flutter analyze`
- **Commit**: `feat(home): activate Match Players Radar card on home screen`

---

## 🏁 Checkpoint & Final Verification
- [ ] Backend tests: `npx jest` passes 100% green
- [ ] Mobile analyzer: `flutter analyze` reports zero errors/warnings
- [ ] Mobile responsive tests: `flutter test test/responsive_280x520_overflow_test.dart` passes cleanly on 280x520 viewport
- [ ] Developer review of diffs and commit log
- [ ] Merge into target branch

---

## 🔄 Handoff to `executing-plans`

Once this plan is approved by the developer, immediately proceed to execution using:
> **`/executing-plans`**
