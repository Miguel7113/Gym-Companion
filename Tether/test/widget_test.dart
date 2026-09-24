import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gym_app_mobile/core/widgets/cached_media.dart';
import 'package:gym_app_mobile/main.dart';
import 'package:gym_app_mobile/features/auth/providers/auth_provider.dart';
import 'package:gym_app_mobile/features/workouts/models/workout_models.dart';
import 'package:gym_app_mobile/features/workouts/screens/workout_session_screen.dart';
import 'package:gym_app_mobile/features/workouts/screens/workout_detail_screen.dart';

void main() {
  testWidgets('app boots inside its required provider scope', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateStreamProvider.overrideWith(
            (ref) => const Stream<Never>.empty(),
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(MyApp), findsOneWidget);
  });

  testWidgets('active workout keeps finish actions and expands exercise sets', (
    WidgetTester tester,
  ) async {
    final exercise = Exercise(id: 'bench', name: 'Bench Press');
    final session = WorkoutSession(
      id: 'session',
      userId: 'user',
      gymId: 'gym',
      startedAt: DateTime.now().subtract(const Duration(minutes: 4)),
      sets: [
        WorkoutSet(
          id: 'set',
          sessionId: 'session',
          exerciseId: exercise.id,
          setNumber: 1,
          weightKg: 60,
          reps: 8,
          exercise: exercise,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: WorkoutSessionScreen(session: session)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Finish'), findsOneWidget);
    expect(find.text('Log workout'), findsOneWidget);
    expect(find.text('Previous'), findsOneWidget);

    await tester.tap(find.text('Bench Press'));
    await tester.pumpAndSettle();
    expect(find.text('How To'), findsOneWidget);
  });

  testWidgets('completed workout keeps a fixed duration and is read-only', (
    WidgetTester tester,
  ) async {
    final startedAt = DateTime.now().subtract(const Duration(minutes: 12));
    final session = WorkoutSession(
      id: 'completed-session',
      userId: 'user',
      gymId: 'gym',
      startedAt: startedAt,
      endedAt: startedAt.add(const Duration(minutes: 3, seconds: 14)),
      sets: const [],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: WorkoutSessionScreen(session: session)),
      ),
    );
    await tester.pump();

    expect(find.text('3min 14s'), findsOneWidget);
    expect(find.text('Finish'), findsNothing);

    await tester.pump(const Duration(seconds: 2));
    expect(find.text('3min 14s'), findsOneWidget);
  });

  testWidgets('cached media renders an offline fallback without a URL', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 120,
          height: 80,
          child: AppCachedImage(url: null),
        ),
      ),
    );

    expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
  });

  testWidgets('save workout screen shows summary and optional gym sharing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: WorkoutCompleteScreen(
            sessionId: 'session',
            duration: const Duration(minutes: 42),
            totalSets: 12,
            exerciseCount: 4,
            prCount: 1,
            totalVolume: 1250,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Save Workout'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);
    expect(find.text('Share with Gym'), findsOneWidget);
    expect(find.text('Skip & Finish'), findsOneWidget);
  });

  testWidgets('manual workout detail renders summary and exercise list', (
    WidgetTester tester,
  ) async {
    final exercise = Exercise(id: 'squat', name: 'Squat');
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: WorkoutDetailScreen(
            session: WorkoutSession(
              id: 'session',
              userId: 'user',
              gymId: 'gym',
              startedAt: DateTime(2026, 8, 31, 18),
              endedAt: DateTime(2026, 8, 31, 19),
              sets: [
                WorkoutSet(
                  id: 'set',
                  sessionId: 'session',
                  exerciseId: exercise.id,
                  reps: 8,
                  weightKg: 80,
                  exercise: exercise,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Duration'), findsOneWidget);
    expect(find.text('Exercises'), findsWidgets);
    expect(find.text('Squat'), findsOneWidget);
  });
}
