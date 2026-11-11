import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/onboarding_data.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/providers/api_provider.dart';

/// Key for storing onboarding completion in SharedPreferences
const String _onboardingCompleteKey = 'onboarding_complete';

/// Provider that manages onboarding state
final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingData>((ref) {
  return OnboardingNotifier(ref);
});

class OnboardingNotifier extends StateNotifier<OnboardingData> {
  final Ref _ref;

  OnboardingNotifier(this._ref) : super(const OnboardingData()) {
    _loadCompletionStatus();
  }

  /// Load onboarding completion status from storage
  Future<void> _loadCompletionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isComplete = prefs.getBool(_onboardingCompleteKey) ?? false;
    if (isComplete) {
      state = state.copyWith(isComplete: true);
    }
  }

  /// Update display name
  void setDisplayName(String name) {
    state = state.copyWith(displayName: name.trim());
  }

  /// Update gender
  void setGender(String? gender) {
    state = state.copyWith(gender: gender);
  }

  /// Update body weight (optional)
  void setBodyWeight(double? weight) {
    state = state.copyWith(bodyWeightKg: weight);
  }

  /// Move to next step
  void nextStep() {
    if (state.currentStep < 5 && state.canProceed(state.currentStep)) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  /// Move to previous step
  void previousStep() {
    if (state.currentStep > 1) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  /// Skip to specific step
  void goToStep(int step) {
    if (step >= 1 && step <= 5) {
      state = state.copyWith(currentStep: step);
    }
  }

  /// Complete onboarding and save to backend
  Future<bool> completeOnboarding() async {
    if (!state.hasRequiredFields) {
      return false;
    }

    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) return false;

      // Save to backend
      final apiClient = _ref.read(apiClientProvider);
      await apiClient.patch('/members/profile', data: {
        'displayName': state.displayName,
        'gender': state.gender,
        if (state.bodyWeightKg != null) 'bodyWeightKg': state.bodyWeightKg,
      });

      // Mark as complete in local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCompleteKey, true);

      state = state.copyWith(isComplete: true);
      return true;
    } catch (e) {
      // Log error but don't crash
      print('[OnboardingNotifier] Failed to complete onboarding: $e');
      return false;
    }
  }

  /// Skip onboarding (mark as complete without saving data)
  Future<void> skipOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompleteKey, true);
    state = state.copyWith(isComplete: true);
  }

  /// Reset onboarding (for testing or re-onboarding)
  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_onboardingCompleteKey);
    state = const OnboardingData();
  }
}

/// Provider to check if user needs onboarding
final needsOnboardingProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  final onboarding = ref.watch(onboardingProvider);

  // No user = no onboarding needed (show login)
  if (user == null) return false;

  // User exists but onboarding not complete
  return !onboarding.isComplete;
});
