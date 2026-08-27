import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/services/auth_service.dart';
import '../../workouts/services/offline_workout_service.dart';
import '../../../core/sync/background_sync.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      extendBodyBehindAppBar: true,
      appBar: _ProfileAppBar(),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 80)),

          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.containerMargin,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppTheme.stackMd),

                // ── Hero header ──────────────────────────────────────
                const _ProfileHero(),

                const SizedBox(height: AppTheme.stackLg),

                // ── Stats bento ──────────────────────────────────────
                Text(
                  'YOUR STATS',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: AppTheme.stackSm),
                const _StatsBento(),

                const SizedBox(height: AppTheme.stackLg),

                // ── Settings list ────────────────────────────────────
                Text(
                  'SETTINGS',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: AppTheme.stackSm),
                _SettingsList(),

                const SizedBox(height: AppTheme.stackMd),

                // ── Log out ──────────────────────────────────────────
                _LogOutButton(ref: ref),

                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App bar
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileAppBar extends StatelessWidget implements PreferredSizeWidget {
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
              Text(
                'PROFILE',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppTheme.primaryContainer,
                      letterSpacing: 0.05 * 28,
                      shadows: [
                        Shadow(
                          color: AppTheme.primaryContainer.withOpacity(0.2),
                          blurRadius: 12,
                        ),
                      ],
                    ),
              ),
              const Spacer(),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.surfaceContainerHigh,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.1), width: 1),
                ),
                child: const Icon(Symbols.settings,
                    size: 18, color: AppTheme.onSurface),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile hero — large avatar with lime neon rim, name, gym chip
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileHero extends ConsumerWidget {
  const _ProfileHero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    // Show displayName if available, fall back to email, then generic label
    final displayName = user?.displayName?.isNotEmpty == true
        ? user!.displayName!
        : user?.email?.isNotEmpty == true
            ? user!.email!
            : 'Member';

    return GlassCard(
      padding: const EdgeInsets.all(AppTheme.stackMd),
      borderRadius: AppTheme.radiusXxl,
      child: Row(
        children: [
          // Avatar with neon rim
          _AvatarWithRim(),
          const SizedBox(width: AppTheme.stackMd),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Member role label
                Text(
                  user?.role.toUpperCase() == 'MEMBER'
                      ? 'GYM MEMBER'
                      : user?.role.toUpperCase() ?? 'GYM MEMBER',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 4),
                // Display name
                Text(
                  displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppTheme.stackSm),
                // Active chip
                MetricChip(label: 'ACTIVE', isSelected: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarWithRim extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Neon lime rim — the design spec calls for a subtle lime ring
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryContainer.withOpacity(0.6),
            AppTheme.primaryContainer.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: AppTheme.neonGlow(opacity: 0.2, blur: 16),
      ),
      child: Padding(
        // 2px "ring" gap
        padding: const EdgeInsets.all(2.5),
        child: Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceContainerHigh,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Symbols.person,
            size: 36,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats bento — 2x2 glass tiles
// ─────────────────────────────────────────────────────────────────────────────
class _StatsBento extends ConsumerStatefulWidget {
  const _StatsBento();

  @override
  ConsumerState<_StatsBento> createState() => _StatsBentoState();
}

class _StatsBentoState extends ConsumerState<_StatsBento> {
  int _workouts = 0;
  int _week = 0;
  int _setsWeek = 0;
  int _streak = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final svc = ref.read(offlineWorkoutServiceProvider);
    final results = await Future.wait([
      svc.getTotalWorkoutCount(),
      svc.getSessionCountThisWeek(),
      svc.getSetsCountThisWeek(),
      svc.getStreak(),
    ]);
    if (!mounted) return;
    setState(() {
      _workouts = results[0];
      _week = results[1];
      _setsWeek = results[2];
      _streak = results[3];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.primaryContainer,
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _BentoStatTile(
                  label: 'WORKOUTS',
                  value: '$_workouts',
                  icon: Symbols.fitness_center),
            ),
            const SizedBox(width: AppTheme.stackSm),
            Expanded(
              child: _BentoStatTile(
                  label: 'THIS WEEK',
                  value: '$_week',
                  icon: Symbols.calendar_today),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.stackSm),
        Row(
          children: [
            Expanded(
              child: _BentoStatTile(
                  label: 'SETS THIS WEEK',
                  value: '$_setsWeek',
                  icon: Symbols.bolt),
            ),
            const SizedBox(width: AppTheme.stackSm),
            Expanded(
              child: _BentoStatTile(
                  label: 'STREAK',
                  value: '$_streak',
                  icon: Symbols.local_fire_department),
            ),
          ],
        ),
      ],
    );
  }
}

class _BentoStatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _BentoStatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.stackSm),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border:
            Border.all(color: Colors.white.withOpacity(0.07), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Icon(icon, size: 16, color: AppTheme.primaryContainer),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontSize: 28,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Settings list — glass card with dividers between rows
// ─────────────────────────────────────────────────────────────────────────────
class _SettingsList extends StatelessWidget {
  static const List<_SettingsItem> _items = [
    _SettingsItem(
        icon: Symbols.person, label: 'Edit Profile', onTapKey: 'edit_profile'),
    _SettingsItem(
        icon: Symbols.notifications,
        label: 'Notifications',
        onTapKey: 'notifications'),
    _SettingsItem(
        icon: Symbols.security, label: 'Privacy & Security', onTapKey: 'privacy'),
    _SettingsItem(
        icon: Symbols.help, label: 'Help & Support', onTapKey: 'help'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
        border:
            Border.all(color: Colors.white.withOpacity(0.07), width: 1),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: List.generate(_items.length, (i) {
          final item = _items[i];
          return Column(
            children: [
              if (i > 0)
                Divider(
                  height: 1,
                  color: Colors.white.withOpacity(0.06),
                ),
              _SettingRow(item: item),
            ],
          );
        }),
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String label;
  final String onTapKey;
  const _SettingsItem(
      {required this.icon, required this.label, required this.onTapKey});
}

class _SettingRow extends StatelessWidget {
  final _SettingsItem item;
  const _SettingRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // TODO: route based on item.onTapKey
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.gutter,
          vertical: 16,
        ),
        child: Row(
          children: [
            Icon(item.icon, size: 20, color: AppTheme.onSurfaceVariant),
            const SizedBox(width: AppTheme.stackSm),
            Expanded(
              child: Text(
                item.label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.onSurface,
                    ),
              ),
            ),
            Icon(Symbols.chevron_right,
                size: 18, color: AppTheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Log Out button — secondary glass button, triggers styled dialog
// ─────────────────────────────────────────────────────────────────────────────
class _LogOutButton extends StatelessWidget {
  final WidgetRef ref;
  const _LogOutButton({required this.ref});

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppTheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
          side: BorderSide(color: Colors.white.withOpacity(0.07)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.stackMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.errorContainer.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppTheme.error.withOpacity(0.3), width: 1),
                ),
                child: const Icon(Symbols.logout,
                    size: 24, color: AppTheme.error),
              ),
              const SizedBox(height: AppTheme.stackSm),
              Text(
                'LOG OUT',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Are you sure you want to log out?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.stackMd),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Cancel',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: AppTheme.stackSm),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        Navigator.pop(context);
                        await cancelBackgroundSync();
                        await ref.read(authServiceProvider).signOut();
                        // Navigation handled by authStateStreamProvider in _AuthGate
                      },
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppTheme.errorContainer.withOpacity(0.3),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusFull),
                          border: Border.all(
                              color: AppTheme.error.withOpacity(0.4),
                              width: 1),
                        ),
                        child: Center(
                          child: Text(
                            'LOG OUT',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontSize: 14,
                                  color: AppTheme.error,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SecondaryButton(
      label: 'Log Out',
      icon: Symbols.logout,
      onPressed: () => _confirmLogout(context),
    );
  }
}
