# Gym Companion Mobile App - File Structure

## Project Root
```
gym_app_mobile/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── core/                        # Core architecture
│   │   ├── api_client.dart          # HTTP client with auth interceptors
│   │   ├── providers/
│   │   │   └── api_provider.dart   # Riverpod provider for ApiClient
│   │   ├── theme/
│   │   │   └── app_theme.dart      # Light/dark theme definitions
│   │   └── navigation/
│   │       └── main_navigation.dart # Bottom navigation bar
│   └── features/                    # Feature modules
│       ├── auth/                    # Authentication
│       │   ├── models/
│       │   │   └── auth_models.dart # Auth DTOs and response models
│       │   ├── services/
│       │   │   └── auth_service.dart # Auth API integration
│       │   └── screens/
│       │       ├── gym_selection_screen.dart
│       │       ├── otp_request_screen.dart
│       │       └── otp_verification_screen.dart
│       ├── workouts/                # Workout tracking
│       │   ├── data/
│       │   │   └── exercise_seed_data.dart # Common exercises
│       │   ├── models/
│       │   │   └── workout_models.dart # Workout DTOs and models
│       │   ├── services/
│       │   │   └── workout_service.dart # Workout API integration
│       │   └── screens/
│       │       ├── workouts_screen.dart
│       │       ├── workout_session_screen.dart
│       │       ├── workout_history_screen.dart
│       │       ├── exercise_list_screen.dart
│       │       └── progress_screen.dart
│       ├── food/                    # Food tracking (placeholder)
│       │   └── screens/
│       │       └── food_screen.dart
│       ├── profile/                 # User profile (placeholder)
│       │   └── screens/
│       │       └── profile_screen.dart
│       └── home/                    # Home screen (placeholder)
│           └── screens/
│               └── home_screen.dart
├── docs/                            # Documentation
│   ├── dependencies.md
│   ├── file-structure.md
│   ├── auth-feature.md
│   └── workouts-feature.md
├── pubspec.yaml                     # Dependencies
└── test/                            # Tests
```

## Architecture Patterns

### Feature-Based Structure
Each feature is self-contained with its own:
- **Models**: Data transfer objects and domain models
- **Services**: API integration and business logic
- **Screens**: UI components

### State Management
- **Riverpod**: Used for dependency injection and state management
- **Providers**: Located in `core/providers/` for shared services
- **Feature Providers**: Located in each feature's `services/` directory

### API Communication
- **ApiClient**: Centralized HTTP client in `core/api_client.dart`
- **Dio**: HTTP library with interceptors for JWT authentication
- **Services**: Each feature has a service class wrapping API calls

### Navigation
- **Named Routes**: Defined in `main.dart`
- **Bottom Navigation**: Main navigation in `core/navigation/main_navigation.dart`
- **Screen Navigation**: Imperative navigation using `Navigator.push()`
