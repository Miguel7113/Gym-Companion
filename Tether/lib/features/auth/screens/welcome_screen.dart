import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/media_catalog.dart';
import '../../../core/widgets/tether_logo.dart';
import '../models/auth_models.dart';
import '../providers/gym_choice_provider.dart';
import '../widgets/auth_widgets.dart';
import 'gym_picker_screen.dart';
import 'sign_in_screen.dart';

/// First screen for signed-out users: brand, one promise and one way in.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  Future<void> _continueWith(BuildContext context, WidgetRef ref, Gym gym) async {
    HapticFeedback.lightImpact();
    await rememberGym(ref, gym);
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SignInScreen(gym: gym)),
    );
  }

  void _pickGym(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GymPickerScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastGym = ref.watch(lastGymProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              AppMedia.authHero,
              fit: BoxFit.cover,
              alignment: const Alignment(0.1, -0.3),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xB3000000),
                    Color(0x1A000000),
                    Color(0xD9000000),
                    AppTheme.surface,
                  ],
                  stops: [0.0, 0.28, 0.62, 0.86],
                ),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: _content(context, ref, lastGym),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context, WidgetRef ref, Gym? lastGym) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.containerMargin,
        AppTheme.stackSm,
        AppTheme.containerMargin,
        AppTheme.gutter,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: TetherLogo(size: 26),
          ),
          const Spacer(),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Train with\n'),
                TextSpan(
                  text: 'your gym.',
                  style: TextStyle(
                    color: AppTheme.primaryContainer,
                    shadows: AppTheme.neonGlow(opacity: 0.35, blur: 24),
                  ),
                ),
              ],
            ),
            style: text.displayLarge?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 52,
              height: 1.0,
              letterSpacing: -2,
            ),
          ),
          const SizedBox(height: AppTheme.gutter),
          Text(
            'Log every session, follow your gym\'s feed and keep '
            'your training buddies close.',
            style: text.bodyLarge?.copyWith(
              color: AppTheme.onSurface.withValues(alpha: 0.75),
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppTheme.stackLg),
          if (lastGym != null) ...[
            _ContinueButton(
              gym: lastGym,
              onTap: () => _continueWith(context, ref, lastGym),
            ),
            const SizedBox(height: 4),
            AuthTextButton(
              label: 'Choose a different gym',
              onPressed: () => _pickGym(context),
            ),
          ] else ...[
            AuthPrimaryButton(
              label: 'Find your gym',
              icon: Symbols.search,
              onPressed: () => _pickGym(context),
            ),
            const SizedBox(height: AppTheme.stackSm),
            Text(
              'Your gym adds you to Tether. Sign in with the email or '
              'phone number they have on file.',
              textAlign: TextAlign.center,
              style: text.bodySmall?.copyWith(
                color: AppTheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Primary button that already knows the member's gym.
class _ContinueButton extends StatelessWidget {
  final Gym gym;
  final VoidCallback onTap;

  const _ContinueButton({required this.gym, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: AppTheme.primaryContainer,
      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        child: Container(
          height: 64,
          padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            boxShadow: AppTheme.neonGlow(opacity: 0.3, blur: 20),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: AppTheme.surface,
                  shape: BoxShape.circle,
                ),
                child: GymAvatar(gym: gym, size: 44),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Continue to',
                      style: text.labelMedium?.copyWith(
                        color: AppTheme.onPrimaryFixed.withValues(alpha: 0.7),
                        letterSpacing: 0,
                      ),
                    ),
                    Text(
                      gym.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleMedium?.copyWith(
                        color: AppTheme.onPrimaryFixed,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Symbols.arrow_forward,
                size: 22,
                color: AppTheme.onPrimaryFixed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
