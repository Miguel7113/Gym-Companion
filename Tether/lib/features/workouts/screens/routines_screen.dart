import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/workout_models.dart';
import '../services/workout_service.dart';
import 'workout_builder_screen.dart';
import 'workout_detail_screen.dart';

class RoutinesScreen extends ConsumerStatefulWidget {
  const RoutinesScreen({super.key});

  @override
  ConsumerState<RoutinesScreen> createState() => _RoutinesScreenState();
}

class _RoutinesScreenState extends ConsumerState<RoutinesScreen> {
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
          SnackBar(content: Text("Couldn't load routines: $e")),
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
          const SnackBar(content: Text('Routine copied to your routines')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't copy routine: $e")),
        );
      }
    }
  }

  Future<void> _delete(WorkoutTemplate routine) async {
    try {
      await ref.read(workoutServiceProvider).deleteRoutine(routine.id);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't delete routine: $e")),
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
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't update program: $e")),
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
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Text(
          'Routines',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
        ),
        actions: [
          IconButton(
            onPressed: _create,
            icon: const Icon(Symbols.add),
            tooltip: 'Create routine',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppTheme.primaryContainer,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primaryContainer,
                ),
              )
            : _routines.isEmpty
                ? _EmptyRoutines(onCreate: _create)
                : ListView.separated(
                    padding: const EdgeInsets.all(AppTheme.containerMargin),
                    itemCount: _routines.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppTheme.stackSm),
                    itemBuilder: (_, index) {
                      final routine = _routines[index];
                      final isOwner = routine.createdByUserId ==
                          ref.read(currentUserProvider)?.memberId;
                      final role = ref.read(currentUserProvider)?.role;
                      final isStaff = role != null &&
                          {'coach', 'admin'}.contains(role.toLowerCase());
                      return _RoutineCard(
                        routine: routine,
                        isOwner: isOwner,
                        onOpen: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                WorkoutDetailScreen(routine: routine),
                          ),
                        ),
                        onStart: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                WorkoutBuilderScreen(routine: routine),
                          ),
                        ),
                        onCopy: routine.isShared && !isOwner
                            ? () => _copy(routine)
                            : null,
                        onDelete: isOwner ? () => _delete(routine) : null,
                        onPublish: isOwner && isStaff
                            ? () => _togglePublish(routine)
                            : null,
                      );
                    },
                  ),
      ),
    );
  }
}

class _EmptyRoutines extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyRoutines({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: EmptyState(
            icon: Symbols.bookmark_add,
            title: 'Build your routine',
            message:
                'Save your favourite exercises and start the same plan with one tap',
            actionLabel: 'Create routine',
            actionIcon: Symbols.add,
            onAction: onCreate,
          ),
        ),
      ],
    );
  }
}

class _RoutineCard extends StatelessWidget {
  final WorkoutTemplate routine;
  final bool isOwner;
  final VoidCallback onOpen;
  final VoidCallback onStart;
  final VoidCallback? onCopy;
  final VoidCallback? onDelete;
  final VoidCallback? onPublish;

  const _RoutineCard({
    required this.routine,
    required this.isOwner,
    required this.onOpen,
    required this.onStart,
    required this.onCopy,
    required this.onDelete,
    this.onPublish,
  });

  @override
  Widget build(BuildContext context) {
    final names = routine.exercises
        .map((e) => e.exercise?.name)
        .whereType<String>()
        .take(3)
        .join(' · ');
    return GlassCard(
      padding: const EdgeInsets.all(AppTheme.stackMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onOpen,
                  child: Text(
                    routine.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              if (routine.isCoachProgram)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainer.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'GYM',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.primaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              if (routine.isShared)
                Icon(
                  isOwner ? Symbols.public : Symbols.explore,
                  size: 16,
                  color: AppTheme.primaryContainer,
                )
              else
                const Icon(
                  Symbols.lock,
                  size: 16,
                  color: AppTheme.onSurfaceVariant,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${routine.exercises.length} exercises${names.isEmpty ? '' : ' · $names'}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppTheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppTheme.stackSm),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: 'Start',
                  icon: Symbols.play_arrow,
                  onPressed: onStart,
                ),
              ),
              if (onPublish != null) ...[
                const SizedBox(width: AppTheme.stackSm),
                IconButton(
                  onPressed: onPublish,
                  icon: Icon(
                    routine.isCoachProgram
                        ? Symbols.unpublished
                        : Symbols.publish,
                  ),
                  tooltip: routine.isCoachProgram
                      ? 'Unpublish gym program'
                      : 'Publish as gym program',
                ),
              ],
              if (onCopy != null) ...[
                const SizedBox(width: AppTheme.stackSm),
                IconButton(
                  onPressed: onCopy,
                  icon: const Icon(Symbols.content_copy),
                  tooltip: 'Copy routine',
                ),
              ],
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Symbols.delete_outline),
                  tooltip: 'Delete routine',
                ),
            ],
          ),
        ],
      ),
    );
  }
}
