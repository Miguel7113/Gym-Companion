import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Notice model — local for now, will be wired to backend posts endpoint
// when staff announcement flow is complete.
// ─────────────────────────────────────────────────────────────────────────────
class Notice {
  final String id;
  final String tag; // 'ANNOUNCEMENT' | 'CLASS UPDATE' | 'REMINDER' | 'EVENT'
  final IconData icon;
  final String title;
  final String body;
  final String? imageUrl;
  final String timeAgo;
  final bool isHighlighted;

  const Notice({
    required this.id,
    required this.tag,
    required this.icon,
    required this.title,
    required this.body,
    this.imageUrl,
    required this.timeAgo,
    this.isHighlighted = false,
  });
}

// Hardcoded placeholder notices — replaced with real API call once
// the gym staff posting flow is built on the dashboard.
final List<Notice> _placeholderNotices = [
  Notice(
    id: '1',
    tag: 'ANNOUNCEMENT',
    icon: Symbols.campaign,
    title: 'New Squat Racks Installed',
    body:
        'Level 2 free weights area now features 6 additional squat racks with safety bars and plate storage. The area has been reorganised for better flow and safety. Come check it out — available from 6AM daily.',
    imageUrl:
        'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=800&q=80',
    timeAgo: '2 HOURS AGO',
    isHighlighted: true,
  ),
  Notice(
    id: '2',
    tag: 'CLASS UPDATE',
    icon: Symbols.schedule,
    title: 'HIIT 45 Moving to Studio B',
    body:
        'Starting tomorrow, the HIIT 45 class will be held in Studio B instead of Studio A. Please arrive 5 minutes early for setup. All other class details remain the same.',
    timeAgo: '5 HOURS AGO',
  ),
  Notice(
    id: '3',
    tag: 'REMINDER',
    icon: Symbols.notifications_active,
    title: 'Gym Closes at 8PM Sunday',
    body:
        'Public holiday hours apply this weekend. The gym will close at 8PM on Sunday instead of the usual 10PM. All classes scheduled after 7PM are cancelled. Normal hours resume Monday.',
    timeAgo: 'YESTERDAY',
  ),
  Notice(
    id: '4',
    tag: 'EVENT',
    icon: Symbols.emoji_events,
    title: 'Member Fitness Challenge — August',
    body:
        'Our monthly fitness challenge kicks off August 1st. This month: most consecutive workout days. Top 3 members win a free month membership. Sign up at the front desk or via the app.',
    imageUrl:
        'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=800&q=80',
    timeAgo: '2 DAYS AGO',
  ),
  Notice(
    id: '5',
    tag: 'ANNOUNCEMENT',
    icon: Symbols.campaign,
    title: 'New Changing Room Lockers',
    body:
        'We have upgraded all changing room lockers to digital keypad locks. Your 4-digit code is your membership number. Please see staff if you need assistance setting up your locker.',
    timeAgo: '3 DAYS AGO',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// NoticesScreen — full list of gym notices
// ─────────────────────────────────────────────────────────────────────────────
class NoticesScreen extends StatelessWidget {
  const NoticesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: const Icon(Symbols.arrow_back, size: 18),
          ),
        ),
        title: Text('GYM NOTICES',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppTheme.primaryContainer,
            letterSpacing: 1,
          )),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
            AppTheme.containerMargin, AppTheme.stackSm,
            AppTheme.containerMargin, 100),
        itemCount: _placeholderNotices.length,
        separatorBuilder: (_, __) =>
            const SizedBox(height: AppTheme.stackSm),
        itemBuilder: (_, i) => _NoticeCard(
          notice: _placeholderNotices[i],
          onTap: () => _openDetail(context, _placeholderNotices[i]),
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, Notice notice) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NoticeDetailScreen(notice: notice)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notice card — compact list item
// ─────────────────────────────────────────────────────────────────────────────
class _NoticeCard extends StatelessWidget {
  final Notice notice;
  final VoidCallback onTap;
  const _NoticeCard({required this.notice, required this.onTap});

  Color get _tagColor {
    switch (notice.tag) {
      case 'ANNOUNCEMENT': return AppTheme.primaryContainer;
      case 'CLASS UPDATE': return const Color(0xFF2196F3);
      case 'REMINDER': return const Color(0xFFFF9800);
      case 'EVENT': return const Color(0xFF9C27B0);
      default: return AppTheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
          border: Border.all(
            color: notice.isHighlighted
                ? AppTheme.primaryContainer.withOpacity(0.25)
                : Colors.white.withOpacity(0.07),
          ),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo (only when imageUrl set)
            if (notice.imageUrl != null)
              SizedBox(
                height: 120,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(notice.imageUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                            color: AppTheme.surfaceContainerHigh)),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.6),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Content
            Padding(
              padding: const EdgeInsets.all(AppTheme.stackSm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tag + time
                  Row(
                    children: [
                      Icon(notice.icon, size: 12, color: _tagColor),
                      const SizedBox(width: 5),
                      Text(notice.tag,
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: _tagColor, fontSize: 10)),
                      const Spacer(),
                      Text(notice.timeAgo,
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: AppTheme.onSurfaceVariant,
                                fontSize: 9)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Title
                  Text(notice.title,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  // Body preview
                  Text(notice.body,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppTheme.onSurfaceVariant),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  // Read more
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('READ MORE',
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: AppTheme.primaryContainer,
                                fontSize: 10)),
                      const SizedBox(width: 3),
                      const Icon(Symbols.arrow_forward, size: 11,
                          color: AppTheme.primaryContainer),
                    ],
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

// ─────────────────────────────────────────────────────────────────────────────
// NoticeDetailScreen — full notice with photo and complete body text
// ─────────────────────────────────────────────────────────────────────────────
class NoticeDetailScreen extends StatelessWidget {
  final Notice notice;
  const NoticeDetailScreen({super.key, required this.notice});

  Color get _tagColor {
    switch (notice.tag) {
      case 'ANNOUNCEMENT': return AppTheme.primaryContainer;
      case 'CLASS UPDATE': return const Color(0xFF2196F3);
      case 'REMINDER': return const Color(0xFFFF9800);
      case 'EVENT': return const Color(0xFF9C27B0);
      default: return AppTheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          // ── Hero ────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: notice.imageUrl != null ? 260 : 0,
            pinned: true,
            backgroundColor: AppTheme.surface,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: const Icon(Symbols.arrow_back,
                    color: Colors.white, size: 20),
              ),
            ),
            flexibleSpace: notice.imageUrl != null
                ? FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(notice.imageUrl!, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                                color: AppTheme.surfaceContainerHigh)),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  AppTheme.surface.withOpacity(0.95),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
          ),

          // ── Content ──────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                AppTheme.containerMargin, AppTheme.stackMd,
                AppTheme.containerMargin, 80),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Tag badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _tagColor.withOpacity(0.12),
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusFull),
                    border: Border.all(color: _tagColor.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(notice.icon, size: 12, color: _tagColor),
                      const SizedBox(width: 5),
                      Text(notice.tag,
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: _tagColor)),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.stackSm),

                // Title
                Text(notice.title,
                  style: Theme.of(context).textTheme.headlineLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),

                // Time
                Text(notice.timeAgo,
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: AppTheme.onSurfaceVariant)),
                const SizedBox(height: AppTheme.stackMd),

                // Divider
                Divider(color: Colors.white.withOpacity(0.08)),
                const SizedBox(height: AppTheme.stackMd),

                // Full body
                Text(notice.body,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.7,
                    color: AppTheme.onSurface,
                  )),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
