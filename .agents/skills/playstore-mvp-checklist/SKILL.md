---
name: playstore-mvp-checklist
description: Rally (Pulse) Google Play Store deployment readiness checklist, versioning standards, testing track requirements (20 testers / 14 days), and policy compliance for MVP 1.0.0 release. Trigger via /playstore-mvp-checklist or when preparing app releases.
---

# Rally (Pulse) - Google Play Store MVP 1.0.0 Deployment Skill

Use this skill to track Android release readiness, audit required Google Play Store policies, review testing tracks (including the mandatory 20 testers for 14 days closed testing rule), and follow release build procedures for Rally.

---

## 🏷️ Version Tagging & Android Release Strategy

| Stage / Track | Pubspec Version (`version+build`) | Git Tag | Play Console Track | Status |
| :--- | :--- | :--- | :--- | :--- |
| **Internal Alpha** | `0.1.0+1` | `v0.1.0-alpha.1` | **Internal Testing** | Baseline |
| **Pre-Launch Closed Beta** | `1.0.0+1` | `v0.2.0` | **Closed Testing (20 Testers / 14 Days)** | ⚙️ **Active in Codebase (`mobile/pubspec.yaml`)** |
| **Production MVP 1.0.0** | `1.0.0+X` | `v1.0.0` | **Production Track** | 🎯 Ready for Store Compliance & Build |

---

## 🚀 MVP 1.0.0 Feature Implementation Matrix

| Priority | Feature Scope | Policy / Core Objective | Status |
| :---: | :--- | :--- | :---: |
| 1️⃣ | **In-App Account Deletion** | Mandatory Google Play Policy | ✅ **COMPLETED** (`86a1412`) |
| 2️⃣ | **Post-Match Player Confirmation & Dispute** | Core Trust & ELO Rating System | ✅ **COMPLETED** (`971ea99`, `3eebc0b`) |
| 3️⃣ | **QR Code / 6-Digit PIN Match Join** | Court UX & Quick Lobby Join | ✅ **COMPLETED** (`440f225`) |
| 4️⃣ | **Mobile Push Notifications (FCM)** | Off-App Invites & User Retention | ✅ **COMPLETED** (Hardware Verified) |
| 5️⃣ | **Network Disconnection & Signal Banner** | Outdoor Sports Court Resilience | ✅ **COMPLETED** |
| 6️⃣ | **Post-Match Victory Card / Flex Your ELO Share** | Viral Growth & Social Media Image Sharing | ✅ **COMPLETED** |
| 7️⃣ | **Find Nearby Players & Courts Map (UI Teaser)** | UX Teaser & Future Feature Preview | ✅ **COMPLETED** (Bento Netflix Teasers) |

---

## 🤖 Google Play Store 100% Readiness Checklist

### 1. Mandatory Store Policy & External URLs
- [x] **In-App Account Deletion:** Functional in `account_settings_screen.dart` calling `DELETE /auth/me`.
- [x] **External Account Deletion URL:** Public web route `/delete-account` served directly on backend server allowing web-based deletion requests without having the app installed (Mandatory Google Play Policy).
- [x] **Hosted Privacy Policy URL:** Public web route `/privacy-policy` served directly on backend server declaring data collection:
  - Account info (Email, Display Name)
  - Sports gameplay (Match scores, ELO ratings)
  - Device/Identifiers (FCM Push Notification tokens)
- [ ] **Data Safety Questionnaire:** Completed in Google Play Console with declarations matching the privacy policy.
- [ ] **Target API Level:** `targetSdkVersion 34` (Android 14) configured in `android/app/build.gradle`.

### 2. Android Release Signing Keystore
- [ ] **Generate Keystore:** Create `upload-keystore.jks` using `keytool`.
- [ ] **Configure Properties:** Populate `android/key.properties` (never commit keys to public VCS).
- [ ] **Build Rule:** Verify `android/app/build.gradle` references `key.properties` for `signingConfigs.release`.

### 3. Google Play Testing Tracks & The 20-Tester Rule
- [ ] **Internal Testing Track (Day 0):**
  - Instant deployment to up to 100 internal testers (no Google review required).
  - Used for developer & team sanity checks on real hardware.
- [ ] **Closed Testing Track (Mandatory 20 Testers / 14 Days):**
  - *Google Requirement:* Personal developer accounts registered after Nov 13, 2023 must have **at least 20 testers opted in continuously for 14 days** before applying for Production access.
  - Set up Google Group or email list with 20+ testers.
  - Distribute closed testing link via Play Console.
  - Testers must remain opted-in for 14 continuous days with active app feedback.
- [ ] **Production Track Promotion:** Apply for production access in Play Console after completing the 14-day closed test.

---

## 🛠️ Build & Verification Commands

```powershell
# 1. Run Layout Overflow & Automated Regression Suite
cd mobile
flutter test test/responsive_280x520_overflow_test.dart

# 2. Build Android Release APK
flutter build apk --release

# 3. Build Android App Bundle (.aab) for Google Play
flutter build aab --release --build-number=1 --build-name=1.0.0
```
