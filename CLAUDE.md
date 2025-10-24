# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Cross-platform mobile application (iOS/Android) for streaming Islamic audio lessons with integrated testing system. Built with Flutter for the frontend and FastAPI for the backend API.

**Tech Stack:**
- **Frontend:** Flutter 3.x, Dart 3.x, Riverpod (state management), just_audio + audio_service (audio playback)
- **Backend:** FastAPI, SQLAlchemy 2.0, Pydantic, asyncpg
- **Database:** PostgreSQL 15
- **Cache:** Redis 7.x (API responses, sessions)
- **Auth:** JWT tokens (access: 1 hour, refresh: 7 days)

## Architecture

### Dual-Stack Structure

This is a **two-part application**:

1. **`mobile_app/`** - Flutter frontend (iOS/Android)
2. **`backend/`** - FastAPI REST API server

### Database Model

The PostgreSQL schema defines the following key relationships:

- **Content hierarchy:** themes → books (by book_authors) → lesson_series (by lesson_teachers) → lessons
- **User data:** Users authenticate with email/password, stored with hashed passwords
- **Tests:** Linked to lesson_series, with test_questions and test_attempts tracking user progress
- **Bookmarks:** Max 20 per user, unique per user/lesson combination

**Critical CASCADE rules:**
- Deleting a lesson_series is **RESTRICTED** if it has lessons or tests
- Deleting a user **CASCADES** to all their bookmarks, test_attempts, feedbacks
- Deleting a lesson **CASCADES** to bookmarks and test_questions
- Theme/BookAuthor/Book deletions **SET NULL** on related records

### Redis Caching Strategy

Redis is used for performance with two separate databases:
- **DB 0:** API response cache (themes, teachers, series, lessons metadata)
- **DB 1:** JWT sessions

**Cache TTL:**
- Themes/Teachers: 3600s (1 hour)
- Series/Lessons: 1800s (30 minutes)

Cache is invalidated when admins modify data through the admin panel or backend. Do NOT cache: user personal data, audio files, or JWT tokens in the API cache.

### Audio Streaming

Audio files are served via FastAPI with **Range request support** (HTTP 206 Partial Content) to enable seeking and background playback. Files are stored in the `audio_files/` directory on the server.

## Common Commands

### Backend (FastAPI)

Assuming standard Python FastAPI setup in `backend/`:

```bash
# Install dependencies
pip install -r requirements.txt

# Run development server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Run with Docker Compose (includes PostgreSQL and Redis)
docker-compose up -d
```

### Frontend (Flutter)

Assuming standard Flutter setup in `mobile_app/`:

```bash
# Install dependencies
flutter pub get

# Run on iOS simulator
flutter run -d ios

# Run on Android emulator
flutter run -d android

# Build for production
flutter build ios --release
flutter build apk --release

# Run tests
flutter test

# Analyze code
flutter analyze
```

## Key Implementation Notes

### Authentication Flow

1. User registers via `POST /api/auth/register` with email/password
2. Login returns JWT access_token + refresh_token
3. Mobile app stores tokens in secure storage
4. All API requests include `Authorization: Bearer {access_token}` header
5. Token auto-refresh when expired

### API Response Structure

Lessons API includes nested relationship data to minimize round-trips:

```json
{
  "id": 1,
  "title": "auto_generated_title",
  "display_title": "Урок 1",
  "duration_seconds": 2258,
  "audio_url": "/api/lessons/1/audio",
  "series": { "id": 5, "name": "...", "year": 2025 },
  "teacher": { "id": 2, "name": "..." },
  "book": { "id": 3, "name": "..." },
  "theme": { "id": 1, "name": "..." }
}
```

### Flutter State Management

Use **Riverpod** for state management. Key providers needed:
- `authProvider` - JWT tokens, current user
- `lessonsProvider` - Lessons list with filters
- `playerProvider` - Audio player state (position, playing, playlist)
- `bookmarksProvider` - User bookmarks (max 20)

### Audio Player Requirements

- Background playback via `audio_service`
- Lock screen controls
- Playback speed (0.5x - 2x)
- Auto-advance to next lesson in series
- Sleep timer
- Seek bar with Range requests to backend

### Testing System

Tests are linked to `lesson_series`. Flow:
1. Start test: `POST /api/tests/{id}/start` creates a `test_attempt`
2. User answers questions (timer enforced client-side)
3. Complete test: `POST /api/tests/attempts/{id}/complete` calculates score
4. `passed` is true if `score / max_score >= passing_score` percentage
5. Users can retake tests unlimited times

### Offline Mode (Optional)

Use **Hive** or **sqflite** to cache:
- Themes, teachers, series metadata
- User's bookmarks
- Optionally: downloaded audio files

Sync on network reconnection.

## File Naming Conventions

**Lessons:** Auto-generated titles follow pattern:
```
{teacher_name}_{book_name}_{year}_{series_name}_урок_{N}
```

Display to users as: "Урок {lesson_number}"

## Environment Configuration

Backend requires `.env` file:
```env
DATABASE_URL=postgresql+asyncpg://user:pass@localhost/audio_bot
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_CACHE_DB=0
REDIS_SESSION_DB=1
REDIS_PASSWORD=your_password
JWT_SECRET=your_secret
```

Mobile app requires `lib/config/api_config.dart`:
```dart
const String API_BASE_URL = "https://api.example.com";
```

## MVP Priority

**Must have (P1):**
- Registration/Login
- Browse themes, teachers, series, lessons
- Audio player with background playback
- Bookmarks
- Basic search

**Should have (P2):**
- Testing system
- Listening history
- Feedback/support

**Nice to have (P3):**
- Offline mode
- Social features (comments, ratings)
- Statistics dashboard
