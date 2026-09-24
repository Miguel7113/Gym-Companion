import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../profile/services/profile_service.dart';
import '../../social/services/social_extras_service.dart';
import '../../workouts/models/workout_models.dart';
import '../../workouts/screens/workout_builder_screen.dart';
import '../../workouts/screens/workout_detail_screen.dart';

Future<void> showMemberDirectorySheet(
  BuildContext context, {
  required GymMemberDirectoryEntry member,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _MemberDirectorySheet(member: member),
  );
}

Future<void> showCoachDirectorySheet(
  BuildContext context, {
  required GymCoach coach,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _CoachDirectorySheet(coach: coach),
  );
}

class _MemberDirectorySheet extends ConsumerStatefulWidget {
  const _MemberDirectorySheet({required this.member});
  final GymMemberDirectoryEntry member;

  @override
  ConsumerState<_MemberDirectorySheet> createState() =>
      _MemberDirectorySheetState();
}

class _MemberDirectorySheetState extends ConsumerState<_MemberDirectorySheet> {
  bool _busy = false;

  Future<void> _requestBuddy() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(socialExtrasServiceProvider)
          .requestBuddy(widget.member.userId);
      ref.invalidate(homeMembersDirectoryProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Buddy request sent')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't send request: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _acceptBuddy() async {
    final linkId = widget.member.buddyLinkId;
    if (linkId == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(socialExtrasServiceProvider).acceptBuddy(linkId);
      ref.invalidate(homeMembersDirectoryProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are now gym buddies')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't accept: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final member = widget.member;
    final profileAsync = ref.watch(memberProfileProvider(member.userId));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _AvatarBubble(
                  name: member.displayName,
                  isTrainingNow: member.isTrainingNow,
                  size: 56,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.displayName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        member.isTrainingNow
                            ? 'Training now'
                            : _buddyLabel(member.buddyStatus),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: member.isTrainingNow
                                  ? AppTheme.primaryContainer
                                  : AppTheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            profileAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (profile) => Row(
                children: [
                  _StatChip(
                    label: 'Workouts',
                    value: '${profile.stats.workoutCount}',
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    label: 'Streak',
                    value: '${profile.stats.streakDays}d',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (member.buddyStatus == 'none')
              FilledButton.icon(
                onPressed: _busy ? null : _requestBuddy,
                icon: const Icon(Symbols.group_add),
                label: Text(_busy ? 'Sending…' : 'Send buddy request'),
              )
            else if (member.buddyStatus == 'pending_incoming')
              FilledButton.icon(
                onPressed: _busy ? null : _acceptBuddy,
                icon: const Icon(Symbols.check),
                label: Text(_busy ? 'Accepting…' : 'Accept buddy request'),
              )
            else if (member.buddyStatus == 'pending_outgoing')
              OutlinedButton(
                onPressed: null,
                child: const Text('Buddy request pending'),
              )
            else
              OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Symbols.handshake),
                label: const Text('Gym buddies'),
              ),
          ],
        ),
      ),
    );
  }

  String _buddyLabel(String status) {
    switch (status) {
      case 'active':
        return 'Gym buddy';
      case 'pending_outgoing':
        return 'Request sent';
      case 'pending_incoming':
        return 'Wants to be your buddy';
      default:
        return 'Gym member';
    }
  }
}

class _CoachDirectorySheet extends ConsumerStatefulWidget {
  const _CoachDirectorySheet({required this.coach});
  final GymCoach coach;

  @override
  ConsumerState<_CoachDirectorySheet> createState() =>
      _CoachDirectorySheetState();
}

class _CoachDirectorySheetState extends ConsumerState<_CoachDirectorySheet> {
  Future<List<WorkoutTemplate>>? _programsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _programsFuture ??=
        ref.read(socialExtrasServiceProvider).listCoachPrograms(widget.coach.userId);
  }

  @override
  Widget build(BuildContext context) {
    final coach = widget.coach;
    final roleLabel =
        coach.role.toLowerCase() == 'admin' ? 'Admin' : 'Coach';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _AvatarBubble(
                  name: coach.displayName,
                  isTrainingNow: coach.isTrainingNow,
                  size: 56,
                  accent: true,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coach.displayName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        coach.isTrainingNow
                            ? '$roleLabel · Training now'
                            : '$roleLabel · ${coach.programCount} program${coach.programCount == 1 ? '' : 's'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Programs',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: FutureBuilder<List<WorkoutTemplate>>(
                future: _programsFuture,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  final programs = snap.data ?? [];
                  if (programs.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No published gym programs yet.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.onSurfaceVariant,
                            ),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: programs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final program = programs[i];
                      return GlassCard(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  WorkoutDetailScreen(routine: program),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    program.name,
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                  ),
                                  Text(
                                    '${program.exercises.length} exercises',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppTheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        WorkoutBuilderScreen(routine: program),
                                  ),
                                );
                              },
                              child: const Text('Start'),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Booking a 1:1 with this coach is coming later.',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarBubble extends StatelessWidget {
  const _AvatarBubble({
    required this.name,
    this.isTrainingNow = false,
    this.size = 44,
    this.accent = false,
  });

  final String name;
  final bool isTrainingNow;
  final double size;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent
                ? AppTheme.primaryContainer.withValues(alpha: 0.18)
                : AppTheme.surfaceContainerHigh,
            border: isTrainingNow
                ? Border.all(color: AppTheme.primaryContainer, width: 2)
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: TextStyle(
              color: accent
                  ? AppTheme.primaryContainer
                  : AppTheme.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: size * 0.36,
            ),
          ),
        ),
        if (isTrainingNow)
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.surfaceContainer, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
