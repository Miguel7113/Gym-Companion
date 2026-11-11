import 'package:flutter/material.dart';
import '../../../core/theme/tether_tokens.dart';

/// Skeleton loading placeholder for PR verification cards
/// Shows while data is being fetched
class PRCardSkeleton extends StatefulWidget {
  const PRCardSkeleton({super.key});

  @override
  State<PRCardSkeleton> createState() => _PRCardSkeletonState();
}

class _PRCardSkeletonState extends State<PRCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: TetherTokens.nightCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: TetherTokens.cream.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Header Row
              Row(
                children: [
                  // Avatar skeleton
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: TetherTokens.cream.withValues(alpha: _animation.value * 0.15),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name skeleton
                        Container(
                          width: 120,
                          height: 16,
                          decoration: BoxDecoration(
                            color: TetherTokens.cream.withValues(alpha: _animation.value * 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Exercise skeleton
                        Container(
                          width: 80,
                          height: 12,
                          decoration: BoxDecoration(
                            color: TetherTokens.cream.withValues(alpha: _animation.value * 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Expand button skeleton
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: TetherTokens.cream.withValues(alpha: _animation.value * 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Stats Row
              Row(
                children: List.generate(3, (index) {
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(left: index > 0 ? 12 : 0),
                      height: 80,
                      decoration: BoxDecoration(
                        color: TetherTokens.cream.withValues(alpha: _animation.value * 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: TetherTokens.cream.withValues(alpha: 0.05),
                          width: 1,
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: TetherTokens.cream.withValues(alpha: _animation.value * 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: TetherTokens.cream.withValues(alpha: _animation.value * 0.2),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Simplified skeleton for list view
class PRCardSkeletonSimple extends StatelessWidget {
  const PRCardSkeletonSimple({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TetherTokens.nightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: TetherTokens.cream.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: TetherTokens.cream.withValues(alpha: 0.1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 16,
                      decoration: BoxDecoration(
                        color: TetherTokens.cream.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 80,
                      height: 12,
                      decoration: BoxDecoration(
                        color: TetherTokens.cream.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(3, (index) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(left: index > 0 ? 12 : 0),
                  height: 60,
                  decoration: BoxDecoration(
                    color: TetherTokens.cream.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
