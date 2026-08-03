# Project Rules for Rally (Pulse App)

## Frontend UI & Styling Standards (Flutter & Dart)
- **STRICT NO DROP SHADOW RULE**: Do NOT add or re-implement drop shadows (`boxShadow`, `BoxShadow(...)`, `elevation`, `shadows`) anywhere in the application.
- All cards, containers, buttons, app bars, navigation bars, and modals MUST be flat with clean borders (`Border.all(...)`, `side: BorderSide(...)`) and surface fills.
- Use `PulseColors` palette and `Theme.of(context)` for all colors and border strokes.

## Notification Drawer & UI Standards
- **Modern Design & Layout**: Uses Bell Icon `🔔`, `All` / `Unread` tab filter bar, plain text category labels (no colored background pills), and inline `Mark as read` action buttons.
- **Strictly Implemented Event Triggers Only**: Notification items are generated ONLY from active, existing features in the codebase.
- **Active Implemented Categories**:
  1. `ACCOUNT`: Password Updates, Password Created, Google Auth Sign-in, Welcome Onboarding.
  2. `INVITE`: Match Invitations (Player 2 / Scorer invite with Accept/Decline actions, Invite Accepted/Declined, Participant Kicked).
  3. `RATING`: Rating & ELO Updates (gained/lost ELO with rating status).
  4. `VERIFIED`: Score Verifications & Match Results (confirmed match outcomes).


