# Pulse MVP

## Vision

Pulse is a mobile app that turns casual sports into verified competitive matches.

Supported sports (MVP):
- Pickleball
- Table Tennis
- Tennis
- Badminton (future-ready)

The core idea is that every ranked match is verified by a neutral scorer/referee.

---

# Core Roles

## Player
- Create account
- Join a match
- View live score
- View results
- View rankings

Players cannot edit scores.

## Scorer (Referee)
- Accept invitation
- Start match
- Record points
- Undo mistakes
- End match
- Submit winner

## Role & Authorization Model (Contextual Roles)

- **No Static Account Roles**: Every account in Pulse is a generic **User**. There are no separate "Player" or "Scorer" user account types in the database.
- **Dynamic Per-Match Roles**: A user can participate as a **Player** in Match A, and be invited to officiate as the **Scorer** in Match B.
- **Contextual Authorization**: Authorization checks (e.g., verifying who can record points) are enforced at the resource level by comparing the authenticated user's ID (`req.user.id`) against the match assignment (`match.scorer_id`).

---


# MVP Match Flow

### Singles Match Flow (1v1)
1. Player A creates a singles match.
2. Invite Player B (Opponent).
3. Invite a Scorer (Referee).
4. Everyone joins and marks Ready.
5. Scorer starts the match.
6. Scorer records live score events.
7. Node.js saves the score events to PostgreSQL and Socket.IO broadcasts updates.
8. Players see the live scoreboard instantly.
9. Match finishes and players confirm the outcome.
10. ELO rankings update.

### Doubles Match Flow (2v2)
1. Player A creates a doubles match (Team 1).
2. Invite Team 1 Partner, Player B (Opponent / Team 2), and Team 2 Partner.
3. Invite a Scorer (Referee).
4. All 4 players and the referee accept invitations and room marks Ready.
5. Scorer starts the match and records live points.
6. Score events are broadcast live to all 4 participants in real-time.
7. Match concludes with winner declaration.
8. ELO updates using team average ratings (+/- rating change applied to winning and losing team members with a 100-rating floor).


---

# Why a Scorer?

A neutral scorer provides trust.

Benefits:
- Fewer disputes
- Verified results
- Fair rankings
- Better tournament support

---

# Recommended Tech Stack

## Mobile
- Flutter
- Dart

## Backend
- Node.js
- TypeScript
- Express.js
- Socket.IO
- JWT Authentication
- bcrypt

## Database
- PostgreSQL
- Knex.js (SQL Query Builder)
- Knex Migrations & Seeds

## Local Storage
- Drift (SQLite)

Use Drift only as an offline cache.

PostgreSQL remains the source of truth.

---

# Architecture

```text
Flutter App
(Player A / Player B / Scorer)
            │
       REST API (HTTPS)
            │
 Node.js + Express + Socket.IO
            │
       Knex.js
            │
       PostgreSQL
            │
 Drift (Offline Cache)
```

---

# Why Not SQLite Alone?

SQLite is local to a device and cannot synchronize data between players.

Realtime synchronization is handled by Socket.IO through the Node.js backend.

---

# Realtime Flow

```text
Scorer
   │
Records Point
   │
Node.js
   │
Knex.js
   │
PostgreSQL
   │
Socket.IO Broadcast
 ┌─────────────┐
 │             │
Player A   Player B
```

---

# Event-Based Scoring

Store every scoring action instead of only the latest score.

Examples:
- PLAYER1_POINT
- PLAYER2_POINT
- UNDO
- END_SET
- END_MATCH

Benefits:
- Undo support
- Audit history
- Match replay
- Statistics
- Easier dispute resolution

---

# Database (Simplified)

## users
- id
- name
- email
- rating
- wins
- losses

## matches
- id
- player1_id
- player2_id
- scorer_id
- status
- winner_id
- created_at
- finished_at

## score_events
- id
- match_id
- event_type
- player_id
- created_at

---

# Match States

- WAITING
- READY
- LIVE (Currently in match)
- FINISHED
- CONFIRMED

---

# Future Features

- Friends
- Clubs
- Leaderboards
- Tournaments
- Seasons
- Elo Rating
- Push Notifications
- Match Statistics
- QR Code Match Join
- AI-assisted officiating

---

# MVP Goal

Validate that players enjoy verified competitive matches with live scoring before investing in advanced features.


---

# Backend Architecture

Pulse uses a **Layered Architecture (Controller → Service → Repository)** instead of a traditional MVC architecture.

## Why?

As the application grows with features like tournaments, rankings, statistics, and live scoring, separating responsibilities keeps the codebase maintainable and testable.

```text
Client Request
      │
      ▼
Controller
      │
      ▼
Service
      │
      ▼
Repository
      │
      ▼
Knex.js
      │
      ▼
PostgreSQL
```

## Layer Responsibilities

### Controllers
- Receive HTTP requests
- Validate request data
- Call the appropriate service
- Return HTTP responses

### Services
- Contains all business logic
- Validates match rules
- Handles scoring logic
- Updates rankings
- Coordinates multiple repositories

### Repositories
- Responsible only for database access
- Uses Knex.js to execute SQL queries
- No business logic

### Socket.IO

Realtime events reuse the same service layer.

```text
Socket.IO Event
      │
      ▼
Socket Handler
      │
      ▼
MatchService
      │
      ▼
MatchRepository
      │
      ▼
Knex.js
      │
      ▼
PostgreSQL
```

## Recommended Backend Structure

```text
src/
├── config/
├── controllers/
├── routes/
├── middleware/
├── services/
├── repositories/
├── sockets/
├── database/
│   ├── migrations/
│   ├── seeds/
│   ├── knexfile.ts
│   └── db.ts
├── utils/
├── types/
├── app.ts
└── server.ts
```

---

## Build Instructions

### Mobile (Android)
```bash
# Build Android Release APK
cd mobile
flutter build apk --release

# Build Android App Bundle (Play Store)
flutter build aab --release
```

