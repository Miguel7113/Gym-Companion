import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../models/workout_models.dart';
import '../services/offline_workout_service.dart';

class ExerciseListScreen extends ConsumerStatefulWidget {
  final Function(Exercise) onExerciseSelected;
  final String? initialBodyPart;
  final String? initialCategory;

  const ExerciseListScreen({
    super.key,
    required this.onExerciseSelected,
    this.initialBodyPart,
    this.initialCategory,
  });

  @override
  ConsumerState<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends ConsumerState<ExerciseListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Exercise> _allExercises = [];
  List<Exercise> _filteredExercises = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadExercises();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final svc = ref.read(offlineWorkoutServiceProvider);

      final exercises = await svc.listExercises(
        bodyPart: widget.initialBodyPart,
        category: widget.initialCategory,
      );

      exercises.sort((a, b) => a.name.compareTo(b.name));

      setState(() {
        _allExercises = exercises;
        _filteredExercises = exercises;
        _isLoading = false;
        if (exercises.isEmpty) _error = 'offline_fallback';
      });
    } catch (e) {
      debugPrint('[ExerciseListScreen] _loadExercises failed: $e');
      setState(() {
        _isLoading = false;
        _error = 'offline_fallback';
        _allExercises = [];
        _filteredExercises = [];
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredExercises = _allExercises
          .where((exercise) => exercise.name.toLowerCase().contains(query))
          .toList();
    });
  }

  Map<String, List<Exercise>> _groupExercisesByCategory() {
    // Group exercises by category for better organization
    final grouped = <String, List<Exercise>>{};
    for (final exercise in _filteredExercises) {
      final category = exercise.category ?? 'Other';
      if (!grouped.containsKey(category)) {
        grouped[category] = [];
      }
      grouped[category]!.add(exercise);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialBodyPart != null
              ? widget.initialBodyPart!.toUpperCase()
              : widget.initialCategory != null
              ? widget.initialCategory!.toUpperCase()
              : 'Select Exercise',
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? _buildErrorView()
                : _buildExerciseList(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    if (_allExercises.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Symbols.download_for_offline,
                size: 48,
                color: AppTheme.onSurfaceVariant.withOpacity(0.7),
              ),
              const SizedBox(height: 16),
              Text(
                'Exercise library not downloaded',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Connect to the server once to make exercises available offline.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _loadExercises,
                icon: const Icon(Symbols.refresh, size: 18),
                label: const Text('TRY AGAIN'),
              ),
            ],
          ),
        ),
      );
    }

    // Cached data remains usable even if a refresh fails.
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              Icon(
                Symbols.wifi_off,
                size: 14,
                color: AppTheme.onSurfaceVariant.withOpacity(0.6),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Can't refresh right now — showing downloaded exercises",
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _loadExercises,
                child: Icon(
                  Symbols.refresh,
                  size: 16,
                  color: AppTheme.primaryContainer,
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _buildExerciseList()),
      ],
    );
  }

  Widget _buildExerciseList() {
    if (_filteredExercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No exercises found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    final grouped = _groupExercisesByCategory();

    return ListView.builder(
      itemCount: grouped.keys.length,
      itemBuilder: (context, index) {
        final category = grouped.keys.elementAt(index);
        final exercises = grouped[category]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                category,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            ...exercises.map(
              (exercise) => ListTile(
                title: Text(exercise.name),
                trailing: exercise.isCustom
                    ? const Icon(Icons.person, size: 16, color: Colors.grey)
                    : null,
                onTap: () {
                  widget.onExerciseSelected(exercise);
                  Navigator.pop(context);
                },
              ),
            ),
            if (index < grouped.keys.length - 1) const Divider(),
          ],
        );
      },
    );
  }
}
