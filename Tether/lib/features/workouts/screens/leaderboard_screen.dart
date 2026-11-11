import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/tether_palette.dart';
import '../../../core/theme/tether_text.dart';
import '../../../core/theme/tether_tokens.dart';
import '../../../core/widgets/cached_media.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/models/personal_record.dart';
import '../../profile/services/personal_records_service.dart';

/// Full Leaderboard Screen with Big 3 exercises and gender filtering
class LeaderboardScreen extends ConsumerStatefulWidget {
  final String? initialExercise;

  const LeaderboardScreen({
    super.key,
    this.initialExercise,
  });

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _genderFilter; // null, 'male', 'female'
  
  final List<String> _exercises = ['Bench Press', 'Squat', 'Deadlift'];
  
  Map<String, List<LeaderboardEntry>> _leaderboards = {};
  Map<String, bool> _loading = {};
  Map<String, Map<String, dynamic>?> _userRanks = {};

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.initialExercise != null
        ? _exercises.indexOf(widget.initialExercise!)
        : 0;
    _tabController = TabController(
      length: _exercises.length,
      vsync: this,
      initialIndex: initialIndex >= 0 ? initialIndex : 0,
    );
    _tabController.addListener(_onTabChanged);
    _loadCurrentExercise();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      _loadCurrentExercise();
    }
  }

  String get _currentExercise => _exercises[_tabController.index];

  Future<void> _loadCurrentExercise() async {
    final exercise = _currentExercise;
    if (_leaderboards.containsKey(_cacheKey(exercise))) return;
    await _loadLeaderboard(exercise);
  }

  String _cacheKey(String exercise) =>
      '$exercise${_genderFilter != null ? '_$_genderFilter' : ''}';

  Future<void> _loadLeaderboard(String exercise) async {
    final cacheKey = _cacheKey(exercise);
    setState(() => _loading[cacheKey] = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user?.gymId == null) {
        if (mounted) setState(() => _loading[cacheKey] = false);
        return;
      }

      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      if (token == null) {
        if (mounted) setState(() => _loading[cacheKey] = false);
        return;
      }

      final service = ref.read(personalRecordsServiceProvider);
      
      // Load leaderboard
      final leaderboard = await service.getLeaderboard(
        gymId: user!.gymId,
        exercise: exercise,
        gender: _genderFilter,
        limit: 50,
        token: token,
      );

      // Load user's rank
      Map<String, dynamic>? userRank;
      try {
        userRank = await service.getUserRank(
          userId: user.memberId,
          gymId: user.gymId,
          exercise: exercise,
          gender: _genderFilter,
          token: token,
        );
      } catch (e) {
        debugPrint('[LeaderboardScreen] user rank failed: $e');
      }

      if (mounted) {
        setState(() {
          _leaderboards[cacheKey] = leaderboard;
          _userRanks[cacheKey] = userRank;
          _loading[cacheKey] = false;
        });
      }
    } catch (e) {
      debugPrint('[LeaderboardScreen] leaderboard failed: $e');
      if (mounted) {
        setState(() => _loading[cacheKey] = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load leaderboard: $e')),
        );
      }
    }
  }

  void _toggleGenderFilter(String? gender) {
    if (_genderFilter == gender) {
      // Turn off filter
      setState(() => _genderFilter = null);
    } else {
      setState(() => _genderFilter = gender);
    }
    // Clear cache and reload
    _leaderboards.clear();
    _userRanks.clear();
    _loadCurrentExercise();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.tether;
    final cacheKey = _cacheKey(_currentExercise);
    final entries = _leaderboards[cacheKey] ?? [];
    final loading = _loading[cacheKey] ?? true;
    final userRank = _userRanks[cacheKey];

    return Scaffold(
      backgroundColor: TetherTokens.ink,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
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
                      Icon(
                        Symbols.emoji_events,
                        size: 28,
                        color: p.accent,
                        fill: 1,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Leaderboard',
                    style: TetherText.sans(
                      32,
                      w: TetherTokens.w800,
                      color: TetherTokens.cream,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Top lifters in your gym',
                    style: TetherText.sans(
                      14,
                      color: TetherTokens.cream.withOpacity(0.6),
                      w: TetherTokens.w400,
                    ),
                  ),
                ],
              ),
            ),

            // Gender Filter
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  _GenderFilterChip(
                    label: 'All',
                    isSelected: _genderFilter == null,
                    onTap: () => _toggleGenderFilter(null),
                    accentColor: p.accent,
                  ),
                  const SizedBox(width: 8),
                  _GenderFilterChip(
                    label: 'Male',
                    isSelected: _genderFilter == 'male',
                    onTap: () => _toggleGenderFilter('male'),
                    accentColor: p.accent,
                  ),
                  const SizedBox(width: 8),
                  _GenderFilterChip(
                    label: 'Female',
                    isSelected: _genderFilter == 'female',
                    onTap: () => _toggleGenderFilter('female'),
                    accentColor: p.accent,
                  ),
                ],
              ),
            ),

            // Exercise Tabs
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: TetherTokens.cream.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: p.accent,
                indicatorWeight: 3,
                labelColor: TetherTokens.cream,
                unselectedLabelColor: TetherTokens.cream.withOpacity(0.5),
                labelStyle: TetherText.sans(14, w: TetherTokens.w800),
                unselectedLabelStyle: TetherText.sans(14, w: TetherTokens.w600),
                tabs: _exercises
                    .map((ex) => Tab(text: ex.toUpperCase()))
                    .toList(),
              ),
            ),

            // User Rank Card (if has PR)
            if (userRank != null && userRank['rank'] != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _buildUserRankCard(userRank, p),
              ),

            // Leaderboard List
            Expanded(
              child: loading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: p.accent,
                      ),
                    )
                  : entries.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Symbols.emoji_events,
                                size: 64,
                                color: TetherTokens.cream.withOpacity(0.2),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No records yet',
                                style: TetherText.sans(
                                  18,
                                  color: TetherTokens.cream,
                                  w: TetherTokens.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Be the first to set a PR!',
                                style: TetherText.sans(
                                  14,
                                  color: TetherTokens.cream.withOpacity(0.5),
                                  w: TetherTokens.w400,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: entries.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final entry = entries[index];
                            return _buildLeaderboardItem(
                              entry,
                              index + 1,
                              p,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserRankCard(Map<String, dynamic> rankData, TetherPalette p) {
    final rank = rankData['rank'] as int;
    final total = rankData['total'] as int;
    final pr = PersonalRecord.fromJson(rankData['pr']);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.accent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: p.accent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: p.accent,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TetherText.sans(
                  16,
                  color: TetherTokens.ink,
                  w: TetherTokens.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Rank',
                  style: TetherText.sans(
                    11,
                    color: TetherTokens.cream.withOpacity(0.6),
                    w: TetherTokens.w400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$rank of $total',
                  style: TetherText.sans(
                    18,
                    color: TetherTokens.cream,
                    w: TetherTokens.w800,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                pr.weightKg != null ? '${pr.weightKg}kg' : 'Bodyweight',
                style: TetherText.sans(
                  16,
                  color: p.accent,
                  w: TetherTokens.w800,
                ),
              ),
              Text(
                '${pr.reps} ${pr.reps == 1 ? 'rep' : 'reps'}',
                style: TetherText.sans(
                  12,
                  color: TetherTokens.cream.withOpacity(0.5),
                  w: TetherTokens.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem(
    LeaderboardEntry entry,
    int rank,
    TetherPalette p,
  ) {
    final isTopThree = rank <= 3;
    final rankColor = rank == 1
        ? const Color(0xFFFFD700) // Gold
        : rank == 2
            ? const Color(0xFFC0C0C0) // Silver
            : rank == 3
                ? const Color(0xFFCD7F32) // Bronze
                : TetherTokens.cream.withOpacity(0.3);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isTopThree
            ? TetherTokens.nightCard
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: isTopThree
            ? Border.all(
                color: rankColor.withOpacity(0.3),
                width: 1,
              )
            : null,
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isTopThree
                  ? rankColor.withOpacity(0.2)
                  : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: rankColor,
                width: isTopThree ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TetherText.sans(
                  isTopThree ? 15 : 13,
                  color: isTopThree ? rankColor : TetherTokens.cream,
                  w: TetherTokens.w800,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isTopThree
                    ? rankColor.withOpacity(0.5)
                    : TetherTokens.cream.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: entry.user.avatarPath != null
                  ? AppCachedImage(
                      url: entry.user.avatarPath!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      fallback: _buildAvatarPlaceholder(
                        entry.user.displayName ?? 'M',
                      ),
                    )
                  : _buildAvatarPlaceholder(entry.user.displayName ?? 'M'),
            ),
          ),

          const SizedBox(width: 12),

          // Name
          Expanded(
            child: Text(
              entry.user.displayName ?? 'Member',
              style: TetherText.sans(
                15,
                color: TetherTokens.cream,
                w: isTopThree ? TetherTokens.w600 : TetherTokens.w400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // PR Stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                entry.weightKg != null
                    ? '${entry.weightKg}kg'
                    : 'Bodyweight',
                style: TetherText.sans(
                  16,
                  color: isTopThree ? p.accent : TetherTokens.cream,
                  w: TetherTokens.w800,
                ),
              ),
              Text(
                '${entry.reps} ${entry.reps == 1 ? 'rep' : 'reps'}',
                style: TetherText.sans(
                  12,
                  color: TetherTokens.cream.withOpacity(0.5),
                  w: TetherTokens.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder(String name) {
    final initials = name.split(' ').take(2).map((w) => w[0]).join();
    return Container(
      color: TetherTokens.nightCard,
      child: Center(
        child: Text(
          initials.toUpperCase(),
          style: TetherText.sans(
            16,
            color: TetherTokens.cream,
            w: TetherTokens.w600,
          ),
        ),
      ),
    );
  }
}

class _GenderFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color accentColor;

  const _GenderFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : TetherTokens.nightCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? accentColor
                : TetherTokens.cream.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: TetherText.sans(
            11,
            color: isSelected ? TetherTokens.ink : TetherTokens.cream,
            w: TetherTokens.w800,
            ls: 0.5,
          ),
        ),
      ),
    );
  }
}
