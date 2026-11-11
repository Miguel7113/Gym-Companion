import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/tether_text.dart';
import '../../../core/theme/tether_tokens.dart';
import '../models/workout_models.dart';
import '../services/offline_workout_service.dart';
import 'workout_detail_screen.dart';

/// Workout History screen redesign with foundry-style: dark header + cream sheet + wide cards
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

      // Load server data to replace local
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

  Future<void> _deleteSession(WorkoutSession session) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TetherTokens.cream,
        title: Text(
          'Delete Workout?',
          style: TetherText.sans(18, w: TetherTokens.w800)
              .copyWith(color: TetherTokens.ink),
        ),
        content: Text(
          'This workout and all its sets will be permanently deleted. This action cannot be undone.',
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

    if (confirmed != true || !mounted) return;

    try {
      final workoutService = ref.read(offlineWorkoutServiceProvider);
      await workoutService.deleteSession(session.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Workout deleted'),
            backgroundColor: TetherTokens.ink,
          ),
        );
        _loadSessions();
      }
    } catch (e) {
      debugPrint('[WorkoutHistoryScreen] _deleteSession failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Couldn't delete workout"),
            backgroundColor: TetherTokens.ink,
          ),
        );
      }
    }
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
                child: _buildContent(context),
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
          // Title and stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HISTORY',
                  style: TetherText.sans(18, w: TetherTokens.w800)
                      .copyWith(color: TetherTokens.cream),
                ),
                if (_sessions.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${_sessions.length} WORKOUTS',
                    style: TetherText.sans(12, w: TetherTokens.w600)
                        .copyWith(color: TetherTokens.defaultAccent),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFF5A1F),
        ),
      );
    }

    if (_hasError) {
      return _buildErrorState(context);
    }

    if (_sessions.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: _loadSessions,
      color: TetherTokens.defaultAccent,
      child: _buildHistoryList(context),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        Center(
          child: Column(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: TetherTokens.sand,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Symbols.cloud_off,
                  size: 48,
                  color: TetherTokens.nightMuted,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'CONNECTION ERROR',
                textAlign: TextAlign.center,
                style: TetherText.sans(18, w: TetherTokens.w800)
                    .copyWith(color: TetherTokens.ink),
              ),
              const SizedBox(height: 12),
              Text(
                'Check your internet connection\nand try again',
                textAlign: TextAlign.center,
                style: TetherText.sans(14, w: TetherTokens.w400)
                    .copyWith(color: TetherTokens.nightMuted),
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: _loadSessions,
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
                        Symbols.refresh,
                        color: TetherTokens.ink,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'RETRY',
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

  Widget _buildEmptyState(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        Center(
          child: Column(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: TetherTokens.sand,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Symbols.fitness_center,
                  size: 48,
                  color: TetherTokens.nightMuted,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'NO WORKOUTS YET',
                textAlign: TextAlign.center,
                style: TetherText.sans(18, w: TetherTokens.w800)
                    .copyWith(color: TetherTokens.ink),
              ),
              const SizedBox(height: 12),
              Text(
                'Start your first workout to\ntrack your progress',
                textAlign: TextAlign.center,
                style: TetherText.sans(14, w: TetherTokens.w400)
                    .copyWith(color: TetherTokens.nightMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryList(BuildContext context) {
    // Group sessions by month for better organization
    final groupedSessions = <String, List<WorkoutSession>>{};
    for (final session in _sessions) {
      final key = _getMonthKey(session.startedAt);
      groupedSessions.putIfAbsent(key, () => []).add(session);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
      itemCount: groupedSessions.length,
      itemBuilder: (context, groupIndex) {
        final monthKey = groupedSessions.keys.elementAt(groupIndex);
        final sessions = groupedSessions[monthKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month header
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                monthKey,
                style: TetherText.sans(14, w: TetherTokens.w800)
                    .copyWith(color: TetherTokens.nightMuted),
              ),
            ),
            // Session cards
            ...sessions.map((session) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildSessionCard(context, session),
                )),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  String _getMonthKey(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month) {
      return 'THIS MONTH';
    }
    if (date.year == now.year && date.month == now.month - 1) {
      return 'LAST MONTH';
    }
    final months = [
      'JANUARY',
      'FEBRUARY',
      'MARCH',
      'APRIL',
      'MAY',
      'JUNE',
      'JULY',
      'AUGUST',
      'SEPTEMBER',
      'OCTOBER',
      'NOVEMBER',
      'DECEMBER'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  Widget _buildSessionCard(BuildContext context, WorkoutSession session) {
    final exerciseCount = session.sets
        .map((s) => s.exerciseId)
        .toSet()
        .length;
    
    final totalVolume = session.sets.fold<double>(
      0,
      (sum, set) => sum + (set.weightKg ?? 0) * (set.reps ?? 0),
    );

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WorkoutDetailScreen(session: session),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: TetherTokens.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: TetherTokens.dayBorder.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date badge
            Container(
              width: 56,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: TetherTokens.sand,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    _getMonthShort(session.startedAt),
                    style: TetherText.sans(10, w: TetherTokens.w800)
                        .copyWith(color: TetherTokens.defaultAccent),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    session.startedAt.day.toString(),
                    style: TetherText.sans(20, w: TetherTokens.w800)
                        .copyWith(color: TetherTokens.ink),
                  ),
                  Text(
                    _formatTime(session.startedAt),
                    style: TetherText.sans(10, w: TetherTokens.w600)
                        .copyWith(color: TetherTokens.nightMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatRelativeDate(session.startedAt),
                    style: TetherText.sans(16, w: TetherTokens.w800)
                        .copyWith(color: TetherTokens.ink),
                  ),
                  if (session.notes != null && session.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      session.notes!,
                      style: TetherText.sans(13, w: TetherTokens.w400)
                          .copyWith(color: TetherTokens.nightMuted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Metrics row
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildMetricChip(
                        '${session.sets.length} SETS',
                        Symbols.fitness_center,
                      ),
                      _buildMetricChip(
                        '$exerciseCount EXERCISES',
                        Symbols.list,
                      ),
                      if (session.endedAt != null)
                        _buildMetricChip(
                          _formatDuration(
                            session.startedAt,
                            session.endedAt!,
                          ),
                          Symbols.timer,
                        ),
                      if (totalVolume > 0)
                        _buildMetricChip(
                          '${totalVolume.toStringAsFixed(0)} KG',
                          Symbols.scale,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Delete button
            GestureDetector(
              onTap: () => _deleteSession(session),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Symbols.delete_outline,
                  size: 20,
                  color: Colors.red.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: TetherTokens.sand,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: TetherTokens.defaultAccent,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TetherText.sans(11, w: TetherTokens.w600)
                .copyWith(color: TetherTokens.ink),
          ),
        ],
      ),
    );
  }

  String _getMonthShort(DateTime date) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC'
    ];
    return months[date.month - 1];
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _formatRelativeDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt).inDays;
    if (diff == 0) return 'TODAY';
    if (diff == 1) return 'YESTERDAY';
    if (diff < 7) return '$diff DAYS AGO';
    return '${dt.day} ${_getMonthShort(dt)} ${dt.year}';
  }

  String _formatDuration(DateTime start, DateTime end) {
    final d = end.difference(start);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}H ${m}M';
    return '${m}M';
  }
}
