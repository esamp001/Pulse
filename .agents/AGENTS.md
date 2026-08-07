# Project Rules for Rally (Pulse App)

## Frontend UI & Styling Standards (Flutter & Dart)
- **STRICT NO DROP SHADOW RULE**: Do NOT add or re-implement drop shadows (`boxShadow`, `BoxShadow(...)`, `elevation`, `shadows`) anywhere in the application.
- **NO FORCED STYLING BORDERS / BORDERLESS DESIGN**: Do NOT automatically add explicit outline borders (`Border.all(...)`, `borderSide`) for visual styling. Cards, input fields, containers, and modals should rely on clean, borderless surface fills (like the username/email input fields with `BorderSide.none`) rather than forced borders. Use borders only when structurally necessary for separation.
- Use `PulseColors` palette and `Theme.of(context)` for all colors.
- **RESPONSIVE LAYOUT & OVERFLOW PROTECTION**: Support standard modern screen sizes (~360dp–430dp width) while ensuring full layout flexibility down to ultra-small legacy viewports (~280dp–360dp width). Wrap horizontal row text, pill tags, and action buttons in `Expanded`, `Flexible`, or `FittedBox(fit: BoxFit.scaleDown)` with `TextOverflow.ellipsis` to strictly prevent `RenderFlex` pixel overflow errors.
- **MANDATORY 280x520 WORST-CASE OVERFLOW TEST FOR NEW SCREENS**: Standard mobile screens are fully supported, but to guarantee zero layout breaks even for worst-case ultra-small viewports (~280x520), whenever a new screen, page, or modal component is created in `mobile/lib/`, you MUST register a corresponding widget test in `mobile/test/responsive_280x520_overflow_test.dart` using `setSmallestScreen280x520(tester)` to ensure automated overflow verification passes continuously.
- **OFFICIAL BRAND MASCOT LOGO**: Use `assets/images/official_logo_rally.png` (Rally Dog + Ball Mascot Logo) for all primary app branding, login/auth screens, splash views, and global logo components (`PulseLogo`).
- **DYNAMIC LIGHT & DARK MODE ADAPTATION**: Every newly created or modified screen, page, tab, or modal component in `mobile/lib/` MUST strictly support consistent light and dark mode styling based on the user's selected theme setting (`themeModeNotifier` / `isDarkMode`). All surface backgrounds, card fills, text labels, borders, and icons must dynamically re-evaluate and adapt using `PulseColors` theme helpers (`getBackground`, `getSurface`, `getCard`, `getTextPrimary`, `getTextSecondary`, `getBorder`) or wrap in `ValueListenableBuilder<ThemeMode>` so theme toggles update instantly across all views.

## Notification Drawer & UI Standards
- **Modern Design & Layout**: Uses Bell Icon `🔔`, `All` / `Unread` tab filter bar, plain text category labels (no colored background pills), and inline `Mark as read` action buttons.
- **Strictly Implemented Event Triggers Only**: Notification items are generated ONLY from active, existing features in the codebase.
- **Active Implemented Categories**:
  1. `ACCOUNT`: Password Updates, Password Created, Google Auth Sign-in, Welcome Onboarding.
  2. `INVITE`: Match Invitations (Player 2 / Scorer invite with Accept/Decline actions, Invite Accepted/Declined, Participant Kicked).
  3. `RATING`: Rating & ELO Updates (gained/lost ELO with rating status).
  4. `VERIFIED`: Score Verifications & Match Results (confirmed match outcomes).

## Database & Migration Standards
- **MANDATORY TABLE INDEXING**: ALWAYS define database indexes (`table.index(...)` or composite raw SQL indexes) on all Knex database table migrations for foreign keys, foreign/primary lookups, status/filter columns, and ranking/leaderboard fields.

## Error Handling & Logging Standards
- **EXPLICIT ERROR LOGGING IN CATCH BLOCKS**: Never swallow errors silently with empty `catch (_) {}` or `catch (err) {}` blocks (especially during database transactions, socket emits, or background operations). Always catch errors explicitly and log them with clear contextual naming:
  ```typescript
  catch (err) {
    console.error('[Service/Feature Name Error]:', err);
  }
  ```
