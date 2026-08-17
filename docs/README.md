# Pulse Project Documentation

This directory contains the complete specification-driven documentation for the **Pulse** platform, a mobile application designed to transform casual sports matches into verified competitive games through neutral officiating and live scoring.

---

## Documentation Structure

### 📋 Global Specifications
- [**Root README.md**](../README.md) - Global project overview, vision, match flow, tech stack, and system architecture.
- [**Coding Standards**](./coding%20standard.md) - Architecture guidelines, folder structures, naming rules, and standards for Flutter & Node.js.

### 🖥️ Frontend Specifications (Flutter)
- [**Theme System**](../mobile/lib/core/theme/pulse_colors.dart) - Color tokens (`PulseColors`: `#0b1213`, `#f2f7f8`, `#2a525a`, `#88c2cd`, `#3a92a1`).
- [**Auth Screens**](../mobile/lib/features/auth/presentation/screens/) - Login & Registration UI flows (`LoginScreen`, `RegisterScreen`).
- [**Reusable Widgets**](../mobile/lib/core/widgets/) - Shared branding widgets (`PulseLogo`).

### 🔧 Backend Specifications (Node.js)
- [**Layered Architecture**](./backend/architecture.md) - Controller → Service → Repository 3-Layer architecture, Knex.js queries, and Cloudflare R2 integration.
- [**Leaderboard Pagination**](./backend/leaderboard_pagination.md) - Indexed database pagination, limit/offset rules, and Flutter lazy-loading specification.


### 📦 Module Specifications
- **User & Auth Management**: Registration, Login, and Social OAuth UI (Google & Apple Sign-In).

### 🚀 Deployment & Testing
- [**TestFlight Testing Guide**](./testflight-testing.md) - Cloudflare tunnel setup and backend exposure guide for TestFlight testing.

---

## Documentation Guidelines

1. **NEVER make assumptions** about code functionality.
2. **ALWAYS verify** against actual codebase implementation.
3. **Cross-reference** multiple sources to ensure complete accuracy.
