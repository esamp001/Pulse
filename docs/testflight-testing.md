# TestFlight Backend & Testing Guide

This guide details how to expose your local backend for **TestFlight (iOS)** and external builds using Cloudflare Tunnel.

---

## 🌐 Expose Local Backend via Cloudflare Tunnel

TestFlight builds run on physical devices outside your local network (over cellular or external Wi-Fi). They cannot connect to `localhost` or local network IPs (e.g. `192.168.x.x`). Use Cloudflare Tunnel to expose your local backend server securely via HTTPS.

### Active 24/7 Cloud Backend URL (Oracle Cloud VPS)

The backend runs 24/7 in the cloud with PM2 and Cloudflare Tunnel. For complete deployment steps, see [VPS Deployment & Cloudflare Tunnel Guide](file:///c:/Users/ellejun.sampaga/Documents/Pulse/docs/backend/vps-deployment-and-cloudflare-guide.md).

```env
API_BASE_URL=https://retailers-nuke-unsigned-jaguar.trycloudflare.com/api/v1
```

---

## 📋 Step-by-Step TestFlight Setup

### 1. 24/7 Backend Status
Your backend runs 24/7 on Oracle Cloud VPS. You do NOT need your laptop turned on for TestFlight testers or CI/CD builds.

To inspect backend or tunnel status on the server:
```bash
pm2 status
pm2 logs pulse-backend
```

### 2. Update Mobile App Base URL
Set `API_BASE_URL` in `mobile/.env` (or pass via Codemagic / CI/CD environment variables):
```env
API_BASE_URL=https://retailers-nuke-unsigned-jaguar.trycloudflare.com/api/v1
```

### 3. Build and Distribute via TestFlight
1. Ensure `GoogleService-Info.plist` is in `mobile/ios/Runner/`.
2. Ensure Apple Push Notification service (APNs) `.p8` key is uploaded in Firebase Console.
3. Build the iOS archive and distribute through App Store Connect / TestFlight.

---

## 🔍 Verification Checklist

- [ ] Backend is running on port 5000.
- [ ] Cloudflare tunnel is active and reachable via browser/curl.
- [ ] TestFlight build is packaged with the active Cloudflare HTTPS URL.
- [ ] On app launch, check backend console logs for `[PATCH /auth/fcm-token] -> 200 OK` to confirm device token registration.
