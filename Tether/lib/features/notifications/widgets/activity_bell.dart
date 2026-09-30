import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_theme.dart';
import '../../social/services/social_extras_service.dart';
import '../screens/notifications_screen.dart';

/// Opens Activity. The dot is shown only while something is unread.
class ActivityBell extends ConsumerWidget {
  const ActivityBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationCountProvider).valueOrNull ?? 0;

    return IconButton(
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        );
        ref.invalidate(unreadNotificationCountProvider);
      },
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(
            Symbols.notifications,
            size: 24,
            color: AppTheme.onSurface,
          ),
          if (unread > 0)
            Positioned(
              top: -1,
              right: -1,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer,
                  shape: BoxShape.circle,
                  boxShadow: AppTheme.neonGlow(opacity: 0.45, blur: 6),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
