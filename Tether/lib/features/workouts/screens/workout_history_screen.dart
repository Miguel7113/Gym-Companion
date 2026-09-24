import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/glass_card.dart';
import '../models/workout_models.dart';
import '../services/offline_workout_service.dart';
import 'workout_detail_screen.dart';

class WorkoutHistoryScreen extends ConsumerStatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  ConsumerState<WorkoutHistoryScreen> createState() =>
      _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends ConsumerState<WorkoutHistoryScreen> {
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

    var hasLocalData = false;
    try {
      final workoutService = ref.read(offlineWorkoutServiceProvider);
      final localSessions = await workoutService.listLocalSessions();
      hasLocalData = localSessions.isNotEmpty;
      if (mounted) {
        setState(() {
          _sessions = localSessions;
          _isLoading = false;
        });
      }

      // Show local history immediately, then replace it with the server's
      // complete version when the device is online.
      final sessions = await workoutService.listSessions();
      if (mounted) setState(() => _sessions = sessions);
    } catch (e) {
      debugPrint('[WorkoutHistoryScreen] _loadSessions failed: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = !hasLocalData;
        });
      }
    }
  }

  Future<void> _deleteSession(String sessionId) async {
    final confirmed = await showAppConfirmDialog(
      context,
      icon: Symbols.delete,
      tone: AppDialogTone.danger,
      title: 'Delete workout?',
      message: 'This workout and all its sets will be permanently deleted.',
      confirmLabel: 'Delete',
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
    showAppSnack(
      context,
      message,
      tone: isError ? AppSnackTone.error : AppSnackTone.success,
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
        separatorBuilder: (_, __) => const SizedBox(height: AppTheme.stackSm),
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
    return EmptyState(
      icon: Symbols.fitness_center,
      title: 'No workouts yet',
      message: 'Start your first workout to track your progress',
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
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';

  String _formatDuration(DateTime start, DateTime end) {
    final d = end.difference(start);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WorkoutDetailScreen(session: session),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.stackSm),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(color: Colors.white.withOpacity(0.07), width: 1),
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
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: AppTheme.onSurface),
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
                        label: '${session.sets.length} sets',
                        icon: Symbols.fitness_center,
                      ),
                      if (session.endedAt != null) ...[
                        const SizedBox(width: 6),
                        MetricChip(
                          label: _formatDuration(
                            session.startedAt,
                            session.endedAt!,
                          ),
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
                child: const Icon(
                  Symbols.delete,
                  size: 16,
                  color: AppTheme.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
