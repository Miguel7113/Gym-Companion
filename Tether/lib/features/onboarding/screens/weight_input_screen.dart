import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_progress_indicator.dart';

class WeightInputScreen extends ConsumerStatefulWidget {
  const WeightInputScreen({super.key});

  @override
  ConsumerState<WeightInputScreen> createState() => _WeightInputScreenState();
}

class _WeightInputScreenState extends ConsumerState<WeightInputScreen> {
  final _weightController = TextEditingController();
  final _focusNode = FocusNode();
  String _unit = 'kg'; // 'kg' or 'lb'
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Pre-fill with existing data if returning to this step
    final currentData = ref.read(onboardingProvider);
    final weight = currentData.bodyWeightKg;
    if (weight != null && weight > 0) {
      _weightController.text = weight.toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  double? _parseWeight() {
    final text = _weightController.text.trim();
    if (text.isEmpty) return null;
    
    final value = double.tryParse(text);
    if (value == null) return null;
    
    // Convert to kg if in pounds
    if (_unit == 'lb') {
      return value * 0.453592;
    }
    return value;
  }

  void _validateAndContinue() {
    final weightKg = _parseWeight();
    
    if (weightKg != null) {
      // Validate reasonable range
      if (weightKg < 30 || weightKg > 300) {
        setState(() => _errorMessage = 'Please enter a realistic weight');
        return;
      }
    }
    
    // Save to provider (null is OK, field is optional)
    ref.read(onboardingProvider.notifier).setBodyWeight(weightKg);
    ref.read(onboardingProvider.notifier).nextStep();
  }

  void _skip() {
    // Save null weight and continue
    ref.read(onboardingProvider.notifier).setBodyWeight(null);
    ref.read(onboardingProvider.notifier).nextStep();
  }

  void _onTextChanged(String value) {
    setState(() {
      if (_errorMessage != null) {
        _errorMessage = null;
      }
    });
  }

  void _switchUnit(String newUnit) {
    if (_unit == newUnit) return;
    
    final currentWeight = double.tryParse(_weightController.text.trim());
    if (currentWeight != null) {
      double converted;
      if (newUnit == 'lb') {
        // kg to lb
        converted = currentWeight * 2.20462;
      } else {
        // lb to kg
        converted = currentWeight * 0.453592;
      }
      _weightController.text = converted.toStringAsFixed(1);
    }
    
    setState(() => _unit = newUnit);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasText = _weightController.text.trim().isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              const SizedBox(height: 40),
              
              // Progress Indicator
              const OnboardingProgressIndicator(
                currentStep: 3,
                totalSteps: 5,
              ),
              
              const SizedBox(height: 48),
              
              // Title
              Text(
                'What\'s your body weight?',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Subtitle
              Text(
                'We use this to calculate your Wilks score and provide accurate strength comparisons across weight classes',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Weight Input Field with Unit Selector
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Weight Input
                  Expanded(
                    child: TextField(
                      controller: _weightController,
                      focusNode: _focusNode,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                      ],
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter weight',
                        hintStyle: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                          fontWeight: FontWeight.w600,
                        ),
                        errorText: _errorMessage,
                        errorStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.error,
                            width: 2,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.error,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 20,
                        ),
                        suffixIcon: hasText
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                                onPressed: () {
                                  _weightController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                      ),
                      onChanged: _onTextChanged,
                      onSubmitted: (_) => _validateAndContinue(),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Unit Selector
                  Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _UnitButton(
                          label: 'kg',
                          isSelected: _unit == 'kg',
                          onTap: () => _switchUnit('kg'),
                        ),
                        _UnitButton(
                          label: 'lb',
                          isSelected: _unit == 'lb',
                          onTap: () => _switchUnit('lb'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Helper Text
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This is optional. You can add or update it later in your profile',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
              
              const Spacer(),
              
              // Navigation Buttons
              Row(
                children: [
                  // Back Button
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      onPressed: () {
                        ref.read(onboardingProvider.notifier).previousStep();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      child: const Text(
                        'Back',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Skip Button (if no input)
                  if (!hasText)
                    Expanded(
                      flex: 3,
                      child: OutlinedButton(
                        onPressed: _skip,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        child: Text(
                          'Skip for now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  
                  // Continue Button (if has input)
                  if (hasText)
                    Expanded(
                      flex: 3,
                      child: FilledButton(
                        onPressed: _validateAndContinue,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UnitButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _UnitButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}
