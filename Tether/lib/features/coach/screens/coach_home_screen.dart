import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/providers/nav_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/screens/home_screen.dart';
import '../../notices/screens/notices_screen.dart';
import '../../workouts/screens/routines_screen.dart';
import 'certify_queue_screen.dart';

/// Home tab for coach/admin — shortcuts into staff workflows.
class CoachHomeScreen extends ConsumerWidget {
  const CoachHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final name = user?.displayName ?? 'Coach';
    final role = user?.role ?? 'coach';

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Text(
          'Coach home',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.containerMargin),
        children: [
          Text(
            'Hey $name',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(
            role.toLowerCase() == 'admin'
                ? 'Admin tools for your gym floor.'
                : 'Certify workouts, publish programs, and post notices.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppTheme.stackMd),
          _CoachTile(
            icon: Symbols.verified,
            title: 'Certify queue',
            subtitle: 'Review uncertified workout shares',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CertifyQueueScreen()),
            ),
          ),
          _CoachTile(
            icon: Symbols.fitness_center,
            title: 'My programs',
            subtitle: 'Build and publish gym programs',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RoutinesScreen()),
            ),
          ),
          _CoachTile(
            icon: Symbols.campaign,
            title: 'Notices',
            subtitle: 'Post announcements for members',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NoticesScreen()),
            ),
          ),
          _CoachTile(
            icon: Symbols.group,
            title: 'Feed',
            subtitle: 'Staff posts and member activity',
            onTap: () => ref.read(navIndexProvider.notifier).state = NavTab.feed,
          ),
          _CoachTile(
            icon: Symbols.home,
            title: 'Member home',
            subtitle: 'Open the member home view',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachTile extends StatelessWidget {
  const _CoachTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.primaryContainer),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(Symbols.chevron_right, color: AppTheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
