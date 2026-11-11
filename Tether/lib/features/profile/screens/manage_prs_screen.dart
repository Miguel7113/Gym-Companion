import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/tether_text.dart';
import '../../../core/theme/tether_tokens.dart';
import '../models/personal_record.dart';
import '../services/personal_records_service.dart';
import '../../auth/providers/auth_provider.dart';

/// Manage Personal Records Screen
/// Allows users to add, edit, and delete their PRs
class ManagePRsScreen extends ConsumerStatefulWidget {
  const ManagePRsScreen({super.key});

  @override
  ConsumerState<ManagePRsScreen> createState() => _ManagePRsScreenState();
}

class _ManagePRsScreenState extends ConsumerState<ManagePRsScreen> {
  List<PersonalRecord> _prs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPRs();
  }

  Future<void> _loadPRs() async {
    setState(() => _loading = true);
    try {
      final user = ref.read(currentUserProvider);
      if (user?.gymId == null) return;

      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      if (token == null) return;

      final service = ref.read(personalRecordsServiceProvider);
      final prs = await service.getMyPRs(user!.gymId, token);

      if (mounted) {
        setState(() {
          _prs = prs;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load PRs: $e')),
        );
      }
    }
  }

  Future<void> _deletePR(PersonalRecord pr) async {
    // Confirm deletion
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TetherTokens.cream,
        title: Text(
          'Delete PR?',
          style: TetherText.sans(18, color: TetherTokens.ink, w: TetherTokens.w600),
        ),
        content: Text(
          'Are you sure you want to delete your ${pr.exerciseName} PR?',
          style: TetherText.sans(14, color: TetherTokens.ink),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TetherText.sans(14, color: TetherTokens.ink),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TetherText.sans(14, color: TetherTokens.defaultAccent, w: TetherTokens.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      if (token == null) return;

      final service = ref.read(personalRecordsServiceProvider);
      await service.deletePR(pr.id, token);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PR deleted')),
        );
        _loadPRs();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete PR: $e')),
        );
      }
    }
  }

  void _showAddEditPRDialog({PersonalRecord? existingPR}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditPRSheet(
        existingPR: existingPR,
        onSaved: _loadPRs,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TetherTokens.ink,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
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
                          child: Icon(
                            Symbols.arrow_back,
                            size: 18,
                            color: TetherTokens.cream,
                          ),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _showAddEditPRDialog(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: TetherTokens.defaultAccent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Symbols.add,
                                size: 16,
                                color: TetherTokens.cream,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'ADD PR',
                                style: TetherText.sans(
                                  12,
                                  color: TetherTokens.cream,
                                  w: TetherTokens.w600,
                                  ls: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Manage PRs',
                    style: TetherText.sans(
                      32,
                      w: TetherTokens.w800,
                      color: TetherTokens.cream,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your personal records and get them verified by a coach',
                    style: TetherText.sans(
                      14,
                      color: TetherTokens.cream.withOpacity(0.6),
                      w: TetherTokens.w400,
                    ),
                  ),
                ],
              ),
            ),

            // PR List
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: TetherTokens.cream,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: TetherTokens.ink,
                        ),
                      )
                    : _prs.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Symbols.emoji_events,
                                  size: 64,
                                  color: TetherTokens.ink.withOpacity(0.2),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No PRs yet',
                                  style: TetherText.sans(
                                    18,
                                    color: TetherTokens.ink,
                                    w: TetherTokens.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap ADD PR to record your first',
                                  style: TetherText.sans(
                                    14,
                                    color: TetherTokens.ink.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(20),
                            itemCount: _prs.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final pr = _prs[index];
                              return _buildPRCard(pr);
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPRCard(PersonalRecord pr) {
    final weightText = pr.weightKg != null ? '${pr.weightKg}kg' : 'Bodyweight';
    final repsText = '${pr.reps} ${pr.reps == 1 ? 'rep' : 'reps'}';
    
    // Rate limit check
    final hoursSinceSubmission = DateTime.now()
        .difference(pr.lastSubmissionAt)
        .inHours;
    final canEdit = hoursSinceSubmission >= 24;
    final hoursRemaining = canEdit ? 0 : (24 - hoursSinceSubmission);

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (pr.isVerified) {
      statusColor = TetherTokens.defaultAccent;
      statusText = 'VERIFIED';
      statusIcon = Symbols.check_circle;
    } else if (pr.isRejected) {
      statusColor = TetherTokens.dayMuted;
      statusText = 'REJECTED';
      statusIcon = Symbols.cancel;
    } else {
      statusColor = TetherTokens.defaultAccent;
      statusText = 'PENDING';
      statusIcon = Symbols.schedule;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE4DFD3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  pr.exerciseName,
                  style: TetherText.sans(
                    16,
                    color: TetherTokens.ink,
                    w: TetherTokens.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TetherText.sans(
                        10,
                        color: statusColor,
                        w: TetherTokens.w600,
                        ls: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weight',
                      style: TetherText.sans(
                        11,
                        color: TetherTokens.ink.withOpacity(0.5),
                        w: TetherTokens.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      weightText,
                      style: TetherText.sans(
                        16,
                        color: TetherTokens.ink,
                        w: TetherTokens.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reps',
                      style: TetherText.sans(
                        11,
                        color: TetherTokens.ink.withOpacity(0.5),
                        w: TetherTokens.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      repsText,
                      style: TetherText.sans(
                        16,
                        color: TetherTokens.ink,
                        w: TetherTokens.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date',
                      style: TetherText.sans(
                        11,
                        color: TetherTokens.ink.withOpacity(0.5),
                        w: TetherTokens.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(pr.achievedDate),
                      style: TetherText.sans(
                        13,
                        color: TetherTokens.ink,
                        w: TetherTokens.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (pr.rejectionReason != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: TetherTokens.sand,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Symbols.info,
                    size: 16,
                    color: TetherTokens.dayMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      pr.rejectionReason!,
                      style: TetherText.sans(
                        12,
                        color: TetherTokens.dayMuted,
                        w: TetherTokens.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (!pr.isVerified) ...[
            const SizedBox(height: 12),
            
            // Rate limit warning
            if (!canEdit) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: TetherTokens.sand,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Symbols.schedule,
                      size: 16,
                      color: TetherTokens.dayMuted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Can edit in $hoursRemaining hour${hoursRemaining != 1 ? 's' : ''}',
                        style: TetherText.sans(
                          12,
                          color: TetherTokens.dayMuted,
                          w: TetherTokens.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: canEdit ? () => _showAddEditPRDialog(existingPR: pr) : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: canEdit 
                            ? TetherTokens.ink 
                            : TetherTokens.ink.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'EDIT',
                          style: TetherText.sans(
                            12,
                            color: TetherTokens.cream,
                            w: TetherTokens.w600,
                            ls: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _deletePR(pr),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: TetherTokens.dayMuted,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'DELETE',
                          style: TetherText.sans(
                            12,
                            color: TetherTokens.dayMuted,
                            w: TetherTokens.w600,
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
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';

    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Bottom sheet for adding/editing a PR
class AddEditPRSheet extends ConsumerStatefulWidget {
  final PersonalRecord? existingPR;
  final VoidCallback onSaved;

  const AddEditPRSheet({
    super.key,
    this.existingPR,
    required this.onSaved,
  });

  @override
  ConsumerState<AddEditPRSheet> createState() => _AddEditPRSheetState();
}

class _AddEditPRSheetState extends ConsumerState<AddEditPRSheet> {
  final _formKey = GlobalKey<FormState>();
  final _weightCtrl = TextEditingController();
  final _repsCtrl = TextEditingController();

  String? _selectedExercise;
  DateTime _selectedDate = DateTime.now();
  bool _saving = false;

  // Big 3 + common exercises
  final List<String> _exercises = [
    'Bench Press',
    'Squat',
    'Deadlift',
    'Overhead Press',
    'Barbell Row',
    'Pull Up',
    'Dip',
    'Front Squat',
    'Romanian Deadlift',
    'Incline Bench Press',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingPR != null) {
      _selectedExercise = widget.existingPR!.exerciseName;
      _weightCtrl.text = widget.existingPR!.weightKg?.toString() ?? '';
      _repsCtrl.text = widget.existingPR!.reps.toString();
      _selectedDate = widget.existingPR!.achievedDate;
    }
  }

  /// Check if user can submit (24 hour rate limit)
  bool _canSubmit() {
    if (widget.existingPR == null) return true; // New PR, no limit
    
    final hoursSince = DateTime.now()
        .difference(widget.existingPR!.lastSubmissionAt)
        .inHours;
    return hoursSince >= 24;
  }

  /// Get hours remaining until can resubmit
  int _hoursRemaining() {
    if (widget.existingPR == null) return 0;
    
    final hoursSince = DateTime.now()
        .difference(widget.existingPR!.lastSubmissionAt)
        .inHours;
    return (24 - hoursSince).clamp(0, 24);
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedExercise == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an exercise')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user?.gymId == null) return;

      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      if (token == null) return;

      final service = ref.read(personalRecordsServiceProvider);
      await service.upsertPR(
        gymId: user!.gymId,
        exerciseName: _selectedExercise!,
        weightKg: _weightCtrl.text.isNotEmpty
            ? double.tryParse(_weightCtrl.text)
            : null,
        reps: int.parse(_repsCtrl.text),
        achievedDate: _selectedDate,
        token: token,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save PR: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingPR != null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: TetherTokens.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: TetherTokens.ink.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEdit ? 'Edit PR' : 'Add New PR',
                  style: TetherText.sans(
                    24,
                    color: TetherTokens.ink,
                    w: TetherTokens.w800,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Symbols.close,
                    size: 24,
                    color: TetherTokens.ink,
                  ),
                ),
              ],
            ),
          ),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Exercise dropdown
                    Text(
                      'Exercise',
                      style: TetherText.sans(
                        13,
                        color: TetherTokens.ink.withOpacity(0.6),
                        w: TetherTokens.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: TetherTokens.ink.withOpacity(0.1),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedExercise,
                          dropdownColor: TetherTokens.cream,
                          hint: Text(
                            'Select exercise',
                            style: TetherText.sans(
                              15,
                              color: TetherTokens.ink.withOpacity(0.4),
                            ),
                          ),
                          isExpanded: true,
                          icon: Icon(
                            Symbols.expand_more,
                            color: TetherTokens.ink,
                          ),
                          items: _exercises.map((exercise) {
                            return DropdownMenuItem(
                              value: exercise,
                              child: Text(
                                exercise,
                                style: TetherText.sans(
                                  15,
                                  color: TetherTokens.ink,
                                  w: TetherTokens.w400,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: isEdit
                              ? null
                              : (value) => setState(() => _selectedExercise = value),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Weight
                    Text(
                      'Weight (kg) - Optional for bodyweight',
                      style: TetherText.sans(
                        13,
                        color: TetherTokens.ink.withOpacity(0.6),
                        w: TetherTokens.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _weightCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TetherText.sans(16, color: TetherTokens.ink),
                      decoration: InputDecoration(
                        hintText: 'Leave empty for bodyweight',
                        hintStyle: TetherText.sans(
                          15,
                          color: TetherTokens.ink.withOpacity(0.4),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: TetherTokens.ink.withOpacity(0.1),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: TetherTokens.ink.withOpacity(0.1),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: TetherTokens.defaultAccent,
                            width: 2,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Reps
                    Text(
                      'Reps',
                      style: TetherText.sans(
                        13,
                        color: TetherTokens.ink.withOpacity(0.6),
                        w: TetherTokens.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _repsCtrl,
                      keyboardType: TextInputType.number,
                      style: TetherText.sans(16, color: TetherTokens.ink),
                      decoration: InputDecoration(
                        hintText: 'Number of reps',
                        hintStyle: TetherText.sans(
                          15,
                          color: TetherTokens.ink.withOpacity(0.4),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: TetherTokens.ink.withOpacity(0.1),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: TetherTokens.ink.withOpacity(0.1),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: TetherTokens.defaultAccent,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter reps';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Date
                    Text(
                      'Date Achieved',
                      style: TetherText.sans(
                        13,
                        color: TetherTokens.ink.withOpacity(0.6),
                        w: TetherTokens.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _selectedDate = date);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: TetherTokens.ink.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                              style: TetherText.sans(
                                15,
                                color: TetherTokens.ink,
                                w: TetherTokens.w400,
                              ),
                            ),
                            Icon(
                              Symbols.calendar_today,
                              size: 20,
                              color: TetherTokens.ink.withOpacity(0.5),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Rate limit warning (if applicable)
                    if (isEdit && !_canSubmit())
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: TetherTokens.sand,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: TetherTokens.dayMuted.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Symbols.schedule,
                              size: 20,
                              color: TetherTokens.dayMuted,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Rate Limit Active',
                                    style: TetherText.sans(
                                      13,
                                      color: TetherTokens.ink,
                                      w: TetherTokens.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'You can edit this PR in ${_hoursRemaining()} hour${_hoursRemaining() != 1 ? 's' : ''}',
                                    style: TetherText.sans(
                                      12,
                                      color: TetherTokens.dayMuted,
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
                ),
              ),
            ),
          ),

          // Save button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: TetherTokens.cream,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: GestureDetector(
              onTap: (_saving || (isEdit && !_canSubmit())) ? null : _save,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: (_saving || (isEdit && !_canSubmit()))
                      ? TetherTokens.ink.withOpacity(0.5)
                      : TetherTokens.ink,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: TetherTokens.cream,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          isEdit ? 'UPDATE PR' : 'SUBMIT FOR VERIFICATION',
                          style: TetherText.sans(
                            14,
                            color: TetherTokens.cream,
                            w: TetherTokens.w600,
                            ls: 0.5,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
