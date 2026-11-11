import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/tether_text.dart';
import '../../../core/theme/tether_tokens.dart';
import '../models/personal_record.dart';

/// Personal Records card for profile screen
/// Shows top 5 verified PRs with unverified badge for pending ones
class PersonalRecordsCard extends StatelessWidget {
  final List<PersonalRecord> records;
  final bool isOwnProfile;
  final VoidCallback? onManagePRs;

  const PersonalRecordsCard({
    super.key,
    required this.records,
    required this.isOwnProfile,
    this.onManagePRs,
  });

  @override
  Widget build(BuildContext context) {
    // Filter: show only verified PRs for public view
    final displayRecords =
        isOwnProfile ? records : records.where((pr) => pr.isVerified).toList();

    return Container(
      decoration: BoxDecoration(
        color: TetherTokens.cream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: TetherTokens.ink.withOpacity(0.1),
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
                      size: 20,
                      color: TetherTokens.defaultAccent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'PERSONAL RECORDS',
                      style: TetherText.sans(
                        11,
                        color: TetherTokens.ink.withOpacity(0.6),
                        w: TetherTokens.w600,
                        ls: 0.8,
                      ),
                    ),
                  ],
                ),
                if (isOwnProfile && onManagePRs != null)
                  GestureDetector(
                    onTap: onManagePRs,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: TetherTokens.ink,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'MANAGE',
                        style: TetherText.sans(
                          10,
                          color: TetherTokens.cream,
                          w: TetherTokens.w600,
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
            color: TetherTokens.ink.withOpacity(0.1),
          ),

          // PRs List or Empty State
          if (displayRecords.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Symbols.fitness_center,
                      size: 32,
                      color: TetherTokens.ink.withOpacity(0.3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isOwnProfile
                          ? 'No verified PRs yet'
                          : 'No PRs to display',
                      style: TetherText.sans(
                        13,
                        color: TetherTokens.ink.withOpacity(0.5),
                        w: TetherTokens.w400,
                      ),
                    ),
                    if (isOwnProfile) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Tap MANAGE to add your PRs',
                        style: TetherText.sans(
                          11,
                          color: TetherTokens.ink.withOpacity(0.4),
                          w: TetherTokens.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: displayRecords.take(5).length,
              separatorBuilder: (_, __) => Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: TetherTokens.ink.withOpacity(0.05),
              ),
              itemBuilder: (context, index) {
                final pr = displayRecords[index];
                return _buildPRItem(pr);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPRItem(PersonalRecord pr) {
    final weightText = pr.weightKg != null ? '${pr.weightKg}kg' : 'Bodyweight';
    final repsText = '${pr.reps} ${pr.reps == 1 ? 'rep' : 'reps'}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Exercise name
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Text(
                  pr.exerciseName,
                  style: TetherText.sans(
                    14,
                    color: TetherTokens.ink,
                    w: TetherTokens.w600,
                  ),
                ),
                if (!pr.isVerified && isOwnProfile) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: pr.isRejected
                          ? TetherTokens.dayMuted.withOpacity(0.1)
                          : TetherTokens.defaultAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: pr.isRejected
                            ? TetherTokens.dayMuted.withOpacity(0.3)
                            : TetherTokens.defaultAccent.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      pr.isRejected ? 'REJECTED' : 'PENDING',
                      style: TetherText.sans(
                        8,
                        color: pr.isRejected
                            ? TetherTokens.dayMuted
                            : TetherTokens.defaultAccent,
                        w: TetherTokens.w600,
                        ls: 0.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Stats (right-aligned)
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  weightText,
                  style: TetherText.sans(
                    14,
                    color: TetherTokens.ink,
                    w: TetherTokens.w600,
                  ),
                ),
                Text(
                  repsText,
                  style: TetherText.sans(
                    11,
                    color: TetherTokens.ink.withOpacity(0.5),
                    w: TetherTokens.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
