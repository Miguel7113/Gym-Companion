import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart';
import 'otp_request_screen.dart';

class GymSelectionScreen extends ConsumerStatefulWidget {
  const GymSelectionScreen({super.key});

  @override
  ConsumerState<GymSelectionScreen> createState() => _GymSelectionScreenState();
}

class _GymSelectionScreenState extends ConsumerState<GymSelectionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          // ── Hero background: full-bleed dark gym image ───────────────────
          Positioned.fill(
            child: Image.network(
              // Moody high-contrast gym environment — placeholder until
              // real gym asset is fetched from backend branding config
              'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800&q=80',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppTheme.surfaceContainerLowest,
              ),
            ),
          ),

          // ── Dark gradient overlay ─────────────────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xB3121317), // 70% at top
                    Color(0xE6121317), // 90% mid
                    Color(0xFF000000), // 100% at bottom
                  ],
                  stops: [0.0, 0.4, 0.75],
                ),
              ),
            ),
          ),

          // ── Content ───────────────────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  const SizedBox(height: AppTheme.stackLg),

                  // Brand wordmark
                  Text(
                    'Tether',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: AppTheme.primaryContainer,
                          letterSpacing: -1.0,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: AppTheme.unit),
                  Text(
                    'Your gym, always within reach.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.onSurfaceVariant,
                        ),
                  ),

                  const SizedBox(height: AppTheme.stackLg),

                  // ── Glass panel ──────────────────────────────────────────
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.containerMargin,
                      ),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusXxl),
                        child: BackdropFilter(
                          filter:
                              ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.surface.withOpacity(0.7),
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusXxl),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.08),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    AppTheme.stackMd,
                                    AppTheme.stackMd,
                                    AppTheme.stackMd,
                                    AppTheme.stackSm,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Find your gym',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineLarge,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Select your gym to get started',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color:
                                                  AppTheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(),
                                Expanded(
                                  child: _GymList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppTheme.stackMd),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _GymList — separated so FutureBuilder doesn't rebuild the whole screen
// ─────────────────────────────────────────────────────────────────────────────
class _GymList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<Gym>>(
      future: ref.read(authServiceProvider).getGyms(),
      builder: (context, snapshot) {
        // ── Loading ────────────────────────────────────────────────────────
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryContainer),
                  ),
                ),
                const SizedBox(height: AppTheme.stackSm),
                Text(
                  'LOADING GYMS...',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          );
        }

        // ── Error ─────────────────────────────────────────────────────────
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.stackMd),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Symbols.wifi_off,
                    size: 40,
                    color: AppTheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                  const SizedBox(height: AppTheme.stackSm),
                  Text(
                    'COULD NOT LOAD GYMS',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Check your connection and try again',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.stackMd),
                  MetricChip(
                    label: 'Retry',
                    icon: Symbols.refresh,
                    onTap: () {
                      // Riverpod FutureBuilder retry: pop and push
                      (context as Element).markNeedsBuild();
                    },
                  ),
                ],
              ),
            ),
          );
        }

        // ── Empty ─────────────────────────────────────────────────────────
        final gyms = snapshot.data ?? [];
        if (gyms.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.stackMd),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Symbols.fitness_center,
                    size: 40,
                    color: AppTheme.onSurfaceVariant.withOpacity(0.4),
                  ),
                  const SizedBox(height: AppTheme.stackSm),
                  Text(
                    'NO GYMS AVAILABLE',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Contact your gym administrator to get set up',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        // ── Gym list ──────────────────────────────────────────────────────
        return ListView.separated(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.gutter,
            vertical: AppTheme.stackSm,
          ),
          itemCount: gyms.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: AppTheme.stackSm),
          itemBuilder: (context, index) {
            final gym = gyms[index];
            return _GymTile(gym: gym);
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _GymTile — individual gym row with avatar, name, subtle chevron
// ─────────────────────────────────────────────────────────────────────────────
class _GymTile extends StatefulWidget {
  final Gym gym;
  const _GymTile({required this.gym});

  @override
  State<_GymTile> createState() => _GymTileState();
}

class _GymTileState extends State<_GymTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final gym = widget.gym;

    // Parse optional hex color from gym branding
    Color accentColor = AppTheme.primaryContainer;
    if (gym.primaryColor != null) {
      try {
        accentColor = Color(
          int.parse(gym.primaryColor!.replaceFirst('#', '0xFF')),
        );
      } catch (_) {}
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpRequestScreen(gym: gym),
          ),
        );
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.gutter,
            vertical: AppTheme.stackSm,
          ),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            border: Border.all(
              color: Colors.white.withOpacity(0.07),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Gym avatar
              _GymAvatar(gym: gym, accentColor: accentColor),
              const SizedBox(width: AppTheme.stackSm),

              // Name + email
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gym.name,
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.onSurface,
                              ),
                    ),
                    if (gym.contactEmail != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        gym.contactEmail!,
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppTheme.onSurfaceVariant,
                                ),
                      ),
                    ],
                  ],
                ),
              ),

              // Chevron
              Icon(
                Symbols.chevron_right,
                size: 20,
                color: AppTheme.onSurfaceVariant.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GymAvatar extends StatelessWidget {
  final Gym gym;
  final Color accentColor;

  const _GymAvatar({required this.gym, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
      ),
      child: ClipOval(
        child: gym.logoUrl != null
            ? Image.network(
                gym.logoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initials(context),
              )
            : _initials(context),
      ),
    );
  }

  Widget _initials(BuildContext context) {
    return Center(
      child: Text(
        gym.name.isNotEmpty ? gym.name[0].toUpperCase() : 'G',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: accentColor,
              fontSize: 18,
            ),
      ),
    );
  }
}
