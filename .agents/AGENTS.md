# Project Rules for Rally (Pulse App)

## Frontend UI & Styling Standards (Flutter & Dart)
- **STRICT NO DROP SHADOW RULE**: Do NOT add or re-implement drop shadows (`boxShadow`, `BoxShadow(...)`, `elevation`, `shadows`) anywhere in the application.
- All cards, containers, buttons, app bars, navigation bars, and modals MUST be flat with clean borders (`Border.all(...)`, `side: BorderSide(...)`) and surface fills.
- Use `PulseColors` palette and `Theme.of(context)` for all colors and border strokes.
