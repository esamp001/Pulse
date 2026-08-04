# Project Rules for Rally (Pulse App)

## Frontend UI & Styling Standards (Flutter & Dart)
- **STRICT NO DROP SHADOW RULE**: Do NOT add or re-implement drop shadows (`boxShadow`, `BoxShadow(...)`, `elevation`, `shadows`) anywhere in the application.
- **NO FORCED STYLING BORDERS / BORDERLESS DESIGN**: Do NOT automatically add explicit outline borders (`Border.all(...)`, `borderSide`) for visual styling. Cards, input fields, containers, and modals should rely on clean, borderless surface fills (like the username/email input fields with `BorderSide.none`) rather than forced borders. Use borders only when structurally necessary for separation.
- Use `PulseColors` palette and `Theme.of(context)` for all colors.

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



