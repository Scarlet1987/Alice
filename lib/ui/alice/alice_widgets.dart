// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice edition shared widgets. Flat, simple, no runtime font loading,
// minimal shadows. Colors come from AppColors (already teal).

import 'package:flutter/material.dart';
import 'package:front_porch_ai/ui/alice/alice_motion.dart';
import 'package:front_porch_ai/ui/theme/app_colors.dart';

export 'package:front_porch_ai/ui/alice/alice_buttons.dart';

/// A card in the approved preview's language: card fill, soft border,
/// 12px radius, the preview's strategic shadow (0 8px 32px black at .6)
/// and a teal top highlight. The CSS highlight is an inset shadow;
/// Flutter draws it as an inner [BlurStyle.inner] shadow — same read.
class AliceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const AliceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.porchAmberOf(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.cardOf(context),
        border: Border.all(color: AppColors.borderSoftOf(context)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: AppColors.isLight(context) ? 0.10 : 0.6,
            ),
            offset: const Offset(0, 8),
            blurRadius: 32,
          ),
          BoxShadow(
            color: accent.withValues(alpha: 0.12),
            offset: const Offset(0, 1),
            blurRadius: 0,
            blurStyle: BlurStyle.inner,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// A section title on the preview's card-title gradient: the tint washes
/// in from the left at .16 and is gone by 60%, on a 6px radius. Shared by
/// [AliceSectionHead] and the collapsible section header so every card
/// title in the app speaks the same language.
class _AliceGradientTitle extends StatelessWidget {
  final String title;
  final Color tint;
  final TextStyle? style;

  const _AliceGradientTitle({
    required this.title,
    required this.tint,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [tint.withValues(alpha: 0.16), tint.withValues(alpha: 0)],
          stops: const [0, 0.6],
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(title, style: style),
    );
  }
}

/// Screen title in the preview's language: a 3px accent bar with the
/// title on a gradient that washes in at .22 and fades out by 70%,
/// rounded on the right only. The subtitle stays the screen's own
/// muted line under it.
class AliceScreenTitle extends StatelessWidget {
  final String title;

  const AliceScreenTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.porchAmberOf(context);
    // IntrinsicHeight gives the stretch row a finite height (the title
    // text's) even in the unbounded-height contexts screens put it in.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(width: 3, color: accent),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accent.withValues(alpha: 0.22),
                    accent.withValues(alpha: 0),
                  ],
                  stops: const [0, 0.7],
                ),
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(8),
                ),
              ),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card title + subtitle: the title sits on the preview's card-title
/// gradient (see [_AliceGradientTitle]); [barColor] tints the wash and
/// defaults to the teal accent.
class AliceSectionHead extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color? barColor;

  const AliceSectionHead({
    super.key,
    required this.title,
    this.subtitle,
    this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AliceGradientTitle(
          title: title,
          tint: barColor ?? AppColors.porchAmberOf(context),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ),
      ],
    );
  }
}

/// Small pill chip.
class AliceChip extends StatelessWidget {
  final String label;
  final Color? color;

  const AliceChip({super.key, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border.all(color: color ?? theme.dividerColor),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

/// Circular avatar with initial letter.
class AliceAvatar extends StatelessWidget {
  final String name;
  final double size;
  final Color? background;

  const AliceAvatar({
    super.key,
    required this.name,
    this.size = 44,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    // Deterministic color from name hash, in the teal/pink/blue family.
    final palette = [
      AppColors.porchAmber,
      const Color(0xFFC2437F),
      const Color(0xFF0F766E),
      const Color(0xFF3366A3),
      const Color(0xFFF472B6),
    ];
    final bg = background ?? palette[name.hashCode.abs() % palette.length];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.38,
        ),
      ),
    );
  }
}

/// Segmented control (Simple / Balanced / Advanced style).
class AliceSegmentedControl<T> extends StatelessWidget {
  final List<T> values;
  final List<String> labels;
  final T selected;
  final ValueChanged<T> onChanged;

  const AliceSegmentedControl({
    super.key,
    required this.values,
    required this.labels,
    required this.selected,
    required this.onChanged,
  }) : assert(values.length == labels.length);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.sunkenSurfaceOf(context),
        border: Border.all(color: AppColors.borderOf(context)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < values.length; i++)
            _segButton(context, values[i], labels[i]),
        ],
      ),
    );
  }

  Widget _segButton(BuildContext context, T value, String label) {
    final isOn = value == selected;
    return AlicePressable(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isOn ? AppColors.porchAmber : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isOn ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13.5,
            color: isOn ? AppColors.onChaosAccent : Theme.of(context).hintColor,
          ),
        ),
      ),
    );
  }
}

/// Collapsible section: header button with chevron, body folds away.
/// Used for the MC board sections.
class AliceCollapsibleSection extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Color? barColor;
  final Widget child;
  final bool initiallyOpen;

  const AliceCollapsibleSection({
    super.key,
    required this.title,
    this.subtitle,
    this.barColor,
    required this.child,
    this.initiallyOpen = false,
  });

  @override
  State<AliceCollapsibleSection> createState() =>
      _AliceCollapsibleSectionState();
}

class _AliceCollapsibleSectionState extends State<AliceCollapsibleSection> {
  late bool _open;

  @override
  void initState() {
    super.initState();
    _open = widget.initiallyOpen;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderOf(context)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _AliceGradientTitle(
                          title: widget.title,
                          tint:
                              widget.barColor ??
                              AppColors.porchAmberOf(context),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (widget.subtitle != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              widget.subtitle!,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    _open
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_right_rounded,
                    color: Theme.of(context).hintColor,
                  ),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: widget.child,
            ),
        ],
      ),
    );
  }
}

/// Key-value row used across Alice screens.
class AliceKeyValue extends StatelessWidget {
  final String label;
  final String value;

  const AliceKeyValue({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                color: Theme.of(context).hintColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
