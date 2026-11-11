import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/navigation/main_navigation.dart';
import '../../../core/theme/tether_text.dart';
import '../../../core/theme/tether_tokens.dart';
import '../../workouts/screens/workout_session_screen.dart';
import '../../workouts/services/workout_service.dart';
import '../services/social_extras_service.dart';

/// Buddies screen redesign with foundry-style: dark header + cream sheet + wide cards
class BuddiesScreen extends ConsumerStatefulWidget {
  const BuddiesScreen({super.key});

  @override
  ConsumerState<BuddiesScreen> createState() =>
      _BuddiesScreenState();
}

class _BuddiesScreenState extends ConsumerState<BuddiesScreen> {
  List<BuddyLink> _links = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;

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
          SnackBar(
            content: Text("Couldn't load buddies: $e"),
            backgroundColor: TetherTokens.ink,
          ),
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

    setState(() => _searching = true);
    try {
      final results =
          await ref.read(socialExtrasServiceProvider).searchBuddyCandidates(q);
      if (mounted) setState(() => _results = results);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Search failed: $e"),
            backgroundColor: TetherTokens.ink,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _requestBuddy(String userId, String name) async {
    try {
      await ref.read(socialExtrasServiceProvider).requestBuddy(userId);
      setState(() => _results = []);
      _searchCtrl.clear();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Buddy request sent to $name'),
            backgroundColor: TetherTokens.ink,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Couldn't send request: $e"),
            backgroundColor: TetherTokens.ink,
          ),
        );
      }
    }
  }

  Future<void> _acceptBuddy(BuddyLink link) async {
    try {
      await ref.read(socialExtrasServiceProvider).acceptBuddy(link.id);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${link.otherDisplayName} is now your buddy!'),
            backgroundColor: TetherTokens.ink,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Couldn't accept: $e"),
            backgroundColor: TetherTokens.ink,
          ),
        );
      }
    }
  }

  Future<void> _declineBuddy(BuddyLink link) async {
    try {
      await ref.read(socialExtrasServiceProvider).declineBuddy(link.id);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Request declined'),
            backgroundColor: TetherTokens.ink,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Couldn't decline: $e"),
            backgroundColor: TetherTokens.ink,
          ),
        );
      }
    }
  }

  Future<void> _cancelBuddy(BuddyLink link) async {
    try {
      await ref.read(socialExtrasServiceProvider).cancelBuddy(link.id);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed ${link.otherDisplayName}'),
            backgroundColor: TetherTokens.ink,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Couldn't cancel: $e"),
            backgroundColor: TetherTokens.ink,
          ),
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
          SnackBar(
            content: Text("Couldn't start buddy workout: $e"),
            backgroundColor: TetherTokens.ink,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _links.where((l) => l.status == 'active').toList();
    final pending = _links.where((l) => l.status == 'pending').toList();

    return Scaffold(
      backgroundColor: TetherTokens.ink,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // DARK HEADER
            _buildHeader(context, active.length),
            // CREAM SHEET
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: TetherTokens.cream,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFFF5A1F),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: TetherTokens.defaultAccent,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
                          children: [
                            // Search bar
                            _buildSearchBar(),
                            // Search results
                            if (_results.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              _buildSearchResults(),
                            ],
                            // Active buddies
                            const SizedBox(height: 20),
                            _buildSection(
                              'ACTIVE BUDDIES (${active.length}/3)',
                              active.isEmpty
                                  ? [_buildEmptyState('No active buddies yet')]
                                  : active
                                      .map((link) => _buildBuddyCard(link))
                                      .toList(),
                            ),
                            // Pending requests
                            if (pending.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              _buildSection(
                                'PENDING REQUESTS',
                                pending
                                    .map((link) => _buildPendingCard(link))
                                    .toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int activeCount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: TetherTokens.nightCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Symbols.arrow_back,
                color: TetherTokens.cream,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GYM BUDDIES',
                  style: TetherText.sans(18, w: TetherTokens.w800)
                      .copyWith(color: TetherTokens.cream),
                ),
                if (activeCount > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '$activeCount ACTIVE',
                    style: TetherText.sans(12, w: TetherTokens.w600)
                        .copyWith(color: TetherTokens.defaultAccent),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: TetherTokens.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: TetherTokens.dayBorder.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              style: TetherText.sans(14, w: TetherTokens.w400)
                  .copyWith(color: TetherTokens.ink),
              decoration: InputDecoration(
                hintText: 'Search gym members...',
                hintStyle: TetherText.sans(14, w: TetherTokens.w400)
                    .copyWith(color: TetherTokens.nightMuted),
                prefixIcon: const Icon(
                  Symbols.search,
                  size: 20,
                  color: TetherTokens.nightMuted,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
                isDense: true,
              ),
              onSubmitted: (_) => _search(),
            ),
          ),
          if (_searching)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: TetherTokens.defaultAccent,
                ),
              ),
            )
          else
            GestureDetector(
              onTap: _search,
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: TetherTokens.defaultAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Symbols.arrow_forward,
                  size: 18,
                  color: TetherTokens.ink,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'SEARCH RESULTS',
            style: TetherText.sans(12, w: TetherTokens.w800)
                .copyWith(color: TetherTokens.nightMuted),
          ),
        ),
        ..._results.map((row) {
          final id = row['id'] as String;
          final name = row['displayName'] as String? ?? 'Member';
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TetherTokens.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: TetherTokens.dayBorder.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: TetherTokens.sand,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Symbols.person,
                    size: 22,
                    color: TetherTokens.nightMuted,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    name,
                    style: TetherText.sans(15, w: TetherTokens.w600)
                        .copyWith(color: TetherTokens.ink),
                  ),
                ),
                GestureDetector(
                  onTap: () => _requestBuddy(id, name),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: TetherTokens.defaultAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'REQUEST',
                      style: TetherText.sans(12, w: TetherTokens.w800)
                          .copyWith(color: TetherTokens.ink),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: TetherText.sans(12, w: TetherTokens.w800)
                .copyWith(color: TetherTokens.nightMuted),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildBuddyCard(BuddyLink link) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TetherTokens.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: TetherTokens.dayBorder.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: TetherTokens.sand,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Symbols.person,
              size: 24,
              color: TetherTokens.defaultAccent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              link.otherDisplayName,
              style: TetherText.sans(15, w: TetherTokens.w600)
                  .copyWith(color: TetherTokens.ink),
            ),
          ),
          GestureDetector(
            onTap: () => _startBuddyWorkout(link),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: TetherTokens.defaultAccent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Symbols.fitness_center,
                    size: 16,
                    color: TetherTokens.ink,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'TRAIN',
                    style: TetherText.sans(12, w: TetherTokens.w800)
                        .copyWith(color: TetherTokens.ink),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _cancelBuddy(link),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: TetherTokens.sand,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Symbols.close,
                size: 18,
                color: TetherTokens.nightMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingCard(BuddyLink link) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: link.isIncoming
            ? TetherTokens.defaultAccent.withValues(alpha: 0.1)
            : TetherTokens.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: link.isIncoming
              ? TetherTokens.defaultAccent.withValues(alpha: 0.3)
              : TetherTokens.dayBorder.withValues(alpha: 0.3),
          width: link.isIncoming ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: link.isIncoming
                  ? TetherTokens.defaultAccent.withValues(alpha: 0.2)
                  : TetherTokens.sand,
              shape: BoxShape.circle,
            ),
            child: Icon(
              link.isIncoming ? Symbols.person_add : Symbols.schedule,
              size: 22,
              color: link.isIncoming
                  ? TetherTokens.defaultAccent
                  : TetherTokens.nightMuted,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  link.otherDisplayName,
                  style: TetherText.sans(15, w: TetherTokens.w600)
                      .copyWith(color: TetherTokens.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  link.isIncoming ? 'Incoming request' : 'Request sent',
                  style: TetherText.sans(12, w: TetherTokens.w400).copyWith(
                    color: link.isIncoming
                        ? TetherTokens.defaultAccent
                        : TetherTokens.nightMuted,
                  ),
                ),
              ],
            ),
          ),
          if (link.isIncoming) ...[
            GestureDetector(
              onTap: () => _acceptBuddy(link),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: TetherTokens.defaultAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'ACCEPT',
                  style: TetherText.sans(11, w: TetherTokens.w800)
                      .copyWith(color: TetherTokens.ink),
                ),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => _declineBuddy(link),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: TetherTokens.sand,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'DECLINE',
                  style: TetherText.sans(11, w: TetherTokens.w800)
                      .copyWith(color: TetherTokens.nightMuted),
                ),
              ),
            ),
          ] else
            GestureDetector(
              onTap: () => _cancelBuddy(link),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: TetherTokens.sand,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'CANCEL',
                  style: TetherText.sans(11, w: TetherTokens.w800)
                      .copyWith(color: TetherTokens.nightMuted),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: TetherTokens.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: TetherTokens.dayBorder.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: TetherTokens.sand,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Symbols.group,
              size: 30,
              color: TetherTokens.nightMuted,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TetherText.sans(14, w: TetherTokens.w600)
                .copyWith(color: TetherTokens.nightMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
