# TestFlight Backend & Testing Guide

This guide details how to expose your local backend for **TestFlight (iOS)** and external builds using Cloudflare Tunnel.

---

## 🌐 Expose Local Backend via Cloudflare Tunnel

TestFlight builds run on physical devices outside your local network (over cellular or external Wi-Fi). They cannot connect to `localhost` or local network IPs (e.g. `192.168.x.x`). Use Cloudflare Tunnel to expose your local backend server securely via HTTPS.

### Command

```bash
cloudflared tunnel --url http://localhost:5000
```

---

## 📋 Step-by-Step TestFlight Setup

### 1. Start Local Backend
Make sure your backend is running locally on port 5000:
```bash
cd backend
npm run dev
```

### 2. Start Cloudflare Tunnel
Run the tunnel command in a separate terminal:
```bash
cloudflared tunnel --url http://localhost:5000
```
Cloudflare will provide a temporary public HTTPS URL (e.g., `https://random-subdomain.trycloudflare.com`).

### 3. Update Mobile App Base URL
Set `API_BASE_URL` in `mobile/.env` (or pass via Codemagic / CI/CD environment variables):
```env
API_BASE_URL=https://<your-cloudflare-subdomain>.trycloudflare.com/api/v1
```

### 4. Build and Distribute via TestFlight
1. Ensure `GoogleService-Info.plist` is in `mobile/ios/Runner/`.
2. Ensure Apple Push Notification service (APNs) `.p8` key is uploaded in Firebase Console.
3. Build the iOS archive and distribute through App Store Connect / TestFlight.

---

## 🔍 Verification Checklist

- [ ] Backend is running on port 5000.
- [ ] Cloudflare tunnel is active and reachable via browser/curl.
- [ ] TestFlight build is packaged with the active Cloudflare HTTPS URL.
- [ ] On app launch, check backend console logs for `[PATCH /auth/fcm-token] -> 200 OK` to confirm device token registration.
