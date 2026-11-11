import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/tether_text.dart';
import '../../../core/theme/tether_tokens.dart';
import '../../../core/navigation/main_navigation.dart';
import '../../social/services/social_extras_service.dart';
import '../../profile/screens/profile_screen.dart';

/// Coaches Directory screen 
/// Foundry aesthetic: dark #131211 + cream #F0EBE1 + orange #FF5A1F
/// Note: Coaches will eventually have their own special profile view
class CoachesDirectoryScreen extends ConsumerStatefulWidget {
  const CoachesDirectoryScreen({super.key});

  @override
  ConsumerState<CoachesDirectoryScreen> createState() =>
      _CoachesDirectoryScreenState();
}

class _CoachesDirectoryScreenState
    extends ConsumerState<CoachesDirectoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _isSearching = value.isNotEmpty;
    });
  }

  List<GymCoach> _filterCoaches(List<GymCoach> coaches) {
    if (_searchQuery.isEmpty) return coaches;
    final query = _searchQuery.toLowerCase();
    return coaches
        .where((coach) => coach.displayName.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TetherTokens.ink,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              color: TetherTokens.ink,
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button and title
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE4DFD3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            size: 20,
                            color: TetherTokens.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'COACHES',
                          style: TetherText.sans(
                            20,
                            color: TetherTokens.cream,
                            w: TetherTokens.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Search bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4DFD3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Symbols.search,
                          size: 20,
                          color: TetherTokens.ink.withOpacity(0.4),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            style: TetherText.sans(
                              14,
                              color: TetherTokens.ink,
                              w: TetherTokens.w400,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search coaches...',
                              hintStyle: TetherText.sans(
                                14,
                                color: TetherTokens.ink.withOpacity(0.4),
                                w: TetherTokens.w400,
                              ),
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        if (_isSearching)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                            child: Icon(
                              Icons.close,
                              size: 20,
                              color: TetherTokens.ink.withOpacity(0.4),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Coaches list
          _buildCoachesList(),
        ],
      ),
    );
  }

  Widget _buildCoachesList() {
    final coachesAsync = ref.watch(homeCoachesProvider);

    return coachesAsync.when(
      loading: () => const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(
            color: TetherTokens.defaultAccent,
          ),
        ),
      ),
      error: (error, stack) => SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Failed to load coaches',
                style: TetherText.sans(
                  16,
                  color: TetherTokens.cream,
                  w: TetherTokens.w600,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => ref.invalidate(homeCoachesProvider),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: TetherTokens.defaultAccent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Retry',
                    style: TetherText.sans(
                      14,
                      color: TetherTokens.ink,
                      w: TetherTokens.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      data: (coaches) {
        final filteredCoaches = _filterCoaches(coaches);

        if (filteredCoaches.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Symbols.person,
                    size: 48,
                    color: TetherTokens.cream.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isSearching ? 'No coaches found' : 'No coaches yet',
                    style: TetherText.sans(
                      18,
                      color: TetherTokens.cream,
                      w: TetherTokens.w600,
                    ),
                  ),
                  if (_isSearching) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Try a different search',
                      style: TetherText.sans(
                        14,
                        color: TetherTokens.cream.withOpacity(0.5),
                        w: TetherTokens.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final coach = filteredCoaches[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildCoachCard(coach),
                );
              },
              childCount: filteredCoaches.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCoachCard(GymCoach coach) {
    final initials = _getInitials(coach.displayName);

    return GestureDetector(
      onTap: () {
        // TODO: Navigate to CoachProfileScreen once created
        // For now, use the member profile as placeholder
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                MemberProfileScreen(memberId: coach.userId),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFE4DFD3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Avatar with accent color
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: TetherTokens.defaultAccent,
                shape: BoxShape.circle,
              ),
              child: Text(
                initials,
                style: TetherText.sans(
                  16,
                  color: TetherTokens.ink,
                  w: TetherTokens.w600,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Name and info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          coach.displayName,
                          style: TetherText.sans(
                            15,
                            color: TetherTokens.ink,
                            w: TetherTokens.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (coach.isTrainingNow) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Symbols.verified,
                          size: 16,
                          color: TetherTokens.defaultAccent,
                          fill: 1,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        coach.role.toUpperCase(),
                        style: TetherText.sans(
                          11,
                          color: TetherTokens.ink.withOpacity(0.5),
                          w: TetherTokens.w600,
                          ls: 0.5,
                        ),
                      ),
                      if (coach.programCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: TetherTokens.ink.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${coach.programCount} ${coach.programCount == 1 ? 'program' : 'programs'}',
                          style: TetherText.sans(
                            12,
                            color: TetherTokens.ink.withOpacity(0.6),
                            w: TetherTokens.w400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Chevron
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: TetherTokens.ink.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }
}
