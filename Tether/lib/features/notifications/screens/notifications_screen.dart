import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/tether_text.dart';
import '../../../core/theme/tether_tokens.dart';
import '../../social/screens/buddies_screen.dart';
import '../../social/services/social_extras_service.dart';
import '../../workouts/screens/workout_session_screen.dart';
import '../../workouts/services/workout_service.dart';

/// Notifications redesign with foundry-style: dark header + cream sheet + wide cards
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState
    extends ConsumerState<NotificationsScreen> {
  List<AppNotificationItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items =
          await ref.read(socialExtrasServiceProvider).listNotifications();
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Couldn't load notifications: $e"),
            backgroundColor: TetherTokens.ink,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    await ref.read(socialExtrasServiceProvider).markAllNotificationsRead();
    ref.invalidate(unreadNotificationCountProvider);
    await _load();
  }

  Future<void> _open(AppNotificationItem item) async {
    // Mark as read
    if (item.isUnread) {
      await ref
          .read(socialExtrasServiceProvider)
          .markNotificationRead(item.id);
      ref.invalidate(unreadNotificationCountProvider);
      await _load();
    }
    if (!mounted) return;

    // Navigate based on type
    switch (item.type) {
      case 'buddy_request':
      case 'buddy_accepted':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BuddiesScreen()),
        );
        break;
      case 'buddy_session':
        final rawId = item.payload['sessionId'];
        await _openBuddySession(rawId is String ? rawId : null);
        break;
      default:
        break;
    }
  }

  Future<void> _openBuddySession(String? sessionId) async {
    if (sessionId == null || sessionId.isEmpty) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BuddiesScreen()),
      );
      return;
    }
    try {
      final session =
          await ref.read(workoutServiceProvider).getSession(sessionId);
      if (!mounted) return;
      if (session.endedAt != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('That workout has already ended'),
            backgroundColor: TetherTokens.ink,
          ),
        );
        return;
      }
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WorkoutSessionScreen(session: session),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Couldn't open that workout: $e"),
          backgroundColor: TetherTokens.ink,
        ),
      );
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.inMinutes < 1) return 'JUST NOW';
    if (diff.inMinutes < 60) return '${diff.inMinutes}M AGO';
    if (diff.inHours < 24) return '${diff.inHours}H AGO';
    if (diff.inDays < 7) return '${diff.inDays}D AGO';
    return '${dt.month}/${dt.day}/${dt.year}';
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'buddy_request':
        return Symbols.person_add;
      case 'buddy_accepted':
        return Symbols.group;
      case 'buddy_session':
        return Symbols.fitness_center;
      case 'pr_achieved':
        return Symbols.trophy;
      case 'workout_milestone':
        return Symbols.celebration;
      case 'like':
        return Symbols.favorite;
      case 'comment':
        return Symbols.chat_bubble;
      default:
        return Symbols.notifications;
    }
  }

  Color _accentColorFor(String type) {
    switch (type) {
      case 'buddy_request':
      case 'buddy_accepted':
        return TetherTokens.defaultAccent;
      case 'buddy_session':
        return TetherTokens.defaultAccent;
      case 'pr_achieved':
        return const Color(0xFFFFB800); // Gold color
      case 'workout_milestone':
        return TetherTokens.defaultAccent;
      case 'like':
        return Colors.red.shade400;
      case 'comment':
        return TetherTokens.defaultAccent;
      default:
        return TetherTokens.nightMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = _items.where((i) => i.isUnread).length;

    return Scaffold(
      backgroundColor: TetherTokens.ink,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // DARK HEADER
            _buildHeader(context, unread),
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
                        child: _items.isEmpty
                            ? _buildEmptyState(context)
                            : _buildNotificationsList(context),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int unread) {
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
                  'NOTIFICATIONS',
                  style: TetherText.sans(18, w: TetherTokens.w800)
                      .copyWith(color: TetherTokens.cream),
                ),
                if (unread > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '$unread NEW',
                    style: TetherText.sans(12, w: TetherTokens.w600)
                        .copyWith(color: TetherTokens.defaultAccent),
                  ),
                ],
              ],
            ),
          ),
          // Mark all read button
          if (unread > 0)
            GestureDetector(
              onTap: _markAllRead,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: TetherTokens.defaultAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'MARK READ',
                  style: TetherText.sans(12, w: TetherTokens.w800)
                      .copyWith(color: TetherTokens.ink),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: TetherTokens.sand,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Symbols.notifications_off,
                  size: 40,
                  color: TetherTokens.nightMuted,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'NO NOTIFICATIONS',
                style: TetherText.sans(16, w: TetherTokens.w800)
                    .copyWith(color: TetherTokens.ink),
              ),
              const SizedBox(height: 8),
              Text(
                'You\'re all caught up',
                style: TetherText.sans(14, w: TetherTokens.w400)
                    .copyWith(color: TetherTokens.nightMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsList(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
      itemCount: _items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final item = _items[i];
        return _buildNotificationCard(context, item);
      },
    );
  }

  Widget _buildNotificationCard(
      BuildContext context, AppNotificationItem item) {
    final accentColor = _accentColorFor(item.type);

    return GestureDetector(
      onTap: () => _open(item),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: item.isUnread
              ? TetherTokens.sand
              : Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: item.isUnread
              ? Border.all(color: accentColor.withValues(alpha: 0.3), width: 2)
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _iconFor(item.type),
                size: 24,
                color: accentColor,
              ),
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TetherText.sans(
                            14,
                            w: item.isUnread
                                ? TetherTokens.w800
                                : TetherTokens.w600,
                          ).copyWith(color: TetherTokens.ink),
                        ),
                      ),
                      if (item.isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.body,
                    style: TetherText.sans(13, w: TetherTokens.w400)
                        .copyWith(color: TetherTokens.nightMuted),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _timeAgo(item.createdAt),
                    style: TetherText.sans(11, w: TetherTokens.w600)
                        .copyWith(color: TetherTokens.nightMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
