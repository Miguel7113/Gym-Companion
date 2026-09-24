import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/cached_media.dart';
import '../../auth/providers/auth_provider.dart';
import '../../social/models/feed_models.dart';
import '../../workouts/services/offline_workout_service.dart';
import '../../workouts/screens/workout_detail_screen.dart';
import '../models/member_profile.dart';
import '../services/profile_service.dart';
import 'settings_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: const _ProfileAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          final memberId = ref.read(currentUserProvider)?.memberId;
          if (memberId != null && memberId.isNotEmpty) {
            ref.invalidate(memberProfileProvider(memberId));
          }
        },
        color: AppTheme.primaryContainer,
        backgroundColor: AppTheme.surfaceContainerHigh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.containerMargin,
                8,
                AppTheme.containerMargin,
                100,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const _ProfileHero(),
                  const SizedBox(height: AppTheme.stackLg),
                  const _OverviewSection(),
                  const SizedBox(height: AppTheme.stackLg),
                  const _ProfileDataSection(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App bar
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ProfileAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: AppTheme.containerMargin,
      title: Text(
        'Profile',
        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
            ),
      ),
      centerTitle: false,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            icon: const Icon(
              Symbols.settings,
              size: 24,
              color: AppTheme.onSurface,
            ),
            tooltip: 'Settings',
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero — WHOOP-style identity block
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileHero extends ConsumerWidget {
  const _ProfileHero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final memberId = user?.memberId;
    final profileAsync = (memberId != null && memberId.isNotEmpty)
        ? ref.watch(memberProfileProvider(memberId))
        : null;

    final displayName = profileAsync?.valueOrNull?.displayName ??
        (user?.displayName?.isNotEmpty == true
            ? user!.displayName!
            : user?.email?.isNotEmpty == true
                ? user!.email!
                : 'Member');
    final gymName = profileAsync?.valueOrNull?.gymName;
    final roleLabel = _roleLabel(user?.role, profileAsync?.valueOrNull?.staffRole);
    final avatarUrl = profileAsync?.valueOrNull?.avatarUrl;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.stackMd),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
        boxShadow: AppTheme.cardElevation,
      ),
      child: Row(
        children: [
          _AvatarRing(url: avatarUrl),
          const SizedBox(width: AppTheme.stackMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  roleLabel,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (gymName != null && gymName.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Symbols.apartment,
                        size: 14,
                        color: AppTheme.primaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          gymName,
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: AppTheme.primaryContainer,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _roleLabel(String? role, String? staffRole) {
    if (staffRole != null && staffRole.isNotEmpty) {
      return '${staffRole[0].toUpperCase()}${staffRole.substring(1)}';
    }
    switch (role) {
      case 'coach':
        return 'Coach';
      case 'admin':
        return 'Admin';
      default:
        return 'Gym member';
    }
  }
}

class _AvatarRing extends StatelessWidget {
  final String? url;
  const _AvatarRing({this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryContainer,
            AppTheme.primaryContainer.withOpacity(0.25),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: AppTheme.neonGlow(opacity: 0.18, blur: 14),
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceContainerHigh,
          shape: BoxShape.circle,
        ),
        clipBehavior: Clip.antiAlias,
        child: url == null
            ? const Icon(
                Symbols.person,
                size: 36,
                color: AppTheme.onSurfaceVariant,
              )
            : AppCachedImage(url: url, fit: BoxFit.cover),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Overview — glanceable metrics (WHOOP tier 1)
// ─────────────────────────────────────────────────────────────────────────────
class _OverviewSection extends ConsumerStatefulWidget {
  const _OverviewSection();

  @override
  ConsumerState<_OverviewSection> createState() => _OverviewSectionState();
}

class _OverviewSectionState extends ConsumerState<_OverviewSection> {
  int _workouts = 0;
  int _week = 0;
  int _setsWeek = 0;
  int _streak = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final svc = ref.read(offlineWorkoutServiceProvider);
    final results = await Future.wait([
      svc.getTotalWorkoutCount(),
      svc.getSessionCountThisWeek(),
      svc.getSetsCountThisWeek(),
      svc.getStreak(),
    ]);
    if (!mounted) return;
    setState(() {
      _workouts = results[0];
      _week = results[1];
      _setsWeek = results[2];
      _streak = results[3];
      _loading = false;
    });
  }

  Color get _streakColor {
    if (_streak <= 0) return AppTheme.metricAttention;
    if (_streak < 3) return AppTheme.metricModerate;
    return AppTheme.metricGood;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SkeletonBox(
        width: double.infinity,
        height: 168,
        radius: AppTheme.radiusXxl,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
        ),
        const SizedBox(height: AppTheme.stackSm),
        // Primary glanceable metric
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppTheme.stackMd),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainer,
            borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
            boxShadow: AppTheme.cardElevation,
          ),
          child: Row(
            children: [
              _StreakRing(days: _streak, color: _streakColor),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Day streak',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppTheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _streak == 0
                          ? 'Start a streak today'
                          : _streak == 1
                              ? '1 day and counting'
                              : '$_streak days and counting',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _streak == 0
                          ? 'Log a workout to light this up'
                          : 'Keep logging to protect the run',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: 'Workouts',
                value: '$_workouts',
                icon: Symbols.fitness_center,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                label: 'This week',
                value: '$_week',
                icon: Symbols.calendar_today,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                label: 'Sets / week',
                value: '$_setsWeek',
                icon: Symbols.bolt,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StreakRing extends StatelessWidget {
  final int days;
  final Color color;

  const _StreakRing({required this.days, required this.color});

  @override
  Widget build(BuildContext context) {
    final progress = (days / 7).clamp(0.0, 1.0);
    return SizedBox(
      width: 84,
      height: 84,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 84,
            height: 84,
            child: CircularProgressIndicator(
              value: progress <= 0 ? 0.04 : progress,
              strokeWidth: 7,
              backgroundColor: AppTheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(color),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$days',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      height: 1,
                    ),
              ),
              Text(
                'days',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 108,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
        boxShadow: AppTheme.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryContainer),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                  height: 1,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile data (routines + posts)
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileDataSection extends ConsumerWidget {
  const _ProfileDataSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberId = ref.watch(currentUserProvider)?.memberId;
    if (memberId == null || memberId.isEmpty) {
      return EmptyState(
        icon: Symbols.person,
        title: 'Profile unavailable',
        message: 'Sign in again to load your gym profile details',
      );
    }
    final profile = ref.watch(memberProfileProvider(memberId));
    return profile.when(
      loading: () => const SkeletonBox(
        width: double.infinity,
        height: 160,
        radius: AppTheme.radiusXxl,
      ),
      error: (error, _) {
        debugPrint('[ProfileScreen] profile load failed: $error');
        return EmptyState(
          icon: Symbols.cloud_off,
          title: 'Could not load profile',
          message: 'Check your connection and try again',
          actionLabel: 'Retry',
          actionIcon: Symbols.refresh,
          onAction: () => ref.invalidate(memberProfileProvider(memberId)),
        );
      },
      data: (data) => _ProfileSharedContent(profile: data),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
    );
  }
}

class _ProfileSharedContent extends StatelessWidget {
  final MemberProfile profile;
  const _ProfileSharedContent({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (profile.sharedRoutines.isNotEmpty) ...[
          const _SectionTitle('Shared routines'),
          const SizedBox(height: AppTheme.stackSm),
          ...profile.sharedRoutines.map(
            (routine) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WorkoutDetailScreen(routine: routine),
                  ),
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
                    border: Border.all(color: Colors.white.withOpacity(0.07)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryContainer.withOpacity(0.12),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusLg),
                        ),
                        child: const Icon(
                          Symbols.public,
                          color: AppTheme.primaryContainer,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          routine.name,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                      Text(
                        '${routine.exercises.length} exercises',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppTheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.stackMd),
        ],
        const _SectionTitle('Activity'),
        const SizedBox(height: AppTheme.stackSm),
        if (profile.posts.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.stackMd),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
              border: Border.all(color: Colors.white.withOpacity(0.07)),
            ),
            child: Text(
              'No shared workouts yet',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
            ),
          )
        else
          ...profile.posts.map((post) => _ProfilePostCard(post: post)),
      ],
    );
  }
}

class _ProfilePostCard extends StatelessWidget {
  final FeedPost post;
  const _ProfilePostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final summary = post.workoutSummary;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            post.content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (post.imageUrl != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              child: AppCachedImage(
                url: post.imageUrl,
                width: double.infinity,
                height: 148,
                fit: BoxFit.cover,
              ),
            ),
          ],
          if (summary != null) ...[
            const SizedBox(height: 10),
            Text(
              '${summary['exerciseCount'] ?? 0} exercises · '
              '${summary['totalSets'] ?? 0} sets · '
              '${summary['volumeKg'] ?? 0} kg',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.primaryContainer,
                  ),
            ),
          ],
          if (post.coachCertification != null) ...[
            const SizedBox(height: 8),
            Text(
              'Certified by ${post.coachCertification!.coachName}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.primaryContainer,
                  ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            post.timeAgo,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Member profile (other users)
// ─────────────────────────────────────────────────────────────────────────────
class MemberProfileScreen extends ConsumerWidget {
  final String memberId;

  const MemberProfileScreen({super.key, required this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(memberProfileProvider(memberId));
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: const Text('Member'),
      ),
      body: profile.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.primaryContainer,
          ),
        ),
        error: (error, _) => EmptyState(
          icon: Symbols.cloud_off,
          title: 'Could not load profile',
          message: 'Check your connection and try again',
          actionLabel: 'Retry',
          actionIcon: Symbols.refresh,
          onAction: () => ref.invalidate(memberProfileProvider(memberId)),
        ),
        data: (data) => ListView(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.containerMargin,
            8,
            AppTheme.containerMargin,
            40,
          ),
          children: [
            _MemberHeader(profile: data),
            const SizedBox(height: AppTheme.stackMd),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: 'Workouts',
                    value: '${data.stats.workoutCount}',
                    icon: Symbols.fitness_center,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricTile(
                    label: 'Streak',
                    value: '${data.stats.streakDays}',
                    icon: Symbols.local_fire_department,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricTile(
                    label: 'Sets',
                    value: '${data.stats.totalSets}',
                    icon: Symbols.bolt,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.stackLg),
            _ProfileSharedContent(profile: data),
          ],
        ),
      ),
    );
  }
}

class _MemberHeader extends StatelessWidget {
  final MemberProfile profile;
  const _MemberHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.stackMd),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
        boxShadow: AppTheme.cardElevation,
      ),
      child: Row(
        children: [
          _AvatarRing(url: profile.avatarUrl),
          const SizedBox(width: AppTheme.stackMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.staffRole ?? 'Gym member',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.primaryContainer,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.gymName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.onSurfaceVariant,
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
