import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/tether_text.dart';
import '../../../core/theme/tether_tokens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cached_media.dart';
import '../models/personal_record.dart';
import '../models/coach_stats.dart';
import '../services/personal_records_service.dart';
import '../widgets/coach_stats_header.dart';
import '../widgets/exercise_filter_tabs.dart';
import '../widgets/pr_verification_card.dart';
import '../widgets/pr_rejection_modal.dart';
import '../widgets/pr_card_skeleton.dart';

/// Coach PR Verification Screen
/// Shows pending PRs that need coach approval
class PendingPRsScreen extends ConsumerStatefulWidget {
  const PendingPRsScreen({super.key});

  @override
  ConsumerState<PendingPRsScreen> createState() => _PendingPRsScreenState();
}

class _PendingPRsScreenState extends ConsumerState<PendingPRsScreen> {
  List<_PendingPRWithUser> _pendingPRs = [];
  List<_PendingPRWithUser> _allPendingPRs = []; // Unfiltered list
  bool _loading = true;
  CoachStats? _stats;
  bool _loadingStats = true;
  final Set<String> _processingIds = {};
  ExerciseFilter _selectedFilter = ExerciseFilter.all;

  @override
  void initState() {
    super.initState();
    _loadPendingPRs();
    _loadStats();
  }

  Future<void> _loadPendingPRs() async {
    setState(() => _loading = true);
    try {
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      if (token == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final service = ref.read(personalRecordsServiceProvider);
      final prs = await service.getPendingPRs(token);

      if (mounted) {
        // Convert to our local model with user info
        final prsWithUser = prs.map((pr) {
          // The API returns PR with user nested
          return _PendingPRWithUser(
            pr: pr,
            userName: 'Member', // Will be populated from API response
            userAvatar: null,
          );
        }).toList();

        setState(() {
          _allPendingPRs = prsWithUser;
          _applyFilter();
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('[PendingPRsScreen] load failed: $e');
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load pending PRs: $e')),
        );
      }
    }
  }

  Future<void> _loadStats() async {
    setState(() => _loadingStats = true);
    try {
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      if (token == null) {
        if (mounted) setState(() => _loadingStats = false);
        return;
      }

      final service = ref.read(personalRecordsServiceProvider);
      final stats = await service.getCoachStats(token);
      
      if (mounted) {
        setState(() {
          _stats = stats;
          _loadingStats = false;
        });
      }
    } catch (e) {
      debugPrint('[PendingPRsScreen] stats load failed: $e');
      if (mounted) {
        setState(() => _loadingStats = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load stats: $e')),
        );
      }
    }
  }

  void _applyFilter() {
    if (_selectedFilter == ExerciseFilter.all) {
      _pendingPRs = _allPendingPRs;
    } else {
      final filterName = _selectedFilter.toExerciseName();
      _pendingPRs = _allPendingPRs
          .where((pr) => pr.pr.exerciseName == filterName)
          .toList();
    }
  }

  void _onFilterChanged(ExerciseFilter filter) {
    setState(() {
      _selectedFilter = filter;
      _applyFilter();
    });
  }

  Map<ExerciseFilter, int> _getFilterCounts() {
    final counts = <ExerciseFilter, int>{
      ExerciseFilter.all: _allPendingPRs.length,
      ExerciseFilter.benchPress: 0,
      ExerciseFilter.squat: 0,
      ExerciseFilter.deadlift: 0,
    };

    for (final pr in _allPendingPRs) {
      switch (pr.pr.exerciseName) {
        case 'Bench Press':
          counts[ExerciseFilter.benchPress] = 
              (counts[ExerciseFilter.benchPress] ?? 0) + 1;
          break;
        case 'Squat':
          counts[ExerciseFilter.squat] = (counts[ExerciseFilter.squat] ?? 0) + 1;
          break;
        case 'Deadlift':
          counts[ExerciseFilter.deadlift] = 
              (counts[ExerciseFilter.deadlift] ?? 0) + 1;
          break;
      }
    }

    return counts;
  }

  Future<void> _verifyPR(_PendingPRWithUser prData) async {
    if (_processingIds.contains(prData.pr.id)) return;

    setState(() => _processingIds.add(prData.pr.id));

    try {
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      if (token == null) return;

      final service = ref.read(personalRecordsServiceProvider);
      await service.verifyPR(prData.pr.id, token);

      if (mounted) {
        // Remove from both lists and reload stats
        setState(() {
          _allPendingPRs.removeWhere((pr) => pr.pr.id == prData.pr.id);
          _pendingPRs.removeWhere((pr) => pr.pr.id == prData.pr.id);
          _processingIds.remove(prData.pr.id);
        });
        
        // Reload stats to update verified count
        _loadStats();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Symbols.check_circle, color: AppTheme.toneSuccess),
                const SizedBox(width: 8),
                const Text('PR verified ✓'),
              ],
            ),
            backgroundColor: TetherTokens.nightCard,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _processingIds.remove(prData.pr.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to verify PR: $e'),
            backgroundColor: AppTheme.toneDanger,
          ),
        );
      }
    }
  }

  Future<void> _rejectPR(_PendingPRWithUser prData) async {
    // Show enhanced rejection modal
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => PRRejectionModal(
        exerciseName: prData.pr.exerciseName,
        userName: prData.userName,
      ),
    );

    if (reason == null) return; // User cancelled

    if (_processingIds.contains(prData.pr.id)) return;
    setState(() => _processingIds.add(prData.pr.id));

    try {
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      if (token == null) return;

      final service = ref.read(personalRecordsServiceProvider);
      await service.rejectPR(prData.pr.id, token, reason: reason);

      if (mounted) {
        setState(() {
          _allPendingPRs.removeWhere((pr) => pr.pr.id == prData.pr.id);
          _pendingPRs.removeWhere((pr) => pr.pr.id == prData.pr.id);
          _processingIds.remove(prData.pr.id);
        });
        
        // Reload stats to update pending count
        _loadStats();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PR rejected'),
            backgroundColor: TetherTokens.nightCard,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _processingIds.remove(prData.pr.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject PR: $e'),
            backgroundColor: AppTheme.toneDanger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _pendingPRs.length;

    return Scaffold(
      backgroundColor: TetherTokens.ink,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: TetherTokens.cream.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Symbols.arrow_back,
                            size: 18,
                            color: TetherTokens.cream,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (pendingCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: TetherTokens.defaultAccent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$pendingCount',
                            style: TetherText.sans(
                              14,
                              color: TetherTokens.cream,
                              w: TetherTokens.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'PR Verification',
                    style: TetherText.sans(
                      32,
                      w: TetherTokens.w800,
                      color: TetherTokens.cream,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Review and verify member achievements',
                    style: TetherText.sans(
                      14,
                      color: TetherTokens.cream.withOpacity(0.6),
                      w: TetherTokens.w400,
                    ),
                  ),
                ],
              ),
            ),

            // Stats Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: CoachStatsHeader(
                stats: _loadingStats ? null : _stats,
              ),
            ),
            const SizedBox(height: 20),

            // Exercise Filter Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ExerciseFilterTabs(
                selectedFilter: _selectedFilter,
                onFilterChanged: _onFilterChanged,
                counts: _loading ? null : _getFilterCounts(),
              ),
            ),
            const SizedBox(height: 16),

            // Content
            Expanded(
              child: _loading
                  ? _buildLoadingState()
                  : _pendingPRs.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: () async {
                            await Future.wait([
                              _loadPendingPRs(),
                              _loadStats(),
                            ]);
                          },
                          color: TetherTokens.defaultAccent,
                          backgroundColor: TetherTokens.nightCard,
                          displacement: 40,
                          strokeWidth: 3,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(20),
                            itemCount: _pendingPRs.length + 1,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return _buildSummaryCard(pendingCount);
                              }
                              final prData = _pendingPRs[index - 1];
                              final isProcessing =
                                  _processingIds.contains(prData.pr.id);
                              return PRVerificationCard(
                                pr: prData.pr,
                                userName: prData.userName,
                                userAvatar: prData.userAvatar,
                                isProcessing: isProcessing,
                                onVerify: () => _verifyPR(prData),
                                onReject: () => _rejectPR(prData),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: 5, // Show 5 skeleton cards
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          // Summary card skeleton
          return Container(
            height: 68,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TetherTokens.defaultAccent.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: TetherTokens.defaultAccent.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: TetherTokens.defaultAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 150,
                  height: 16,
                  decoration: BoxDecoration(
                    color: TetherTokens.cream.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          );
        }
        return const PRCardSkeleton();
      },
    );
  }

  Widget _buildSummaryCard(int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TetherTokens.defaultAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: TetherTokens.defaultAccent.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Symbols.notifications,
            size: 24,
            color: TetherTokens.defaultAccent,
          ),
          const SizedBox(width: 12),
          Text(
            '$count ${count == 1 ? 'PR' : 'PRs'} awaiting verification',
            style: TetherText.sans(
              15,
              color: TetherTokens.cream,
              w: TetherTokens.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isFiltered = _selectedFilter != ExerciseFilter.all;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getEmptyStateIcon(),
            size: 64,
            color: _getEmptyStateColor(),
            fill: isFiltered ? 0 : 1,
          ),
          const SizedBox(height: 20),
          Text(
            isFiltered ? 'No ${_selectedFilter.label} PRs' : 'All caught up!',
            style: TetherText.sans(
              24,
              color: TetherTokens.cream,
              w: TetherTokens.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getEmptyStateHint(),
            style: TetherText.sans(
              14,
              color: TetherTokens.cream.withOpacity(0.5),
              w: TetherTokens.w400,
            ),
            textAlign: TextAlign.center,
          ),
          if (isFiltered) ...[
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => _onFilterChanged(ExerciseFilter.all),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _getEmptyStateColor().withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getEmptyStateColor().withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Symbols.grid_view,
                      size: 18,
                      color: _getEmptyStateColor(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'View All PRs',
                      style: TetherText.sans(
                        14,
                        color: _getEmptyStateColor(),
                        w: TetherTokens.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getEmptyStateIcon() {
    switch (_selectedFilter) {
      case ExerciseFilter.all:
        return Symbols.check_circle;
      case ExerciseFilter.benchPress:
        return Symbols.fitness_center;
      case ExerciseFilter.squat:
        return Symbols.airline_seat_legroom_normal;
      case ExerciseFilter.deadlift:
        return Symbols.exercise;
    }
  }

  Color _getEmptyStateColor() {
    switch (_selectedFilter) {
      case ExerciseFilter.all:
        return AppTheme.toneSuccess;
      case ExerciseFilter.benchPress:
        return const Color(0xFF6366F1); // Indigo
      case ExerciseFilter.squat:
        return const Color(0xFFEC4899); // Pink
      case ExerciseFilter.deadlift:
        return const Color(0xFF8B5CF6); // Purple
    }
  }

  String _getEmptyStateHint() {
    switch (_selectedFilter) {
      case ExerciseFilter.all:
        return 'No pending PRs to review';
      case ExerciseFilter.benchPress:
        return 'No bench press PRs to verify right now';
      case ExerciseFilter.squat:
        return 'No squat PRs awaiting your review';
      case ExerciseFilter.deadlift:
        return 'No deadlift PRs need verification currently';
    }
  }
}

/// Local model to hold PR with user info
class _PendingPRWithUser {
  final PersonalRecord pr;
  final String userName;
  final String? userAvatar;

  _PendingPRWithUser({
    required this.pr,
    required this.userName,
    this.userAvatar,
  });
}

