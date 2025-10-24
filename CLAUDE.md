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

### Backend Structure

```
backend/
├── app/
│   ├── api/              # FastAPI route handlers
│   │   ├── auth.py       # Authentication endpoints
│   │   ├── lessons.py    # Lesson CRUD + audio streaming
│   │   ├── series.py     # Series management
│   │   ├── themes.py     # Theme management
│   │   ├── teachers.py   # Teacher management
│   │   ├── books.py      # Book management
│   │   └── book_authors.py
│   ├── auth/             # JWT token handling
│   │   ├── jwt.py        # Token creation/verification
│   │   └── dependencies.py # Auth dependencies (get_current_user)
│   ├── crud/             # Database operations
│   │   ├── user.py
│   │   ├── lesson.py
│   │   ├── series.py
│   │   └── ...
│   ├── models/           # SQLAlchemy ORM models
│   │   ├── base.py       # Base model with timestamps
│   │   ├── user.py
│   │   ├── content.py    # Theme, BookAuthor, Book
│   │   ├── lesson.py     # LessonTeacher, LessonSeries, Lesson
│   │   ├── test.py
│   │   ├── bookmark.py
│   │   └── feedback.py
│   ├── schemas/          # Pydantic schemas for request/response
│   │   ├── user.py
│   │   ├── content.py
│   │   └── lesson.py
│   ├── utils/            # Utilities
│   │   └── audio.py      # Audio file utilities
│   ├── config.py         # Settings from environment variables
│   ├── database.py       # SQLAlchemy async setup
│   ├── main.py           # FastAPI app entry point
│   └── seed.py           # Database seeding script
├── alembic/              # Database migrations
│   └── versions/
├── audio_files/          # Audio file storage (not in git)
├── requirements.txt
└── alembic.ini
```

### Database Model

The PostgreSQL schema defines the following key relationships:

- **Content hierarchy:** themes → books (by book_authors) → lesson_series (by lesson_teachers) → lessons
- **User data:** Users authenticate with email/password, stored with hashed passwords
- **Tests:** Linked to lesson_series, with test_questions and test_attempts tracking user progress
- **Bookmarks:** Max 20 per user, unique per user/lesson combination

**Critical CASCADE and CONSTRAINT rules:**
- Deleting a `lesson_series` is **RESTRICTED** if it has lessons or tests
- Deleting a `lesson_teacher` is **RESTRICTED** if they have series
- Deleting a `user` **CASCADES** to all their bookmarks, test_attempts, feedbacks
- Deleting a `lesson` **CASCADES** to bookmarks and test_questions
- Theme/BookAuthor/Book deletions **SET NULL** on related records
- **UNIQUE constraints:**
  - Series: unique per `(year, name, teacher_id)`
  - Lesson: unique `lesson_number` per series
  - Bookmark: unique per `(user_id, lesson_id)`

**Boolean fields with defaults:**
- `is_active` (default: `True`) - All content entities
- `is_completed` (default: `False`) - LessonSeries only

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

Commands run from `backend/` directory:

```bash
# Install dependencies
pip install -r requirements.txt

# Run development server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Database migrations
alembic revision --autogenerate -m "description"  # Create new migration
alembic upgrade head                               # Apply migrations
alembic downgrade -1                               # Rollback one migration
alembic current                                    # Show current migration

# Seed database with test data
python -m app.seed

# Run API tests
python test_api.py
python test_content_api.py
python test_audio_streaming.py
```

### Frontend (Flutter)

Commands run from `mobile_app/` directory:

```bash
# Install dependencies
flutter pub get

# Generate code (models, providers, API client)
flutter pub run build_runner build --delete-conflicting-outputs

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

# Clean build artifacts
flutter clean
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

### Flutter Architecture

The mobile app follows a **layered architecture**:

```
lib/
├── config/           # API configuration and constants
├── core/             # Theme, utilities
├── data/
│   ├── api/          # Retrofit API client, Dio provider
│   └── models/       # JSON-serializable data models
└── presentation/
    ├── providers/    # Riverpod state providers
    └── screens/      # UI screens (auth, admin, themes, etc.)
```

**State Management (Riverpod):**
- `authProvider` - JWT tokens, current user, authentication state
- `themesProvider` - Themes list (cached)
- `teachersProvider` - Teachers list (cached)
- `seriesProvider` - Series list with filters
- `booksProvider` - Books list
- `bookAuthorsProvider` - Book authors list

**Code Generation:**
- Models use `json_serializable` for JSON serialization
- API client uses `retrofit` for type-safe HTTP requests
- Run `flutter pub run build_runner build --delete-conflicting-outputs` after modifying models or API definitions

### Audio Player (Future Implementation)

Audio player with `just_audio` and `audio_service` is not yet implemented. When implementing:

- Background playback via `audio_service`
- Lock screen controls
- Playback speed (0.5x - 2x)
- Auto-advance to next lesson in series
- Sleep timer
- Seek bar with Range requests to backend (`GET /api/lessons/{id}/audio` with Range header)

### Testing System (Future Implementation)

Tests will be linked to `lesson_series`. Planned flow:
1. Start test: `POST /api/tests/{id}/start` creates a `test_attempt`
2. User answers questions (timer enforced client-side)
3. Complete test: `POST /api/tests/attempts/{id}/complete` calculates score
4. `passed` is true if `score / max_score >= passing_score` percentage
5. Users can retake tests unlimited times

Database models exist in `backend/app/models/test.py` but API endpoints not yet implemented.

### Offline Mode (Future Implementation)

Use **Hive** (already in pubspec.yaml) or **sqflite** to cache:
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

### Backend `.env` file

Located in `backend/.env`:

```env
# Database
DATABASE_URL=postgresql+asyncpg://user:pass@localhost/audio_bot

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_CACHE_DB=0
REDIS_SESSION_DB=1
REDIS_PASSWORD=your_password

# JWT
JWT_SECRET_KEY=your_secret_key_here

# Application
DEBUG=True
API_V1_PREFIX=/api
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080

# Audio
AUDIO_FILES_PATH=/app/audio_files
```

### Mobile App Configuration

Update `mobile_app/lib/config/api_config.dart` to point to your backend:

```dart
class ApiConfig {
  static const String baseUrl = 'http://localhost:8000';  // Change for production
  static const String apiPrefix = '/api';
  // ...
}
```

## Current Implementation Status

**Implemented (Backend + Mobile):**
- User registration and authentication (JWT)
- Admin panel screens (themes, books, authors, teachers, series management)
- CRUD operations for all content entities
- Database migrations with Alembic
- Basic Flutter app structure with Riverpod

**Partially Implemented:**
- API endpoints exist but mobile screens incomplete:
  - Lessons browsing
  - User-facing content viewing
  - Audio streaming (backend ready, player not implemented)

**Not Yet Implemented:**
- Audio player with background playback
- Bookmarks system
- Testing system (models exist, no endpoints/UI)
- Search functionality
- Listening history
- Offline mode

## Development Workflow

When working on this codebase:

1. **Backend changes:**
   - Modify models in `backend/app/models/`
   - Update CRUD operations in `backend/app/crud/`
   - Add/modify API endpoints in `backend/app/api/`
   - Create Pydantic schemas in `backend/app/schemas/`
   - Generate migration: `alembic revision --autogenerate -m "description"`
   - Apply migration: `alembic upgrade head`

2. **Mobile changes:**
   - Add/modify models in `mobile_app/lib/data/models/`
   - Update API client in `mobile_app/lib/data/api/api_client.dart`
   - Run code generation: `flutter pub run build_runner build --delete-conflicting-outputs`
   - Create/update providers in `mobile_app/lib/presentation/providers/`
   - Build UI in `mobile_app/lib/presentation/screens/`

3. **Testing:**
   - Backend: Run test scripts in `backend/` directory
   - Mobile: `flutter test` in `mobile_app/` directory
