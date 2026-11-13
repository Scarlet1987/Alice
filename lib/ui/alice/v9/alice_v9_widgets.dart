// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice v9 shared chrome, restyled to the Alice Demo Space (2026-11-09,
// the entire design): quiet dark green, sage/mint text, serif headings,
// soft 16px panels, 10px pill-free buttons — no FF13 battle-ui look.
// Every v9 page uses these widgets — no second look for the same job.

import 'package:flutter/material.dart';

import 'package:front_porch_ai/ui/theme/app_colors.dart';

/// Serif text style used for every v9 heading and card title.
/// Demo Space pairs Cormorant Garamond with Georgia; Flutter has no
/// bundled Cormorant, so Georgia is the serif here.
const _v9Serif = TextStyle(fontFamily: 'Georgia');

/// A v9 card: Demo Space panel — dark surface, thin sage-green line,
/// 16px corners, soft shadow. Headers always sit inside it.
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
        color: AppColors.aliceSurface,
        border: Border.all(color: AppColors.aliceLine, width: 1),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.pureBlack.withValues(alpha: 0.45),
            offset: const Offset(0, 18),
            blurRadius: 44,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// A v9 section heading: Demo Space section head — serif, mint, plain
/// text, no green bar. Left-aligned like the Demo Space headings.
class V9Heading extends StatelessWidget {
  final String title;

  const V9Heading(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.left,
      style: _v9Serif.copyWith(
        fontSize: 25,
        fontWeight: FontWeight.w700,
        color: AppColors.aliceMint,
        letterSpacing: 0.02,
      ),
    );
  }
}

/// A v9 button: Demo Space .btn — solid green, pale words, 10px
/// corners, soft green shadow; `ghost` is the Demo .btn-ghost —
/// transparent, mint words, thin mint border. Sans, semibold, no serif,
/// no 3D bottom edge. Centred in its parent by the Center wrapper.
class V9Button extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool small;
  final bool ghost;

  const V9Button({
    super.key,
    required this.label,
    required this.onPressed,
    this.small = false,
    this.ghost = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: ghost
              ? AppColors.aliceClear
              : AppColors.aliceGreen,
          foregroundColor: ghost
              ? AppColors.aliceMint
              : AppColors.aliceOnGreen,
          padding: EdgeInsets.symmetric(
            horizontal: small ? 16 : 24,
            vertical: small ? 9 : 13,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(small ? 8 : 10),
            side: BorderSide(
              color: ghost
                  ? AppColors.aliceMint.withValues(alpha: 0.55)
                  : AppColors.aliceGreen,
            ),
          ),
          elevation: ghost ? 0 : 4,
          shadowColor: AppColors.aliceGreen.withValues(alpha: 0.35),
          textStyle: TextStyle(
            fontSize: small ? 15 : 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

/// Muted v9 helper text: Demo Space ink-soft on the dark green.
class V9Muted extends StatelessWidget {
  final String text;

  const V9Muted(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: AppColors.aliceInkSoft,
        fontSize: 15,
      ),
    );
  }
}

/// Cover Flow: three cards in a row, the centre one larger and raised.
/// Tapping a card selects it; the centre card is the current pick.
/// Empty library: the same three-card shape, as outlines with no names
/// on them — the centre card is the create action, the side cards do
/// nothing. No fake character or stage is ever invented here.
class V9CoverFlow extends StatelessWidget {
  final List<String> items;
  final int selected;
  final ValueChanged<int> onSelect;
  final String emptyText;
  final VoidCallback? onCreate;

  const V9CoverFlow({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelect,
    required this.emptyText,
    this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Column(
        children: [
          Row(
            children: [
              for (var i = 0; i < 3; i++)
                Expanded(
                  flex: i == 1 ? 13 : 10,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: i == 1
                        ? InkWell(
                            onTap: onCreate,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 180,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.aliceSurface2,
                                border: Border.all(
                                  color: AppColors.aliceMint.withValues(
                                    alpha: 0.35,
                                  ),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.pureBlack.withValues(
                                      alpha: 0.5,
                                    ),
                                    offset: const Offset(0, 24),
                                    blurRadius: 44,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '+new',
                                    textAlign: TextAlign.center,
                                    style: _v9Serif.copyWith(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.aliceMint,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'create your first',
                                    textAlign: TextAlign.center,
                                    style: _v9Serif.copyWith(
                                      fontSize: 14,
                                      color: AppColors.aliceSage,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Container(
                            height: 150,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.aliceMint.withValues(
                                  alpha: 0.35,
                                ),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '—',
                              textAlign: TextAlign.center,
                              style: _v9Serif.copyWith(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.aliceSage.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          V9Muted(emptyText),
        ],
      );
    }
    final start = (selected - 1).clamp(0, items.length - 1);
    final visible = [
      for (var i = start; i < start + 3 && i < items.length; i++) i,
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 30, 18, 24),
      decoration: BoxDecoration(
        color: AppColors.aliceInk,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.pureBlack.withValues(alpha: 0.45),
            offset: const Offset(0, 18),
            blurRadius: 44,
          ),
        ],
      ),
      child: Row(
        children: [
          for (final index in visible)
            Expanded(
              flex: index == selected ? 13 : 10,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: InkWell(
                  onTap: () => onSelect(index),
                  borderRadius: BorderRadius.circular(12),
                  child: Opacity(
                    opacity: index == selected ? 1 : 0.55,
                    child: Container(
                      height: index == selected ? 220 : 190,
                      alignment: Alignment.bottomCenter,
                      padding: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: index == selected
                              ? [
                                  AppColors.aliceForest,
                                  AppColors.aliceGreenDeep,
                                  AppColors.aliceInk,
                                ]
                              : [
                                  AppColors.aliceSurface2,
                                  AppColors.aliceInk,
                                ],
                        ),
                        border: Border.all(
                          color: AppColors.aliceMint.withValues(
                            alpha: index == selected ? 0.5 : 0.35,
                          ),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.pureBlack.withValues(alpha: 0.5),
                            offset: const Offset(0, 24),
                            blurRadius: 44,
                          ),
                        ],
                      ),
                      child: Text(
                        items[index],
                        textAlign: TextAlign.center,
                        style: _v9Serif.copyWith(
                          fontSize: 21,
                          fontWeight: FontWeight.w600,
                          color: AppColors.aliceSage.withValues(
                            alpha: index == selected ? 1 : 0.45,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
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
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: AppColors.aliceSage,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          isExpanded: true,
          dropdownColor: AppColors.aliceForest,
          initialValue: value,
          hint: Text(
            items.isEmpty ? emptyHint : '—',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.aliceSage),
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text(
                '—',
                style: TextStyle(color: AppColors.aliceSage),
              ),
            ),
            for (final item in items)
              DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: const TextStyle(color: AppColors.aliceSage),
                ),
              ),
          ],
          onChanged: items.isEmpty ? null : onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.aliceSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.aliceLine),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.aliceLine),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.aliceGreen),
            ),
            isDense: true,
          ),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.aliceSage),
        ),
      ],
    );
  }
}
