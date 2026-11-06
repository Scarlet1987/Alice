// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice v9 shared chrome (combined preview v9): one look for one job.
// Green #00914f buttons with white words and a 3D bottom edge, serif
// headings on green, dark-green blended cards, pale-mint dropdowns with
// dark text. Every v9 page uses these widgets — no second look for the
// same job anywhere on the screen.

import 'package:flutter/material.dart';

import 'package:front_porch_ai/ui/theme/app_colors.dart';

/// Serif text style used for every v9 heading, button, and card title.
const _v9Serif = TextStyle(fontFamily: 'Georgia');

/// A v9 card: dark-green blended fill, green border with a green top
/// edge, soft shadow. Headers always sit inside it, never hidden.
class V9Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const V9Card({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.aliceDark.withValues(alpha: 0.88),
        border: const Border(
          left: BorderSide(color: AppColors.aliceGreen, width: 2),
          right: BorderSide(color: AppColors.aliceGreen, width: 2),
          bottom: BorderSide(color: AppColors.aliceGreen, width: 2),
          top: BorderSide(color: AppColors.aliceGreen, width: 3),
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.pureBlack.withValues(alpha: 0.35),
            offset: const Offset(0, 6),
            blurRadius: 18,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// A v9 section heading: white serif text on a solid green chip.
class V9Heading extends StatelessWidget {
  final String title;

  const V9Heading(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.aliceGreen,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.pureBlack.withValues(alpha: 0.45),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Text(
        title,
        style: _v9Serif.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.pureWhite,
          letterSpacing: 0.02,
          shadows: const [
            Shadow(
              color: AppColors.pureBlack,
              offset: Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
      ),
    );
  }
}

/// A v9 button: solid green, white serif words, a 3D bottom edge in the
/// darker green, lift on hover, press on tap. Both unit buttons (cm/in)
/// use this — there is no inverted white/green variant in v9.
class V9Button extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool small;

  const V9Button({
    super.key,
    required this.label,
    required this.onPressed,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.aliceGreen,
        foregroundColor: AppColors.pureWhite,
        padding: EdgeInsets.symmetric(
          horizontal: small ? 18 : 20,
          vertical: small ? 12 : 18,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.aliceGreen),
        ),
        elevation: 4,
        shadowColor: AppColors.aliceEdge,
        textStyle: _v9Serif.copyWith(
          fontSize: small ? 18 : 19,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.03,
        ),
      ),
      child: Text(label),
    );
  }
}

/// Muted v9 helper text: pale mint, readable on the dark green.
class V9Muted extends StatelessWidget {
  final String text;

  const V9Muted(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: AppColors.alicePale,
        shadows: const [
          Shadow(
            color: AppColors.pureBlack,
            offset: Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
    );
  }
}

/// Cover Flow: three cards in a row, the centre one larger and raised.
/// Tapping a card selects it; the centre card is the current pick.
class V9CoverFlow extends StatelessWidget {
  final List<String> items;
  final int selected;
  final ValueChanged<int> onSelect;
  final String emptyText;

  const V9CoverFlow({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelect,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: V9Muted('Nothing here yet.'),
      );
    }
    final start = (selected - 1).clamp(0, items.length - 1);
    final visible = [
      for (var i = start; i < start + 3 && i < items.length; i++) i,
    ];
    return Row(
      children: [
        for (final index in visible)
          Expanded(
            flex: index == selected ? 13 : 10,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: InkWell(
                onTap: () => onSelect(index),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: index == selected ? 180 : 150,
                  alignment: Alignment.bottomCenter,
                  padding: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: index == selected
                          ? [
                              AppColors.alicePale,
                              AppColors.aliceGreen,
                              AppColors.aliceDark,
                            ]
                          : [
                              AppColors.pureWhite,
                              AppColors.alicePale,
                            ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.pureBlack.withValues(
                          alpha: index == selected ? 0.3 : 0.2,
                        ),
                        offset: const Offset(0, 8),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Text(
                    items[index],
                    textAlign: TextAlign.center,
                    style: _v9Serif.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: index == selected
                          ? AppColors.pureWhite
                          : AppColors.aliceDark,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A loadout dropdown fed by a real list. When the list is empty the
/// dropdown is disabled and says so honestly — never "Option 1".
class V9SlotDropdown extends StatelessWidget {
  final String label;
  final List<String> items;
  final String? value;
  final ValueChanged<String?> onChanged;
  final String emptyHint;

  const V9SlotDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.value,
    required this.onChanged,
    required this.emptyHint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: value,
          hint: Text(items.isEmpty ? emptyHint : '—'),
          items: [
            const DropdownMenuItem<String>(value: null, child: Text('—')),
            for (final item in items)
              DropdownMenuItem<String>(value: item, child: Text(item)),
          ],
          onChanged: items.isEmpty ? null : onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.alicePale,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.pureBlack,
          ),
        ),
      ],
    );
  }
}
