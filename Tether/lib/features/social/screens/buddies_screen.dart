import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../workouts/screens/workout_session_screen.dart';
import '../../workouts/services/workout_service.dart';
import '../services/social_extras_service.dart';

class BuddiesScreen extends ConsumerStatefulWidget {
  const BuddiesScreen({super.key});

  @override
  ConsumerState<BuddiesScreen> createState() => _BuddiesScreenState();
}

class _BuddiesScreenState extends ConsumerState<BuddiesScreen> {
  List<BuddyLink> _links = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final links = await ref.read(socialExtrasServiceProvider).listBuddies();
      if (mounted) setState(() => _links = links);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't load buddies: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _search() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) {
      setState(() => _results = []);
      return;
    }
    try {
      final results =
          await ref.read(socialExtrasServiceProvider).searchBuddyCandidates(q);
      if (mounted) setState(() => _results = results);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Search failed: $e")),
        );
      }
    }
  }

  Future<void> _startBuddyWorkout(BuddyLink link) async {
    try {
      final session = await ref.read(workoutServiceProvider).createBuddySession(
            buddyUserId: link.otherUserId,
          );
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WorkoutSessionScreen(session: session),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't start buddy workout: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _links.where((l) => l.status == 'active').toList();
    final pending = _links.where((l) => l.status == 'pending').toList();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text('Gym buddies'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(AppTheme.containerMargin),
                children: [
                  TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search members',
                      suffixIcon: IconButton(
                        onPressed: _search,
                        icon: const Icon(Symbols.search),
                      ),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                  if (_results.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('Search results',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ..._results.map((row) {
                      final id = row['id'] as String;
                      final name = row['displayName'] as String? ?? 'Member';
                      return ListTile(
                        title: Text(name),
                        trailing: TextButton(
                          onPressed: () async {
                            await ref
                                .read(socialExtrasServiceProvider)
                                .requestBuddy(id);
                            await _load();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Buddy request sent')),
                              );
                            }
                          },
                          child: const Text('Request'),
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 20),
                  Text('Active (${active.length}/3)',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (active.isEmpty)
                    const Text('No active buddies yet.')
                  else
                    ...active.map(
                      (link) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GlassCard(
                          child: Row(
                            children: [
                              Expanded(child: Text(link.otherDisplayName)),
                              TextButton(
                                onPressed: () => _startBuddyWorkout(link),
                                child: const Text('Train'),
                              ),
                              IconButton(
                                onPressed: () async {
                                  await ref
                                      .read(socialExtrasServiceProvider)
                                      .cancelBuddy(link.id);
                                  await _load();
                                },
                                icon: const Icon(Symbols.close),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Text('Pending', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (pending.isEmpty)
                    const Text('No pending requests.')
                  else
                    ...pending.map(
                      (link) => ListTile(
                        title: Text(link.otherDisplayName),
                        subtitle: Text(link.isIncoming ? 'Incoming' : 'Outgoing'),
                        trailing: link.isIncoming
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton(
                                    onPressed: () async {
                                      await ref
                                          .read(socialExtrasServiceProvider)
                                          .acceptBuddy(link.id);
                                      await _load();
                                    },
                                    child: const Text('Accept'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      await ref
                                          .read(socialExtrasServiceProvider)
                                          .declineBuddy(link.id);
                                      await _load();
                                    },
                                    child: const Text('Decline'),
                                  ),
                                ],
                              )
                            : TextButton(
                                onPressed: () async {
                                  await ref
                                      .read(socialExtrasServiceProvider)
                                      .cancelBuddy(link.id);
                                  await _load();
                                },
                                child: const Text('Cancel'),
                              ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
