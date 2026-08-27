import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../theme/app_theme.dart';
import '../sync/connectivity_provider.dart';
import '../sync/sync_service.dart';
import '../sync/background_sync.dart';
import '../providers/nav_provider.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/workouts/screens/workouts_screen.dart';
import '../../features/social/screens/social_screen.dart';
import '../../features/profile/screens/profile_screen.dart';

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  static const List<_NavItem> _navItems = [
    _NavItem(label: 'HOME',    icon: Symbols.home,           activeFill: true),
    _NavItem(label: 'TRAIN',   icon: Symbols.fitness_center, activeFill: true),
    _NavItem(label: 'FEED',    icon: Symbols.group,          activeFill: true),
    _NavItem(label: 'PROFILE', icon: Symbols.person,         activeFill: true),
  ];

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  static const List<Widget> _screens = [
    HomeScreen(),
    WorkoutsScreen(),
    SocialScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      registerBackgroundSync();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<bool>>(connectivityProvider, (prev, next) {
      final wasOnline = prev?.valueOrNull ?? false;
      final isOnline = next.valueOrNull ?? false;
      if (!wasOnline && isOnline) {
        ref.read(syncServiceProvider).syncPendingSessions();
      }
    });

    final currentIndex = ref.watch(navIndexProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      extendBody: true,
      body: IndexedStack(
        index: currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          left: AppTheme.gutter,
          right: AppTheme.gutter,
          bottom: bottomPadding > 0 ? bottomPadding : AppTheme.gutter,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHigh.withOpacity(0.85),
                borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
                border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryContainer.withOpacity(0.04),
                    blurRadius: 24,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: List.generate(
                  MainNavigation._navItems.length,
                  (i) => Expanded(
                    child: _NavButton(
                      item: MainNavigation._navItems[i],
                      isActive: currentIndex == i,
                      onTap: () => ref.read(navIndexProvider.notifier).state = i,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final bool activeFill;
  const _NavItem({required this.label, required this.icon, this.activeFill = false});
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavButton({required this.item, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final iconColor = isActive ? AppTheme.primaryContainer : AppTheme.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              decoration: isActive
                  ? BoxDecoration(boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryContainer.withOpacity(0.18),
                        blurRadius: 12,
                      ),
                    ])
                  : null,
              child: Icon(item.icon, size: 22, color: iconColor,
                  fill: isActive ? 1.0 : 0.0),
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.08,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isActive ? 4 : 0,
              height: isActive ? 4 : 0,
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                shape: BoxShape.circle,
                boxShadow: isActive
                    ? [BoxShadow(
                        color: AppTheme.primaryContainer.withOpacity(0.6),
                        blurRadius: 4,
                      )]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
