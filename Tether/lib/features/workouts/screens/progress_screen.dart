import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../models/workout_models.dart';
import '../services/workout_service.dart';
import 'exercise_list_screen.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  Exercise? _selectedExercise;
  List<ProgressData> _progressData = [];
  bool _isLoading = false;
  String? _error;

  Future<void> _selectExercise() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseListScreen(
          onExerciseSelected: (exercise) {
            setState(() {
              _selectedExercise = exercise;
            });
            _loadProgress();
          },
        ),
      ),
    );
  }

  Future<void> _loadProgress() async {
    if (_selectedExercise == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final workoutService = ref.read(workoutServiceProvider);
      
      final progress = await workoutService.getProgress(_selectedExercise!.id);

      setState(() {
        _progressData = progress;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[ProgressScreen] _loadProgress failed: $e');
      setState(() {
        _isLoading = false;
        _error = "Can't connect right now — check your connection and try again";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              title: Text(_selectedExercise?.name ?? 'Select Exercise'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _selectExercise,
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    const Icon(Symbols.wifi_off, size: 16, color: AppTheme.onSurfaceVariant),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _error!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _loadProgress,
                      child: const Icon(Symbols.refresh,
                          size: 16, color: AppTheme.primaryContainer),
                    ),
                  ],
                ),
              )
            else if (_selectedExercise != null && _progressData.isEmpty)
              const Center(
                child: Text('No progress data available for this exercise'),
              )
            else if (_selectedExercise != null)
              _buildProgressChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressChart() {
    if (_progressData.length < 2) {
      return const Center(
        child: Text('Need at least 2 data points to show progress'),
      );
    }

    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 10,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[300],
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: _calculateInterval(),
                getTitlesWidget: (value, meta) {
                  final date = _progressData[value.toInt()].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${date.day}/${date.month}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: _calculateWeightInterval(),
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(0),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey[300]!),
          ),
          minX: 0,
          maxX: (_progressData.length - 1).toDouble(),
          minY: _calculateMinY(),
          maxY: _calculateMaxY(),
          lineBarsData: [
            LineChartBarData(
              spots: _progressData.asMap().entries.map((entry) {
                final index = entry.key;
                final data = entry.value;
                return FlSpot(
                  index.toDouble(),
                  data.weightKg ?? 0,
                );
              }).toList(),
              isCurved: true,
              color: Theme.of(context).colorScheme.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Theme.of(context).colorScheme.primary,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateMinY() {
    final weights = _progressData.map((d) => d.weightKg ?? 0).toList();
    final min = weights.reduce((a, b) => a < b ? a : b);
    return (min - 5).clamp(0, double.infinity);
  }

  double _calculateMaxY() {
    final weights = _progressData.map((d) => d.weightKg ?? 0).toList();
    final max = weights.reduce((a, b) => a > b ? a : b);
    return max + 5;
  }

  double _calculateWeightInterval() {
    final range = _calculateMaxY() - _calculateMinY();
    return (range / 5).ceilToDouble();
  }

  double _calculateInterval() {
    if (_progressData.length <= 5) return 1;
    if (_progressData.length <= 10) return 2;
    return (_progressData.length / 10).ceilToDouble();
  }
}
