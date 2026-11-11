import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Rest timer preset selector with common durations
class RestTimerPicker extends StatelessWidget {
  final int? currentSeconds;
  final Function(int) onSelect;

  // Common rest periods in seconds
  static const List<int> presets = [30, 60, 90, 120, 180, 240, 300];

  const RestTimerPicker({
    super.key,
    required this.currentSeconds,
    required this.onSelect,
  });

  String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    } else if (seconds % 60 == 0) {
      return '${seconds ~/ 60}m';
    } else {
      final mins = seconds ~/ 60;
      final secs = seconds % 60;
      return '$mins:${secs.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 14, bottom: 8, top: 4),
          child: Text(
            'REST TIME',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...presets.map((seconds) => _RestChip(
                  label: _formatDuration(seconds),
                  seconds: seconds,
                  isSelected: currentSeconds == seconds,
                  onTap: () => onSelect(seconds),
                )),
            _RestChip(
              label: 'Custom',
              seconds: null,
              isSelected: currentSeconds != null &&
                  !presets.contains(currentSeconds),
              onTap: () => _showCustomPicker(context),
            ),
          ],
        ),
      ],
    );
  }

  void _showCustomPicker(BuildContext context) {
    final controller = TextEditingController(
      text: currentSeconds?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainer,
        title: const Text('Custom Rest Time'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Seconds',
            hintText: 'e.g., 75',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            final seconds = int.tryParse(value);
            if (seconds != null && seconds > 0) {
              onSelect(seconds);
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final seconds = int.tryParse(controller.text);
              if (seconds != null && seconds > 0) {
                onSelect(seconds);
                Navigator.pop(context);
              }
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }
}

class _RestChip extends StatelessWidget {
  final String label;
  final int? seconds;
  final bool isSelected;
  final VoidCallback onTap;

  const _RestChip({
    required this.label,
    required this.seconds,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryContainer.withOpacity(0.15)
              : AppTheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryContainer.withOpacity(0.5)
                : Colors.white.withOpacity(0.08),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? AppTheme.primaryContainer
                : AppTheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
