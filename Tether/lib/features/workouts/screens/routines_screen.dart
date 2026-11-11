import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/tether_text.dart';
import '../../../core/theme/tether_tokens.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/workout_models.dart';
import '../services/workout_service.dart';
import 'workout_builder_screen.dart';
import 'workout_detail_screen.dart';

/// Routines screen redesign with foundry-style: dark header + cream sheet + wide cards
class RoutinesScreen extends ConsumerStatefulWidget {
  const RoutinesScreen({super.key});

  @override
  ConsumerState<RoutinesScreen> createState() =>
      _RoutinesScreenState();
}

class _RoutinesScreenState
    extends ConsumerState<RoutinesScreen> {
  List<WorkoutTemplate> _routines = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final routines = await ref.read(workoutServiceProvider).listRoutines();
      if (mounted) setState(() => _routines = routines);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Couldn't load routines: $e"),
            backgroundColor: TetherTokens.ink,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _copy(WorkoutTemplate routine) async {
    try {
      await ref.read(workoutServiceProvider).copyRoutine(routine.id);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Routine copied to your routines'),
            backgroundColor: TetherTokens.ink,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Couldn't copy routine: $e"),
            backgroundColor: TetherTokens.ink,
          ),
        );
      }
    }
  }

  Future<void> _delete(WorkoutTemplate routine) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TetherTokens.cream,
        title: Text(
          'Delete Routine?',
          style: TetherText.sans(18, w: TetherTokens.w800)
              .copyWith(color: TetherTokens.ink),
        ),
        content: Text(
          'This will permanently delete "${routine.name}". This action cannot be undone.',
          style: TetherText.sans(14, w: TetherTokens.w400)
              .copyWith(color: TetherTokens.nightMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'CANCEL',
              style: TetherText.sans(13, w: TetherTokens.w800)
                  .copyWith(color: TetherTokens.nightMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'DELETE',
              style: TetherText.sans(13, w: TetherTokens.w800)
                  .copyWith(color: Colors.red.shade600),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(workoutServiceProvider).deleteRoutine(routine.id);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Routine deleted'),
            backgroundColor: TetherTokens.ink,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Couldn't delete routine: $e"),
            backgroundColor: TetherTokens.ink,
          ),
        );
      }
    }
  }

  Future<void> _togglePublish(WorkoutTemplate routine) async {
    try {
      if (routine.isCoachProgram) {
        await ref.read(workoutServiceProvider).unpublishRoutine(routine.id);
      } else {
        await ref.read(workoutServiceProvider).publishRoutine(routine.id);
      }
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              routine.isCoachProgram
                  ? 'Program unpublished'
                  : 'Published as gym program',
            ),
            backgroundColor: TetherTokens.ink,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Couldn't update program: $e"),
            backgroundColor: TetherTokens.ink,
          ),
        );
      }
    }
  }

  Future<void> _create() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const WorkoutBuilderScreen(saveAsRoutine: true),
      ),
    );
    if (saved == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TetherTokens.ink,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // DARK HEADER
            _buildHeader(context),
            // CREAM SHEET
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: TetherTokens.cream,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFFF5A1F),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: TetherTokens.defaultAccent,
                        child: _routines.isEmpty
                            ? _buildEmptyState(context)
                            : _buildRoutinesList(context),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: TetherTokens.nightCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Symbols.arrow_back,
                color: TetherTokens.cream,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Title
          Expanded(
            child: Text(
              'ROUTINES',
              style: TetherText.sans(18, w: TetherTokens.w800)
                  .copyWith(color: TetherTokens.cream),
            ),
          ),
          // Create button
          GestureDetector(
            onTap: _create,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: TetherTokens.defaultAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Symbols.add,
                    color: TetherTokens.ink,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'CREATE',
                    style: TetherText.sans(12, w: TetherTokens.w800)
                        .copyWith(color: TetherTokens.ink),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        Center(
          child: Column(
            children: [
              // Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: TetherTokens.sand,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Symbols.bookmark_add,
                  size: 48,
                  color: TetherTokens.nightMuted,
                ),
              ),
              const SizedBox(height: 24),
              // Title
              Text(
                'BUILD YOUR ROUTINE',
                textAlign: TextAlign.center,
                style: TetherText.sans(18, w: TetherTokens.w800)
                    .copyWith(color: TetherTokens.ink),
              ),
              const SizedBox(height: 12),
              // Message
              Text(
                'Save your favourite exercises and start\nthe same plan with one tap',
                textAlign: TextAlign.center,
                style: TetherText.sans(14, w: TetherTokens.w400)
                    .copyWith(color: TetherTokens.nightMuted),
              ),
              const SizedBox(height: 32),
              // CTA Button
              GestureDetector(
                onTap: _create,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: TetherTokens.defaultAccent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Symbols.add,
                        color: TetherTokens.ink,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'CREATE ROUTINE',
                        style: TetherText.sans(14, w: TetherTokens.w800)
                            .copyWith(color: TetherTokens.ink),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoutinesList(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
      itemCount: _routines.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final routine = _routines[index];
        final isOwner = routine.createdByUserId ==
            ref.read(currentUserProvider)?.memberId;
        final role = ref.read(currentUserProvider)?.role;
        final isStaff =
            role != null && {'coach', 'admin'}.contains(role.toLowerCase());
        return _buildRoutineCard(
          context,
          routine,
          isOwner,
          isStaff,
        );
      },
    );
  }

  Widget _buildRoutineCard(
    BuildContext context,
    WorkoutTemplate routine,
    bool isOwner,
    bool isStaff,
  ) {
    final exerciseNames = routine.exercises
        .map((e) => e.exercise?.name)
        .whereType<String>()
        .take(3)
        .join(' · ');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TetherTokens.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: TetherTokens.dayBorder.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WorkoutDetailScreen(routine: routine),
                    ),
                  ),
                  child: Text(
                    routine.name,
                    style: TetherText.sans(16, w: TetherTokens.w800)
                        .copyWith(color: TetherTokens.ink),
                  ),
                ),
              ),
              // Badges
              if (routine.isCoachProgram) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: TetherTokens.defaultAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'GYM',
                    style: TetherText.sans(10, w: TetherTokens.w800)
                        .copyWith(color: TetherTokens.defaultAccent),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Icon(
                routine.isShared
                    ? (isOwner ? Symbols.public : Symbols.explore)
                    : Symbols.lock,
                size: 18,
                color: routine.isShared
                    ? TetherTokens.defaultAccent
                    : TetherTokens.nightMuted,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Exercise count and preview
          Text(
            '${routine.exercises.length} EXERCISES${exerciseNames.isEmpty ? '' : ' · $exerciseNames'}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TetherText.sans(12, w: TetherTokens.w400)
                .copyWith(color: TetherTokens.nightMuted),
          ),
          const SizedBox(height: 16),
          // Actions row
          Row(
            children: [
              // Start button (primary)
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WorkoutBuilderScreen(routine: routine),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: TetherTokens.defaultAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Symbols.play_arrow,
                          color: TetherTokens.ink,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'START',
                          style: TetherText.sans(13, w: TetherTokens.w800)
                              .copyWith(color: TetherTokens.ink),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Action buttons
              if (isOwner && isStaff) ...[
                const SizedBox(width: 12),
                _buildActionButton(
                  icon: routine.isCoachProgram
                      ? Symbols.unpublished
                      : Symbols.publish,
                  onTap: () => _togglePublish(routine),
                  tooltip: routine.isCoachProgram
                      ? 'Unpublish'
                      : 'Publish as gym program',
                ),
              ],
              if (routine.isShared && !isOwner) ...[
                const SizedBox(width: 12),
                _buildActionButton(
                  icon: Symbols.content_copy,
                  onTap: () => _copy(routine),
                  tooltip: 'Copy routine',
                ),
              ],
              if (isOwner) ...[
                const SizedBox(width: 12),
                _buildActionButton(
                  icon: Symbols.delete_outline,
                  onTap: () => _delete(routine),
                  tooltip: 'Delete',
                  color: Colors.red.shade600,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: TetherTokens.sand,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 20,
            color: color ?? TetherTokens.ink,
          ),
        ),
      ),
    );
  }
}
