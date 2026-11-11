import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/navigation/main_navigation.dart';
import '../../../core/theme/tether_text.dart';
import '../../../core/theme/tether_tokens.dart';
import '../../../core/sync/background_sync.dart';
import '../../auth/services/auth_service.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../social/screens/buddies_screen.dart';
import 'edit_profile_screen.dart';

/// Settings screen redesign with foundry-style: dark header + cream sheet + wide cards
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: TetherTokens.ink,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // DARK HEADER
            _buildHeader(context),
            // CREAM SHEET
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: TetherTokens.cream,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
                  children: [
                    _buildGroup(
                      context,
                      'ACCOUNT',
                      [
                        _buildRow(
                          context,
                          Symbols.person,
                          'Edit Profile',
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EditProfileScreen(),
                            ),
                          ),
                        ),
                        _buildRow(
                          context,
                          Symbols.group,
                          'Gym Buddies',
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BuddiesScreen(),
                            ),
                          ),
                        ),
                        _buildRow(
                          context,
                          Symbols.notifications,
                          'Notifications',
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          ),
                        ),
                        _buildRow(
                          context,
                          Symbols.security,
                          'Privacy & Security',
                          () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                    'Privacy settings coming soon'),
                                backgroundColor: TetherTokens.ink,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildGroup(
                      context,
                      'SUPPORT',
                      [
                        _buildRow(
                          context,
                          Symbols.help,
                          'Help & Support',
                          () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    const Text('Support options coming soon'),
                                backgroundColor: TetherTokens.ink,
                              ),
                            );
                          },
                        ),
                        _buildRow(
                          context,
                          Symbols.info,
                          'About',
                          () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Tether v1.0.0'),
                                backgroundColor: TetherTokens.ink,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Log out button
                    GestureDetector(
                      onTap: () => _confirmLogout(context, ref),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.red.shade200,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Symbols.logout,
                              size: 20,
                              color: Colors.red.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'LOG OUT',
                              style: TetherText.sans(14, w: TetherTokens.w800)
                                  .copyWith(color: Colors.red.shade600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
            child: Text(
              'SETTINGS',
              style: TetherText.sans(18, w: TetherTokens.w800)
                  .copyWith(color: TetherTokens.cream),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroup(
      BuildContext context, String title, List<Widget> children) {
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
        Container(
          decoration: BoxDecoration(
            color: TetherTokens.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: TetherTokens.dayBorder.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    color: TetherTokens.dayBorder.withValues(alpha: 0.3),
                    indent: 56,
                  ),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRow(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: TetherTokens.sand,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 20,
                color: TetherTokens.defaultAccent,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TetherText.sans(15, w: TetherTokens.w600)
                    .copyWith(color: TetherTokens.ink),
              ),
            ),
            Icon(
              Symbols.chevron_right,
              size: 18,
              color: TetherTokens.nightMuted,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TetherTokens.cream,
        title: Text(
          'Log Out?',
          style: TetherText.sans(18, w: TetherTokens.w800)
              .copyWith(color: TetherTokens.ink),
        ),
        content: Text(
          "You'll need to sign in again to see your workouts and gym feed.",
          style: TetherText.sans(14, w: TetherTokens.w400)
              .copyWith(color: TetherTokens.nightMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'CANCEL',
              style: TetherText.sans(13, w: TetherTokens.w800)
                  .copyWith(color: TetherTokens.nightMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'LOG OUT',
              style: TetherText.sans(13, w: TetherTokens.w800)
                  .copyWith(color: Colors.red.shade600),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await cancelBackgroundSync();
    await ref.read(authServiceProvider).signOut();
  }
}
