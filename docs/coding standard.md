# Pulse Coding Standards

This document specifies coding standards, formatting guidelines, architectural rules, and folder structures for the Pulse project codebase across Flutter (mobile frontend) and Node.js (backend).

---

## 📱 Frontend Standards (Flutter & Dart)

### 1. Folder Structure (Feature-First Architecture)
```text
mobile/lib/
├── core/
│   ├── theme/          # pulse_colors.dart, pulse_theme.dart
│   ├── widgets/        # Reusable global widgets (pulse_logo.dart, etc.)
│   └── constants/      # App constants, route strings & API endpoints
├── features/
│   └── auth/           # Authentication domain module
│       └── presentation/
│           ├── screens/ # login_screen.dart, register_screen.dart
│           └── widgets/ # Feature-specific widgets
└── main.dart
```

### 2. Naming Conventions
- **Files & Folders**: `snake_case.dart` (e.g., `login_screen.dart`, `pulse_colors.dart`).
- **Classes & Widgets**: `PascalCase` (e.g., `LoginScreen`, `PulseLogo`, `PulseColors`).
- **Variables & Functions**: `camelCase` (e.g., `_isPasswordVisible`, `_handleRegister`).
- **Private Properties**: Prefix with an underscore `_` (e.g., `_emailController`).

### 3. Widget Choice & Performance Guidelines
- **`StatelessWidget`**: Use for static, read-only UI components or screens.
- **`StatefulWidget`**: Use only when a component maintains mutable local state (`setState()`, text controllers, toggles).
- **Constructors**: Always prefer `const` constructors wherever possible for optimal rendering performance.
- **Theme Usage**: Always consume brand colors from `PulseColors` or `Theme.of(context)` rather than hardcoding hex colors inline.

### 4. UI & Styling Rules (Strict Flat Design)
- **NO DROP SHADOWS (`boxShadow` / `elevation`)**: Do NOT use `boxShadow`, `BoxShadow(...)`, `elevation`, or drop shadows on cards, buttons, dialogs, top app bars, or navigation bars across the mobile app. All containers MUST remain flat with clean borders (`Border.all(...)`, `side: BorderSide(...)`).
- **Notification Center Design**: Must use Bell Icon `🔔`, `All` / `Unread` filter tabs, plain text category labels (no colored background pills), and inline `Mark as read` action buttons. Only active, existing event triggers (`ACCOUNT`, `INVITE`, `RATING`, `VERIFIED`) are populated.

---

## ⚙️ Backend Standards (Node.js + TypeScript)

### 1. Layered Architecture (Controller → Service → Repository)
*See detailed spec in [Backend Architecture Document](./backend/architecture.md).*
- **Routes**: Map endpoints to controllers (`src/routes/`).
- **Controllers**: Handle HTTP requests, payload validation (Zod), and HTTP status codes (`src/controllers/`).
- **Services**: Encapsulate pure business logic, password encryption (bcrypt), JWT generation, and cloud storage integrations (`src/services/`).
- **Repositories**: Execute Knex.js database queries against PostgreSQL (`src/repositories/`). No business logic. Use generic types `db<T>('table_name')`.

### 2. Naming Conventions
- **Files**: `kebab-case.ts` (e.g., `auth-service.ts`, `user-repository.ts`).
- **Classes & Interfaces**: `PascalCase` (e.g., `AuthService`, `IUserPayload`).
- **Variables & Functions**: `camelCase` (e.g., `findUserByEmail`, `calculateElo`).
- **Database Tables & Columns**: `snake_case` (e.g., `users`, `score_events`, `player1_id`).

---

## 📄 Documentation & Spec Standards

1. Update specification documents under `docs/` before making major architectural changes.
2. Keep documentation grounded in actual code implementation without assumptions.