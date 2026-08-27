import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/providers/nav_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../workouts/models/workout_models.dart';
import '../../workouts/screens/workout_session_screen.dart';
import '../../notices/screens/notices_screen.dart';
import '../providers/home_data_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeAsync = ref.watch(homeDataProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      extendBodyBehindAppBar: false,
      appBar: _HomeAppBar(),
      body: homeAsync.when(
        loading: () => _HomeBody(data: null, isLoading: true, ref: ref),
        error: (e, __) {
          debugPrint('[HomeScreen] homeDataProvider error: $e');
          return _HomeBody(data: null, isLoading: false, ref: ref, hasError: true);
        },
        data: (data) => _HomeBody(data: data, isLoading: false, ref: ref),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App bar — glass, avatar → Profile, TETHER wordmark, bell → Notifications
// ─────────────────────────────────────────────────────────────────────────────
class _HomeAppBar extends ConsumerWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: GestureDetector(
          onTap: () => ref.read(navIndexProvider.notifier).state = NavTab.profile,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primaryContainer.withOpacity(0.2),
                width: 1.5,
              ),
              color: AppTheme.surfaceContainerHigh,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Symbols.person,
              size: 20,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
      title: Text(
        'TETHER',
        style: TextStyle(
          color: AppTheme.primaryContainer,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
          shadows: [
            Shadow(
              color: AppTheme.primaryContainer.withOpacity(0.4),
              blurRadius: 16,
            ),
            Shadow(
              color: AppTheme.primaryContainer.withOpacity(0.2),
              blurRadius: 8,
            ),
          ],
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primaryContainer.withOpacity(0.2),
                  width: 1.5,
                ),
                color: AppTheme.surfaceContainerHigh,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Symbols.notifications,
                    size: 20,
                    color: AppTheme.onSurface,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryContainer.withOpacity(0.6),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _HomeBody — the scrollable canvas. Receives nullable HomeData so it can
// render skeletons (isLoading) or the full error state (hasError) from
// the same widget tree without code duplication.
// ─────────────────────────────────────────────────────────────────────────────
class _HomeBody extends ConsumerWidget {
  final HomeData? data;
  final bool isLoading;
  final bool hasError;
  final WidgetRef ref;

  const _HomeBody({
    required this.data,
    required this.isLoading,
    required this.ref,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Full-screen connection error with retry
    if (hasError) {
      return Center(
        child: ConnectErrorState(
          onRetry: () => ref.invalidate(homeDataProvider),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(homeDataProvider.notifier).refresh(),
      color: AppTheme.primaryContainer,
      backgroundColor: AppTheme.surfaceContainerHigh,
      child: CustomScrollView(
        slivers: [
          // 1. Hero greeting with photo background
          SliverToBoxAdapter(
            child: _HeroGreetingSection(data: data, isLoading: isLoading),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.containerMargin),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppTheme.stackLg),
                // 2. Today's Workout card
                _TodayWorkoutCard(data: data, isLoading: isLoading),
                const SizedBox(height: AppTheme.stackLg),
                // 3. Today stats with gym-focused bento
                const _SectionLabel(label: 'TODAY'),
                const SizedBox(height: AppTheme.stackSm),
                _ModernStatsBento(data: data, isLoading: isLoading),
                const SizedBox(height: AppTheme.stackLg),
                // 4. Announcements label
                Row(
                  children: [
                    const _SectionLabel(label: 'GYM NOTICES'),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const NoticesScreen())),
                      child: Text('SEE ALL',
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: AppTheme.primaryContainer)),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.stackSm),
              ]),
            ),
          ),
          // 5. Announcement asymmetric layout
          SliverToBoxAdapter(child: _ModernAnnouncementSection()),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.containerMargin),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppTheme.stackLg),
                // 6. Social teaser with avatars
                _ModernSocialTeaser(data: data, isLoading: isLoading),
                const SizedBox(height: AppTheme.stackLg),
                // 7. Trainer tip with photo
                const _SectionLabel(label: 'TRAINER TIP'),
                const SizedBox(height: AppTheme.stackSm),
                const _PhotoTrainerTip(),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. Hero Greeting Section — full-width photo with gradient overlay
// ─────────────────────────────────────────────────────────────────────────────
class _HeroGreetingSection extends ConsumerWidget {
  final HomeData? data;
  final bool isLoading;
  const _HeroGreetingSection({required this.data, required this.isLoading});

  String get _salutation {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final displayName = user?.displayName?.split(' ').first ?? 'there';

    return Container(
      height: 220,
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800&q=80'),
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.4),
              Colors.black.withOpacity(0.8),
            ],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppTheme.containerMargin,
          AppTheme.containerMargin,
          AppTheme.containerMargin,
          20,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _salutation,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(color: Colors.black.withOpacity(0.6), blurRadius: 12)
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        displayName,
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 36,
                          height: 1.1,
                          letterSpacing: -0.5,
                          shadows: [
                            Shadow(color: Colors.black.withOpacity(0.7), blurRadius: 16)
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.stackSm),
                // Streak chip — aligned to bottom
                if (isLoading)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    child: SkeletonBox(width: 85, height: 34, radius: AppTheme.radiusFull),
                  )
                else if ((data?.streakDays ?? 0) > 0)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    child: _NeonStreakChip(days: data!.streakDays),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Neon Streak Chip — stronger glow
// ─────────────────────────────────────────────────────────────────────────────
class _NeonStreakChip extends StatelessWidget {
  final int days;
  const _NeonStreakChip({required this.days});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryContainer.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: AppTheme.primaryContainer, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryContainer.withOpacity(0.5),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 14, height: 1)),
          const SizedBox(width: 4),
          Text(
            '$days DAY',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.primaryContainer,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              shadows: [
                Shadow(color: AppTheme.primaryContainer.withOpacity(0.8), blurRadius: 4)
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. Today's Workout card — photo-backed when active
// ─────────────────────────────────────────────────────────────────────────────
class _TodayWorkoutCard extends ConsumerWidget {
  final HomeData? data;
  final bool isLoading;
  const _TodayWorkoutCard({required this.data, required this.isLoading});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isLoading) {
      return SkeletonBox(width: double.infinity, height: 180, radius: AppTheme.radiusXxl);
    }

    final session = data?.activeSession;

    if (session != null) {
      return _ActiveWorkoutHero(session: session);
    }

    return _NoWorkoutPrompt();
  }
}

class _ActiveWorkoutHero extends ConsumerWidget {
  final WorkoutSession session;
  const _ActiveWorkoutHero({required this.session});

  String _elapsed(DateTime start) {
    final mins = DateTime.now().difference(start).inMinutes;
    if (mins < 60) return '$mins MIN';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m > 0 ? '${h}H ${m}M' : '${h}H';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => WorkoutSessionScreen(session: session)),
      ),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
          image: const DecorationImage(
            image: NetworkImage('https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=800&q=80'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.4),
                Colors.black.withOpacity(0.8),
              ],
            ),
          ),
          padding: const EdgeInsets.all(AppTheme.stackMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  border: Border.all(color: AppTheme.primaryContainer, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryContainer.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'IN PROGRESS • ${_elapsed(session.startedAt)}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.primaryContainer,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Title
              Text(
                session.notes?.isNotEmpty == true ? session.notes! : 'Active Workout',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                  shadows: [
                    Shadow(color: Colors.black.withOpacity(0.6), blurRadius: 8)
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppTheme.stackSm),
              // Resume button
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    'RESUME',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoWorkoutPrompt extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => ref.read(navIndexProvider.notifier).state = NavTab.train,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.stackMd),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainer.withOpacity(0.6),
          borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHigh,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: const Icon(Symbols.fitness_center, size: 22, color: AppTheme.onSurfaceVariant),
            ),
            const SizedBox(width: AppTheme.stackSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ready to train?',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Browse workouts and start your session',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Symbols.chevron_right, size: 20, color: AppTheme.onSurfaceVariant.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section label
// ─────────────────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: AppTheme.onSurfaceVariant,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. Modern Announcement Section — asymmetric layout
// ─────────────────────────────────────────────────────────────────────────────
class _ModernAnnouncementSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Use first 3 placeholder notices from NoticesScreen
    final notices = [
      _placeholderNoticeData(
        tag: 'ANNOUNCEMENT', icon: Symbols.campaign,
        title: 'New Squat Racks Installed',
        body: 'Level 2 free weights area now features 6 additional squat racks. Push your limits.',
        imageUrl: 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=800&q=80',
      ),
      _placeholderNoticeData(
        tag: 'CLASS UPDATE', icon: Symbols.schedule,
        title: 'HIIT 45 Moving',
        subtitle: 'Studio B • Tomorrow',
      ),
      _placeholderNoticeData(
        tag: 'REMINDER', icon: Symbols.notifications_active,
        title: 'Early Close',
        subtitle: '8PM Sunday',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.containerMargin),
      child: Column(
        children: [
          // Featured announcement (large with photo)
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const NoticesScreen())),
            child: _FeaturedAnnouncementCard(
              title: notices[0]['title']!,
              body: notices[0]['body']!,
              imageUrl: notices[0]['imageUrl']!,
            ),
          ),
          const SizedBox(height: AppTheme.stackSm),
          // Two compact announcements side-by-side
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const NoticesScreen())),
                  child: _CompactAnnouncementCard(
                    tag: notices[1]['tag']!,
                    icon: Symbols.schedule,
                    title: notices[1]['title']!,
                    subtitle: notices[1]['subtitle']!,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.stackSm),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const NoticesScreen())),
                  child: _CompactAnnouncementCard(
                    tag: notices[2]['tag']!,
                    icon: Symbols.notifications_active,
                    title: notices[2]['title']!,
                    subtitle: notices[2]['subtitle']!,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, String> _placeholderNoticeData({
    required String tag,
    required IconData icon,
    required String title,
    String body = '',
    String subtitle = '',
    String? imageUrl,
  }) => {
    'tag': tag,
    'title': title,
    'body': body,
    'subtitle': subtitle,
    if (imageUrl != null) 'imageUrl': imageUrl,
  };
}

class _FeaturedAnnouncementCard extends StatelessWidget {
  final String title;
  final String body;
  final String imageUrl;

  const _FeaturedAnnouncementCard({
    required this.title,
    required this.body,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.2),
              Colors.black.withOpacity(0.85),
            ],
          ),
        ),
        padding: const EdgeInsets.all(AppTheme.stackMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                border: Border.all(color: AppTheme.primaryContainer, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryContainer.withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Symbols.campaign, size: 12, color: AppTheme.primaryContainer),
                  const SizedBox(width: 4),
                  Text(
                    'ANNOUNCEMENT',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.primaryContainer,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Title
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 22,
                shadows: [
                  Shadow(color: Colors.black.withOpacity(0.6), blurRadius: 8)
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            // Body
            Text(
              body,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.9),
                shadows: [
                  Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 4)
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactAnnouncementCard extends StatelessWidget {
  final String tag;
  final IconData icon;
  final String title;
  final String subtitle;

  const _CompactAnnouncementCard({
    required this.tag,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(AppTheme.stackSm),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon + tag
          Row(
            children: [
              Icon(icon, size: 12, color: AppTheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                tag,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 9,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Title
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          // Subtitle
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.onSurfaceVariant,
              fontSize: 12,
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
// 3. Modern Stats Bento — visual cards with photo backgrounds (REFINED)
// ─────────────────────────────────────────────────────────────────────────────
// 3. Modern Stats Bento — 3-card grid with photo backgrounds
// ─────────────────────────────────────────────────────────────────────────────
class _ModernStatsBento extends StatelessWidget {
  final HomeData? data;
  final bool isLoading;
  const _ModernStatsBento({required this.data, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Column(
        children: [
          SkeletonBox(width: double.infinity, height: 140, radius: AppTheme.radiusXxl),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: SkeletonBox(width: double.infinity, height: 120, radius: AppTheme.radiusXxl)),
              const SizedBox(width: 8),
              Expanded(child: SkeletonBox(width: double.infinity, height: 120, radius: AppTheme.radiusXxl)),
            ],
          ),
        ],
      );
    }

    final workouts = data?.todayWorkoutCount ?? 0;
    final streak = data?.streakDays ?? 0;
    final activeMembers = data?.activeTodayCount ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Full-width workouts card ──
        _BentoCard(
          height: 140,
          imageUrl: 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=800&q=80',
          child: _StatContent(
            icon: Symbols.fitness_center,
            value: '$workouts',
            label: 'WORKOUTS TODAY',
            valueFontSize: 44,
          ),
        ),
        const SizedBox(height: 8),
        // ── Streak + Active Members side by side ──
        SizedBox(
          height: 130,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _BentoCard(
                  imageUrl: 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=800&q=80',
                  child: _StatContent(
                    icon: Symbols.local_fire_department,
                    value: '$streak',
                    label: 'DAY STREAK',
                    valueFontSize: 38,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _BentoCard(
                  imageUrl: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800&q=80',
                  child: _StatContent(
                    icon: Symbols.group,
                    value: activeMembers > 0 ? '$activeMembers' : '--',
                    label: 'ACTIVE TODAY',
                    valueFontSize: 38,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Wraps any child in a photo card with a dark gradient overlay and rounded corners.
/// Pass explicit [height] to fix the card size; omit to let content size it.
class _BentoCard extends StatelessWidget {
  final Widget child;
  final String imageUrl;
  final double? height;

  const _BentoCard({
    required this.child,
    required this.imageUrl,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    Widget inner = Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.5, 1.0],
            colors: [
              Colors.black.withOpacity(0.25),
              Colors.black.withOpacity(0.55),
              Colors.black.withOpacity(0.88),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );

    // When height is null, the card sizes to its child (used inside SizedBox Row)
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: inner,
    );
  }
}

/// The icon + number + label content that sits inside each _BentoCard.
/// Using strict Column with minimal children — no Spacer/Expanded so it
/// never fights its parent's height constraint.
class _StatContent extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final double valueFontSize;

  const _StatContent({
    required this.icon,
    required this.value,
    required this.label,
    required this.valueFontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Icon pill at top
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
        // Number + label at bottom
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: valueFontSize,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1,
                letterSpacing: -1.5,
                shadows: const [
                  Shadow(color: Colors.black54, blurRadius: 12),
                  Shadow(color: Colors.black38, blurRadius: 4),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white.withOpacity(0.92),
                letterSpacing: 0.5,
                height: 1,
                shadows: const [
                  Shadow(color: Colors.black54, blurRadius: 6),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. Modern Social Teaser — with member avatars
// ─────────────────────────────────────────────────────────────────────────────
class _ModernSocialTeaser extends ConsumerWidget {
  final HomeData? data;
  final bool isLoading;
  const _ModernSocialTeaser({required this.data, required this.isLoading});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isLoading) {
      return SkeletonBox(width: double.infinity, height: 100, radius: AppTheme.radiusXxl);
    }

    final post = data?.latestAchievementPost;
    final activeTodayCount = data?.activeTodayCount ?? 12; // Fallback for visual demo

    return GestureDetector(
      onTap: () => ref.read(navIndexProvider.notifier).state = NavTab.feed,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.stackMd),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            // Stacked avatars
            SizedBox(
              width: 80,
              height: 48,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    child: _MemberAvatar(imageUrl: 'https://i.pravatar.cc/150?img=12'),
                  ),
                  Positioned(
                    left: 24,
                    child: _MemberAvatar(imageUrl: 'https://i.pravatar.cc/150?img=23'),
                  ),
                  Positioned(
                    left: 48,
                    child: _MemberAvatar(imageUrl: 'https://i.pravatar.cc/150?img=35'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.stackSm),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _headline(post, activeTodayCount),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _subline(post),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.stackSm),
            // Arrow
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primaryContainer.withOpacity(0.3)),
              ),
              child: const Icon(Symbols.arrow_forward, size: 16, color: AppTheme.primaryContainer),
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
        return '$name hit a ${post.achievementTag}!';
      }
      return '$name just posted';
    }
    return '$activeCount members active today';
  }

  String _subline(SocialPostPreview? post) {
    if (post != null) return post.caption;
    return 'See what your gym is up to';
  }
}

class _MemberAvatar extends StatelessWidget {
  final String imageUrl;
  const _MemberAvatar({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.surface, width: 2),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 6. Photo Trainer Tip — coach photo with advice. Tap opens a modal sheet
//    with a rotating collection of tips.
// ─────────────────────────────────────────────────────────────────────────────

// All tips shown in the modal sheet (rotated based on day-of-year so the tip
// changes daily without any backend call)
const List<_TrainerTip> _allTrainerTips = [
  _TrainerTip(
    quote: '"Focus on the eccentric movement during pull-ups. Taking 3 seconds to lower builds more strength than the pull itself."',
    coach: 'COACH SARAH',
    avatarUrl: 'https://i.pravatar.cc/150?img=45',
  ),
  _TrainerTip(
    quote: '"Progressive overload is the #1 driver of muscle growth. Add 2.5kg or one extra rep each week — consistency compounds."',
    coach: 'COACH MARCUS',
    avatarUrl: 'https://i.pravatar.cc/150?img=67',
  ),
  _TrainerTip(
    quote: '"Rest days are training days. Your muscles grow during recovery, not during the workout. Sleep 7–9 hours."',
    coach: 'COACH SARAH',
    avatarUrl: 'https://i.pravatar.cc/150?img=45',
  ),
  _TrainerTip(
    quote: '"Form over weight, always. One clean rep at 80kg builds more than five sloppy reps at 100kg — and keeps you injury-free."',
    coach: 'COACH MARCUS',
    avatarUrl: 'https://i.pravatar.cc/150?img=67',
  ),
  _TrainerTip(
    quote: '"Warm up with purpose. 5 minutes of dynamic stretching primes your CNS and adds 10–15% to your working capacity."',
    coach: 'COACH SARAH',
    avatarUrl: 'https://i.pravatar.cc/150?img=45',
  ),
];

class _TrainerTip {
  final String quote;
  final String coach;
  final String avatarUrl;
  const _TrainerTip({required this.quote, required this.coach, required this.avatarUrl});
}

class _PhotoTrainerTip extends StatelessWidget {
  const _PhotoTrainerTip();

  // Rotate tips daily — no state needed
  _TrainerTip get _todaysTip {
    final dayIndex = DateTime.now().difference(DateTime(2026)).inDays;
    return _allTrainerTips[dayIndex % _allTrainerTips.length];
  }

  void _showTipsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _TrainerTipsSheet(tips: _allTrainerTips),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tip = _todaysTip;
    return GestureDetector(
      onTap: () => _showTipsSheet(context),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
          image: const DecorationImage(
            image: NetworkImage('https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800&q=80'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.2),
                Colors.black.withOpacity(0.85),
              ],
            ),
          ),
          padding: const EdgeInsets.all(AppTheme.stackMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tag row with "tap for more" hint
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                      border: Border.all(color: AppTheme.primaryContainer, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryContainer.withOpacity(0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Symbols.lightbulb, size: 12, color: AppTheme.primaryContainer, fill: 1),
                        const SizedBox(width: 4),
                        Text(
                          'FROM THE TRAINER',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTheme.primaryContainer,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Tap hint
                  Text(
                    'MORE TIPS',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 9,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Symbols.chevron_right, size: 12, color: Colors.white.withOpacity(0.6)),
                ],
              ),
              const Spacer(),
              // Quote
              Text(
                tip.quote,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                  shadows: [
                    Shadow(color: Colors.black.withOpacity(0.6), blurRadius: 8)
                  ],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppTheme.stackSm),
              // Coach attribution
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      image: DecorationImage(
                        image: NetworkImage(tip.avatarUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    tip.coach,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white.withOpacity(0.95),
                      fontWeight: FontWeight.w700,
                      shadows: [
                        Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 4)
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Trainer Tips Modal Sheet — all tips in a scrollable list
// ─────────────────────────────────────────────────────────────────────────────
class _TrainerTipsSheet extends StatelessWidget {
  final List<_TrainerTip> tips;
  const _TrainerTipsSheet({required this.tips});

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(0, 12, 0, bottomPad + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainer.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.primaryContainer.withOpacity(0.3)),
                  ),
                  child: Icon(Symbols.lightbulb, size: 16, color: AppTheme.primaryContainer, fill: 1),
                ),
                const SizedBox(width: 12),
                Text(
                  'TRAINER TIPS',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Symbols.close, size: 16, color: AppTheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.white.withOpacity(0.06)),
          // Tips list
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: tips.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.white.withOpacity(0.05)),
              itemBuilder: (_, i) => _TipTile(tip: tips[i], index: i),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipTile extends StatelessWidget {
  final _TrainerTip tip;
  final int index;
  const _TipTile({required this.tip, required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Index badge
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primaryContainer.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: AppTheme.primaryContainer,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip.quote,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.onSurface,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: NetworkImage(tip.avatarUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tip.coach,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
