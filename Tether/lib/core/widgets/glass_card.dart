import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GlassCard
// Soft elevated panel with optional backdrop blur.
// Used for social post cards, stat tiles, announcement tiles, settings panels.
// ─────────────────────────────────────────────────────────────────────────────
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final Color? color;
  final double blurAmount;
  final double opacity;
  final double? borderRadius;
  final bool showBorder;
  final bool elevated;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
    this.color,
    this.blurAmount = 16.0,
    this.opacity = 0.92,
    this.borderRadius,
    this.showBorder = true,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppTheme.radiusXl;

    Widget content = Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: (color ?? AppTheme.surfaceContainer).withOpacity(opacity),
        borderRadius: BorderRadius.circular(radius),
        border: showBorder
            ? Border.all(color: Colors.white.withOpacity(0.08), width: 1)
            : null,
        boxShadow: elevated ? AppTheme.cardElevation : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }
    return content;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PrimaryButton
// Solid teal pill with soft glow and scale-down press feedback.
// ─────────────────────────────────────────────────────────────────────────────
class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 52,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.05,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
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
    final theme = Theme.of(context);
    final enabled = widget.onPressed != null && !widget.isLoading;

    return GestureDetector(
      onTapDown: enabled ? (_) => _controller.forward() : null,
      onTapUp: enabled
          ? (_) {
              _controller.reverse();
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: enabled ? () => _controller.reverse() : null,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: Container(
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            color: enabled
                ? AppTheme.primaryContainer
                : AppTheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            boxShadow:
                enabled ? AppTheme.neonGlow(opacity: 0.28, blur: 22) : null,
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.onPrimaryFixed,
                      ),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          size: 18,
                          color: enabled
                              ? AppTheme.onPrimaryFixed
                              : AppTheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: enabled
                              ? AppTheme.onPrimaryFixed
                              : AppTheme.onSurfaceVariant,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SecondaryButton
// Soft glass pill with optional accent text.
// ─────────────────────────────────────────────────────────────────────────────
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool useAccentText;
  @Deprecated('Use useAccentText')
  final bool useLimeText;
  final IconData? icon;
  final double? width;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.useAccentText = false,
    this.useLimeText = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = useAccentText || useLimeText;
    final textColor =
        accent ? AppTheme.primaryContainer : AppTheme.onSurface;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: width ?? double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerHigh.withOpacity(0.75),
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(
            color: accent
                ? AppTheme.primaryContainer.withOpacity(0.4)
                : Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: textColor),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MetricChip / TagChip
// Pill-shaped label. Selected = teal border + tinted bg + soft glow.
// ─────────────────────────────────────────────────────────────────────────────
class MetricChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDashed;
  final VoidCallback? onTap;
  final IconData? icon;

  const MetricChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.isDashed = false,
    this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bgColor = isSelected
        ? AppTheme.primaryContainer.withOpacity(0.12)
        : AppTheme.surfaceContainerHigh;
    final borderColor = isSelected
        ? AppTheme.primaryContainer
        : Colors.white.withOpacity(0.1);
    final textColor =
        isSelected ? AppTheme.primaryContainer : AppTheme.onSurfaceVariant;
    final shadows = isSelected ? AppTheme.neonGlow(opacity: 0.15) : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: isDashed
              ? Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                  style: BorderStyle.solid,
                )
              : Border.all(color: borderColor, width: 1),
          boxShadow: shadows,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: textColor),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SkeletonBox
// Animated shimmer placeholder used while async data is loading.
// ─────────────────────────────────────────────────────────────────────────────
class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = AppTheme.radiusLg,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          color: Color.lerp(
            AppTheme.surfaceContainerHigh,
            AppTheme.surfaceContainerHighest,
            _anim.value,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ConnectErrorState
// Standard full-screen error state for every fetch that can fail.
// ─────────────────────────────────────────────────────────────────────────────
class ConnectErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const ConnectErrorState({
    super.key,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Symbols.wifi_off,
      title: "Can't connect right now",
      message: 'Check your connection and try again',
      actionLabel: 'Try again',
      onAction: onRetry,
      actionIcon: Symbols.refresh,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EmptyState
// Friendly empty / error placeholder with icon badge, copy, and optional CTA.
// ─────────────────────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.stackLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHigh,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                  width: 1,
                ),
                boxShadow: AppTheme.cardElevation,
              ),
              child: Icon(
                icon,
                size: 30,
                color: AppTheme.onSurfaceVariant.withOpacity(0.75),
              ),
            ),
            const SizedBox(height: AppTheme.stackMd),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: AppTheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppTheme.stackLg),
              SecondaryButton(
                label: actionLabel!,
                icon: actionIcon,
                onPressed: onAction,
                width: 180,
                useAccentText: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// StatTile
// Elevated tile used in bento grids (workout complete, home stats).
// ─────────────────────────────────────────────────────────────────────────────
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? accentColor;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = accentColor ?? AppTheme.primaryContainer;

    return GlassCard(
      elevated: true,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: Icon(icon, size: 18, color: accent),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            value,
            style: theme.textTheme.displayMedium,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TetherAppBar
// Fixed glass top bar used across all main screens.
// ─────────────────────────────────────────────────────────────────────────────
class TetherAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showWordmark;
  final Widget? leading;
  final List<Widget>? actions;

  const TetherAppBar({
    super.key,
    this.title = 'Tether',
    this.showWordmark = true,
    this.leading,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 64 + MediaQuery.of(context).padding.top,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
            left: AppTheme.gutter,
            right: AppTheme.gutter,
          ),
          decoration: const BoxDecoration(
            color: Color(0x99000000),
            border: Border(
              bottom: BorderSide(color: Color(0x1AFFFFFF), width: 1),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: leading,
              ),
              Expanded(
                child: Center(
                  child: showWordmark
                      ? Text(
                          'Tether',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            color: AppTheme.primaryContainer,
                            letterSpacing: -0.4,
                          ),
                        )
                      : Text(
                          title,
                          style: theme.textTheme.headlineLarge?.copyWith(
                            letterSpacing: -0.4,
                          ),
                        ),
                ),
              ),
              SizedBox(
                width: 40,
                child: actions != null && actions!.isNotEmpty
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: actions!,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
