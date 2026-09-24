import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../social/services/social_extras_service.dart';

/// Real in-app notifications inbox (buddy requests, sessions, etc.).
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
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
          SnackBar(content: Text("Couldn't load notifications: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    await ref.read(socialExtrasServiceProvider).markAllNotificationsRead();
    await _load();
  }

  Future<void> _open(AppNotificationItem item) async {
    if (item.isUnread) {
      await ref
          .read(socialExtrasServiceProvider)
          .markNotificationRead(item.id);
      await _load();
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}';
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'buddy_request':
      case 'buddy_accepted':
        return Symbols.group;
      case 'buddy_session':
        return Symbols.fitness_center;
      default:
        return Symbols.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = _items.where((i) => i.isUnread).length;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Text(
          'Activity',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
        ),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: Center(
                            child: Text(
                              'No notifications yet',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(color: AppTheme.onSurfaceVariant),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.containerMargin,
                        8,
                        AppTheme.containerMargin,
                        40,
                      ),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppTheme.stackSm),
                      itemBuilder: (_, i) {
                        final item = _items[i];
                        return GlassCard(
                          onTap: () => _open(item),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: item.isUnread
                                      ? AppTheme.primaryContainer
                                          .withValues(alpha: 0.16)
                                      : AppTheme.surfaceContainerHigh,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _iconFor(item.type),
                                  size: 20,
                                  color: item.isUnread
                                      ? AppTheme.primaryContainer
                                      : AppTheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: item.isUnread
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.body,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppTheme.onSurfaceVariant,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _timeAgo(item.createdAt),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: AppTheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              if (item.isUnread)
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(top: 6),
                                  decoration: const BoxDecoration(
                                    color: AppTheme.primaryContainer,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
