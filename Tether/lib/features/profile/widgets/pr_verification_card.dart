import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tether_text.dart';
import '../../../core/theme/tether_tokens.dart';
import '../../../core/widgets/cached_media.dart';
import '../models/personal_record.dart';

/// Enhanced PR card for coach verification
/// Features expandable details, resubmission warnings, and action buttons
class PRVerificationCard extends StatefulWidget {
  final PersonalRecord pr;
  final String userName;
  final String? userAvatar;
  final bool isProcessing;
  final VoidCallback onVerify;
  final VoidCallback onReject;

  const PRVerificationCard({
    super.key,
    required this.pr,
    required this.userName,
    this.userAvatar,
    this.isProcessing = false,
    required this.onVerify,
    required this.onReject,
  });

  @override
  State<PRVerificationCard> createState() => _PRVerificationCardState();
}

class _PRVerificationCardState extends State<PRVerificationCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Color get _exerciseColor {
    switch (widget.pr.exerciseName) {
      case 'Bench Press':
        return const Color(0xFF6366F1); // Indigo
      case 'Squat':
        return const Color(0xFFEC4899); // Pink
      case 'Deadlift':
        return const Color(0xFF8B5CF6); // Purple
      default:
        return TetherTokens.defaultAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final weightText =
        widget.pr.weightKg != null ? '${widget.pr.weightKg}kg' : 'BW';
    final repsText = '${widget.pr.reps}';
    final dateText = _formatDate(widget.pr.achievedDate);
    final isResubmission = widget.pr.submissionCount > 1;
    final daysSinceSubmission =
        DateTime.now().difference(widget.pr.lastSubmissionAt).inDays;

    return Container(
      decoration: BoxDecoration(
        color: TetherTokens.nightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isResubmission
              ? AppTheme.toneWarning.withValues(alpha: 0.3)
              : TetherTokens.cream.withValues(alpha: 0.1),
          width: isResubmission ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Card Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Header Row
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _exerciseColor.withValues(alpha: 0.4),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: widget.userAvatar != null
                            ? AppCachedImage(
                                url: widget.userAvatar!,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                fallback: _buildAvatarPlaceholder(),
                              )
                            : _buildAvatarPlaceholder(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.userName,
                            style: TetherText.sans(
                              16,
                              color: TetherTokens.cream,
                              w: TetherTokens.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: _exerciseColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: _exerciseColor.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  widget.pr.exerciseName.toUpperCase(),
                                  style: TetherText.sans(
                                    11,
                                    color: _exerciseColor,
                                    w: TetherTokens.w800,
                                    ls: 0.5,
                                  ),
                                ),
                              ),
                              if (daysSinceSubmission == 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.toneSuccess
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'NEW',
                                    style: TetherText.sans(
                                      10,
                                      color: AppTheme.toneSuccess,
                                      w: TetherTokens.w800,
                                      ls: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Expand/Collapse button
                    GestureDetector(
                      onTap: _toggleExpand,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: TetherTokens.cream.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: RotationTransition(
                          turns: Tween(begin: 0.0, end: 0.5)
                              .animate(_expandAnimation),
                          child: Icon(
                            Symbols.expand_more,
                            size: 20,
                            color: TetherTokens.cream.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // PR Stats - Large Display
                Row(
                  children: [
                    Expanded(
                      child: _buildLargeStatCard(
                        label: 'WEIGHT',
                        value: weightText,
                        icon: Symbols.fitness_center,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildLargeStatCard(
                        label: 'REPS',
                        value: repsText,
                        icon: Symbols.repeat,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildLargeStatCard(
                        label: 'DATE',
                        value: dateText,
                        icon: Symbols.calendar_today,
                      ),
                    ),
                  ],
                ),

                // Resubmission Warning
                if (isResubmission) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.toneWarning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.toneWarning.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Symbols.warning,
                          size: 18,
                          color: AppTheme.toneWarning,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Resubmitted ${_ordinal(widget.pr.submissionCount)} time${widget.pr.submissionCount > 2 ? ' — review carefully' : ''}',
                            style: TetherText.sans(
                              12,
                              color: AppTheme.toneWarning,
                              w: TetherTokens.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildVerifyButton(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildRejectButton(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Expandable Details Section
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Container(
              decoration: BoxDecoration(
                color: TetherTokens.cream.withValues(alpha: 0.03),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(
                    color: TetherTokens.cream.withValues(alpha: 0.1),
                    height: 1,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Additional Details',
                    style: TetherText.sans(
                      13,
                      color: TetherTokens.cream.withValues(alpha: 0.6),
                      w: TetherTokens.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Submitted',
                    _formatDateTime(widget.pr.lastSubmissionAt),
                    Symbols.schedule,
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    'Achieved',
                    _formatDateTime(widget.pr.achievedDate),
                    Symbols.event,
                  ),
                  if (widget.pr.submissionCount > 1) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Attempts',
                      '${widget.pr.submissionCount} submission${widget.pr.submissionCount > 1 ? 's' : ''}',
                      Symbols.history,
                    ),
                  ],
                  if (widget.pr.rejectionReason != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.toneDanger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.toneDanger.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Symbols.info,
                            size: 16,
                            color: AppTheme.toneDanger,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Previous Rejection',
                                  style: TetherText.sans(
                                    11,
                                    color: AppTheme.toneDanger,
                                    w: TetherTokens.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.pr.rejectionReason!,
                                  style: TetherText.sans(
                                    12,
                                    color: TetherTokens.cream
                                        .withValues(alpha: 0.7),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    final initials = widget.userName
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0] : '')
        .join();
    return Container(
      color: TetherTokens.nightCard,
      child: Center(
        child: Text(
          initials.toUpperCase(),
          style: TetherText.sans(
            18,
            color: TetherTokens.cream,
            w: TetherTokens.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLargeStatCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: _exerciseColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _exerciseColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 16,
            color: _exerciseColor.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TetherText.sans(
              20,
              color: TetherTokens.cream,
              w: TetherTokens.w800,
              ls: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TetherText.sans(
              10,
              color: TetherTokens.cream.withValues(alpha: 0.5),
              w: TetherTokens.w600,
              ls: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: TetherTokens.cream.withValues(alpha: 0.4),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TetherText.sans(
            12,
            color: TetherTokens.cream.withValues(alpha: 0.5),
            w: TetherTokens.w400,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TetherText.sans(
            12,
            color: TetherTokens.cream,
            w: TetherTokens.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildVerifyButton() {
    return GestureDetector(
      onTap: widget.isProcessing ? null : widget.onVerify,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: widget.isProcessing
              ? AppTheme.toneSuccess.withValues(alpha: 0.5)
              : AppTheme.toneSuccess,
          borderRadius: BorderRadius.circular(12),
          boxShadow: !widget.isProcessing
              ? [
                  BoxShadow(
                    color: AppTheme.toneSuccess.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: widget.isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Symbols.check_circle,
                      size: 20,
                      color: Colors.white,
                      fill: 1,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'VERIFY',
                      style: TetherText.sans(
                        13,
                        color: Colors.white,
                        w: TetherTokens.w800,
                        ls: 0.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildRejectButton() {
    return GestureDetector(
      onTap: widget.isProcessing ? null : widget.onReject,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.isProcessing
                ? AppTheme.toneDanger.withValues(alpha: 0.5)
                : AppTheme.toneDanger,
            width: 2,
          ),
        ),
        child: Center(
          child: widget.isProcessing
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: AppTheme.toneDanger,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Symbols.cancel,
                      size: 20,
                      color: AppTheme.toneDanger,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'REJECT',
                      style: TetherText.sans(
                        13,
                        color: AppTheme.toneDanger,
                        w: TetherTokens.w800,
                        ls: 0.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yest.';
    if (diff < 7) return '$diff days';
    if (diff < 30) return '${(diff / 7).floor()}w ago';

    return '${date.day}/${date.month}';
  }

  String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;

    if (diff == 0) {
      final hours = now.difference(date).inHours;
      if (hours == 0) {
        final minutes = now.difference(date).inMinutes;
        return '$minutes min${minutes != 1 ? 's' : ''} ago';
      }
      return '$hours hour${hours != 1 ? 's' : ''} ago';
    }
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';

    return '${date.day}/${date.month}/${date.year}';
  }

  String _ordinal(int number) {
    if (number == 1) return '1st';
    if (number == 2) return '2nd';
    if (number == 3) return '3rd';
    return '${number}th';
  }
}
