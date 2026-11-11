import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tether_text.dart';
import '../../../core/theme/tether_tokens.dart';

/// Enhanced rejection modal with predefined reasons
/// Allows coaches to quickly select common rejection reasons with optional details
class PRRejectionModal extends StatefulWidget {
  final String exerciseName;
  final String userName;

  const PRRejectionModal({
    super.key,
    required this.exerciseName,
    required this.userName,
  });

  @override
  State<PRRejectionModal> createState() => _PRRejectionModalState();
}

class _PRRejectionModalState extends State<PRRejectionModal> {
  final Set<String> _selectedReasons = {};
  final TextEditingController _detailsCtrl = TextEditingController();
  bool _showDetails = false;

  static const List<String> _commonReasons = [
    "Didn't witness it",
    'Form was incorrect',
    'Video unclear/missing',
    'Weight not verified',
    'Incomplete lift',
    'Range of motion insufficient',
  ];

  bool get _canSubmit => _selectedReasons.isNotEmpty;

  String get _formattedReason {
    if (_selectedReasons.isEmpty) return '';

    final reasons = _selectedReasons.join(' • ');
    final details = _detailsCtrl.text.trim();

    if (details.isEmpty) {
      return reasons;
    } else {
      return '$reasons ($details)';
    }
  }

  @override
  void dispose() {
    _detailsCtrl.dispose();
    super.dispose();
  }

  void _toggleReason(String reason) {
    setState(() {
      if (_selectedReasons.contains(reason)) {
        _selectedReasons.remove(reason);
      } else {
        _selectedReasons.add(reason);
      }
      // Show details field after first selection
      if (_selectedReasons.isNotEmpty && !_showDetails) {
        _showDetails = true;
      }
    });
  }

  void _submit() {
    if (!_canSubmit) return;
    Navigator.pop(context, _formattedReason);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: TetherTokens.cream,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with warning icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.toneDanger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Symbols.warning,
                    size: 24,
                    color: AppTheme.toneDanger,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reject This PR?',
                        style: TetherText.sans(
                          20,
                          color: TetherTokens.ink,
                          w: TetherTokens.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.userName} • ${widget.exerciseName}',
                        style: TetherText.sans(
                          13,
                          color: TetherTokens.ink.withValues(alpha: 0.6),
                          w: TetherTokens.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Common Reasons Label
            Text(
              'Select reason(s):',
              style: TetherText.sans(
                14,
                color: TetherTokens.ink.withValues(alpha: 0.7),
                w: TetherTokens.w600,
              ),
            ),
            const SizedBox(height: 12),

            // Reason Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _commonReasons.map((reason) {
                final isSelected = _selectedReasons.contains(reason);
                return GestureDetector(
                  onTap: () => _toggleReason(reason),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.toneDanger.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.toneDanger
                            : TetherTokens.ink.withValues(alpha: 0.2),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          Icon(
                            Symbols.check_circle,
                            size: 16,
                            color: AppTheme.toneDanger,
                            fill: 1,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          reason,
                          style: TetherText.sans(
                            13,
                            color: isSelected
                                ? AppTheme.toneDanger
                                : TetherTokens.ink.withValues(alpha: 0.8),
                            w: isSelected
                                ? TetherTokens.w600
                                : TetherTokens.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            // Additional Details Field (shown after selection)
            if (_showDetails) ...[
              const SizedBox(height: 16),
              Text(
                'Additional details (optional):',
                style: TetherText.sans(
                  14,
                  color: TetherTokens.ink.withValues(alpha: 0.7),
                  w: TetherTokens.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _detailsCtrl,
                maxLines: 2,
                maxLength: 100,
                style: TetherText.sans(14, color: TetherTokens.ink),
                decoration: InputDecoration(
                  hintText: 'e.g., "Rep 3 depth was questionable"',
                  hintStyle: TetherText.sans(
                    13,
                    color: TetherTokens.ink.withValues(alpha: 0.4),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: TetherTokens.ink.withValues(alpha: 0.1),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: TetherTokens.ink.withValues(alpha: 0.1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppTheme.toneDanger,
                      width: 2,
                    ),
                  ),
                  counterStyle: TetherText.sans(
                    11,
                    color: TetherTokens.ink.withValues(alpha: 0.4),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],

            // Preview of selected reasons
            if (_selectedReasons.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.toneDanger.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.toneDanger.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Symbols.preview,
                      size: 16,
                      color: AppTheme.toneDanger.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rejection message:',
                            style: TetherText.sans(
                              11,
                              color: TetherTokens.ink.withValues(alpha: 0.5),
                              w: TetherTokens.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formattedReason,
                            style: TetherText.sans(
                              13,
                              color: TetherTokens.ink.withValues(alpha: 0.8),
                              w: TetherTokens.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: TetherTokens.ink.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'CANCEL',
                          style: TetherText.sans(
                            13,
                            color: TetherTokens.ink.withValues(alpha: 0.6),
                            w: TetherTokens.w600,
                            ls: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _canSubmit ? _submit : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 48,
                      decoration: BoxDecoration(
                        color: _canSubmit
                            ? AppTheme.toneDanger
                            : TetherTokens.ink.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: _canSubmit
                            ? [
                                BoxShadow(
                                  color:
                                      AppTheme.toneDanger.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          'REJECT PR',
                          style: TetherText.sans(
                            13,
                            color: _canSubmit
                                ? Colors.white
                                : TetherTokens.ink.withValues(alpha: 0.3),
                            w: TetherTokens.w800,
                            ls: 0.5,
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
      ),
    );
  }
}
