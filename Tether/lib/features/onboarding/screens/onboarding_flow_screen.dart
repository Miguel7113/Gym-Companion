import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/onboarding_provider.dart';
import 'welcome_screen.dart';
import 'name_input_screen.dart';
import 'gender_selection_screen.dart';
import 'weight_input_screen.dart';
import 'feature_tour_screen.dart';

class OnboardingFlowScreen extends ConsumerWidget {
  const OnboardingFlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStep = ref.watch(onboardingProvider.select((state) => state.currentStep));

    return PopScope(
      canPop: currentStep == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && currentStep > 0) {
          ref.read(onboardingProvider.notifier).previousStep();
        }
      },
      child: Scaffold(
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.1, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: _buildCurrentStep(currentStep),
        ),
      ),
    );
  }

  Widget _buildCurrentStep(int step) {
    switch (step) {
      case 0:
        return const WelcomeScreen(key: ValueKey(0));
      case 1:
        return const NameInputScreen(key: ValueKey(1));
      case 2:
        return const GenderSelectionScreen(key: ValueKey(2));
      case 3:
        return const WeightInputScreen(key: ValueKey(3));
      case 4:
        return const FeatureTourScreen(key: ValueKey(4));
      default:
        return const WelcomeScreen(key: ValueKey(0));
    }
  }
}
