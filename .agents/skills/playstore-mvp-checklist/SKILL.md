---
name: playstore-mvp-checklist
description: Rally (Pulse) Google Play Store deployment readiness checklist, versioning standards, timeline tracking, and policy compliance requirements for MVP 1.0.0 release. Trigger via /playstore-mvp-checklist or when preparing app releases.
---

# Rally (Pulse) - Play Store MVP 1.0.0 Deployment Skill

Use this skill to track release readiness, audit required Google Play Store policies, review feature completion timelines, and follow versioning/tagging conventions for Rally.

---

## 🏷️ Version Tagging & Release Track Strategy

When deploying builds:

| Environment / Stage | Pubspec Version (`version+build`) | Git Tag | Play Console Track | Status |
| :--- | :--- | :--- | :--- | :--- |
| **Alpha / Initial Deploy** | `0.1.0+1` | `v0.1.0-alpha.1` | **Internal Testing** | Baseline |
| **Current Progress (Pre-Launch)** | `1.0.0+1` | `v0.1.0` / `v0.2.0` | **Internal / Closed Alpha** | ⚙️ **Active in Codebase (`mobile/pubspec.yaml`)** |
| **Production MVP 1.0.0 Launch** | `1.0.0+X` | `v1.0.0` | **Production Track** | 🎯 Target after final push items |

---

## 🚀 Top 6 MVP 1.0.0 Feature Roadmap & Status Tracker

**Total Initial Scope:** `10 - 13 Working Days`  
**Remaining Effort:** `~3 - 5 Working Days`

### Implementation Status Matrix

| Priority | Feature | Est. Time | Policy/Core Need | Status |
| :---: | :--- | :---: | :--- | :---: |
| 1️⃣ | **In-App Account Deletion** | 1–1.5 Days | **Mandatory Google Play Policy** | ✅ **COMPLETED** (`86a1412`) |
| 2️⃣ | **Post-Match Player Confirmation & Dispute** | 2–3 Days | Core Trust & ELO Rating System | ✅ **COMPLETED** (`971ea99`, `3eebc0b`) |
| 3️⃣ | **QR Code / 6-Digit PIN Match Join** | 2 Days | Court UX & Quick Lobby Join | ✅ **COMPLETED** (`440f225`) |
| 4️⃣ | **Mobile Push Notifications (FCM)** | 2–3 Days | Off-App Invites & User Retention | ⏳ Pending Setup |
| 5️⃣ | **Detailed Scorecard & Match Replay** | 1.5–2 Days | Post-Match Stats Breakdown | 🔄 In Progress / Enhancing |
| 6️⃣ | **Network Disconnection & Signal Banner** | 1–1.5 Days | Outdoor Sports Court Resilience | ⏳ Pending |

---

## 📋 Feature Specification & Audit Checklist

### 1. 🗑️ In-App Account Deletion (Google Play Policy Requirement) — ✅ DONE
- [x] Backend endpoint: User deletion route in `auth-controller.ts` & `user-repository.ts`.
- [x] Flutter UI: "Delete Account" button & dialog in `account_settings_screen.dart`.
- [ ] External Account Deletion Request URL (Web page needed for Play Console Data Safety submission).

### 2. 🤝 Post-Match Player Confirmation & Dispute Flow — ✅ DONE
- [x] Backend migration: `20260807_add_match_confirmation_and_dispute.ts`.
- [x] Scorer transition & set score storage (`20260807_add_set_scores_to_matches.ts`).
- [x] Flutter UI: Post-match modal with score summary & ELO update verification.

### 3. 📱 QR Code / 6-Digit PIN Match Join — ✅ DONE
- [x] Match PIN generator & lobby PIN display (`440f225`).
- [x] PIN entry & lobby positioning on Flutter home / match screens.

### 4. 🔔 Mobile Push Notifications (Firebase Cloud Messaging) — ⏳ NEXT
- [ ] Firebase project setup (`google-services.json` in `android/app/`).
- [ ] Node.js backend FCM Admin SDK setup (`firebase-admin`).
- [ ] Triggers for match invites, scorer invites, match outcome verification requests, and dispute alerts.
- [ ] Flutter FCM payload listener with deep linking to target match lobby screen when notification is tapped.

### 5. 📊 Detailed Match Scorecard & Match Replay — 🔄 IN PROGRESS
- [ ] Scorecard Screen route showing set-by-set breakdown (e.g. Set 1: 11-8, Set 2: 9-11, Set 3: 11-5).
- [ ] Match metadata: duration, referee/scorer name, court/location, and timestamp.
- [ ] Chronological match point timeline / log viewer.

### 6. ⚠️ Network Disconnection & Signal Recovery Banner — ⏳ NEXT
- [ ] Socket.IO connectivity listener in `scorer_screen.dart` & live match widgets.
- [ ] Sticky top status banner: "Reconnecting to live match..." with warning styling (`PulseColors.warning`).
- [ ] Local offline queue for storing score events while offline.

---

## 🛡️ Pre-Submission Google Play Console Checklist

Before submitting an Android App Bundle (`.aab`) for public distribution:

- [ ] **Android Build target:** Target SDK 34+ (Android 14+ mandatory).
- [ ] **Signing Keystore:** Release keystore configured in `android/key.properties` and `android/app/build.gradle`.
- [ ] **Bundle Generation:** Build release bundle using `flutter build aab --release`.
- [ ] **Privacy Policy URL:** Hosted URL linking to Rally's Privacy Policy.
- [ ] **Data Safety Section:** Full declaration in Play Console detailing user data collected (Email, Name, Sports Stats, Device ID).
- [ ] **Account Deletion Link:** Dedicated URL or web form submitted in Play Console settings.

---

## 🛠️ Quick Commands

```bash
# Build Android App Bundle for Internal / Closed Alpha Track
cd mobile
flutter build aab --release --build-number=1 --build-name=1.0.0

# Verify Dart & Layout Test Standards
flutter test test/responsive_280x520_overflow_test.dart
```
