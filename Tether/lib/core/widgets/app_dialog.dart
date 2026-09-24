import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// App dialog kit — same visual language as the staff portal cards:
// 12px radius, hairline border, left-aligned copy, tinted icon chip,
// white primary / rose danger / outlined secondary buttons.
// ─────────────────────────────────────────────────────────────────────────────

enum AppDialogTone { neutral, accent, success, danger }

extension on AppDialogTone {
  Color get color => switch (this) {
        AppDialogTone.neutral => AppTheme.onSurfaceVariant,
        AppDialogTone.accent => AppTheme.primaryContainer,
        AppDialogTone.success => AppTheme.toneSuccess,
        AppDialogTone.danger => AppTheme.toneDanger,
      };
}

const _ease = Cubic(0.22, 0.9, 0.3, 1);

/// Shows [builder] with the app's fade + lift entrance instead of Material's zoom.
Future<T?> showAppDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withOpacity(0.6),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, _, _) => builder(ctx),
    transitionBuilder: (ctx, animation, _, child) {
      if (MediaQuery.of(ctx).disableAnimations) {
        return FadeTransition(opacity: animation, child: child);
      }
      final curved = CurvedAnimation(parent: animation, curve: _ease);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.03), end: Offset.zero)
              .animate(curved),
          child: ScaleTransition(
            scale: Tween(begin: 0.97, end: 1.0).animate(curved),
            child: child,
          ),
        ),
      );
    },
  );
}

/// Two-button confirmation. Resolves to `true` only when confirmed.
Future<bool> showAppConfirmDialog(
  BuildContext context, {
  required String title,
  String? message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  AppDialogTone tone = AppDialogTone.neutral,
  IconData? icon,
  bool barrierDismissible = true,
}) async {
  final result = await showAppDialog<bool>(
    context,
    barrierDismissible: barrierDismissible,
    builder: (ctx) => AppDialog(
      icon: icon,
      tone: tone,
      title: title,
      message: message,
      actions: [
        AppDialogButton(
          label: cancelLabel,
          variant: AppButtonVariant.secondary,
          onPressed: () => Navigator.pop(ctx, false),
        ),
        AppDialogButton(
          label: confirmLabel,
          variant: tone == AppDialogTone.danger
              ? AppButtonVariant.danger
              : AppButtonVariant.primary,
          onPressed: () => Navigator.pop(ctx, true),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Single-button acknowledgement.
Future<void> showAppInfoDialog(
  BuildContext context, {
  required String title,
  String? message,
  String confirmLabel = 'Got it',
  AppDialogTone tone = AppDialogTone.accent,
  IconData? icon,
  bool barrierDismissible = true,
}) {
  return showAppDialog<void>(
    context,
    barrierDismissible: barrierDismissible,
    builder: (ctx) => AppDialog(
      icon: icon,
      tone: tone,
      title: title,
      message: message,
      actions: [
        AppDialogButton(
          label: confirmLabel,
          onPressed: () => Navigator.pop(ctx),
        ),
      ],
    ),
  );
}

class AppDialog extends StatelessWidget {
  final String title;
  final String? message;
  final IconData? icon;
  final AppDialogTone tone;

  /// Extra content between the message and the actions (fields, stats…).
  final Widget? body;
  final List<Widget> actions;

  const AppDialog({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.tone = AppDialogTone.neutral,
    this.body,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final toneColor = tone.color;

    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: toneColor.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg + 2),
                  ),
                  child: Icon(icon, size: 18, color: toneColor),
                ),
                const SizedBox(height: 14),
              ],
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: AppTheme.onSurface,
                  ),
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 6),
                Text(
                  message!,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.45,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (body != null) ...[
                const SizedBox(height: 16),
                body!,
              ],
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    for (var i = 0; i < actions.length; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(child: actions[i]),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum AppButtonVariant { primary, secondary, danger, accent }

class AppDialogButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;

  const AppDialogButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, Color border) = switch (variant) {
      AppButtonVariant.primary => (
          const Color(0xFFF5F5F5),
          const Color(0xFF0B0C0E),
          Colors.transparent,
        ),
      AppButtonVariant.accent => (
          AppTheme.primaryContainer,
          AppTheme.onPrimaryFixed,
          Colors.transparent,
        ),
      AppButtonVariant.danger => (
          AppTheme.toneDanger.withOpacity(0.12),
          AppTheme.toneDanger,
          AppTheme.toneDanger.withOpacity(0.28),
        ),
      AppButtonVariant.secondary => (
          Colors.transparent,
          AppTheme.onSurface,
          AppTheme.hairlineStrong,
        ),
    };
    final enabled = onPressed != null && !isLoading;

    return SizedBox(
      height: 44,
      child: TextButton(
        onPressed: enabled
            ? () {
                HapticFeedback.selectionClick();
                onPressed!();
              }
            : null,
        style: TextButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: bg.withValues(alpha: bg.a * 0.5),
          disabledForegroundColor: fg.withOpacity(0.5),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: border),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: fg),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 17, color: fg),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(label, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action sheet — short list of choices (e.g. camera vs gallery)
// ─────────────────────────────────────────────────────────────────────────────

class AppSheetAction<T> {
  final IconData icon;
  final String label;
  final T value;
  final bool destructive;

  const AppSheetAction({
    required this.icon,
    required this.label,
    required this.value,
    this.destructive = false,
  });
}

Future<T?> showAppActionSheet<T>(
  BuildContext context, {
  String? title,
  required List<AppSheetAction<T>> actions,
}) {
  return showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ),
            for (final action in actions)
              _SheetActionTile(
                action: action,
                onTap: () => Navigator.pop(ctx, action.value),
              ),
          ],
        ),
      ),
    ),
  );
}

class _SheetActionTile<T> extends StatelessWidget {
  final AppSheetAction<T> action;
  final VoidCallback onTap;

  const _SheetActionTile({required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color =
        action.destructive ? AppTheme.toneDanger : AppTheme.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg + 2),
              ),
              child: Icon(action.icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                action.label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            Icon(
              Symbols.chevron_right,
              size: 18,
              color: AppTheme.onSurfaceVariant.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Snackbars
// ─────────────────────────────────────────────────────────────────────────────

enum AppSnackTone { neutral, success, error }

void showAppSnack(
  BuildContext context,
  String message, {
  AppSnackTone tone = AppSnackTone.neutral,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final (IconData? icon, Color color) = switch (tone) {
    AppSnackTone.neutral => (null, AppTheme.onSurface),
    AppSnackTone.success => (Symbols.check_circle, AppTheme.toneSuccess),
    AppSnackTone.error => (Symbols.error, AppTheme.toneDanger),
  };

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: color, fill: 1),
              const SizedBox(width: 10),
            ],
            Expanded(child: Text(message)),
          ],
        ),
        action: actionLabel != null && onAction != null
            ? SnackBarAction(label: actionLabel, onPressed: onAction)
            : null,
      ),
    );
}
