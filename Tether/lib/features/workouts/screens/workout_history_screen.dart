import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../models/workout_models.dart';
import '../services/offline_workout_service.dart';
import 'workout_session_screen.dart';

class WorkoutHistoryScreen extends ConsumerStatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  ConsumerState<WorkoutHistoryScreen> createState() =>
      _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState
    extends ConsumerState<WorkoutHistoryScreen> {
  List<WorkoutSession> _sessions = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final workoutService = ref.read(offlineWorkoutServiceProvider);
      final sessions = await workoutService.listSessions();
      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[WorkoutHistoryScreen] _loadSessions failed: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _deleteSession(String sessionId) async {
    // Styled confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppTheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
          side: BorderSide(color: Colors.white.withOpacity(0.07)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.stackMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.errorContainer.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppTheme.error.withOpacity(0.3), width: 1),
                ),
                child: const Icon(Symbols.delete,
                    size: 24, color: AppTheme.error),
              ),
              const SizedBox(height: AppTheme.stackSm),
              Text(
                'DELETE WORKOUT',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'This workout and all its sets will be permanently deleted.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.stackMd),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Cancel',
                      onPressed: () => Navigator.pop(context, false),
                    ),
                  ),
                  const SizedBox(width: AppTheme.stackSm),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, true),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppTheme.errorContainer.withOpacity(0.3),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusFull),
                          border: Border.all(
                              color: AppTheme.error.withOpacity(0.4)),
                        ),
                        child: Center(
                          child: Text(
                            'DELETE',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                    fontSize: 14, color: AppTheme.error),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final workoutService = ref.read(offlineWorkoutServiceProvider);
      await workoutService.deleteSession(sessionId);
      if (mounted) {
        _showSnack('Workout deleted');
        _loadSessions();
      }
    } catch (e) {
      debugPrint('[WorkoutHistoryScreen] _deleteSession failed: $e');
      if (mounted) _showSnack("Couldn't delete workout", isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError
            ? AppTheme.errorContainer
            : AppTheme.surfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        content: Text(
          message,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: isError ? AppTheme.error : AppTheme.onSurface,
              ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryContainer),
        ),
      );
    }

    if (_hasError) {
      return ConnectErrorState(onRetry: _loadSessions);
    }

    if (_sessions.isEmpty) {
      return _EmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadSessions,
      color: AppTheme.primaryContainer,
      backgroundColor: AppTheme.surfaceContainerHigh,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: _sessions.length,
        separatorBuilder: (_, __) =>
            const SizedBox(height: AppTheme.stackSm),
        itemBuilder: (_, i) => _SessionCard(
          session: _sessions[i],
          onDelete: () => _deleteSession(_sessions[i].id),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh,
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withOpacity(0.1), width: 1),
            ),
            child: Icon(
              Symbols.fitness_center,
              size: 28,
              color: AppTheme.onSurfaceVariant.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: AppTheme.stackMd),
          Text(
            'NO WORKOUTS YET',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Start your first workout to track your progress',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Session card — Pulse styled, dark surface, metric chips row
// ─────────────────────────────────────────────────────────────────────────────
class _SessionCard extends StatelessWidget {
  final WorkoutSession session;
  final VoidCallback onDelete;

  const _SessionCard({required this.session, required this.onDelete});

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt).inDays;
    if (diff == 0) return 'TODAY';
    if (diff == 1) return 'YESTERDAY';
    if (diff < 7) return '${diff} DAYS AGO';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';

  String _formatDuration(DateTime start, DateTime end) {
    final d = end.difference(start);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return h > 0 ? '${h}H ${m}M' : '${m}M';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WorkoutSessionScreen(session: session),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.stackSm),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border:
              Border.all(color: Colors.white.withOpacity(0.07), width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date block
            Container(
              width: 48,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: Column(
                children: [
                  Text(
                    _formatDate(session.startedAt).split(' ')[0],
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.primaryContainer,
                          fontSize: 8,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    _formatTime(session.startedAt),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.onSurface,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.stackSm),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDate(session.startedAt),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (session.notes != null && session.notes!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      session.notes!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.onSurfaceVariant,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      MetricChip(
                        label: '${session.sets.length} SETS',
                        icon: Symbols.fitness_center,
                      ),
                      if (session.endedAt != null) ...[
                        const SizedBox(width: 6),
                        MetricChip(
                          label: _formatDuration(
                              session.startedAt, session.endedAt!),
                          icon: Symbols.timer,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Delete button
            GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.errorContainer.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                child: const Icon(Symbols.delete,
                    size: 16, color: AppTheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
