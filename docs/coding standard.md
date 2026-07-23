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

---

## ⚙️ Backend Standards (Node.js + TypeScript)

### 1. Layered Architecture (Controller → Service → Repository)
- **Controllers**: Handle HTTP requests, payload validation, and HTTP status codes.
- **Services**: Encapsulate business logic, scoring validation, Elo updates, and event broadcasts.
- **Repositories**: Execute Knex.js database queries against PostgreSQL. No business logic.

### 2. Naming Conventions
- **Files**: `kebab-case.ts` (e.g., `auth-service.ts`, `user-repository.ts`).
- **Classes & Interfaces**: `PascalCase` (e.g., `AuthService`, `IUserPayload`).
- **Variables & Functions**: `camelCase` (e.g., `findUserByEmail`, `calculateElo`).
- **Database Tables & Columns**: `snake_case` (e.g., `users`, `score_events`, `player1_id`).

---

## 📄 Documentation & Spec Standards

1. Update specification documents under `docs/` before making major architectural changes.
2. Keep documentation grounded in actual code implementation without assumptions.