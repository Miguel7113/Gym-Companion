/// User data collected during onboarding flow
class OnboardingData {
  final String displayName;
  final String? gender; // 'male' | 'female' | 'other'
  final double? bodyWeightKg;
  final int currentStep; // 1-5
  final bool isComplete;

  const OnboardingData({
    this.displayName = '',
    this.gender,
    this.bodyWeightKg,
    this.currentStep = 1,
    this.isComplete = false,
  });

  OnboardingData copyWith({
    String? displayName,
    String? gender,
    double? bodyWeightKg,
    int? currentStep,
    bool? isComplete,
  }) {
    return OnboardingData(
      displayName: displayName ?? this.displayName,
      gender: gender ?? this.gender,
      bodyWeightKg: bodyWeightKg ?? this.bodyWeightKg,
      currentStep: currentStep ?? this.currentStep,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'gender': gender,
        'bodyWeightKg': bodyWeightKg,
        'currentStep': currentStep,
        'isComplete': isComplete,
      };

  factory OnboardingData.fromJson(Map<String, dynamic> json) => OnboardingData(
        displayName: json['displayName'] as String? ?? '',
        gender: json['gender'] as String?,
        bodyWeightKg: (json['bodyWeightKg'] as num?)?.toDouble(),
        currentStep: json['currentStep'] as int? ?? 1,
        isComplete: json['isComplete'] as bool? ?? false,
      );
}

/// Extension for validation
extension OnboardingDataValidation on OnboardingData {
  /// Check if current step data is valid
  bool isStepValid(int step) {
    switch (step) {
      case 1: // Welcome screen - no validation
        return true;
      case 2: // Name input
        return displayName.trim().length >= 2;
      case 3: // Gender selection (required for leaderboards)
        return gender != null && gender!.isNotEmpty;
      case 4: // Weight input (optional)
        return true; // Always valid since optional
      case 5: // Feature tour - no validation
        return true;
      default:
        return false;
    }
  }

  /// Check if can proceed to next step
  bool canProceed(int step) => isStepValid(step);

  /// Get progress percentage (0.0 to 1.0)
  double get progress => currentStep / 5.0;

  /// Check if all required fields are filled
  bool get hasRequiredFields =>
      displayName.trim().length >= 2 && gender != null;
}
