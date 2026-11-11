import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/tether_palette.dart';
import '../../../core/theme/tether_text.dart';
import '../../../core/theme/tether_tokens.dart';
import '../../../core/widgets/redesign/streak_plate.dart';
import '../../../core/providers/nav_provider.dart';
import '../../../core/navigation/main_navigation.dart';
import '../../auth/providers/auth_provider.dart';
import '../../workouts/screens/workout_builder_screen.dart';
import '../../social/services/social_extras_service.dart';
import '../../notices/screens/notices_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../providers/home_data_provider.dart';
import 'members_directory_screen.dart';
import 'coaches_directory_screen.dart';

const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
const _daysLong = [
  'MONDAY',
  'TUESDAY',
  'WEDNESDAY',
  'THURSDAY',
  'FRIDAY',
  'SATURDAY',
  'SUNDAY'
];
const _months = [
  'JANUARY',
  'FEBRUARY',
  'MARCH',
  'APRIL',
  'MAY',
  'JUNE',
  'JULY',
  'AUGUST',
  'SEPTEMBER',
  'OCTOBER',
  'NOVEMBER',
  'DECEMBER',
];

/// Redesigned home screen with foundry-style dark ground + cream sheet layout
class HomeScreenRedesignV2 extends ConsumerWidget {
  const HomeScreenRedesignV2({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    return h < 12 ? 'MORNING' : (h < 17 ? 'AFTERNOON' : 'EVENING');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.tether;
    final now = DateTime.now();
    final homeDataAsync = ref.watch(homeDataProvider);
    final authUser = ref.watch(currentUserProvider);

    final memberName = authUser?.displayName?.split(' ').first ??
        authUser?.email?.split('@').first ??
        'MIGUEL';
    final streak = homeDataAsync.valueOrNull?.streakDays ?? 1;
    
    // TODO: Get actual session data from provider
    const sessionsDone = 0;
    const sessionsGoal = 4;

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
                    // Top bar
                    _buildTopBar(context),
                    
                    const SizedBox(height: 20),
                    
                    // Date label
                    Text(
                      '${_daysLong[now.weekday - 1]} / ${now.day} ${_months[now.month - 1]}',
                      style: TetherText.sans(
                        11,
                        color: TetherTokens.cream.withOpacity(0.5),
                        w: TetherTokens.w400,
                        ls: 0.8,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Greeting
                    Text(
                      '${_greeting()}, ${memberName.toUpperCase()}.',
                      style: TetherText.sans(
                        46,
                        color: TetherTokens.cream,
                        w: TetherTokens.w600,
                        height: 1.0,
                        ls: 0.2,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Streak section with plate
                    SizedBox(
                      height: 160,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // StreakPlate bleeds off the right
                          Positioned(
                            right: -20,
                            top: 0,
                            bottom: 0,
                            width: 180,
                            child: StreakPlate(streak: streak, capacity: 14),
                          ),
                          
                          // Streak number and label - adjusted for dynamic sizing
                          Positioned(
                            left: 0,
                            top: 6,
                            right: 100, // Ensure space for the plate
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Dynamic sizing based on number length
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    // Calculate font size based on number length
                                    final digits = streak.toString().length;
                                    final fontSize = digits <= 2 ? 104.0 : (digits == 3 ? 72.0 : 56.0);
                                    
                                    return Row(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            '$streak',
                                            style: TetherText.sans(
                                              fontSize,
                                              color: TetherTokens.cream,
                                              w: TetherTokens.w600,
                                              height: 1.0,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.visible,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 4),
                                // Label row
                                Row(
                                  children: [
                                    Icon(
                                      Symbols.local_fire_department,
                                      size: 16,
                                      color: p.accent,
                                      fill: 1,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'DAY STREAK',
                                      style: TetherText.sans(
                                        10,
                                        color: TetherTokens.cream,
                                        w: TetherTokens.w400,
                                        ls: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  streak > 0
                                      ? "Let's keep it going."
                                      : 'Start your streak today.',
                                  style: TetherText.sans(
                                    12,
                                    color: TetherTokens.cream.withOpacity(0.6),
                                    w: TetherTokens.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 4),
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
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // This week progress
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'THIS WEEK',
                            style: TetherText.sans(
                              10,
                              color: TetherTokens.ink.withOpacity(0.5),
                              w: TetherTokens.w400,
                              ls: 0.8,
                            ),
                          ),
                          Text(
                            '$sessionsDone of $sessionsGoal sessions',
                            style: TetherText.sans(
                              12,
                              color: TetherTokens.ink,
                              w: TetherTokens.w400,
                              ls: 0.8,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Progress bars
                      Row(
                        children: [
                          for (var i = 0; i < sessionsGoal; i++) ...[
                            if (i > 0) const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: i < sessionsDone
                                      ? p.accent
                                      : const Color(0xFFCFC9BB),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      
                      const SizedBox(height: 18),
                      
                      // Week calendar
                      _buildWeekCalendar(now, p),
                      
                      const SizedBox(height: 20),
                      
                      // Class update tile
                      _buildClassUpdateTile(context, p),
                      
                      const SizedBox(height: 14),
                      
                      // Start workout button
                      _buildStartWorkoutButton(context, p),
                      
                      const SizedBox(height: 24),
                      
                      // From your gym section
                      _buildFromYourGym(context, ref),
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

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: TetherTokens.cream,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'MF',
            style: TetherText.sans(
              20,
              w: TetherTokens.w600,
              color: TetherTokens.ink,
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Modern Fitness Gym',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TetherText.sans(
              14,
              color: TetherTokens.cream,
              w: TetherTokens.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificationsScreen(),
              ),
            );
          },
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
            child: const Icon(
              Icons.notifications_none_rounded,
              color: TetherTokens.cream,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekCalendar(DateTime now, TetherPalette p) {
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    
    return Row(
      children: List.generate(7, (i) {
        final day = weekStart.add(Duration(days: i));
        final isToday = day.day == now.day && day.month == now.month;
        final isPast = day.isBefore(now) && !isToday;
        
        // TODO: Check if user worked out on this day
        final workedOut = false;
        
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < 6 ? 8 : 0),
            child: Column(
              children: [
                // Day letter
                Text(
                  _days[i],
                  style: TetherText.sans(
                    11,
                    color: TetherTokens.ink.withOpacity(0.5),
                    w: TetherTokens.w400,
                    ls: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Day number or dash
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: isToday ? p.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isPast && workedOut
                        ? Border.all(color: p.accent, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      isPast || isToday ? '${day.day}' : '—',
                      style: TetherText.sans(
                        16,
                        color: isToday
                            ? TetherTokens.cream
                            : TetherTokens.ink,
                        w: TetherTokens.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildClassUpdateTile(BuildContext context, TetherPalette p) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const NoticesScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFE4DFD3), // paperTile
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CLASS UPDATE',
                    style: TetherText.sans(
                      10,
                      color: TetherTokens.ink.withOpacity(0.5),
                      w: TetherTokens.w400,
                      ls: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'PILATES OPEN',
                    style: TetherText.sans(
                      32,
                      color: TetherTokens.ink,
                      w: TetherTokens.w600,
                      height: 1.0,
                      ls: 0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tomorrow, 4pm',
                    style: TetherText.sans(
                      13,
                      color: TetherTokens.ink.withOpacity(0.6),
                      w: TetherTokens.w400,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Open notices',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NoticesScreen(),
                  ),
                );
              },
              icon: Icon(
                Icons.north_east_rounded,
                size: 20,
                color: TetherTokens.cream,
              ),
              style: IconButton.styleFrom(
                fixedSize: const Size(48, 48),
                backgroundColor: TetherTokens.ink,
                shape: const CircleBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartWorkoutButton(BuildContext context, TetherPalette p) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const WorkoutBuilderScreen(),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: p.accent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Start workout',
              style: TetherText.sans(
                16,
                color: TetherTokens.cream,
                w: TetherTokens.w600,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.north_east_rounded,
              size: 18,
              color: TetherTokens.cream,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFromYourGym(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'FROM YOUR GYM',
              style: TetherText.sans(
                10,
                color: TetherTokens.ink.withOpacity(0.5),
                w: TetherTokens.w400,
                ls: 0.8,
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => ref.read(navIndexProvider.notifier).state = 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'Open feed',
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
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Latest post preview
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: TetherTokens.ink,
                shape: BoxShape.circle,
              ),
              child: Text(
                'MN',
                style: TetherText.sans(
                  18,
                  color: TetherTokens.cream,
                  w: TetherTokens.w600,
                  height: 1.0,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Miguel Ndakwe',
                    style: TetherText.sans(
                      14,
                      color: TetherTokens.ink,
                      w: TetherTokens.w800,
                    ),
                  ),
                  Text(
                    'burning legs',
                    style: TetherText.sans(
                      13,
                      color: TetherTokens.ink.withOpacity(0.6),
                      w: TetherTokens.w400,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '3w ago',
              style: TetherText.sans(
                12,
                color: TetherTokens.ink.withOpacity(0.6),
                w: TetherTokens.w400,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Gym Members section
        _buildGymMembersSection(context),
        
        const SizedBox(height: 24),
        
        // Coaches section
        _buildCoachesSection(context),
      ],
    );
  }

  Widget _buildGymMembersSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final membersAsync = ref.watch(homeMembersDirectoryProvider);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'GYM MEMBERS',
                  style: TetherText.sans(
                    10,
                    color: TetherTokens.ink.withOpacity(0.5),
                    w: TetherTokens.w400,
                    ls: 0.8,
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MembersDirectoryScreen(),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
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
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Member cards
            membersAsync.when(
              loading: () => const SizedBox(
                height: 116,
                child: Center(child: CircularProgressIndicator(color: TetherTokens.defaultAccent)),
              ),
              error: (err, stack) => const SizedBox(
                height: 116,
                child: Center(child: Text('Failed to load members')),
              ),
              data: (members) {
                if (members.isEmpty) {
                  return const SizedBox(
                    height: 116,
                    child: Center(child: Text('No members yet')),
                  );
                }
                
                return SizedBox(
                  height: 116,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: members.take(8).length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) {
                      final member = members[i];
                      final initials = _getInitials(member.displayName);
                      // Get workout count - you'd need to add this to the backend
                      final workouts = 0; // TODO: Add workout count to API
                      return _buildMemberCard(
                        context,
                        member.displayName,
                        initials,
                        workouts > 0 ? '$workouts workouts' : 'New member',
                        member.isTrainingNow,
                        member.userId,
                      );
                    },
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
  
  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }

  Widget _buildMemberCard(
    BuildContext context,
    String name,
    String initials,
    String stats,
    bool isActive,
    String memberId,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MemberProfileScreen(memberId: memberId),
          ),
        );
      },
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFE4DFD3),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: TetherTokens.ink,
                    shape: BoxShape.circle,
                    border: isActive
                        ? Border.all(
                            color: context.tether.accent,
                            width: 2,
                          )
                        : null,
                  ),
                  child: Text(
                    initials,
                    style: TetherText.sans(
                      14,
                      color: TetherTokens.cream,
                      w: TetherTokens.w600,
                    ),
                  ),
                ),
                const Spacer(),
                if (isActive)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: context.tether.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: TetherText.sans(
                13,
                color: TetherTokens.ink,
                w: TetherTokens.w800,
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              stats,
              style: TetherText.sans(
                11,
                color: TetherTokens.ink.withOpacity(0.6),
                w: TetherTokens.w400,
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoachesSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final coachesAsync = ref.watch(homeCoachesProvider);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'COACHES',
                  style: TetherText.sans(
                    10,
                    color: TetherTokens.ink.withOpacity(0.5),
                    w: TetherTokens.w400,
                    ls: 0.8,
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CoachesDirectoryScreen(),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
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
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Coach cards
            coachesAsync.when(
              loading: () => const SizedBox(
                height: 116,
                child: Center(child: CircularProgressIndicator(color: TetherTokens.defaultAccent)),
              ),
              error: (err, stack) => const SizedBox(
                height: 116,
                child: Center(child: Text('Failed to load coaches')),
              ),
              data: (coaches) {
                if (coaches.isEmpty) {
                  return const SizedBox(
                    height: 116,
                    child: Center(child: Text('No coaches yet')),
                  );
                }
                
                return SizedBox(
                  height: 116,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: coaches.take(8).length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) {
                      final coach = coaches[i];
                      final initials = _getInitials(coach.displayName);
                      // For now, use a simple "Coach" specialty - you may want to add this to the backend
                      final specialty = 'Coach';
                      return _buildCoachCard(
                        context,
                        coach.userId,
                        coach.displayName,
                        initials,
                        specialty,
                        coach.isTrainingNow, // Use this as "available"
                      );
                    },
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildCoachCard(
    BuildContext context,
    String coachId,
    String name,
    String initials,
    String specialty,
    bool isAvailable,
  ) {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to CoachProfileScreen once created
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MemberProfileScreen(memberId: coachId),
          ),
        );
      },
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFE4DFD3),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.tether.accent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    initials,
                    style: TetherText.sans(
                      14,
                      color: TetherTokens.cream,
                      w: TetherTokens.w600,
                    ),
                  ),
                ),
                const Spacer(),
                if (isAvailable)
                  Icon(
                    Symbols.verified,
                    size: 16,
                    color: context.tether.accent,
                    fill: 1,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: TetherText.sans(
                13,
                color: TetherTokens.ink,
                w: TetherTokens.w800,
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              specialty,
              style: TetherText.sans(
                11,
                color: TetherTokens.ink.withOpacity(0.6),
                w: TetherTokens.w400,
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
