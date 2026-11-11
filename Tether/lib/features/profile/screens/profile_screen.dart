import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/tether_palette.dart';
import '../../../core/theme/tether_text.dart';
import '../../../core/theme/tether_tokens.dart';
import '../../../core/widgets/cached_media.dart';
import '../../auth/providers/auth_provider.dart';
import '../../workouts/services/offline_workout_service.dart';
import '../models/member_profile.dart';
import '../services/profile_service.dart';
import '../widgets/personal_records_card.dart';
import '../widgets/pr_showcase_widget.dart';
import '../../social/models/feed_models.dart';
import 'settings_screen.dart';
import 'edit_profile_screen.dart';
import 'manage_prs_screen.dart';

/// Redesigned Profile screen matching home page aesthetic
/// Dark header with large avatar + cream sheet with wide stat cards
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.tether;
    final user = ref.watch(currentUserProvider);
    final memberId = user?.memberId;
    final profileAsync = (memberId != null && memberId.isNotEmpty)
        ? ref.watch(memberProfileProvider(memberId))
        : null;

    final displayName = profileAsync?.valueOrNull?.displayName ??
        user?.displayName ??
        'Member';
    final bio = profileAsync?.valueOrNull?.bio;
    final gymName = profileAsync?.valueOrNull?.gymName ?? 'Modern Fitness Gym';
    final avatarUrl = profileAsync?.valueOrNull?.avatarUrl;
    // TODO: Add createdAt field to MemberProfile or use different date source
    final memberSince = null as DateTime?;

    // TODO: Get real stats from providers
    const totalWorkouts = 42;
    const currentStreak = 7;
    const personalRecords = 15;

    return Scaffold(
      backgroundColor: TetherTokens.ink,
      body: SafeArea(
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Dark header section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top bar with settings
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Profile',
                          style: TetherText.sans(
                            32,
                            w: TetherTokens.w800,
                            color: TetherTokens.cream,
                          ),
                        ),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: TetherTokens.cream.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SettingsScreen(),
                              ),
                            ),
                            icon: Icon(
                              Symbols.settings,
                              size: 18,
                              color: TetherTokens.cream,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Large avatar + user info
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: p.accent,
                              width: 3,
                            ),
                          ),
                          child: ClipOval(
                            child: avatarUrl != null
                                ? AppCachedImage(
                                    url: avatarUrl,
                                    width: 96,
                                    height: 96,
                                    fit: BoxFit.cover,
                                    fallback: _buildAvatarPlaceholder(
                                        displayName),
                                  )
                                : _buildAvatarPlaceholder(displayName),
                          ),
                        ),

                        const SizedBox(width: 20),

                        // Name and info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Text(
                                displayName.toUpperCase(),
                                style: TetherText.sans(
                                  24,
                                  w: TetherTokens.w800,
                                  color: TetherTokens.cream,
                                  height: 1.0,
                                  ls: 0.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                gymName,
                                style: TetherText.sans(
                                  13,
                                  color: TetherTokens.cream.withOpacity(0.6),
                                  w: TetherTokens.w400,
                                ),
                              ),
                              if (bio != null && bio.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  bio,
                                  style: TetherText.sans(
                                    12,
                                    color: TetherTokens.cream.withOpacity(0.7),
                                    w: TetherTokens.w400,
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              if (memberSince != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Member since ${_formatDate(memberSince)}',
                                  style: TetherText.sans(
                                    11,
                                    color: TetherTokens.cream.withOpacity(0.5),
                                    w: TetherTokens.w400,
                                    ls: 0.8,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            context,
                            'EDIT PROFILE',
                            Symbols.edit,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const EditProfileScreen(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildIconButton(
                          Symbols.share,
                          () {
                            // Share profile
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Cream sheet section
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  color: TetherTokens.cream,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats label
                      Text(
                        'YOUR STATS',
                        style: TetherText.sans(
                          10,
                          color: TetherTokens.ink.withOpacity(0.5),
                          w: TetherTokens.w400,
                          ls: 0.8,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Stats grid (2x2)
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context,
                              '$totalWorkouts',
                              'WORKOUTS',
                              Symbols.fitness_center,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              '$currentStreak',
                              'DAY STREAK',
                              Symbols.local_fire_department,
                              isAccent: true,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Personal Records Section
                      Text(
                        'PERSONAL RECORDS',
                        style: TetherText.sans(
                          10,
                          color: TetherTokens.ink.withOpacity(0.5),
                          w: TetherTokens.w400,
                          ls: 0.8,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // TODO: Replace with actual PR data
                      PersonalRecordsCard(
                        records: const [], // Will be populated from provider
                        isOwnProfile: true,
                        onManagePRs: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ManagePRsScreen(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // Recent activity
                      if (profileAsync?.valueOrNull?.posts != null &&
                          profileAsync!.valueOrNull!.posts.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'RECENT ACTIVITY',
                              style: TetherText.sans(
                                10,
                                color: TetherTokens.ink.withOpacity(0.5),
                                w: TetherTokens.w400,
                                ls: 0.8,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                // Navigate to full history / social feed
                              },
                              child: Row(
                                children: [
                                  Text(
                                    'View all',
                                    style: TetherText.sans(
                                      13,
                                      color: TetherTokens.ink,
                                      w: TetherTokens.w800,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.north_east_rounded,
                                    size: 14,
                                    color: TetherTokens.ink,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Show actual posts from API
                        ...profileAsync.valueOrNull!.posts.take(3).map((post) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildPostCard(context, post),
                          );
                        }),

                        const SizedBox(height: 24),
                      ],

                      // Achievements
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ACHIEVEMENTS',
                            style: TetherText.sans(
                              10,
                              color: TetherTokens.ink.withOpacity(0.5),
                              w: TetherTokens.w400,
                              ls: 0.8,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              // Navigate to all achievements
                            },
                            child: Row(
                              children: [
                                Text(
                                  'View all',
                                  style: TetherText.sans(
                                    13,
                                    color: TetherTokens.ink,
                                    w: TetherTokens.w800,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.north_east_rounded,
                                  size: 14,
                                  color: TetherTokens.ink,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Achievement badges
                      Row(
                        children: [
                          Expanded(
                            child: _buildAchievementCard(
                              context,
                              '🏋️',
                              'First Workout',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildAchievementCard(
                              context,
                              '🔥',
                              '7 Day Streak',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildAchievementCard(
                              context,
                              '💪',
                              '100 Workouts',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Quick settings
                      Text(
                        'QUICK SETTINGS',
                        style: TetherText.sans(
                          10,
                          color: TetherTokens.ink.withOpacity(0.5),
                          w: TetherTokens.w400,
                          ls: 0.8,
                        ),
                      ),

                      const SizedBox(height: 12),

                      _buildSettingsTile(
                        'Account Settings',
                        Symbols.person,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 10),

                      _buildSettingsTile(
                        'Notifications',
                        Symbols.notifications,
                        () {
                          // Navigate to notifications settings
                        },
                      ),

                      const SizedBox(height: 10),

                      _buildSettingsTile(
                        'Help & Support',
                        Symbols.help,
                        () {
                          // Navigate to help
                        },
                      ),

                      const SizedBox(height: 10),

                      _buildSettingsTile(
                        'Log Out',
                        Symbols.logout,
                        () async {
                          // TODO: Implement sign out
                          Navigator.of(context).pop();
                        },
                        isDanger: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
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
            32,
            color: TetherTokens.cream,
            w: TetherTokens.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: TetherTokens.nightCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: TetherTokens.cream.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: TetherTokens.cream,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TetherText.sans(
                13,
                color: TetherTokens.cream,
                w: TetherTokens.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: TetherTokens.nightCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: TetherTokens.cream.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: TetherTokens.cream,
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String value,
    String label,
    IconData icon, {
    bool isAccent = false,
  }) {
    final p = context.tether;
    final accentColor = isAccent ? p.accent : TetherTokens.ink;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE4DFD3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: TetherText.sans(
                  32,
                  color: accentColor,
                  w: TetherTokens.w800,
                  height: 1.0,
                ),
              ),
              Icon(
                icon,
                size: 24,
                color: accentColor.withOpacity(0.5),
                fill: isAccent ? 1 : 0,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TetherText.sans(
              10,
              color: TetherTokens.ink.withOpacity(0.6),
              w: TetherTokens.w600,
              ls: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(
    BuildContext context,
    String workoutName,
    String details,
    String volume,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE4DFD3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: TetherTokens.ink,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Symbols.fitness_center,
              size: 20,
              color: TetherTokens.cream,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workoutName,
                  style: TetherText.sans(
                    14,
                    color: TetherTokens.ink,
                    w: TetherTokens.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  details,
                  style: TetherText.sans(
                    12,
                    color: TetherTokens.ink.withOpacity(0.6),
                    w: TetherTokens.w400,
                  ),
                ),
              ],
            ),
          ),
          Text(
            volume,
            style: TetherText.sans(
              13,
              color: context.tether.accent,
              w: TetherTokens.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, FeedPost post) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE4DFD3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post content
          if (post.content.isNotEmpty) ...[
            Text(
              post.content,
              style: TetherText.sans(
                14,
                color: TetherTokens.ink,
                w: TetherTokens.w600,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
          ],
          
          // Post metadata
          Row(
            children: [
              Icon(
                Symbols.schedule,
                size: 14,
                color: TetherTokens.ink.withOpacity(0.4),
              ),
              const SizedBox(width: 4),
              Text(
                post.timeAgo,
                style: TetherText.sans(
                  12,
                  color: TetherTokens.ink.withOpacity(0.5),
                  w: TetherTokens.w400,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Symbols.favorite,
                size: 14,
                color: TetherTokens.ink.withOpacity(0.4),
              ),
              const SizedBox(width: 4),
              Text(
                '${post.likeCount}',
                style: TetherText.sans(
                  12,
                  color: TetherTokens.ink.withOpacity(0.5),
                  w: TetherTokens.w400,
                ),
              ),
              if (post.commentCount > 0) ...[
                const SizedBox(width: 16),
                Icon(
                  Symbols.chat_bubble,
                  size: 14,
                  color: TetherTokens.ink.withOpacity(0.4),
                ),
                const SizedBox(width: 4),
                Text(
                  '${post.commentCount}',
                  style: TetherText.sans(
                    12,
                    color: TetherTokens.ink.withOpacity(0.5),
                    w: TetherTokens.w400,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(
    BuildContext context,
    String emoji,
    String label,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE4DFD3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TetherText.sans(
              11,
              color: TetherTokens.ink,
              w: TetherTokens.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    String label,
    IconData icon,
    VoidCallback onTap, {
    bool isDanger = false,
  }) {
    final color = isDanger ? const Color(0xFFDC2626) : TetherTokens.ink;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFE4DFD3),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TetherText.sans(
                  14,
                  color: color,
                  w: TetherTokens.w600,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: color.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Member Profile (other users)
// ─────────────────────────────────────────────────────────────────────────────

class MemberProfileScreen extends ConsumerWidget {
  final String memberId;

  const MemberProfileScreen({super.key, required this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(memberProfileProvider(memberId));

    return Scaffold(
      backgroundColor: TetherTokens.ink,
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: TetherTokens.defaultAccent,
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Failed to load profile',
                style: TetherText.sans(
                  16,
                  color: TetherTokens.cream,
                  w: TetherTokens.w600,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => ref.invalidate(memberProfileProvider(memberId)),
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
        data: (profile) => CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Container(
                color: TetherTokens.ink,
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
                child: Row(
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
                        profile.displayName,
                        style: TetherText.sans(
                          20,
                          color: TetherTokens.cream,
                          w: TetherTokens.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Profile content
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 12),

                  // Avatar and stats
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4DFD3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        // Avatar
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: TetherTokens.ink,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: TetherTokens.defaultAccent,
                              width: 3,
                            ),
                          ),
                          child: profile.avatarUrl != null &&
                                  profile.avatarUrl!.isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    profile.avatarUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Center(
                                      child: Text(
                                        _getInitials(profile.displayName),
                                        style: TetherText.sans(
                                          24,
                                          color: TetherTokens.cream,
                                          w: TetherTokens.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    _getInitials(profile.displayName),
                                    style: TetherText.sans(
                                      24,
                                      color: TetherTokens.cream,
                                      w: TetherTokens.w600,
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),

                        // Name
                        Text(
                          profile.displayName,
                          style: TetherText.sans(
                            20,
                            color: TetherTokens.ink,
                            w: TetherTokens.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (profile.gymName != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            profile.gymName!,
                            style: TetherText.sans(
                              13,
                              color: TetherTokens.ink.withOpacity(0.6),
                              w: TetherTokens.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            profile.bio!,
                            style: TetherText.sans(
                              12,
                              color: TetherTokens.ink.withOpacity(0.7),
                              w: TetherTokens.w400,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 20),

                        // Stats row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              'Workouts',
                              '${profile.stats.workoutCount}',
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: TetherTokens.ink.withOpacity(0.1),
                            ),
                            _buildStatItem(
                              'Streak',
                              '${profile.stats.streakDays}',
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: TetherTokens.ink.withOpacity(0.1),
                            ),
                            _buildStatItem(
                              'Sets',
                              '${profile.stats.totalSets}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // PR Showcase
                  PRShowcaseWidget(
                    userId: memberId,
                    gymId: profile.gymId,
                    showGenderFilter: false, // No gender filter for individual profiles
                  ),
                  const SizedBox(height: 24),

                  // Recent activity (real posts from API)
                  if (profile.posts.isNotEmpty) ...[
                    Text(
                      'RECENT ACTIVITY',
                      style: TetherText.sans(
                        10,
                        color: TetherTokens.cream.withOpacity(0.5),
                        w: TetherTokens.w400,
                        ls: 0.8,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Show actual posts
                    ...profile.posts.take(3).map((post) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildPublicPostCard(context, post),
                      );
                    }),
                  ],
                  
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TetherText.sans(
            24,
            color: TetherTokens.ink,
            w: TetherTokens.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: TetherText.sans(
            10,
            color: TetherTokens.ink.withOpacity(0.5),
            w: TetherTokens.w400,
            ls: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCard(
    BuildContext context,
    String title,
    String time,
    String details,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE4DFD3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TetherText.sans(
              14,
              color: TetherTokens.ink,
              w: TetherTokens.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: TetherText.sans(
              12,
              color: TetherTokens.ink.withOpacity(0.5),
              w: TetherTokens.w400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            details,
            style: TetherText.sans(
              13,
              color: TetherTokens.ink.withOpacity(0.7),
              w: TetherTokens.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublicPostCard(BuildContext context, FeedPost post) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE4DFD3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post content
          if (post.content.isNotEmpty) ...[
            Text(
              post.content,
              style: TetherText.sans(
                14,
                color: TetherTokens.ink,
                w: TetherTokens.w600,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
          ],
          
          // Post metadata
          Row(
            children: [
              Icon(
                Symbols.schedule,
                size: 14,
                color: TetherTokens.ink.withOpacity(0.4),
              ),
              const SizedBox(width: 4),
              Text(
                post.timeAgo,
                style: TetherText.sans(
                  12,
                  color: TetherTokens.ink.withOpacity(0.5),
                  w: TetherTokens.w400,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Symbols.favorite,
                size: 14,
                color: TetherTokens.ink.withOpacity(0.4),
              ),
              const SizedBox(width: 4),
              Text(
                '${post.likeCount}',
                style: TetherText.sans(
                  12,
                  color: TetherTokens.ink.withOpacity(0.5),
                  w: TetherTokens.w400,
                ),
              ),
              if (post.commentCount > 0) ...[
                const SizedBox(width: 16),
                Icon(
                  Symbols.chat_bubble,
                  size: 14,
                  color: TetherTokens.ink.withOpacity(0.4),
                ),
                const SizedBox(width: 4),
                Text(
                  '${post.commentCount}',
                  style: TetherText.sans(
                    12,
                    color: TetherTokens.ink.withOpacity(0.5),
                    w: TetherTokens.w400,
                  ),
                ),
              ],
            ],
          ),
        ],
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
