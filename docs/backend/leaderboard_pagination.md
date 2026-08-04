# Leaderboard Pagination & Large Dataset Specification

This document details the architectural approach for paginating and lazy loading large datasets (1,000+ to 100,000+ users) in the **Pulse** platform.

---

## 🎯 Architecture Overview

When scaling to thousands of ranked players, returning all users in a single HTTP payload leads to memory bloat, high latency, and mobile frame drops. Pulse implements **Indexed Offset Pagination** on the backend and **Lazy Loading (Infinite Scroll)** on the Flutter frontend.

```text
Flutter App (Client)                  Node.js Backend                       PostgreSQL DB
      │                                     │                                     │
      ├─── GET /leaderboard?limit=50&offset=0 ──>│                                     │
      │                                     ├─── SQL Query (Indexed ORDER BY) ──>│
      │                                     │<── Top 50 Rows + Metadata ──────────│
      │<── { entries, hasMore, limit... } ──┤                                     │
      │                                     │                                     │
[User Scrolls Near Bottom]                  │                                     │
      │                                     │                                     │
      ├─── GET /leaderboard?limit=50&offset=50 ─>│                                     │
      │                                     ├─── SQL Query (Offset 50) ──────────>│
      │                                     │<── Ranks #51 - #100 ────────────────│
      │<── Appends to Vertical List ────────┤                                     │
```

---

## ⚙️ Backend Implementation

### 1. Database Indexing
All ranking queries are backed by compound SQL database indexes defined in Knex migration `20260804_add_leaderboard_indexes.ts`:

- `idx_user_sport_rating`: `(sport, rating DESC)`
- `idx_user_sport_wins_losses`: `(sport, wins DESC, losses ASC)`
- `idx_user_sport_stats_global_wins`: `(wins DESC, losses ASC)`

### 2. Service & Repository Layer
- **Limit & Offset Parameters**:
  - `limit`: Default `50` (capped at maximum `100`).
  - `offset`: Starting index (e.g. `0` for Page 1, `50` for Page 2).
- **Metadata Returned**:
  - `hasMore`: `boolean` indicating if additional pages are available (`entries.length === limit`).
  - `currentUserEntry`: Always returns the authenticated user's exact overall rank and metrics, pinned independently of the current offset page.

```typescript
// GET /api/v1/leaderboard?sport=pickleball&category=elo&limit=50&offset=0
{
  "message": "Leaderboard fetched successfully",
  "data": {
    "entries": [ ... ], // 50 items
    "currentUserEntry": { "rank": 14, "name": "You", ... },
    "sport": "pickleball",
    "category": "elo",
    "hasMore": true,
    "limit": 50,
    "offset": 0
  }
}
```

---

## 📱 Mobile Frontend Implementation

### 1. Lazy Loading Listener
`RankingsScreen` uses a `ScrollController` listener that monitors scroll depth:

```dart
void _onScroll() {
  if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
    if (!_isLoadingMore && _hasMore && !_isLoading) {
      _loadMoreEntries();
    }
  }
}
```

### 2. State & Append Workflow
- **Initial Load (`offset = 0`, `limit = 50`)**: Renders top 3 in podium cards and top 4–50 in the vertical list.
- **Scroll Threshold Hit**: Triggered when the user reaches within 200px of the bottom. Fetches `offset = 50, limit = 50` and appends `response.entries` to `_entries`.
- **UI Footer**: Displays a subtle circular loading spinner while appending data.

---

## 🛑 Best Practices & Anti-Patterns Avoided

| Strategy | Why Pulse Follows This |
| :--- | :--- |
| **Database Indexing** | Avoids full table scans on PostgreSQL. Query runs in `< 25ms` even with 100k rows. |
| **Fixed Page Batches (50 items)** | Keeps mobile RAM footprint lightweight and network payload ~5KB. |
| **No Client-side Sorting** | Sorting is delegated entirely to SQL indexes (`ORDER BY rating DESC`) before reaching Flutter. |
