import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Notification model — placeholder until notification provider is wired
// ─────────────────────────────────────────────────────────────────────────────
enum _NotifType { like, comment, achievement, announcement, milestone }

class _Notif {
  final String id;
  final _NotifType type;
  final String title;
  final String body;
  final String timeAgo;
  final bool isUnread;

  const _Notif({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.timeAgo,
    this.isUnread = false,
  });
}

const List<_Notif> _today = [
  _Notif(
    id: '1',
    type: _NotifType.like,
    title: 'Marcus R. liked your post',
    body: 'Just finished Leg Day! PR crushed.',
    timeAgo: '2 MIN AGO',
    isUnread: true,
  ),
  _Notif(
    id: '2',
    type: _NotifType.comment,
    title: 'Coach Sarah commented',
    body: '"Great form on that squat! Keep it up 💪"',
    timeAgo: '45 MIN AGO',
    isUnread: true,
  ),
  _Notif(
    id: '3',
    type: _NotifType.achievement,
    title: 'New Personal Record!',
    body: 'You hit a new PR on Barbell Back Squat — 140 KG.',
    timeAgo: '3 HOURS AGO',
    isUnread: true,
  ),
];

const List<_Notif> _earlier = [
  _Notif(
    id: '4',
    type: _NotifType.announcement,
    title: 'Gym Announcement',
    body: 'New squat racks are now available on Level 2.',
    timeAgo: 'YESTERDAY',
  ),
  _Notif(
    id: '5',
    type: _NotifType.milestone,
    title: '7-Day Streak!',
    body: 'You\'ve worked out 7 days in a row. Keep the momentum.',
    timeAgo: '2 DAYS AGO',
  ),
  _Notif(
    id: '6',
    type: _NotifType.like,
    title: 'Elena V. and 4 others liked your post',
    body: 'Early morning cardio done.',
    timeAgo: '3 DAYS AGO',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// NotificationsScreen — pushed as a route from the bell icon
// ─────────────────────────────────────────────────────────────────────────────
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      extendBodyBehindAppBar: true,
      appBar: _NotifAppBar(),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 80)),

          // TODAY section
          _SectionHeader(label: 'TODAY'),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.containerMargin,
            ),
            sliver: SliverList.separated(
              itemCount: _today.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppTheme.stackSm),
              itemBuilder: (_, i) => _NotifTile(notif: _today[i]),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppTheme.stackLg)),

          // EARLIER section
          _SectionHeader(label: 'EARLIER'),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.containerMargin,
            ),
            sliver: SliverList.separated(
              itemCount: _earlier.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppTheme.stackSm),
              itemBuilder: (_, i) => _NotifTile(notif: _earlier[i]),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App bar — glass blur, back arrow left, screen title center
// ─────────────────────────────────────────────────────────────────────────────
class _NotifAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 64 + topPadding,
          padding: EdgeInsets.only(
            top: topPadding,
            left: AppTheme.gutter,
            right: AppTheme.gutter,
          ),
          decoration: BoxDecoration(
            color: AppTheme.surface.withOpacity(0.75),
            border: Border(
              bottom: BorderSide(
                  color: Colors.white.withOpacity(0.08), width: 1),
            ),
          ),
          child: Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.surfaceContainerHigh,
                    border: Border.all(
                        color: Colors.white.withOpacity(0.1), width: 1),
                  ),
                  child: const Icon(Symbols.arrow_back,
                      size: 18, color: AppTheme.onSurface),
                ),
              ),

              Expanded(
                child: Center(
                  child: Text(
                    'ACTIVITY',
                    style: Theme.of(context)
                        .textTheme
                        .headlineLarge
                        ?.copyWith(letterSpacing: 0.05 * 28),
                  ),
                ),
              ),

              // Placeholder to balance layout
              const SizedBox(width: 36),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header — TODAY / EARLIER
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.containerMargin,
          0,
          AppTheme.containerMargin,
          AppTheme.stackSm,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notification tile
//
// Unread:  lime 4px left border + faint lime tint bg + filled lime icon circle
//          + neon glow on the icon
// Read:    no border, neutral bg, outlined grey icon circle
// ─────────────────────────────────────────────────────────────────────────────
class _NotifTile extends StatelessWidget {
  final _Notif notif;
  const _NotifTile({required this.notif});

  IconData get _icon {
    switch (notif.type) {
      case _NotifType.like:
        return Symbols.favorite;
      case _NotifType.comment:
        return Symbols.chat_bubble;
      case _NotifType.achievement:
        return Symbols.military_tech;
      case _NotifType.announcement:
        return Symbols.campaign;
      case _NotifType.milestone:
        return Symbols.emoji_events;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = notif.isUnread;

    return Container(
      decoration: BoxDecoration(
        color: isUnread
            ? AppTheme.primaryContainer.withOpacity(0.06)
            : AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border(
          left: BorderSide(
            color: isUnread
                ? AppTheme.primaryContainer
                : Colors.transparent,
            width: 3,
          ),
          top: BorderSide(color: Colors.white.withOpacity(0.07), width: 1),
          right: BorderSide(color: Colors.white.withOpacity(0.07), width: 1),
          bottom: BorderSide(color: Colors.white.withOpacity(0.07), width: 1),
        ),
        boxShadow: isUnread
            ? [
                BoxShadow(
                  color: AppTheme.primaryContainer.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(-2, 0),
                )
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.stackSm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon circle
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isUnread
                    ? AppTheme.primaryContainer.withOpacity(0.15)
                    : AppTheme.surfaceContainerHigh,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isUnread
                      ? AppTheme.primaryContainer.withOpacity(0.3)
                      : Colors.white.withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: isUnread
                    ? AppTheme.neonGlow(opacity: 0.2, blur: 12)
                    : null,
              ),
              child: Icon(
                _icon,
                size: 18,
                color: isUnread
                    ? AppTheme.primaryContainer
                    : AppTheme.onSurfaceVariant,
                fill: isUnread ? 1.0 : 0.0,
              ),
            ),
            const SizedBox(width: AppTheme.stackSm),

            // Text block
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notif.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.onSurface,
                          fontWeight: isUnread
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notif.body,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.onSurfaceVariant,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notif.timeAgo,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isUnread
                              ? AppTheme.primaryContainer.withOpacity(0.8)
                              : AppTheme.onSurfaceVariant.withOpacity(0.5),
                        ),
                  ),
                ],
              ),
            ),

            // Unread dot
            if (isUnread)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer,
                  shape: BoxShape.circle,
                  boxShadow: AppTheme.neonGlow(opacity: 0.5, blur: 6),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
