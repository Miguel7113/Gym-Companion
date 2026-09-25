import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gym_app_mobile/features/workouts/models/workout_models.dart';
import 'package:gym_app_mobile/features/workouts/widgets/hevy_exercise_card.dart';

void main() {
  final exercise = Exercise(id: 'bench', name: 'Bench Press');
  const logged = LoggedSetEntry(id: 'set-1', setNumber: 1, weightKg: 60, reps: 8);

  Future<void> pumpCard(
    WidgetTester tester, {
    List<LoggedSetEntry> loggedSets = const [logged],
    List<DraftSetEntry>? draftSets,
    CompleteDraftCallback? onCompleteDraft,
    ValueChanged<LoggedSetEntry>? onUncompleteSet,
    VoidCallback? onRemoveExercise,
    ValueChanged<String>? onNotesChanged,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: HevyExerciseCard(
              exercise: exercise,
              loggedSets: loggedSets,
              draftSets: draftSets ?? [DraftSetEntry.empty()],
              onOpenInfo: () {},
              onAddDraftSet: () {},
              onCompleteDraft: onCompleteDraft ?? (_, __, ___, ____) async {},
              onUncompleteSet: onUncompleteSet ?? (_) {},
              onRemoveExercise: onRemoveExercise,
              onNotesChanged: onNotesChanged,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('ticking a logged set un-completes it instead of removing', (
    tester,
  ) async {
    LoggedSetEntry? uncompleted;
    var removed = false;
    await pumpCard(
      tester,
      onUncompleteSet: (set) => uncompleted = set,
      onRemoveExercise: () => removed = true,
    );

    await tester.tap(find.byIcon(Symbols.check).first);
    await tester.pump();

    expect(uncompleted?.id, 'set-1');
    expect(removed, isFalse);
  });

  testWidgets('second tap of a double-tap does not undo the new set', (
    tester,
  ) async {
    final draft = DraftSetEntry(localId: 'd1', weightKg: 60, reps: 8);
    final loggedSets = <LoggedSetEntry>[];
    var undoCount = 0;

    await pumpCard(
      tester,
      loggedSets: loggedSets,
      draftSets: [draft],
      onCompleteDraft: (_, weight, reps, __) async {
        loggedSets.add(
          LoggedSetEntry(id: 'new', setNumber: 1, weightKg: weight, reps: reps),
        );
      },
      onUncompleteSet: (_) => undoCount++,
    );

    await tester.tap(find.byIcon(Symbols.check).first);
    await tester.pump();
    await pumpCard(
      tester,
      loggedSets: loggedSets,
      draftSets: [DraftSetEntry.empty()],
      onUncompleteSet: (_) => undoCount++,
    );
    await tester.tap(find.byIcon(Symbols.check).first);
    await tester.pump();

    expect(undoCount, 0);
  });

  testWidgets('menu offers options and only removes when chosen', (
    tester,
  ) async {
    var removed = false;
    await pumpCard(tester, onRemoveExercise: () => removed = true);

    await tester.tap(find.byIcon(Symbols.more_vert));
    await tester.pumpAndSettle();

    expect(removed, isFalse);
    expect(find.text('Exercise info'), findsOneWidget);
    expect(find.text('Add set'), findsWidgets);
    expect(find.text('Remove exercise'), findsOneWidget);

    await tester.tap(find.text('Remove exercise'));
    await tester.pumpAndSettle();
    expect(removed, isTrue);
  });

  testWidgets('notes field is editable', (tester) async {
    String? notes;
    await pumpCard(tester, onNotesChanged: (value) => notes = value);

    await tester.enterText(
      find.widgetWithText(TextField, 'Add notes here…'),
      'Felt strong',
    );

    expect(notes, 'Felt strong');
  });
}
