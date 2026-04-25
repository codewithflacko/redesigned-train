# 🚌 MagicBusRoute

A school bus tracking app for parents, drivers, dispatch, and admins — built with **SwiftUI** and a **Python FastAPI** security backend powered by **Claude AI**.

---

## 📁 Project Structure

```
MagicBusRoute/
├── 🗄️  Backend/          # Python FastAPI backend
├── 🔒  Security/         # iOS security layer
├── 📱  Views/            # SwiftUI views (Admin, Driver, Parent, Dispatch)
├── 🧩  Models/           # Shared data models
└── 🛠️  Utilities/        # AppState, NotificationManager
```

---

## ✅ Requirements

### 📱 iOS App
- Xcode 15+
- iOS 17+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`

### 🖥️ Backend
- Python 3.10+
- pip

---

## 🚀 Setup & Run

### 1️⃣ Backend

Install dependencies:
```bash
cd Backend
pip install -r requirements.txt
```

Start the server:
```bash
python3 -m uvicorn main:app --reload --host 127.0.0.1 --port 8000
```

The server runs at `http://127.0.0.1:8000`. A SQLite database (`mbr_security.db`) is created automatically on first run.

To enable Claude AI threat classification, pass your Anthropic API key:
```bash
ANTHROPIC_API_KEY=sk-... python3 -m uvicorn main:app --reload --host 127.0.0.1 --port 8000
```

> Without the key, the backend falls back to rule-based threat detection.

---

### 2️⃣ iOS App

Generate the Xcode project:
```bash
cd /path/to/MagicBusRoute
xcodegen generate
```

Open in Xcode:
```bash
open MagicBusRoute.xcodeproj
```

Select the `MagicBusRoute` scheme and run on a simulator or device.

> ⚠️ **Start the backend before launching the app or login will fail.**

---

## 🔑 Demo Credentials

| Role       | Email               |
|------------|---------------------|
| 👨‍💼 Admin    | admin@mbr.edu       |
| 👩‍👧 Parent   | parent@mbr.edu      |
| 🚌 Driver   | driver@mbr.edu      |
| 📡 Dispatch | dispatch@mbr.edu    |

> 🔒 Passwords are not included here for security. Contact the project owner for access.

---

## 🛡️ Security Features

### 📱 iOS
| Feature | Description |
|---|---|
| 🔍 Jailbreak detection | Checks file paths, sandbox escape, and Cydia URL scheme on launch |
| 📌 Certificate pinning | SHA-256 public key pinning on all network calls — MITM attempts reported as security events |
| 👤 Biometric re-auth | FaceID/TouchID required when app returns from background |
| 🙈 Screenshot prevention | Black overlay covers app in the iOS switcher to prevent data exposure |
| ⏱️ Session timeout | Auto-logout after 30 minutes of inactivity |
| 🔐 Keychain storage | JWT stored in iOS Keychain, never UserDefaults |

### 🖥️ Backend
| Feature | Description |
|---|---|
| 🎟️ JWT authentication | 8-hour tokens with HS256, JTI claim for revocation |
| 🚫 Token revocation | Logout immediately invalidates the JWT — persisted to SQLite |
| 🔒 Account lockout | 5 failed logins triggers a 15-minute lockout |
| 🚦 Rate limiting | 15 req/min on login, 60 req/min on event ingest |
| 🧱 Security headers | X-Content-Type-Options, X-Frame-Options, X-XSS-Protection on every response |
| 🤖 Claude threat detection | AI classifies security events by severity (CRITICAL → INFO) with COPPA/FERPA awareness |
| 💾 SQLite persistence | Events, threats, audit log, and revoked tokens survive server restarts |
| 📊 Admin dashboard | Live threat feed, stats, Claude-generated security report, full audit trail |

---

## 🌐 API Endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/auth/login` | — | 🔓 Login, returns JWT |
| POST | `/auth/logout` | 🔑 Bearer | 🚪 Logout + revoke token |
| POST | `/security/event` | 🔑 Bearer | 📨 Report security event from iOS |
| GET | `/security/threats` | 👨‍💼 Admin | ⚠️ Active threat list |
| PATCH | `/security/threats/{id}/dismiss` | 👨‍💼 Admin | ✅ Resolve a threat |
| GET | `/security/stats` | 👨‍💼 Admin | 📈 Threat counts by severity |
| GET | `/security/report` | 👨‍💼 Admin | 🤖 Claude-generated security report |
| GET | `/security/audit` | 👨‍💼 Admin | 📋 Full audit log |
| GET | `/health` | — | 💚 Health check |

> 📖 Interactive docs available at `http://127.0.0.1:8000/docs` while the server is running.
