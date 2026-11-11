import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/tether_palette.dart';
import '../../../core/theme/tether_text.dart';
import '../../../core/theme/tether_tokens.dart';
import '../../../core/widgets/cached_media.dart';
import '../../profile/models/personal_record.dart';

/// Leaderboard Card for Train Tab
/// Shows top 3 for Bench Press by default
class LeaderboardCard extends StatelessWidget {
  final List<LeaderboardEntry> topThree;
  final bool loading;
  final VoidCallback onViewAll;

  const LeaderboardCard({
    super.key,
    required this.topThree,
    required this.loading,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.tether;

    return Container(
      decoration: BoxDecoration(
        color: TetherTokens.nightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: p.accent.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Symbols.emoji_events,
                      size: 24,
                      color: p.accent,
                      fill: 1,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LEADERBOARD',
                          style: TetherText.sans(
                            11,
                            color: TetherTokens.cream.withOpacity(0.6),
                            w: TetherTokens.w600,
                            ls: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Bench Press',
                          style: TetherText.sans(
                            16,
                            color: TetherTokens.cream,
                            w: TetherTokens.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: onViewAll,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: p.accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'VIEW ALL',
                      style: TetherText.sans(
                        10,
                        color: TetherTokens.ink,
                        w: TetherTokens.w800,
                        ls: 0.6,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(
            height: 1,
            color: TetherTokens.cream.withOpacity(0.1),
          ),

          // Top 3 List or Loading
          if (loading)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(
                  color: p.accent,
                  strokeWidth: 2,
                ),
              ),
            )
          else if (topThree.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No records yet. Be the first!',
                  style: TetherText.sans(
                    13,
                    color: TetherTokens.cream.withOpacity(0.5),
                    w: TetherTokens.w400,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: topThree.length,
              separatorBuilder: (_, __) => Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: TetherTokens.cream.withOpacity(0.05),
              ),
              itemBuilder: (context, index) {
                final entry = topThree[index];
                return _buildLeaderboardItem(entry, index + 1, p);
              },
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
    final rankColor = rank == 1
        ? const Color(0xFFFFD700) // Gold
        : rank == 2
            ? const Color(0xFFC0C0C0) // Silver
            : const Color(0xFFCD7F32); // Bronze

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rankColor.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: rankColor,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TetherText.sans(
                  14,
                  color: rankColor,
                  w: TetherTokens.w800,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: p.accent.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: ClipOval(
              child: entry.user.avatarPath != null
                  ? AppCachedImage(
                      url: entry.user.avatarPath!,
                      width: 36,
                      height: 36,
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
                14,
                color: TetherTokens.cream,
                w: TetherTokens.w600,
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
                  15,
                  color: p.accent,
                  w: TetherTokens.w800,
                ),
              ),
              Text(
                '${entry.reps} ${entry.reps == 1 ? 'rep' : 'reps'}',
                style: TetherText.sans(
                  11,
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
            14,
            color: TetherTokens.cream,
            w: TetherTokens.w600,
          ),
        ),
      ),
    );
  }
}
