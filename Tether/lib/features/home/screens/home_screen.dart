import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/media_catalog.dart';
import '../../../core/providers/nav_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../workouts/models/workout_models.dart';
import '../../workouts/screens/workout_session_screen.dart';
import '../../notices/screens/notices_screen.dart';
import '../../notices/models/gym_notice.dart';
import '../../notices/providers/notices_provider.dart';
import '../../social/services/social_extras_service.dart';
import '../providers/home_data_provider.dart';
import 'gym_directory_screen.dart';
import '../widgets/directory_sheets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // IndexedStack keeps this tab alive — refresh when user returns to Home
    // so an ended workout cannot linger as "in progress".
    ref.listen<int>(navIndexProvider, (prev, next) {
      if (next == NavTab.home && prev != null && prev != NavTab.home) {
        ref.invalidate(homeDataProvider);
      }
    });

    final homeAsync = ref.watch(homeDataProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: const _HomeAppBar(),
      body: homeAsync.when(
        loading: () => const _HomeBody(data: null, isLoading: true),
        error: (e, _) {
          debugPrint('[HomeScreen] homeDataProvider error: $e');
          return const _HomeBody(data: null, isLoading: false, hasError: true);
        },
        data: (data) => _HomeBody(data: data, isLoading: false),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App bar — Strava-style: title left, actions right
// ─────────────────────────────────────────────────────────────────────────────
class _HomeAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const _HomeAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: AppTheme.containerMargin,
      title: Text(
        'Home',
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
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Symbols.notifications,
                  size: 24,
                  color: AppTheme.onSurface,
                ),
                Positioned(
                  top: -1,
                  right: -1,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer,
                      shape: BoxShape.circle,
                      boxShadow: AppTheme.neonGlow(opacity: 0.45, blur: 6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Scrollable home canvas
// ─────────────────────────────────────────────────────────────────────────────
class _HomeBody extends ConsumerWidget {
  final HomeData? data;
  final bool isLoading;
  final bool hasError;

  const _HomeBody({
    required this.data,
    required this.isLoading,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (hasError) {
      return ConnectErrorState(
        onRetry: () => ref.invalidate(homeDataProvider),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          ref.read(homeDataProvider.notifier).refresh(),
          ref.read(noticesProvider.notifier).refresh(),
          ref.refresh(homeMembersDirectoryProvider.future),
          ref.refresh(homeCoachesProvider.future),
        ]);
      },
      color: AppTheme.primaryContainer,
      backgroundColor: AppTheme.surfaceContainerHigh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.containerMargin,
              4,
              AppTheme.containerMargin,
              0,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _GreetingHeader(data: data, isLoading: isLoading),
                const SizedBox(height: AppTheme.stackMd),
                _PrimaryActionCard(data: data, isLoading: isLoading),
                const SizedBox(height: AppTheme.stackLg),
                _SectionHeader(title: 'Today'),
                const SizedBox(height: AppTheme.stackSm),
                _TodayMetricsRow(data: data, isLoading: isLoading),
                const SizedBox(height: AppTheme.stackLg),
                _SectionHeader(
                  title: 'Gym notices',
                  actionLabel: 'See all',
                  onAction: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NoticesScreen()),
                  ),
                ),
                const SizedBox(height: AppTheme.stackSm),
              ]),
            ),
          ),
          const SliverToBoxAdapter(child: _NoticesSection()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.containerMargin,
              AppTheme.stackLg,
              AppTheme.containerMargin,
              0,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SectionHeader(
                  title: 'Gym members',
                  actionLabel: 'See all',
                  onAction: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GymDirectoryScreen(
                        initialTab: GymDirectoryTab.members,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.stackSm),
                const _MembersDirectorySection(),
                const SizedBox(height: AppTheme.stackLg),
                _SectionHeader(
                  title: 'Coaches',
                  actionLabel: 'See all',
                  onAction: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GymDirectoryScreen(
                        initialTab: GymDirectoryTab.coaches,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.stackSm),
                const _CoachesDirectorySection(),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.containerMargin,
              AppTheme.stackLg,
              AppTheme.containerMargin,
              100,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SectionHeader(
                  title: 'From your gym',
                  actionLabel: 'Open feed',
                  onAction: () =>
                      ref.read(navIndexProvider.notifier).state = NavTab.feed,
                ),
                const SizedBox(height: AppTheme.stackSm),
                _FeedTeaserCard(data: data, isLoading: isLoading),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Greeting
// ─────────────────────────────────────────────────────────────────────────────
class _GreetingHeader extends ConsumerWidget {
  final HomeData? data;
  final bool isLoading;

  const _GreetingHeader({required this.data, required this.isLoading});

  String get _salutation {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final firstName = user?.displayName?.split(' ').first ?? 'there';
    final streak = data?.streakDays ?? 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _salutation,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                firstName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (isLoading)
          const SkeletonBox(width: 88, height: 32, radius: AppTheme.radiusFull)
        else if (streak > 0)
          _StreakPill(days: streak),
      ],
    );
  }
}

class _StreakPill extends StatelessWidget {
  final int days;
  const _StreakPill({required this.days});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.primaryContainer.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(
          color: AppTheme.primaryContainer.withOpacity(0.45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Symbols.local_fire_department,
            size: 16,
            color: AppTheme.primaryContainer,
            fill: 1,
          ),
          const SizedBox(width: 4),
          Text(
            '$days day${days == 1 ? '' : 's'}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.primaryContainer,
                ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Primary action — Strava streak / resume card
// ─────────────────────────────────────────────────────────────────────────────
class _PrimaryActionCard extends ConsumerWidget {
  final HomeData? data;
  final bool isLoading;

  const _PrimaryActionCard({required this.data, required this.isLoading});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isLoading) {
      return const SkeletonBox(
        width: double.infinity,
        height: 168,
        radius: AppTheme.radiusXxl,
      );
    }

    final session = data?.activeSession;
    if (session != null) {
      return _ActiveSessionCard(session: session);
    }

    final streak = data?.streakDays ?? 0;
    final title = streak > 0 ? 'Keep your streak going' : 'Start your streak';
    final body = streak > 0
        ? 'Log a workout today to keep the $streak-day run alive.'
        : 'One session is all it takes to begin a streak.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.stackMd),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: AppTheme.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                child: Icon(
                  streak > 0
                      ? Symbols.local_fire_department
                      : Symbols.fitness_center,
                  color: AppTheme.primaryContainer,
                  size: 22,
                  fill: streak > 0 ? 1 : 0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.stackMd),
          PrimaryButton(
            label: 'Train now',
            icon: Symbols.play_arrow,
            height: 48,
            onPressed: () =>
                ref.read(navIndexProvider.notifier).state = NavTab.train,
          ),
        ],
      ),
    );
  }
}

class _ActiveSessionCard extends ConsumerWidget {
  final WorkoutSession session;
  const _ActiveSessionCard({required this.session});

  String _elapsed(DateTime start) {
    final mins = DateTime.now().difference(start).inMinutes;
    if (mins < 60) return '$mins min';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = session.notes?.trim().isNotEmpty == true
        ? session.notes!.trim()
        : 'Active workout';

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WorkoutSessionScreen(session: session),
          ),
        );
        ref.invalidate(homeDataProvider);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
        child: SizedBox(
          height: 176,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(AppMedia.homeWorkout),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.25),
                      Colors.black.withOpacity(0.82),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppTheme.stackMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer.withOpacity(0.18),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusFull),
                        border: Border.all(
                          color: AppTheme.primaryContainer.withOpacity(0.55),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'In progress · ${_elapsed(session.startedAt)}',
                            style:
                                Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: AppTheme.primaryContainer,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryContainer,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusFull),
                          boxShadow:
                              AppTheme.neonGlow(opacity: 0.28, blur: 16),
                        ),
                        child: Text(
                          'Resume',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: AppTheme.onPrimaryFixed,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.primaryContainer,
                  ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Today metrics — clean elevated tiles (no photo collage)
// ─────────────────────────────────────────────────────────────────────────────
class _TodayMetricsRow extends StatelessWidget {
  final HomeData? data;
  final bool isLoading;

  const _TodayMetricsRow({required this.data, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Row(
        children: [
          Expanded(
            child: SkeletonBox(
              width: double.infinity,
              height: 108,
              radius: AppTheme.radiusXxl,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: SkeletonBox(
              width: double.infinity,
              height: 108,
              radius: AppTheme.radiusXxl,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: SkeletonBox(
              width: double.infinity,
              height: 108,
              radius: AppTheme.radiusXxl,
            ),
          ),
        ],
      );
    }

    final workouts = data?.todayWorkoutCount ?? 0;
    final streak = data?.streakDays ?? 0;
    final active = data?.activeTodayCount ?? 0;

    return Row(
      children: [
        Expanded(
          child: _MetricTile(
            icon: Symbols.fitness_center,
            value: '$workouts',
            label: 'Workouts',
            accent: workouts > 0
                ? AppTheme.metricGood
                : AppTheme.primaryContainer,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetricTile(
            icon: Symbols.local_fire_department,
            value: '$streak',
            label: 'Day streak',
            accent: streak > 0
                ? AppTheme.primaryContainer
                : AppTheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetricTile(
            icon: Symbols.group,
            value: active > 0 ? '$active' : '—',
            label: 'Active',
            accent: AppTheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color accent;

  const _MetricTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 112,
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
          Icon(icon, size: 18, color: accent, fill: 1),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.8,
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
// Gym members + coaches directory
// ─────────────────────────────────────────────────────────────────────────────
class _MembersDirectorySection extends ConsumerWidget {
  const _MembersDirectorySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(homeMembersDirectoryProvider);

    return membersAsync.when(
      loading: () => const SkeletonBox(
        width: double.infinity,
        height: 88,
        radius: AppTheme.radiusLg,
      ),
      error: (_, __) => Text(
        'Members unavailable right now',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.onSurfaceVariant,
            ),
      ),
      data: (members) {
        if (members.isEmpty) {
          return Text(
            'No other members here yet',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
          );
        }
        final preview = members.take(8).toList();
        return SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: preview.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final m = preview[i];
              return _PersonChip(
                name: m.displayName,
                subtitle: m.isTrainingNow
                    ? 'Training'
                    : m.isBuddy
                        ? 'Buddy'
                        : null,
                isTrainingNow: m.isTrainingNow,
                onTap: () => showMemberDirectorySheet(context, member: m),
              );
            },
          ),
        );
      },
    );
  }
}

class _CoachesDirectorySection extends ConsumerWidget {
  const _CoachesDirectorySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coachesAsync = ref.watch(homeCoachesProvider);

    return coachesAsync.when(
      loading: () => const SkeletonBox(
        width: double.infinity,
        height: 88,
        radius: AppTheme.radiusLg,
      ),
      error: (_, __) => Text(
        'Coaches unavailable right now',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.onSurfaceVariant,
            ),
      ),
      data: (coaches) {
        if (coaches.isEmpty) {
          return Text(
            'Ask your gym to invite a coach',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
          );
        }
        final preview = coaches.take(8).toList();
        return SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: preview.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final c = preview[i];
              return _PersonChip(
                name: c.displayName,
                subtitle: c.isTrainingNow
                    ? 'Training'
                    : c.programCount > 0
                        ? '${c.programCount} programs'
                        : (c.role.toLowerCase() == 'admin' ? 'Admin' : 'Coach'),
                isTrainingNow: c.isTrainingNow,
                accent: true,
                onTap: () => showCoachDirectorySheet(context, coach: c),
              );
            },
          ),
        );
      },
    );
  }
}

class _PersonChip extends StatelessWidget {
  const _PersonChip({
    required this.name,
    required this.onTap,
    this.subtitle,
    this.isTrainingNow = false,
    this.accent = false,
  });

  final String name;
  final String? subtitle;
  final bool isTrainingNow;
  final bool accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: accent
                      ? AppTheme.primaryContainer.withValues(alpha: 0.16)
                      : AppTheme.surfaceContainerHigh,
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: accent
                          ? AppTheme.primaryContainer
                          : AppTheme.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
                if (isTrainingNow)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.surface, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              name.split(' ').first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isTrainingNow
                          ? AppTheme.primaryContainer
                          : AppTheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gym notices
// ─────────────────────────────────────────────────────────────────────────────
class _NoticesSection extends ConsumerWidget {
  const _NoticesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noticesAsync = ref.watch(noticesProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.containerMargin),
      child: noticesAsync.when(
        loading: () => const SkeletonBox(
          width: double.infinity,
          height: 132,
          radius: AppTheme.radiusXxl,
        ),
        error: (_, __) => _InlineEmptyCard(
          message: 'Could not load notices',
          actionLabel: 'Retry',
          onAction: () => ref.read(noticesProvider.notifier).refresh(),
        ),
        data: (notices) {
          if (notices.isEmpty) {
            return _InlineEmptyCard(
              message: 'No gym notices yet',
              actionLabel: 'Open notices',
              onAction: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NoticesScreen()),
              ),
            );
          }

          final featured = notices.first;
          final rest = notices.skip(1).take(2).toList();

          return Column(
            children: [
              _FeaturedNoticeCard(notice: featured),
              if (rest.isNotEmpty) ...[
                const SizedBox(height: 10),
                ...rest.map(
                  (n) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _NoticeRowCard(notice: n),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _InlineEmptyCard extends StatelessWidget {
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _InlineEmptyCard({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.stackMd),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        children: [
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel,
              style: const TextStyle(
                color: AppTheme.primaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedNoticeCard extends StatelessWidget {
  final GymNotice notice;
  const _FeaturedNoticeCard({required this.notice});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => NoticeDetailScreen(notice: notice)),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.stackMd),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
          border: Border.all(
            color: notice.isPinned
                ? AppTheme.primaryContainer.withOpacity(0.35)
                : Colors.white.withOpacity(0.08),
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(
                    AppTheme.surfaceContainer,
                    AppTheme.primaryContainer,
                    0.08,
                  ) ??
                  AppTheme.surfaceContainer,
              AppTheme.surfaceContainer,
            ],
          ),
          boxShadow: AppTheme.cardElevation,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(notice.icon, size: 14, color: notice.tagColor),
                const SizedBox(width: 6),
                Text(
                  notice.displayTag,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: notice.tagColor,
                      ),
                ),
                if (notice.isPinned) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Symbols.push_pin,
                    size: 13,
                    color: AppTheme.primaryContainer,
                  ),
                ],
                const Spacer(),
                Text(
                  notice.timeAgo,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              notice.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              notice.body,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                    height: 1.4,
                  ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoticeRowCard extends StatelessWidget {
  final GymNotice notice;
  const _NoticeRowCard({required this.notice});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => NoticeDetailScreen(notice: notice)),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: notice.tagColor.withOpacity(0.14),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: Icon(notice.icon, size: 18, color: notice.tagColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notice.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${notice.displayTag} · ${notice.timeAgo}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(
              Symbols.chevron_right,
              size: 20,
              color: AppTheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feed teaser — activity-card style
// ─────────────────────────────────────────────────────────────────────────────
class _FeedTeaserCard extends ConsumerWidget {
  final HomeData? data;
  final bool isLoading;

  const _FeedTeaserCard({required this.data, required this.isLoading});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isLoading) {
      return const SkeletonBox(
        width: double.infinity,
        height: 112,
        radius: AppTheme.radiusXxl,
      );
    }

    final post = data?.latestAchievementPost;
    final activeToday = data?.activeTodayCount ?? 0;

    return GestureDetector(
      onTap: () => ref.read(navIndexProvider.notifier).state = NavTab.feed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.stackMd),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: AppTheme.cardElevation,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              child: SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(AppMedia.homeHero),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    ColoredBox(color: Colors.black.withOpacity(0.25)),
                    const Center(
                      child: Icon(
                        Symbols.group,
                        size: 22,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _headline(post, activeToday),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _subline(post, activeToday),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.onSurfaceVariant,
                          height: 1.3,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Symbols.arrow_forward,
                size: 18,
                color: AppTheme.primaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _headline(SocialPostPreview? post, int activeCount) {
    if (post != null) {
      final name = post.authorName.split(' ').first;
      if (post.achievementTag != null) {
        return '$name hit a ${post.achievementTag}';
      }
      return '$name just posted';
    }
    if (activeCount > 0) return '$activeCount members active today';
    return 'See what your gym is up to';
  }

  String _subline(SocialPostPreview? post, int activeCount) {
    if (post != null) {
      final caption = post.caption.trim();
      if (caption.isNotEmpty) return caption;
      return post.timeAgo;
    }
    if (activeCount > 0) return 'Open the feed for the latest activity';
    return 'Be the first to share a workout today';
  }
}
