import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../models/workout_models.dart';

/// Sheet to load workout from history
class WorkoutHistoryPicker extends StatelessWidget {
  final Function(WorkoutSession) onSelect;

  const WorkoutHistoryPicker({
    super.key,
    required this.onSelect,
  });

  static Future<void> show(
    BuildContext context, {
    required Function(WorkoutSession) onSelect,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WorkoutHistoryPicker(onSelect: onSelect),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDate = DateTime(date.year, date.month, date.day);
    
    final difference = today.difference(sessionDate).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  String _formatDuration(int? seconds) {
    if (seconds == null || seconds == 0) return '--';
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final mins = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${mins}m';
    } else {
      return '${mins}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final h = MediaQuery.of(context).size.height;

    return Container(
      height: h - topPad - 24,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXxl)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Recent Workouts',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.surfaceContainerHigh,
                  ),
                ),
              ],
            ),
          ),

          // Session list
          Expanded(
            child: FutureBuilder<List<WorkoutSession>>(
              future: _loadRecentSessions(context),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(AppTheme.primaryContainer),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: AppTheme.error.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load workouts',
                            style: TextStyle(
                              color: AppTheme.onSurfaceVariant,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final sessions = snapshot.data ?? [];

                if (sessions.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerHigh,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.history,
                              size: 32,
                              color: AppTheme.onSurfaceVariant.withOpacity(0.3),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No workout history',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Complete a workout to see it here',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  itemCount: sessions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    final duration = session.endedAt != null
                        ? session.endedAt!.difference(session.startedAt).inSeconds
                        : null;
                    return _SessionCard(
                      session: session,
                      dateLabel: _formatDate(session.startedAt),
                      durationLabel: _formatDuration(duration),
                      onTap: () {
                        Navigator.pop(context);
                        onSelect(session);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<List<WorkoutSession>> _loadRecentSessions(BuildContext context) async {
    // Access database through provider or direct instance
    // For now, return empty list - will be implemented with actual DB query
    // final db = ref.read(appDatabaseProvider);
    // return await db.workoutSessionsDao.getCompletedSessions(limit: 10);
    return [];
  }
}

class _SessionCard extends StatelessWidget {
  final WorkoutSession session;
  final String dateLabel;
  final String durationLabel;
  final VoidCallback onTap;

  const _SessionCard({
    required this.session,
    required this.dateLabel,
    required this.durationLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final exerciseCount = 0; // TODO: Get actual count from session

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(
            color: Colors.white.withOpacity(0.06),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.fitness_center_rounded,
                color: AppTheme.primaryContainer,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.notes?.isNotEmpty == true
                        ? session.notes!
                        : 'Workout',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        dateLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        ' • ',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.onSurfaceVariant.withOpacity(0.4),
                        ),
                      ),
                      Text(
                        '$exerciseCount set${exerciseCount > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                      if (durationLabel != '--') ...[
                        Text(
                          ' • ',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.onSurfaceVariant.withOpacity(0.4),
                          ),
                        ),
                        Text(
                          durationLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppTheme.onSurfaceVariant.withOpacity(0.4),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
