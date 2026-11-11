import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_progress_indicator.dart';

class FeatureTourScreen extends ConsumerStatefulWidget {
  const FeatureTourScreen({super.key});

  @override
  ConsumerState<FeatureTourScreen> createState() => _FeatureTourScreenState();
}

class _FeatureTourScreenState extends ConsumerState<FeatureTourScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  bool _isFinishing = false;

  final List<_TourSlide> _slides = const [
    _TourSlide(
      icon: Icons.fitness_center,
      title: 'Track Your Workouts',
      description: 'Log exercises, sets, and reps with our easy-to-use workout tracker. See your progress over time.',
      color: Color(0xFF6366F1), // Indigo
    ),
    _TourSlide(
      icon: Icons.emoji_events,
      title: 'Log Personal Records',
      description: 'Submit your best lifts for verification. Celebrate your achievements and watch them get certified by coaches.',
      color: Color(0xFFEC4899), // Pink
    ),
    _TourSlide(
      icon: Icons.leaderboard,
      title: 'Compete on Leaderboards',
      description: 'See how you rank against other members. Filter by gender, view top performers, and aim for the podium.',
      color: Color(0xFF8B5CF6), // Purple
    ),
    _TourSlide(
      icon: Icons.people,
      title: 'Connect with Your Community',
      description: 'Share your progress, support others, and stay motivated. Your gym community is here for you.',
      color: Color(0xFF10B981), // Green
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.animateToPage(
        _currentPage - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finish() async {
    if (_isFinishing) return; // Prevent double-tap
    
    setState(() => _isFinishing = true);
    
    try {
      // Mark onboarding as complete (will save data if available)
      final success = await ref.read(onboardingProvider.notifier).completeOnboarding();
      
      if (!mounted) return;
      
      // Navigate regardless of API success (data can be synced later)
      // The app will check isComplete flag and show main nav
      if (!success) {
        // If API fails, just mark as complete locally
        await ref.read(onboardingProvider.notifier).skipOnboarding();
      }
    } finally {
      if (mounted) {
        setState(() => _isFinishing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLastSlide = _currentPage == _slides.length - 1;
    final isFirstSlide = _currentPage == 0;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Section - Progress and Skip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
              child: Row(
                children: [
                  // Progress Indicator
                  const Expanded(
                    child: OnboardingProgressIndicator(
                      currentStep: 4,
                      totalSteps: 5,
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Skip Button
                  TextButton(
                    onPressed: _finish,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Carousel
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  return _buildSlide(_slides[index]);
                },
              ),
            ),
            
            // Dots Indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) => _buildDot(index == _currentPage, theme),
                ),
              ),
            ),
            
            // Navigation Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  // Back Button (only show if not first slide)
                  if (!isFirstSlide)
                    Expanded(
                      flex: 2,
                      child: OutlinedButton(
                        onPressed: _previousPage,
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
                  
                  if (!isFirstSlide) const SizedBox(width: 12),
                  
                  // Next/Get Started Button
                  Expanded(
                    flex: isFirstSlide ? 1 : 3,
                    child: FilledButton(
                      onPressed: _isFinishing ? null : _nextPage,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isFinishing && isLastSlide
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : Text(
                              isLastSlide ? 'Get Started' : 'Next',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(_TourSlide slide) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon Container
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: slide.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              slide.icon,
              size: 64,
              color: slide.color,
            ),
          ),
          
          const SizedBox(height: 48),
          
          // Title
          Text(
            slide.title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // Description
          Text(
            slide.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildDot(bool isActive, ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _TourSlide {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _TourSlide({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
