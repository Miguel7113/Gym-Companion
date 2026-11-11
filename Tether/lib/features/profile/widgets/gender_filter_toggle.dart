import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Three-button toggle for filtering leaderboards by gender
/// Options: All, Male, Female
class GenderFilterToggle extends StatelessWidget {
  final String? selectedGender; // null or 'all' = All, 'male' = Male, 'female' = Female
  final ValueChanged<String?> onChanged;

  const GenderFilterToggle({
    super.key,
    required this.selectedGender,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Normalize: treat null as 'all'
    final normalizedSelection = selectedGender == null || selectedGender == 'all'
        ? 'all'
        : selectedGender;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FilterButton(
            label: 'All',
            isSelected: normalizedSelection == 'all',
            onTap: () => onChanged(null), // null = show all
          ),
          const SizedBox(width: 4),
          _FilterButton(
            label: 'Male',
            icon: Icons.male,
            isSelected: normalizedSelection == 'male',
            onTap: () => onChanged('male'),
          ),
          const SizedBox(width: 4),
          _FilterButton(
            label: 'Female',
            icon: Icons.female,
            isSelected: normalizedSelection == 'female',
            onTap: () => onChanged('female'),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryContainer.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? Colors.black
                    : AppTheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected
                        ? Colors.black
                        : AppTheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact version for modal headers or tight spaces
class GenderFilterToggleCompact extends StatelessWidget {
  final String? selectedGender;
  final ValueChanged<String?> onChanged;

  const GenderFilterToggleCompact({
    super.key,
    required this.selectedGender,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedSelection = selectedGender == null || selectedGender == 'all'
        ? 'all'
        : selectedGender;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CompactButton(
            label: 'All',
            isSelected: normalizedSelection == 'all',
            onTap: () => onChanged(null),
          ),
          const SizedBox(width: 3),
          _CompactButton(
            icon: Icons.male,
            isSelected: normalizedSelection == 'male',
            onTap: () => onChanged('male'),
          ),
          const SizedBox(width: 3),
          _CompactButton(
            icon: Icons.female,
            isSelected: normalizedSelection == 'female',
            onTap: () => onChanged('female'),
          ),
        ],
      ),
    );
  }
}

class _CompactButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CompactButton({
    this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: label != null ? 12 : 8,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: icon != null
            ? Icon(
                icon,
                size: 14,
                color: isSelected
                    ? Colors.black
                    : AppTheme.onSurfaceVariant,
              )
            : Text(
                label!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected
                          ? Colors.black
                          : AppTheme.onSurfaceVariant,
                    ),
              ),
      ),
    );
  }
}
