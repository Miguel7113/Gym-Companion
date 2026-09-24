import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/sync/background_sync.dart';
import '../../auth/services/auth_service.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../social/screens/buddies_screen.dart';

/// Settings lives under Profile (not a bottom tab).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Settings',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.containerMargin,
          8,
          AppTheme.containerMargin,
          40,
        ),
        children: [
          _SettingsGroup(
            title: 'Account',
            children: [
              _SettingsRow(
                icon: Symbols.person,
                label: 'Edit profile',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile editing is coming soon'),
                    ),
                  );
                },
              ),
              _SettingsRow(
                icon: Symbols.group,
                label: 'Gym buddies',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BuddiesScreen(),
                  ),
                ),
              ),
              _SettingsRow(
                icon: Symbols.notifications,
                label: 'Notifications',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                ),
              ),
              _SettingsRow(
                icon: Symbols.security,
                label: 'Privacy & security',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Privacy settings are coming soon'),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppTheme.stackMd),
          _SettingsGroup(
            title: 'Support',
            children: [
              _SettingsRow(
                icon: Symbols.help,
                label: 'Help & support',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Support options are coming soon'),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppTheme.stackLg),
          SecondaryButton(
            label: 'Log out',
            icon: Symbols.logout,
            onPressed: () => _confirmLogout(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAppConfirmDialog(
      context,
      icon: Symbols.logout,
      tone: AppDialogTone.danger,
      title: 'Log out?',
      message: "You'll need to sign in again to see your workouts and gym feed.",
      confirmLabel: 'Log out',
    );
    if (!confirmed) return;
    await cancelBackgroundSync();
    await ref.read(authServiceProvider).signOut();
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainer,
            borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
            boxShadow: AppTheme.cardElevation,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Divider(height: 1, color: Colors.white.withOpacity(0.06)),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: Icon(icon, size: 18, color: AppTheme.onSurfaceVariant),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const Icon(
              Symbols.chevron_right,
              size: 18,
              color: AppTheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
