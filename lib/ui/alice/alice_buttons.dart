// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice edition buttons, in the approved preview's language: primary
// buttons are solid teal with the preview's teal glow, ghost buttons
// are accent text on an accent outline, and the danger button is the
// preview's red text button (red text, red hairline, faint red fill).

import 'package:flutter/material.dart';
import 'package:front_porch_ai/ui/theme/app_colors.dart';

/// Primary / ghost buttons in the Alice style.
class AliceButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool ghost;
  final bool small;
  final bool block;

  const AliceButton({
    super.key,
    required this.label,
    this.onPressed,
    this.ghost = false,
    this.small = false,
    this.block = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.porchAmberOf(context);
    final style = ElevatedButton.styleFrom(
      backgroundColor: ghost ? Colors.transparent : AppColors.porchAmber,
      foregroundColor: ghost ? accent : AppColors.onChaosAccent,
      padding: EdgeInsets.symmetric(
        horizontal: small ? 16 : 24,
        vertical: small ? 8 : 10,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: ghost ? BorderSide(color: accent) : BorderSide.none,
      ),
      // The preview's glow: 0 2px 12px in accent at .4. Material draws
      // its elevation shadow in shadowColor — the closest honest match.
      elevation: ghost ? 0 : 2,
      shadowColor: AppColors.porchAmber.withValues(alpha: 0.4),
      surfaceTintColor: Colors.transparent,
      textStyle: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: small ? 13 : 14,
      ),
    );
    final btn = ghost
        ? OutlinedButton(onPressed: onPressed, style: style, child: Text(label))
        : ElevatedButton(
            onPressed: onPressed,
            style: style,
            child: Text(label),
          );
    if (block) {
      return SizedBox(width: double.infinity, child: btn);
    }
    return btn;
  }
}

/// The preview's danger text button, for Delete actions in content:
/// bold red text, a red hairline (full red on hover), and a faint red
/// fill that deepens on hover. Dialog confirmation buttons keep the
/// theme's error style — this is for in-card actions only.
class AliceDangerButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const AliceDangerButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final red = AppColors.alertRedOf(context);
    return TextButton(
      onPressed: onPressed,
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(red),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => red.withValues(
            alpha: states.contains(WidgetState.hovered) ? 0.15 : 0.08,
          ),
        ),
        side: WidgetStateProperty.resolveWith(
          (states) => BorderSide(
            color: states.contains(WidgetState.hovered)
                ? red
                : red.withValues(alpha: 0.4),
          ),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
      child: Text(label),
    );
  }
}
