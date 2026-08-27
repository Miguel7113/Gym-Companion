# Workouts Feature

## Overview
The workouts feature allows users to track their gym sessions, log exercise sets, and view progress over time. It includes exercise selection, session management, set entry, and progress visualization.

## Components

### Data (`lib/features/workouts/data/exercise_seed_data.dart`)
- **ExerciseSeedData**: Contains 50+ common exercises across categories
- Categories: Chest, Back, Legs, Shoulders, Arms, Core, Cardio
- Used as fallback when backend is unavailable

### Models (`lib/features/workouts/models/workout_models.dart`)
- **Exercise**: Exercise model (id, name, category, isCustom, createdByUserId)
- **WorkoutSet**: Set model (id, sessionId, exerciseId, setNumber, reps, weightKg, rpe, exercise)
- **WorkoutSession**: Session model (id, userId, gymId, startedAt, endedAt, notes, sets)
- **CreateExerciseDto**: DTO for creating custom exercises
- **CreateSessionDto**: DTO for creating workout sessions
- **UpdateSessionDto**: DTO for updating sessions (notes, ended flag)
- **CreateSetDto**: DTO for adding sets (exerciseId, setNumber, reps, weightKg, rpe)
- **ProgressData**: Progress data point (date, reps, weightKg, rpe)

### Service (`lib/features/workouts/services/workout_service.dart`)
- **listExercises()**: Fetches exercises from backend, combines with seed data
- **createExercise()**: Creates custom exercises
- **createSession()**: Creates new workout session
- **updateSession()**: Updates session notes or ends session
- **deleteSession()**: Deletes workout session
- **addSet()**: Adds set to session
- **updateSet()**: Updates existing set
- **deleteSet()**: Deletes set from session
- **listSessions()**: Fetches user's workout history
- **getProgress()**: Fetches progress data for specific exercise
- **getSeedExercises()**: Returns seed exercises for offline use

### Screens

#### Workouts Screen (`workouts_screen.dart`)
- Main entry point for workouts feature
- Two buttons: "Start Workout" and "Progress"
- Displays recent workouts via WorkoutHistoryScreen

#### Workout Session Screen (`workout_session_screen.dart`)
- **New Session Mode**: Allows starting a new workout with optional notes
- **Active Session Mode**: 
  - Displays session info (start time, notes)
  - Add sets with exercise selection, weight, reps, RPE
  - View all sets in session
  - Delete individual sets
  - End session button
- Auto-increments set number after adding a set

#### Exercise List Screen (`exercise_list_screen.dart`)
- Searchable list of exercises
- Groups exercises by category
- Combines backend exercises with seed data
- Shows custom exercises with person icon
- Handles backend errors gracefully with fallback to seed data

#### Workout History Screen (`workout_history_screen.dart`)
- Displays list of past workout sessions
- Shows date, time, notes, set count, duration
- Pull-to-refresh support
- Delete sessions with confirmation dialog
- Tap to view/edit session details
- Empty state when no workouts exist

#### Progress Screen (`progress_screen.dart`)
- Select exercise to view progress
- Line chart showing weight progression over time
- Uses fl_chart for visualization
- Shows dates on x-axis, weight on y-axis
- Requires at least 2 data points to display chart
- Handles empty data gracefully

## API Endpoints Used
- `GET /workouts/exercises` - List exercises (optional query param `q` for search)
- `POST /workouts/exercises` - Create custom exercise
- `POST /workouts/sessions` - Create workout session
- `PUT /workouts/sessions/:id` - Update workout session
- `DELETE /workouts/sessions/:id` - Delete workout session
- `POST /workouts/sessions/:id/sets` - Add set to session
- `PUT /workouts/sets/:id` - Update set
- `DELETE /workouts/sets/:id` - Delete set
- `GET /workouts/sessions` - List user's sessions (limit, offset params)
- `GET /workouts/progress/:exerciseId` - Get progress data for exercise

## Flow
1. User taps "Start Workout" → Workout Session Screen (new mode)
2. User enters notes and starts session → Workout Session Screen (active mode)
3. User selects exercise → Exercise List Screen
4. User selects exercise → Returns to session screen
5. User enters set details (weight, reps, RPE) → Add set
6. Repeat steps 3-5 for multiple exercises
7. User taps "End Session" → Session marked as complete
8. User can view history in Workout History Screen
9. User can view progress in Progress Screen

## State Management
- Uses Riverpod providers for dependency injection
- WorkoutService provides all workout-related operations
- Local state in screens for UI-specific data

## Error Handling
- Network errors displayed with retry option
- Backend failures fall back to seed exercises
- Invalid set data shows validation errors
- Delete operations require confirmation

## Offline Support
- Seed exercises available when backend is offline
- Graceful degradation when API calls fail
- User can still select exercises and plan workouts

## Progress Tracking
- Charts weight progression over time
- Shows date labels on x-axis
- Shows weight values on y-axis
- Automatically scales based on data range
- Requires backend data for visualization
