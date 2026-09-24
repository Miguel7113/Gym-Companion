import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/media_catalog.dart';
import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_service.dart';
import '../models/workout_models.dart';
import '../services/offline_workout_service.dart';
import 'exercise_detail_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ExercisePickerSheet
//
// A full-screen bottom sheet for picking exercises.
// Features:
//   - Search bar (debounced 350ms)
//   - Body part filter chips (horizontal scroll)
//   - Equipment filter (bottom sheet multi-select)
//   - Recently Used row (when no filters active)
//   - Saved/Favourites row (when no filters active)
//   - Exercise list with quick-add (+) button
//   - Tap exercise name → ExerciseDetailScreen with "Add to Workout" button
// ─────────────────────────────────────────────────────────────────────────────
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

  /// Shows as a full-screen modal bottom sheet.
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

class _ExercisePickerSheetState extends ConsumerState<ExercisePickerSheet> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  // Filters
  String? _selectedBodyPart;
  final Set<String> _selectedEquipment = {};

  // Data
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
    // Pre-populate equipment filter if launched from the Train screen
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

    // If cache is empty, trigger a seed first and wait for it before
    // trying to load body parts — otherwise everything returns [] silently.
    final cacheCount = await ref
        .read(appDatabaseProvider)
        .exercisesDao
        .getCacheCount();

    if (cacheCount == 0) {
      debugPrint('[ExercisePicker] cache empty — seeding before loading meta');
      await ref.read(syncServiceProvider).seedIfNeeded();
    }

    await Future.wait([
      svc
          .listBodyParts()
          .then((parts) {
            if (mounted) setState(() => _bodyParts = parts);
          })
          .catchError((e) {
            debugPrint('[ExercisePicker] listBodyParts failed: $e');
          }),

      svc
          .listEquipments()
          .then((equips) {
            if (mounted) setState(() => _allEquipments = equips);
          })
          .catchError((e) {
            debugPrint('[ExercisePicker] listEquipments failed: $e');
          }),

      svc
          .getRecentlyUsed(limit: 8)
          .then((recent) {
            if (mounted) setState(() => _recentlyUsed = recent);
          })
          .catchError((e) {
            debugPrint('[ExercisePicker] getRecentlyUsed failed: $e');
          }),

      svc
          .getSavedExercises()
          .then((saved) {
            if (mounted) setState(() => _saved = saved);
          })
          .catchError((e) {
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
      final equipment = _selectedEquipment.isNotEmpty
          ? _selectedEquipment.toList()
          : null;

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
      _exercises = []; // clear while loading
    });
    if (part != null) {
      _fetchExercises(); // drill into this body part
    }
  }

  // True when user has drilled into a body part, searched, or filtered equipment
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
          // Apply state first, then fetch with updated filters
          setState(() {
            _selectedEquipment
              ..clear()
              ..addAll(newSelection);
          });
          // Schedule fetch after setState completes
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
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXxl)),
      ),
      child: Column(
        children: [
          // ── Drag handle ──────────────────────────────────────────────
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Header ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Row(
              children: [
                // Back button when drilling into a body part
                if (_isDrilling)
                  GestureDetector(
                    onTap: () => _selectBodyPart(null),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerHigh,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: const Icon(Symbols.arrow_back, size: 16),
                    ),
                  ),
                Expanded(
                  child: Text(
                    _selectedBodyPart != null
                        ? _titleCase(_selectedBodyPart!)
                        : widget.initialCategory != null
                        ? _titleCase(widget.initialCategory!)
                        : 'Add exercise',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerHigh,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: const Icon(Symbols.close, size: 16),
                  ),
                ),
              ],
            ),
          ),

          // ── Search + Equipment filter button ─────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: _onSearchChanged,
                      style: Theme.of(context).textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: _selectedBodyPart != null
                            ? 'Search ${_selectedBodyPart}...'
                            : 'Search all exercises...',
                        hintStyle: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: AppTheme.onSurfaceVariant),
                        prefixIcon: const Icon(
                          Symbols.search,
                          size: 18,
                          color: AppTheme.onSurfaceVariant,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _showEquipmentFilter,
                  child: Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: _selectedEquipment.isNotEmpty
                          ? AppTheme.primaryContainer.withOpacity(0.12)
                          : AppTheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                      border: Border.all(
                        color: _selectedEquipment.isNotEmpty
                            ? AppTheme.primaryContainer.withOpacity(0.4)
                            : Colors.white.withOpacity(0.08),
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Symbols.tune,
                          size: 18,
                          color: _selectedEquipment.isNotEmpty
                              ? AppTheme.primaryContainer
                              : AppTheme.onSurfaceVariant,
                        ),
                        if (_selectedEquipment.isNotEmpty)
                          Positioned(
                            top: 7,
                            right: 7,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryContainer,
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
          ),

          Divider(height: 1, color: Colors.white.withOpacity(0.06)),

          // ── Content — body part grid OR exercise list ────────────────
          Expanded(
            child: _isDrilling || _bodyParts.isEmpty
                ? _buildExerciseList()
                : _buildBodyPartGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyPartGrid() {
    if (_loadingMeta) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(AppTheme.primaryContainer),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading exercises...',
              style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12),
            ),
          ],
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
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.2,
      ),
      itemCount: _bodyParts.length,
      itemBuilder: (_, i) {
        final part = _bodyParts[i];
        return GestureDetector(
          onTap: () => _selectBodyPart(part),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    AppMedia.bodyPart(part),
                    width: 42,
                    height: 42,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 42,
                      height: 42,
                      color: AppTheme.surfaceContainerHigh,
                      alignment: Alignment.center,
                      child: const Icon(
                        Symbols.fitness_center,
                        size: 16,
                        color: AppTheme.primaryContainer,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _titleCase(part),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Symbols.chevron_right,
                  size: 14,
                  color: AppTheme.onSurfaceVariant,
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
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(AppTheme.primaryContainer),
        ),
      );
    }

    final items = _listItems;
    if (items.isEmpty) {
      return _buildLibraryUnavailable(
        message: _searchCtrl.text.isNotEmpty
            ? 'No matching exercises'
            : 'Exercise library not downloaded',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      itemBuilder: (_, i) {
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
    String message = 'Exercise library not downloaded',
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Symbols.download_for_offline,
              size: 44,
              color: AppTheme.onSurfaceVariant.withOpacity(0.7),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Connect once to download the exercise library for offline use.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () {
                _loadMeta();
                _fetchExercises();
              },
              icon: const Icon(Symbols.refresh, size: 18),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  // Builds the flat list including section headers
  List<dynamic> get _listItems {
    final items = <dynamic>[];
    final hasActiveFilter =
        _selectedEquipment.isNotEmpty || _searchCtrl.text.isNotEmpty;

    // Show recently used / saved sections when drilling into a body part
    // but no additional filters are active
    if (_selectedBodyPart != null && !hasActiveFilter) {
      if (_recentlyUsed.isNotEmpty) {
        final relevant = _recentlyUsed
            .where((e) => e.bodyParts.contains(_selectedBodyPart))
            .take(3)
            .toList();
        if (relevant.isNotEmpty) {
          items.add(const _SectionHeader('Recently used'));
          items.addAll(relevant);
        }
      }
      if (_saved.isNotEmpty) {
        final relevant = _saved
            .where((e) => e.bodyParts.contains(_selectedBodyPart))
            .take(3)
            .toList();
        if (relevant.isNotEmpty) {
          items.add(const _SectionHeader('Saved'));
          items.addAll(relevant);
        }
      }
      if (items.isNotEmpty) {
        items.add(const _SectionHeader('All'));
      }
    }

    // When searching across all body parts (no body part selected)
    if (_selectedBodyPart == null &&
        _searchCtrl.text.isEmpty &&
        _selectedEquipment.isEmpty) {
      if (_recentlyUsed.isNotEmpty) {
        items.add(const _SectionHeader('Recently used'));
        items.addAll(_recentlyUsed.take(5));
      }
      if (_saved.isNotEmpty) {
        items.add(const _SectionHeader('Saved'));
        items.addAll(_saved.take(5));
      }
    }

    items.addAll(_exercises);
    return items;
  }
}

// ─── List tile ────────────────────────────────────────────────────────────────

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
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // GIF thumbnail or placeholder
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                border: Border.all(color: Colors.white.withOpacity(0.07)),
              ),
              child: exercise.gifUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      child: Image.network(
                        exercise.gifUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Symbols.fitness_center,
                          size: 20,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : const Icon(
                      Symbols.fitness_center,
                      size: 20,
                      color: AppTheme.onSurfaceVariant,
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
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (exercise.category != null)
                    Text(
                      [
                        exercise.category!,
                        if (exercise.bodyParts.isNotEmpty)
                          exercise.bodyParts.first,
                      ].join(' · '),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            // Quick-add button
            GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primaryContainer.withOpacity(0.35),
                  ),
                ),
                child: const Icon(
                  Symbols.add,
                  size: 16,
                  color: AppTheme.primaryContainer,
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: AppTheme.onSurfaceVariant),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Equipment Filter Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────
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
        color: AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXxl)),
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
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Filter by equipment',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                if (_local.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => _local.clear()),
                    child: Text(
                      'Clear',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.primaryContainer,
                      ),
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
              itemCount: widget.allEquipments.length,
              itemBuilder: (_, i) {
                final eq = widget.allEquipments[i];
                final checked = _local.contains(eq);
                return CheckboxListTile(
                  value: checked,
                  onChanged: (v) {
                    setState(() {
                      if (v == true)
                        _local.add(eq);
                      else
                        _local.remove(eq);
                    });
                  },
                  title: Text(
                    eq,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  activeColor: AppTheme.primaryContainer,
                  checkColor: AppTheme.onPrimaryFixed,
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PrimaryButton(
              label: _local.isEmpty ? 'Show All' : 'Apply (${_local.length})',
              onPressed: () {
                widget.onApply(Set<String>.from(_local));
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
