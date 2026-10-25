// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// This file is part of Front Porch AI.
//
// Front Porch AI is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

import 'package:flutter/material.dart';

import 'package:front_porch_ai/ui/theme/app_colors.dart';

/// The Porch design system: spacing, radii, type scale, shared components and
/// the app [ThemeData] builder (including the OLED true-black variant).
///
/// Colors come exclusively from [AppColors] — no raw color literals here.

/// 4pt-grid spacing scale.
class PorchSpacing {
  PorchSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

/// Corner radius scale.
class PorchRadius {
  PorchRadius._();
  static const double xs = 6;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double pill = 999;
}

/// Type scale. Built on the ambient text theme so the user's font choice and
/// reading-size setting keep working; sizes/weights give every screen one
/// shared voice.
class PorchType {
  PorchType._();

  static TextStyle display(BuildContext context) => Theme.of(
    context,
  ).textTheme.displaySmall!.copyWith(fontWeight: FontWeight.w700);

  static TextStyle headline(BuildContext context) => Theme.of(context)
      .textTheme
      .headlineSmall!
      .copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.2);

  static TextStyle title(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium!.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary(context),
      );

  static TextStyle sectionTitle(BuildContext context) =>
      Theme.of(context).textTheme.titleSmall!.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
        color: AppColors.textPrimary(context),
      );

  static TextStyle body(BuildContext context) => Theme.of(
    context,
  ).textTheme.bodyMedium!.copyWith(color: AppColors.textPrimary(context));

  static TextStyle bodySmall(BuildContext context) => Theme.of(
    context,
  ).textTheme.bodySmall!.copyWith(color: AppColors.textSecondary(context));

  static TextStyle caption(BuildContext context) => Theme.of(context)
      .textTheme
      .labelSmall!
      .copyWith(color: AppColors.textTertiary(context), letterSpacing: 0.3);

  static TextStyle hint(BuildContext context) => Theme.of(
    context,
  ).textTheme.bodySmall!.copyWith(color: AppColors.textSecondary(context));
}

/// Builds the app [ThemeData]. [oledBlack] swaps dark surfaces for true black
/// (OLED-friendly); it only applies in dark mode.
ThemeData buildPorchThemeData({required bool isDark, required bool oledBlack}) {
  final oled = isDark && oledBlack;
  final bg = oled ? AppColors.oledBackground : AppColors.background;
  final card = oled ? AppColors.oledCard : AppColors.card;
  final surface = oled ? AppColors.oledSurface : AppColors.surface;
  return ThemeData(
    brightness: isDark ? Brightness.dark : Brightness.light,
    // Teal app-wide accent: seed the Material 3 color scheme from the teal
    // primary so default controls pick it up; surfaces are pinned to the
    // app's deep-teal (or OLED black) grounds.
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: AppColors.porchAmber,
          brightness: isDark ? Brightness.dark : Brightness.light,
        ).copyWith(
          primary: isDark ? AppColors.porchAmber : AppColors.porchAmberLight,
          onPrimary: isDark ? AppColors.onChaosAccent : Colors.white,
          surface: isDark ? surface : AppColors.lightSurface,
        ),
    scaffoldBackgroundColor: isDark ? bg : AppColors.lightBackground,
    cardColor: isDark ? card : AppColors.lightCard,
    textTheme: ThemeData.light().textTheme.apply(
      fontFamily: 'Inter',
      bodyColor: isDark ? Colors.white : Colors.black87,
      displayColor: isDark ? Colors.white : Colors.black87,
    ),
    useMaterial3: true,
    // Subtle fade + rise on every route push: cheap, 60fps-friendly.
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _PorchPageTransitionBuilder(),
        TargetPlatform.iOS: _PorchPageTransitionBuilder(),
        TargetPlatform.linux: _PorchPageTransitionBuilder(),
        TargetPlatform.macOS: _PorchPageTransitionBuilder(),
        TargetPlatform.windows: _PorchPageTransitionBuilder(),
      },
    ),
  );
}

class _PorchPageTransitionBuilder extends PageTransitionsBuilder {
  const _PorchPageTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.02),
      end: Offset.zero,
    ).animate(fade);
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }
}

/// Modern card container: shared radius, hairline border, soft shadow.
class PorchCard extends StatelessWidget {
  const PorchCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(PorchSpacing.lg),
    this.onTap,
    this.accent,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final card = Material(
      color: AppColors.cardOf(context),
      borderRadius: BorderRadius.circular(PorchRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PorchRadius.lg),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(PorchRadius.lg),
            border: Border.all(
              color:
                  accent?.withValues(alpha: 0.45) ??
                  AppColors.borderOf(context).withValues(alpha: 0.6),
            ),
          ),
          child: child,
        ),
      ),
    );
    if (Theme.of(context).brightness == Brightness.light || onTap == null) {
      return card;
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(PorchRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: card,
    );
  }
}

/// Labeled section header with optional helper line and trailing action.
class PorchSectionHeader extends StatelessWidget {
  const PorchSectionHeader({
    super.key,
    required this.title,
    this.helper,
    this.trailing,
    this.accent,
  });

  final String title;
  final String? helper;
  final Widget? trailing;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: PorchSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (accent != null) ...[
            Container(
              width: 3,
              height: 20,
              margin: const EdgeInsets.only(right: PorchSpacing.sm, top: 2),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(PorchRadius.pill),
              ),
            ),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: PorchType.sectionTitle(context)),
                if (helper case final h?) ...[
                  const SizedBox(height: PorchSpacing.xs),
                  Text(h, style: PorchType.hint(context)),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// One option in a [PorchSegmentedControl].
class PorchSegmentOption<T> {
  const PorchSegmentOption({
    required this.value,
    required this.label,
    this.description,
    this.icon,
  });

  final T value;
  final String label;
  final String? description;
  final IconData? icon;
}

/// Friendly segmented control with an animated selection pill. Colors from
/// [AppColors] only.
class PorchSegmentedControl<T> extends StatelessWidget {
  const PorchSegmentedControl({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<PorchSegmentOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // The container pads its content and draws a 1px border: divide the
        // *inner* width so the segments never overflow the pill.
        final innerWidth = constraints.maxWidth - PorchSpacing.xs * 2 - 2;
        final segmentWidth = innerWidth / options.length.clamp(1, 99);
        final selectedIndex = options.indexWhere((o) => o.value == value);
        return Container(
          padding: const EdgeInsets.all(PorchSpacing.xs),
          decoration: BoxDecoration(
            color: AppColors.sunkenSurfaceOf(context),
            borderRadius: BorderRadius.circular(PorchRadius.pill),
            border: Border.all(
              color: AppColors.borderOf(context).withValues(alpha: 0.5),
            ),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                left: (selectedIndex < 0 ? 0 : selectedIndex) * segmentWidth,
                top: 0,
                bottom: 0,
                width: segmentWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.porchAmberOf(context),
                    borderRadius: BorderRadius.circular(PorchRadius.pill),
                  ),
                ),
              ),
              Row(
                children: [
                  for (final option in options)
                    SizedBox(
                      width: segmentWidth,
                      child: _SegmentButton(
                        option: option,
                        selected: option.value == value,
                        onTap: () => onChanged(option.value),
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

class _SegmentButton<T> extends StatelessWidget {
  const _SegmentButton({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final PorchSegmentOption<T> option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected
        ? AppColors.onPorchAmber
        : AppColors.textSecondary(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(PorchRadius.pill),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: PorchSpacing.sm,
          horizontal: PorchSpacing.xs,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            if (option.icon != null) ...[
              Icon(option.icon, size: 16, color: fg),
              const SizedBox(width: PorchSpacing.xs),
            ],
            Flexible(
              child: Text(
                option.label,
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: fg,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Primary filled button in the porch accent.
class PorchPrimaryButton extends StatelessWidget {
  const PorchPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final button = FilledButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.porchAmberOf(context),
        foregroundColor: AppColors.onPorchAmber,
        padding: const EdgeInsets.symmetric(
          horizontal: PorchSpacing.lg,
          vertical: PorchSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PorchRadius.md),
        ),
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Quiet outlined button.
class PorchGhostButton extends StatelessWidget {
  const PorchGhostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary(context),
        side: BorderSide(
          color: AppColors.borderOf(context).withValues(alpha: 0.8),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: PorchSpacing.lg,
          vertical: PorchSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PorchRadius.md),
        ),
      ),
    );
  }
}

/// Polished empty state: icon, title, helper, optional action.
class PorchEmptyState extends StatelessWidget {
  const PorchEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.helper,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? helper;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PorchSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(PorchSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.sunkenSurfaceOf(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 36,
                color: AppColors.textTertiary(context),
              ),
            ),
            const SizedBox(height: PorchSpacing.lg),
            Text(
              title,
              style: PorchType.title(context),
              textAlign: TextAlign.center,
            ),
            if (helper != null) ...[
              const SizedBox(height: PorchSpacing.sm),
              Text(
                helper!,
                style: PorchType.hint(context),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: PorchSpacing.lg),
              PorchPrimaryButton(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}

/// Polished loading state with a label.
class PorchLoadingState extends StatelessWidget {
  const PorchLoadingState({super.key, this.label = 'Loading…'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.porchAmberOf(context)),
          const SizedBox(height: PorchSpacing.lg),
          Text(label, style: PorchType.hint(context)),
        ],
      ),
    );
  }
}
