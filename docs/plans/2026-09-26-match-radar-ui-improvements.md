# Match Players Radar UI & Contrast Improvements Implementation Plan

> **Execution Directive**: Execute this plan via `/executing-plans` in inline mode. Complete each task, run verification, and commit atomically before moving to the next.

**Goal**: Polish the Match Players Radar UI by standardizing the header to match Find Court, preserving the bottom card layout during loading states, and ensuring all primary Deep Teal buttons/badges throughout the module use high-contrast white text and icons.  
**Target Branch**: `feature/match-players-radar`  
**Affected Tech Stack**: Flutter / Dart (`mobile/lib/features/matches/`, `mobile/lib/features/courts/`, `mobile/test/`).

---

## Context & Architecture Alignment (`/context`, `AGENTS.md`, `coding standard.md`)
- **Coding Standards (`docs/coding standard.md`)**:
  - `PulseColors.primary` is Deep Teal (`#2A525A`). Low luminance requires `Colors.white` text/icons for guaranteed WCAG AA/AAA visual contrast.
  - Strict **NO DROP SHADOWS** (`boxShadow`, `elevation: 0`, `shadowColor: Colors.transparent`).
  - Strict **NO FORCED STYLING BORDERS** — borderless surface fills with `PulseColors.getCard(isDark)`.
  - Header consistency: match `CourtFinderScreen` standard `PreferredSize` AppBar layout.
  - Responsive overflow protection down to 280x520 viewports (`Expanded`, `Flexible`, `FittedBox`).

---

## Implementation Tasks

### Task 1: Standardize Header UI with Find Court Layout
- **Target Files**:
  - `mobile/lib/features/matches/presentation/screens/match_radar_screen.dart`
  - `mobile/test/features/matches/match_radar_screen_test.dart`
- **Action**:
  - Remove the floating green dot and nested "Match Radar" title container.
  - Implement standard `appBar: PreferredSize(preferredSize: const Size.fromHeight(60), ...)` matching `CourtFinderScreen`:
    - `PulseBackButton(isDarkMode: isDark)`
    - `Expanded` Column with title **"Match Players"** (`fontSize: 18, fontWeight: FontWeight.w800`) and subtitle **"Discover & join nearby open matches"** (`fontSize: 12`).
    - Right-aligned GPS locate action button in a card container (`Container` with `PulseColors.getCard(isDark)`, `IconButton` with `Icons.my_location_rounded` and loading spinner state).
  - Position the sports filter pill bar cleanly below the AppBar floating above the map.
  - Update `match_radar_screen_test.dart` to verify header text and back button rendering.
- **Verification Command**:
  - `flutter test test/features/matches/match_radar_screen_test.dart`
- **Commit**: `refactor(matches): standardize MatchRadarScreen header to match Find Court`

---

### Task 2: Retain Bottom Card Container During Loading State
- **Target Files**:
  - `mobile/lib/features/matches/presentation/screens/match_radar_screen.dart`
  - `mobile/test/features/matches/match_radar_screen_test.dart`
- **Action**:
  - Refactor bottom UI state machine to retain a consistent card container across all states:
    - **Loading State** (`_isLoading == true`): Render bottom card container with a pulsing/loading spinner, title **"Scanning for nearby matches..."**, and subtitle **"Locating open games in your area"**.
    - **Empty State** (`_isLoading == false && _openMatches.isEmpty`): Render bottom card container with radar icon, **"No open matches nearby"**, description, and **"Create Match"** button.
    - **Populated State** (`_isLoading == false && _openMatches.isNotEmpty`): Render horizontal `PageView` carousel of `OpenMatchCard` items.
  - Ensure height and padding of card container maintain visual stability with no awkward jumping or floating spinners.
  - Add widget test in `match_radar_screen_test.dart` validating that loading state renders inside the bottom card container.
- **Verification Command**:
  - `flutter test test/features/matches/match_radar_screen_test.dart`
- **Commit**: `feat(matches): retain persistent bottom card layout during loading in MatchRadarScreen`

---

### Task 3: Enforce High-Contrast White Text on Primary Buttons Throughout Module
- **Target Files**:
  - `mobile/lib/features/matches/presentation/screens/match_radar_screen.dart`
  - `mobile/lib/features/matches/presentation/widgets/open_match_card.dart`
  - `mobile/lib/features/matches/presentation/widgets/match_radar_pin.dart`
  - `mobile/lib/features/matches/presentation/screens/match_lobby_screen.dart`
- **Action**:
  - Update `MatchRadarScreen`:
    - Sports filter pill (selected state): `color: Colors.white` (was `Colors.black`) on `PulseColors.primary` background.
    - "Create Match" button in empty state card: `foregroundColor: Colors.white` (was `Colors.black`).
    - "Confirm & Enter" button in join bottom sheet: `foregroundColor: Colors.white` (was `Colors.black`).
    - User location map pin: use `PulseColors.primary` circle with white target icon (`Icons.my_location_rounded`, `Colors.white`).
  - Update `OpenMatchCard`:
    - "Join Match" button: `foregroundColor: Colors.white` (was `Colors.black`).
    - Sport pill badge in header banner: `Text` color `Colors.white`, icon color `Colors.white` (was `Colors.black`).
  - Update `MatchRadarPin`:
    - Mini corner sport badge: icon color `Colors.white` (was `Colors.black`).
  - Update `MatchLobbyScreen`:
    - "Navigate to Court" button: `foregroundColor: Colors.white` (was `Colors.black`), icon and label white.
- **Verification Command**:
  - `flutter test test/features/matches/`
- **Commit**: `fix(matches): ensure white foreground text on primary buttons across match module`

---

### Task 4: Responsive 280x520 Overflow Verification & Global Analysis
- **Target Files**:
  - `mobile/test/responsive_280x520_overflow_test.dart`
- **Action**:
  - Ensure all 36+ tests in `responsive_280x520_overflow_test.dart` pass on the worst-case 280x520 viewport with zero `RenderFlex` overflow errors.
  - Run `flutter analyze` to guarantee zero errors, zero warnings, and zero deprecated member uses.
- **Verification Command**:
  - `flutter test test/responsive_280x520_overflow_test.dart`
  - `flutter analyze`
- **Commit**: `test(matches): verify 280x520 responsive overflow tests and analyzer clean`

---

## 🏁 Checkpoint & Final Verification
- [ ] Header matches Find Court styling with `PreferredSize` AppBar, title, subtitle, and locate button
- [ ] Bottom card remains present with clean scanning state while loading
- [ ] All primary buttons and pills display high-contrast white text
- [ ] `flutter analyze` reports zero errors and zero warnings
- [ ] `flutter test test/responsive_280x520_overflow_test.dart` passes cleanly at 280x520
- [ ] Developer review of diffs and visual appearance

---

## 🔄 Handoff to `executing-plans`

When you are ready to begin implementation, run:
> **`/executing-plans`**
