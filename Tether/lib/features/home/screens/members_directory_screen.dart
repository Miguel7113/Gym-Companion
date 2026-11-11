import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/tether_text.dart';
import '../../../core/theme/tether_tokens.dart';
import '../../../core/navigation/main_navigation.dart';
import '../../social/services/social_extras_service.dart';
import '../../profile/screens/profile_screen.dart';

/// Members Directory screen with search functionality
/// Foundry aesthetic: dark #131211 + cream #F0EBE1 + orange #FF5A1F
class MembersDirectoryScreen extends ConsumerStatefulWidget {
  const MembersDirectoryScreen({super.key});

  @override
  ConsumerState<MembersDirectoryScreen> createState() =>
      _MembersDirectoryScreenState();
}

class _MembersDirectoryScreenState
    extends ConsumerState<MembersDirectoryScreen> {
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
                          'GYM MEMBERS',
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
                              hintText: 'Search members...',
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

          // Members list
          _buildMembersList(),
        ],
      ),
    );
  }

  Widget _buildMembersList() {
    final membersAsync = ref.watch(
      _searchQuery.isEmpty
          ? homeMembersDirectoryProvider
          : _filteredMembersProvider(_searchQuery),
    );

    return membersAsync.when(
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
                'Failed to load members',
                style: TetherText.sans(
                  16,
                  color: TetherTokens.cream,
                  w: TetherTokens.w600,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => ref.invalidate(homeMembersDirectoryProvider),
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
      data: (members) {
        if (members.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Symbols.group,
                    size: 48,
                    color: TetherTokens.cream.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isSearching ? 'No members found' : 'No members yet',
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
                final member = members[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildMemberCard(member),
                );
              },
              childCount: members.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMemberCard(GymMemberDirectoryEntry member) {
    final initials = _getInitials(member.displayName);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MemberProfileScreen(memberId: member.userId),
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
            // Avatar
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: TetherTokens.ink,
                shape: BoxShape.circle,
                border: member.isTrainingNow
                    ? Border.all(
                        color: TetherTokens.defaultAccent,
                        width: 2,
                      )
                    : null,
              ),
              child: Text(
                initials,
                style: TetherText.sans(
                  16,
                  color: TetherTokens.cream,
                  w: TetherTokens.w600,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Name and status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.displayName,
                    style: TetherText.sans(
                      15,
                      color: TetherTokens.ink,
                      w: TetherTokens.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (member.isTrainingNow) ...[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: TetherTokens.defaultAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Training now',
                          style: TetherText.sans(
                            12,
                            color: TetherTokens.ink.withOpacity(0.6),
                            w: TetherTokens.w400,
                          ),
                        ),
                      ] else
                        Text(
                          'Member',
                          style: TetherText.sans(
                            12,
                            color: TetherTokens.ink.withOpacity(0.6),
                            w: TetherTokens.w400,
                          ),
                        ),
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

// Provider for filtered members
final _filteredMembersProvider = FutureProvider.family<
    List<GymMemberDirectoryEntry>, String>((ref, query) async {
  return ref.read(socialExtrasServiceProvider).listMemberDirectory(q: query);
});
