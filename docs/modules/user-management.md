# User & Authentication Module Specification

## 1. Purpose
The User & Authentication module handles user account creation, credentials verification, JWT issuance, and user profile management for both Players and Scorers.

---

## 2. API Contracts & Endpoints

### 🟢 `POST /api/v1/auth/register`
Creates a new user account and returns a JWT token.

- **Request Body**:
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123"
}
```

- **Response `201 Created`**:
```json
{
  "message": "User registered successfully",
  "data": {
    "user": {
      "id": "uuid-v4-string",
      "name": "John Doe",
      "email": "john@example.com",
      "rating": 1200,
      "wins": 0,
      "losses": 0,
      "created_at": "2026-07-23T15:30:00.000Z",
      "updated_at": "2026-07-23T15:30:00.000Z"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI..."
  }
}
```

---

### 🔵 `POST /api/v1/auth/login`
Authenticates an existing user and returns a JWT token.

- **Request Body**:
```json
{
  "email": "john@example.com",
  "password": "password123"
}
```

- **Response `200 OK`**:
```json
{
  "message": "Login successful",
  "data": {
    "user": { ... },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI..."
  }
}
```

---

## 3. Database Schema (`users`)
- `id`: UUID (Primary Key)
- `name`: VARCHAR
- `email`: VARCHAR (Unique)
- `password_hash`: VARCHAR
- `rating`: INT (Default: 1200)
- `wins`: INT (Default: 0)
- `losses`: INT (Default: 0)
- `created_at` / `updated_at`: TIMESTAMPTZ
