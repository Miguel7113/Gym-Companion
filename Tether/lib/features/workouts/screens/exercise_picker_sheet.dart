import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/tether_text.dart';
import '../../../core/theme/tether_tokens.dart';
import '../../../core/widgets/media_catalog.dart';
import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_service.dart';
import '../models/workout_models.dart';
import '../services/offline_workout_service.dart';
import 'exercise_detail_screen.dart';

/// Exercise Picker redesign with foundry-style bottom sheet
/// Full-screen modal with dark header + cream content
class ExercisePickerSheet extends ConsumerStatefulWidget {
  final void Function(Exercise) onExerciseSelected;
  final String? initialBodyPart;
  final String? initialCategory;
  final Set<String>? initialEquipment;

  const ExercisePickerSheet({
    super.key,
    required this.onExerciseSelected,
    this.initialBodyPart,
    this.initialCategory,
    this.initialEquipment,
  });

  static Future<void> show(
    BuildContext context, {
    required void Function(Exercise) onExerciseSelected,
    String? initialBodyPart,
    String? initialCategory,
    Set<String>? initialEquipment,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExercisePickerSheet(
        onExerciseSelected: onExerciseSelected,
        initialBodyPart: initialBodyPart,
        initialCategory: initialCategory,
        initialEquipment: initialEquipment,
      ),
    );
  }

  @override
  ConsumerState<ExercisePickerSheet> createState() =>
      _ExercisePickerSheetState();
}

class _ExercisePickerSheetState
    extends ConsumerState<ExercisePickerSheet> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  String? _selectedBodyPart;
  final Set<String> _selectedEquipment = {};

  List<Exercise> _exercises = [];
  List<Exercise> _recentlyUsed = [];
  List<Exercise> _saved = [];
  List<String> _bodyParts = [];
  List<String> _allEquipments = [];

  bool _loadingExercises = false;
  bool _loadingMeta = false;

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  @override
  void initState() {
    super.initState();
    _selectedBodyPart = widget.initialBodyPart;
    if (widget.initialEquipment != null) {
      _selectedEquipment.addAll(widget.initialEquipment!);
    }
    _loadMeta();
    _fetchExercises();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadMeta() async {
    setState(() => _loadingMeta = true);
    final svc = ref.read(offlineWorkoutServiceProvider);

    final cacheCount =
        await ref.read(appDatabaseProvider).exercisesDao.getCacheCount();

    if (cacheCount == 0) {
      debugPrint('[ExercisePicker] cache empty — seeding before loading meta');
      await ref.read(syncServiceProvider).seedIfNeeded();
    }

    await Future.wait([
      svc.listBodyParts().then((parts) {
        if (mounted) setState(() => _bodyParts = parts);
      }).catchError((e) {
        debugPrint('[ExercisePicker] listBodyParts failed: $e');
      }),
      svc.listEquipments().then((equips) {
        if (mounted) setState(() => _allEquipments = equips);
      }).catchError((e) {
        debugPrint('[ExercisePicker] listEquipments failed: $e');
      }),
      svc.getRecentlyUsed(limit: 8).then((recent) {
        if (mounted) setState(() => _recentlyUsed = recent);
      }).catchError((e) {
        debugPrint('[ExercisePicker] getRecentlyUsed failed: $e');
      }),
      svc.getSavedExercises().then((saved) {
        if (mounted) setState(() => _saved = saved);
      }).catchError((e) {
        debugPrint('[ExercisePicker] getSavedExercises failed: $e');
      }),
    ]);

    if (mounted) setState(() => _loadingMeta = false);
  }

  Future<void> _fetchExercises() async {
    setState(() => _loadingExercises = true);
    final svc = ref.read(offlineWorkoutServiceProvider);
    try {
      final query = _searchCtrl.text.trim();
      final equipment =
          _selectedEquipment.isNotEmpty ? _selectedEquipment.toList() : null;

      final results = await svc.listExercises(
        query: query.isEmpty ? null : query,
        bodyPart: _selectedBodyPart,
        category: widget.initialCategory,
        equipment: equipment,
      );

      if (!mounted) return;
      setState(() {
        _exercises = results;
        _loadingExercises = false;
      });
    } catch (e) {
      debugPrint('[ExercisePicker] _fetchExercises failed: $e');
      if (mounted) setState(() => _loadingExercises = false);
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _fetchExercises);
  }

  void _selectBodyPart(String? part) {
    setState(() {
      _selectedBodyPart = part;
      _exercises = [];
    });
    if (part != null) {
      _fetchExercises();
    }
  }

  bool get _isDrilling =>
      _selectedBodyPart != null ||
      _selectedEquipment.isNotEmpty ||
      _searchCtrl.text.isNotEmpty ||
      widget.initialCategory != null;

  void _addExercise(Exercise ex) {
    HapticFeedback.lightImpact();
    widget.onExerciseSelected(ex);
    Navigator.pop(context);
  }

  void _openDetail(Exercise ex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExerciseDetailScreen(
          exercise: ex,
          onAddToWorkout: () => _addExercise(ex),
          isSaved: _saved.any((s) => s.id == ex.id),
        ),
      ),
    );
  }

  Future<void> _showEquipmentFilter() async {
    final selected = Set<String>.from(_selectedEquipment);
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _EquipmentFilterSheet(
        allEquipments: _allEquipments,
        selected: selected,
        onApply: (newSelection) {
          setState(() {
            _selectedEquipment
              ..clear()
              ..addAll(newSelection);
          });
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _fetchExercises(),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final h = MediaQuery.of(context).size.height;

    return Container(
      height: h - topPad - 24,
      decoration: const BoxDecoration(
        color: TetherTokens.ink,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: TetherTokens.cream.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // DARK HEADER
          _buildHeader(context),

          // CREAM CONTENT
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: TetherTokens.cream,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  _buildSearchAndFilter(),
                  Expanded(
                    child: _isDrilling || _bodyParts.isEmpty
                        ? _buildExerciseList()
                        : _buildBodyPartGrid(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Row(
        children: [
          if (_isDrilling)
            GestureDetector(
              onTap: () => _selectBodyPart(null),
              child: Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: TetherTokens.nightCard,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Symbols.arrow_back,
                  color: TetherTokens.cream,
                  size: 18,
                ),
              ),
            ),
          Expanded(
            child: Text(
              (_selectedBodyPart != null
                      ? _titleCase(_selectedBodyPart!)
                      : widget.initialCategory != null
                          ? _titleCase(widget.initialCategory!)
                          : 'ADD EXERCISE')
                  .toUpperCase(),
              style: TetherText.sans(18, w: TetherTokens.w800)
                  .copyWith(color: TetherTokens.cream),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: TetherTokens.nightCard,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Symbols.close,
                color: TetherTokens.cream,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: TetherTokens.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: TetherTokens.dayBorder.withValues(alpha: 0.3),
                ),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _onSearchChanged,
                style: TetherText.sans(14, w: TetherTokens.w400)
                    .copyWith(color: TetherTokens.ink),
                decoration: InputDecoration(
                  hintText: _selectedBodyPart != null
                      ? 'Search $_selectedBodyPart...'
                      : 'Search exercises...',
                  hintStyle: TetherText.sans(14, w: TetherTokens.w400)
                      .copyWith(color: TetherTokens.nightMuted),
                  prefixIcon: const Icon(
                    Symbols.search,
                    size: 20,
                    color: TetherTokens.nightMuted,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _showEquipmentFilter,
            child: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: _selectedEquipment.isNotEmpty
                    ? TetherTokens.defaultAccent.withValues(alpha: 0.15)
                    : TetherTokens.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedEquipment.isNotEmpty
                      ? TetherTokens.defaultAccent
                      : TetherTokens.dayBorder.withValues(alpha: 0.3),
                  width: _selectedEquipment.isNotEmpty ? 2 : 1,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Symbols.tune,
                    size: 20,
                    color: _selectedEquipment.isNotEmpty
                        ? TetherTokens.defaultAccent
                        : TetherTokens.nightMuted,
                  ),
                  if (_selectedEquipment.isNotEmpty)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: TetherTokens.defaultAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyPartGrid() {
    if (_loadingMeta) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFF5A1F),
        ),
      );
    }

    if (_bodyParts.isEmpty) {
      return _buildLibraryUnavailable();
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.2,
      ),
      itemCount: _bodyParts.length,
      itemBuilder: (context, i) {
        final part = _bodyParts[i];
        return GestureDetector(
          onTap: () => _selectBodyPart(part),
          child: Container(
            decoration: BoxDecoration(
              color: TetherTokens.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: TetherTokens.dayBorder.withValues(alpha: 0.3),
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    AppMedia.bodyPart(part),
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 40,
                      height: 40,
                      color: TetherTokens.sand,
                      alignment: Alignment.center,
                      child: const Icon(
                        Symbols.fitness_center,
                        size: 18,
                        color: TetherTokens.defaultAccent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _titleCase(part),
                    style: TetherText.sans(13, w: TetherTokens.w600)
                        .copyWith(color: TetherTokens.ink),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Symbols.chevron_right,
                  size: 16,
                  color: TetherTokens.nightMuted,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExerciseList() {
    if (_loadingExercises) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFF5A1F),
        ),
      );
    }

    final items = _listItems;
    if (items.isEmpty) {
      return _buildLibraryUnavailable(
        message: _searchCtrl.text.isNotEmpty
            ? 'NO MATCHING EXERCISES'
            : 'LIBRARY NOT DOWNLOADED',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        if (item is _SectionHeader) {
          return _SectionHeaderTile(label: item.label);
        }
        final ex = item as Exercise;
        return _ExerciseListTile(
          exercise: ex,
          onTap: () => _openDetail(ex),
          onAdd: () => _addExercise(ex),
        );
      },
    );
  }

  Widget _buildLibraryUnavailable({
    String message = 'LIBRARY NOT DOWNLOADED',
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: TetherTokens.sand,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Symbols.download_for_offline,
                size: 40,
                color: TetherTokens.nightMuted,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: TetherText.sans(16, w: TetherTokens.w800)
                  .copyWith(color: TetherTokens.ink),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Connect once to download the\nexercise library for offline use',
              style: TetherText.sans(13, w: TetherTokens.w400)
                  .copyWith(color: TetherTokens.nightMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                _loadMeta();
                _fetchExercises();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: TetherTokens.defaultAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Symbols.refresh,
                      color: TetherTokens.ink,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'TRY AGAIN',
                      style: TetherText.sans(13, w: TetherTokens.w800)
                          .copyWith(color: TetherTokens.ink),
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

  List<dynamic> get _listItems {
    final items = <dynamic>[];
    final hasActiveFilter =
        _selectedEquipment.isNotEmpty || _searchCtrl.text.isNotEmpty;

    if (_selectedBodyPart != null && !hasActiveFilter) {
      if (_recentlyUsed.isNotEmpty) {
        final relevant = _recentlyUsed
            .where((e) => e.bodyParts.contains(_selectedBodyPart))
            .take(3)
            .toList();
        if (relevant.isNotEmpty) {
          items.add(const _SectionHeader('RECENTLY USED'));
          items.addAll(relevant);
        }
      }
      if (_saved.isNotEmpty) {
        final relevant = _saved
            .where((e) => e.bodyParts.contains(_selectedBodyPart))
            .take(3)
            .toList();
        if (relevant.isNotEmpty) {
          items.add(const _SectionHeader('SAVED'));
          items.addAll(relevant);
        }
      }
      if (items.isNotEmpty) {
        items.add(const _SectionHeader('ALL EXERCISES'));
      }
    }

    if (_selectedBodyPart == null &&
        _searchCtrl.text.isEmpty &&
        _selectedEquipment.isEmpty) {
      if (_recentlyUsed.isNotEmpty) {
        items.add(const _SectionHeader('RECENTLY USED'));
        items.addAll(_recentlyUsed.take(5));
      }
      if (_saved.isNotEmpty) {
        items.add(const _SectionHeader('SAVED'));
        items.addAll(_saved.take(5));
      }
    }

    items.addAll(_exercises);
    return items;
  }
}

// List tile
class _ExerciseListTile extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  const _ExerciseListTile({
    required this.exercise,
    required this.onTap,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: TetherTokens.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: TetherTokens.dayBorder.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            // GIF thumbnail
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: TetherTokens.sand,
                borderRadius: BorderRadius.circular(12),
              ),
              child: exercise.gifUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        exercise.gifUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Symbols.fitness_center,
                          size: 22,
                          color: TetherTokens.nightMuted,
                        ),
                      ),
                    )
                  : const Icon(
                      Symbols.fitness_center,
                      size: 22,
                      color: TetherTokens.nightMuted,
                    ),
            ),
            const SizedBox(width: 12),
            // Name + category
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: TetherText.sans(14, w: TetherTokens.w600)
                        .copyWith(color: TetherTokens.ink),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (exercise.category != null || exercise.bodyParts.isNotEmpty)
                    Text(
                      [
                        if (exercise.category != null) exercise.category!,
                        if (exercise.bodyParts.isNotEmpty)
                          exercise.bodyParts.first,
                      ].join(' · '),
                      style: TetherText.sans(12, w: TetherTokens.w400)
                          .copyWith(color: TetherTokens.nightMuted),
                    ),
                ],
              ),
            ),
            // Quick-add button
            GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: TetherTokens.defaultAccent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: TetherTokens.defaultAccent.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Symbols.add,
                  size: 18,
                  color: TetherTokens.defaultAccent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader {
  final String label;
  const _SectionHeader(this.label);
}

class _SectionHeaderTile extends StatelessWidget {
  final String label;
  const _SectionHeaderTile({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        label,
        style: TetherText.sans(12, w: TetherTokens.w800)
            .copyWith(color: TetherTokens.nightMuted),
      ),
    );
  }
}

// Equipment Filter Bottom Sheet
class _EquipmentFilterSheet extends StatefulWidget {
  final List<String> allEquipments;
  final Set<String> selected;
  final ValueChanged<Set<String>> onApply;

  const _EquipmentFilterSheet({
    required this.allEquipments,
    required this.selected,
    required this.onApply,
  });

  @override
  State<_EquipmentFilterSheet> createState() => _EquipmentFilterSheetState();
}

class _EquipmentFilterSheetState extends State<_EquipmentFilterSheet> {
  late final Set<String> _local;

  @override
  void initState() {
    super.initState();
    _local = Set<String>.from(widget.selected);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: TetherTokens.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(0, 12, 0, bottomPad + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: TetherTokens.nightMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'FILTER BY EQUIPMENT',
                    style: TetherText.sans(16, w: TetherTokens.w800)
                        .copyWith(color: TetherTokens.ink),
                  ),
                ),
                if (_local.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => _local.clear()),
                    child: Text(
                      'CLEAR',
                      style: TetherText.sans(12, w: TetherTokens.w800)
                          .copyWith(color: TetherTokens.defaultAccent),
                    ),
                  ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.allEquipments.length,
              itemBuilder: (context, i) {
                final eq = widget.allEquipments[i];
                final checked = _local.contains(eq);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (checked) {
                        _local.remove(eq);
                      } else {
                        _local.add(eq);
                      }
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: checked
                          ? TetherTokens.defaultAccent.withValues(alpha: 0.1)
                          : TetherTokens.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: checked
                            ? TetherTokens.defaultAccent
                            : TetherTokens.dayBorder.withValues(alpha: 0.3),
                        width: checked ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          checked ? Symbols.check_circle : Symbols.circle,
                          size: 20,
                          color: checked
                              ? TetherTokens.defaultAccent
                              : TetherTokens.nightMuted,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            eq,
                            style: TetherText.sans(14, w: TetherTokens.w600)
                                .copyWith(
                              color: checked
                                  ? TetherTokens.defaultAccent
                                  : TetherTokens.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: () {
                widget.onApply(Set<String>.from(_local));
                Navigator.pop(context);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: TetherTokens.defaultAccent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _local.isEmpty ? 'SHOW ALL' : 'APPLY (${_local.length})',
                  textAlign: TextAlign.center,
                  style: TetherText.sans(14, w: TetherTokens.w800)
                      .copyWith(color: TetherTokens.ink),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
