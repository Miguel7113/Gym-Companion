import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/tether_palette.dart';
import '../../../core/theme/tether_text.dart';
import '../../../core/theme/tether_tokens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/navigation/main_navigation.dart';
import '../../../core/widgets/media_catalog.dart';
import '../models/workout_models.dart';
import '../services/offline_workout_service.dart';
import '../services/workout_service.dart';
import 'workout_session_screen.dart';
import 'workout_builder_screen.dart';
import 'routines_screen.dart';
import 'workout_history_screen.dart';
import 'exercise_picker_sheet.dart';
import 'workout_detail_screen.dart';
import '../../social/screens/buddies_screen.dart';
import '../widgets/leaderboard_card.dart';
import '../../profile/models/personal_record.dart';
import '../../profile/services/personal_records_service.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'leaderboard_screen.dart';

/// Redesigned Train tab matching Tether design system
/// Dark theme with electric lime accents
class WorkoutsScreen extends ConsumerStatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  ConsumerState<WorkoutsScreen> createState() =>
      _WorkoutsScreenState();
}

class _WorkoutsScreenState
    extends ConsumerState<WorkoutsScreen> {
  WorkoutSession? _activeSession;
  List<WorkoutTemplate> _templates = [];
  bool _loadingTemplates = true;
  
  // Body parts state
  List<String> _bodyParts = [];
  bool _loadingBodyParts = true;
  bool _bodyPartsError = false;
  
  // Leaderboard state
  List<LeaderboardEntry> _leaderboardTop3 = [];
  bool _loadingLeaderboard = true;
  
  // Filters
  int _selectedFilter = 0;
  final Set<String> _selectedEquipment = {};
  
  static const List<_Filter> _filters = [
    _Filter('All', null),
    _Filter('Strength', 'strength'),
    _Filter('Cardio', 'cardio'),
    _Filter('HIIT', 'hiit'),
    _Filter('Mobility', 'mobility'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await Future.wait([
      _loadActiveSession(),
      _loadTemplates(),
      _loadBodyParts(),
      _loadLeaderboard(),
    ]);
  }

  Future<void> _loadActiveSession() async {
    try {
      final session = await ref
          .read(offlineWorkoutServiceProvider)
          .getActiveSession();
      if (mounted) {
        setState(() {
          _activeSession = session != null && session.endedAt == null ? session : null;
        });
      }
    } catch (e) {
      debugPrint('[WorkoutsScreen] active session unavailable: $e');
    }
  }

  Future<void> _loadTemplates() async {
    setState(() => _loadingTemplates = true);
    try {
      final templates = await ref.read(workoutServiceProvider).listRoutines();
      if (mounted) {
        setState(() {
          _templates = templates;
          _loadingTemplates = false;
        });
      }
    } catch (e) {
      debugPrint('[WorkoutsScreen] templates failed: $e');
      if (mounted) setState(() => _loadingTemplates = false);
    }
  }

  Future<void> _loadBodyParts() async {
    setState(() {
      _loadingBodyParts = true;
      _bodyPartsError = false;
    });
    try {
      final svc = ref.read(offlineWorkoutServiceProvider);
      final parts = await svc.listBodyParts();
      if (mounted) {
        setState(() {
          _bodyParts = parts;
          _loadingBodyParts = false;
          _bodyPartsError = parts.isEmpty;
        });
      }
    } catch (e) {
      debugPrint('[WorkoutsScreen] body parts failed: $e');
      if (mounted) {
        setState(() {
          _loadingBodyParts = false;
          _bodyPartsError = true;
        });
      }
    }
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _loadingLeaderboard = true);
    try {
      final user = ref.read(currentUserProvider);
      if (user?.gymId == null) {
        if (mounted) setState(() => _loadingLeaderboard = false);
        return;
      }

      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      if (token == null) {
        if (mounted) setState(() => _loadingLeaderboard = false);
        return;
      }

      final service = ref.read(personalRecordsServiceProvider);
      final leaderboard = await service.getLeaderboard(
        gymId: user!.gymId,
        exercise: 'Bench Press',
        limit: 3,
        token: token,
      );

      if (mounted) {
        setState(() {
          _leaderboardTop3 = leaderboard;
          _loadingLeaderboard = false;
        });
      }
    } catch (e) {
      debugPrint('[WorkoutsScreen] leaderboard failed: $e');
      if (mounted) setState(() => _loadingLeaderboard = false);
    }
  }

  void _openExerciseList({String? bodyPart}) {
    final category = _filters[_selectedFilter].value;
    ExercisePickerSheet.show(
      context,
      onExerciseSelected: (_) {},
      initialBodyPart: bodyPart,
      initialCategory: category,
      initialEquipment: _selectedEquipment.isNotEmpty
          ? Set<String>.from(_selectedEquipment)
          : null,
    );
  }

  Future<void> _showEquipmentFilter() async {
    final svc = ref.read(offlineWorkoutServiceProvider);
    List<String> allEquipments = [];
    try {
      allEquipments = await svc.listEquipments();
    } catch (_) {}

    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _EquipmentGridFilter(
        allEquipments: allEquipments,
        selected: Set<String>.from(_selectedEquipment),
        onApply: (sel) => setState(() {
          _selectedEquipment
            ..clear()
            ..addAll(sel);
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.tether;

    return Scaffold(
      backgroundColor: TetherTokens.ink,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: p.accent,
          backgroundColor: TetherTokens.nightCard,
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: _buildHeader(p),
              ),

              // Active Session Card (if exists)
              if (_activeSession != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _buildActiveSessionCard(p),
                  ),
                ),

              // Current Routines Card (placeholder - shows active program)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _buildCurrentRoutinesCard(p),
                ),
              ),

              // START TRAINING Button
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _buildStartTrainingButton(p),
                ),
              ),

              // Quick Access Cards (Routines, History, Buddies)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _buildQuickAccessRow(p),
                ),
              ),

              // Leaderboard Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: LeaderboardCard(
                    topThree: _leaderboardTop3,
                    loading: _loadingLeaderboard,
                    onViewAll: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LeaderboardScreen(
                            initialExercise: 'Bench Press',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Browse Exercises Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Browse exercises',
                        style: TetherText.sans(20, w: TetherTokens.w800),
                      ),
                      GestureDetector(
                        onTap: () => _openExerciseList(),
                        child: Text(
                          'See all',
                          style: TetherText.sans(
                            14,
                            color: p.accent,
                            w: TetherTokens.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Exercise Filters
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      _EquipmentChip(
                        selectedCount: _selectedEquipment.length,
                        onTap: _showEquipmentFilter,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _FilterChipRow(
                          filters: _filters,
                          selectedIndex: _selectedFilter,
                          onSelected: (i) {
                            setState(() => _selectedFilter = i);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) _openExerciseList();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Body Part Grid
              if (_loadingBodyParts)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.4,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (_, __) => _buildSkeletonBodyPartTile(),
                      childCount: 6,
                    ),
                  ),
                )
              else if (_bodyPartsError)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildErrorState(() => _loadBodyParts()),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.4,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _buildBodyPartTile(_bodyParts[i]),
                      childCount: _bodyParts.length,
                    ),
                  ),
                ),

              // Bottom padding
              const SliverPadding(
                padding: EdgeInsets.only(bottom: 100),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Header
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHeader(TetherPalette p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Train',
            style: TetherText.sans(32, w: TetherTokens.w800),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    backgroundColor: TetherTokens.ink,
                    appBar: AppBar(
                      backgroundColor: TetherTokens.ink,
                      elevation: 0,
                      title: Text(
                        'History',
                        style: TetherText.sans(20, w: TetherTokens.w800),
                      ),
                    ),
                    body: const WorkoutHistoryScreen(),
                  ),
                ),
              );
            },
            icon: Icon(
              Symbols.bar_chart,
              size: 24,
              color: TetherTokens.cream,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Active Session Card
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildActiveSessionCard(TetherPalette p) {
    return GestureDetector(
      onTap: () {
        if (_activeSession == null) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WorkoutSessionScreen(session: _activeSession),
          ),
        ).then((_) => _loadActiveSession());
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: p.accent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WORKOUT IN PROGRESS',
                    style: TetherText.sans(
                      12,
                      color: TetherTokens.ink,
                      w: TetherTokens.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _activeSession?.notes ?? 'Untitled Workout',
                    style: TetherText.sans(
                      18,
                      color: TetherTokens.ink,
                      w: TetherTokens.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Symbols.chevron_right,
              color: TetherTokens.ink,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Current Routines Card (Active Program)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildCurrentRoutinesCard(TetherPalette p) {
    // Use the first template if available, otherwise show placeholder
    final routine = _templates.isNotEmpty ? _templates.first : null;
    
    final programName = routine?.name ?? 'No Active Routine';
    final weekInfo = routine != null ? '${routine.exercises.length} exercises' : 'Start a new routine';
    final todayInfo = routine != null 
        ? 'Ready to train • ${routine.durationMins ?? 0} min'
        : 'Create or select a routine';
    
    // Day circles - fixed width to prevent overflow
    final dayStates = [
      ('M', true, false),   // (label, completed, isToday)
      ('T', true, false),
      ('W', false, true),  // Today
      ('T', false, false),
      ('F', false, false),
      ('S', false, false),
      ('S', false, false),
    ];

    return Container(
      decoration: BoxDecoration(
        color: TetherTokens.cream,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Program card content
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: TetherTokens.nightCard,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        programName,
                        style: TetherText.sans(
                          20,
                          color: TetherTokens.cream,
                          w: TetherTokens.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      weekInfo,
                      style: TetherText.sans(
                        12,
                        color: TetherTokens.cream.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Day circles - use Wrap to prevent overflow
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: dayStates.map((day) {
                    final (label, completed, isToday) = day;
                    return Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: completed
                            ? p.accent
                            : Colors.transparent,
                        border: Border.all(
                          color: isToday
                              ? p.accent
                              : completed
                                  ? p.accent
                                  : TetherTokens.cream.withOpacity(0.2),
                          width: isToday ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          label,
                          style: TetherText.sans(
                            14,
                            color: completed
                                ? TetherTokens.ink
                                : TetherTokens.cream,
                            w: TetherTokens.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Today info and Open button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        todayInfo,
                        style: TetherText.sans(
                          14,
                          color: TetherTokens.cream.withOpacity(0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: routine != null
                          ? () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => RoutinesScreen(),
                                ),
                              );
                            }
                          : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: routine != null 
                              ? TetherTokens.cream
                              : TetherTokens.cream.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Open',
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // START TRAINING Button
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStartTrainingButton(TetherPalette p) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const WorkoutBuilderScreen(),
          ),
        ).then((_) => _loadActiveSession());
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: TetherTokens.nightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: TetherTokens.cream.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            'START TRAINING',
            style: TetherText.sans(
              16,
              color: p.accent,
              w: TetherTokens.w800,
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Quick Access Row (Routines, History, Buddies)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildQuickAccessRow(TetherPalette p) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickAccessCard(
            'Routines',
            Symbols.format_list_bulleted,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RoutinesScreen(),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickAccessCard(
            'History',
            Symbols.history,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    backgroundColor: TetherTokens.ink,
                    appBar: AppBar(
                      backgroundColor: TetherTokens.ink,
                      elevation: 0,
                      title: Text(
                        'History',
                        style: TetherText.sans(20, w: TetherTokens.w800),
                      ),
                    ),
                    body: const WorkoutHistoryScreen(),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickAccessCard(
            'Buddies',
            Symbols.group,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BuddiesScreen(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccessCard(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: TetherTokens.nightCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: TetherTokens.cream.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: TetherTokens.cream,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TetherText.sans(
                12,
                color: TetherTokens.cream,
                w: TetherTokens.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Body Part Tile (with image, gradient, and icon)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildBodyPartTile(String bodyPart) {
    final icon = _bodyPartIcons[bodyPart.toLowerCase()] ?? Symbols.fitness_center;
    final displayName = bodyPart
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');

    return GestureDetector(
      onTap: () => _openExerciseList(bodyPart: bodyPart),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background color
            Container(color: TetherTokens.nightCard),
            
            // Body part image
            Image.asset(
              AppMedia.bodyPart(bodyPart),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(
                child: Icon(
                  icon,
                  size: 32,
                  color: context.tether.accent.withOpacity(0.3),
                ),
              ),
            ),
            
            // Gradient overlay
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.15),
                    Colors.black.withOpacity(0.78),
                  ],
                ),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Icon badge
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.22),
                      ),
                    ),
                    child: Icon(icon, size: 16, color: Colors.white),
                  ),
                  
                  // Body part name
                  Text(
                    displayName,
                    style: TetherText.sans(
                      14,
                      color: Colors.white,
                      w: TetherTokens.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonBodyPartTile() {
    return Container(
      decoration: BoxDecoration(
        color: TetherTokens.nightCard.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Workout Template Card
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildWorkoutCard(WorkoutTemplate template) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WorkoutDetailScreen(routine: template),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: TetherTokens.nightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: TetherTokens.cream.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: TetherTokens.cream.withOpacity(0.05),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  image: template.imageUrl != null && template.imageUrl!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(template.imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: template.imageUrl == null || template.imageUrl!.isEmpty
                    ? Center(
                        child: Icon(
                          Symbols.fitness_center,
                          size: 32,
                          color: TetherTokens.cream.withOpacity(0.3),
                        ),
                      )
                    : null,
              ),
            ),

            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      template.name,
                      style: TetherText.sans(
                        14,
                        color: TetherTokens.cream,
                        w: TetherTokens.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${template.exercises.length} exercises',
                      style: TetherText.sans(
                        12,
                        color: TetherTokens.cream.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonWorkoutCard() {
    return Container(
      decoration: BoxDecoration(
        color: TetherTokens.nightCard.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Empty State
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Symbols.fitness_center,
            size: 48,
            color: TetherTokens.cream.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No workouts yet',
            style: TetherText.sans(
              18,
              color: TetherTokens.cream.withOpacity(0.5),
              w: TetherTokens.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first routine to get started',
            style: TetherText.sans(
              14,
              color: TetherTokens.cream.withOpacity(0.4),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(VoidCallback onRetry) {
    return Column(
      children: [
        Icon(
          Symbols.error,
          size: 48,
          color: TetherTokens.cream.withOpacity(0.3),
        ),
        const SizedBox(height: 16),
        Text(
          'Failed to load',
          style: TetherText.sans(
            18,
            color: TetherTokens.cream.withOpacity(0.5),
            w: TetherTokens.w600,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onRetry,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: TetherTokens.cream.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Retry',
              style: TetherText.sans(
                14,
                color: TetherTokens.cream,
                w: TetherTokens.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body Part Icons Map
// ─────────────────────────────────────────────────────────────────────────────
const Map<String, IconData> _bodyPartIcons = {
  'chest': Symbols.fitness_center,
  'back': Symbols.accessibility_new,
  'upper arms': Symbols.sports_martial_arts,
  'lower arms': Symbols.sports_martial_arts,
  'shoulders': Symbols.fitness_center,
  'upper legs': Symbols.directions_run,
  'lower legs': Symbols.directions_run,
  'waist': Symbols.self_improvement,
  'lower back': Symbols.accessibility_new,
  'cardio': Symbols.favorite,
  'neck': Symbols.self_improvement,
  'full body': Symbols.accessibility,
};

// ─────────────────────────────────────────────────────────────────────────────
// Helper Classes
// ─────────────────────────────────────────────────────────────────────────────

class _Filter {
  final String label;
  final String? value;
  const _Filter(this.label, this.value);
}

class _EquipmentChip extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onTap;

  const _EquipmentChip({
    required this.selectedCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedCount > 0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? context.tether.accent.withOpacity(0.2)
              : TetherTokens.nightCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? context.tether.accent
                : TetherTokens.cream.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Symbols.fitness_center,
              size: 16,
              color: isSelected ? context.tether.accent : TetherTokens.cream,
            ),
            if (selectedCount > 0) ...[
              const SizedBox(width: 6),
              Text(
                '$selectedCount',
                style: TetherText.sans(
                  14,
                  color: context.tether.accent,
                  w: TetherTokens.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterChipRow extends StatelessWidget {
  final List<_Filter> filters;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _FilterChipRow({
    required this.filters,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(filters.length, (i) {
          final isSelected = i == selectedIndex;
          return Padding(
            padding: EdgeInsets.only(right: i < filters.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () => onSelected(i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? context.tether.accent.withOpacity(0.2)
                      : TetherTokens.nightCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? context.tether.accent
                        : TetherTokens.cream.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Text(
                  filters[i].label,
                  style: TetherText.sans(
                    14,
                    color: isSelected ? context.tether.accent : TetherTokens.cream,
                    w: TetherTokens.w600,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _EquipmentGridFilter extends StatefulWidget {
  final List<String> allEquipments;
  final Set<String> selected;
  final ValueChanged<Set<String>> onApply;

  const _EquipmentGridFilter({
    required this.allEquipments,
    required this.selected,
    required this.onApply,
  });

  @override
  State<_EquipmentGridFilter> createState() => _EquipmentGridFilterState();
}

class _EquipmentGridFilterState extends State<_EquipmentGridFilter> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set<String>.from(widget.selected);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: TetherTokens.nightCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Equipment',
            style: TetherText.sans(20, w: TetherTokens.w800),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.allEquipments.map((eq) {
              final isSelected = _selected.contains(eq);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selected.remove(eq);
                    } else {
                      _selected.add(eq);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? context.tether.accent.withOpacity(0.2)
                        : TetherTokens.ink,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? context.tether.accent
                          : TetherTokens.cream.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    eq,
                    style: TetherText.sans(
                      14,
                      color: isSelected ? context.tether.accent : TetherTokens.cream,
                      w: TetherTokens.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selected.clear());
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: TetherTokens.ink,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'Clear',
                        style: TetherText.sans(16, w: TetherTokens.w600),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    widget.onApply(_selected);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: context.tether.accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'Apply',
                        style: TetherText.sans(
                          16,
                          color: TetherTokens.ink,
                          w: TetherTokens.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
