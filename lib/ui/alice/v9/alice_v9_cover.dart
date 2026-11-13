// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice v9 Cover Flow card: the Demo Space portrait when the character
// is one of the Demo Space's four, otherwise the gradient portrait
// shape. Split from alice_v9_widgets.dart to keep every file under
// 500 lines.

import 'package:flutter/material.dart';

import 'package:front_porch_ai/ui/theme/app_colors.dart';

/// Serif for the card name. Mirrors `_v9Serif` in alice_v9_widgets —
/// Cormorant Garamond, bundled (see pubspec), Georgia as fallback.
const _coverSerif = TextStyle(
  fontFamily: 'Cormorant Garamond',
  fontFamilyFallback: ['Georgia'],
);

/// Demo Space portrait for a character name, or null for anyone else.
/// Matches the Demo Space's four — Alice, Cheshire Cat, Mad Hatter,
/// White Rabbit — by first word, case-insensitive.
String? demoPortraitAsset(String name) {
  final first = name.trim().toLowerCase().split(RegExp(r'\s+')).first;
  return switch (first) {
    'alice' => 'assets/images/demo-characters/alice.webp',
    'cheshire' => 'assets/images/demo-characters/cheshire.webp',
    'mad' => 'assets/images/demo-characters/hatter.webp',
    'white' => 'assets/images/demo-characters/rabbit.webp',
    _ => null,
  };
}

/// One Cover Flow card. When [showPortraits] is true and the name is
/// one of the Demo Space's four, the card shows that portrait (cover,
/// 12px radius, framed like the Demo `.flow-card img`); otherwise it
/// keeps the gradient portrait shape. Stage cards pass false — worlds
/// are not characters and never get a portrait. The name sits at the
/// bottom either way, over a dark scrim when it is over a photo.
class V9CoverCard extends StatelessWidget {
  final String name;
  final bool isCentre;
  final bool showPortraits;

  const V9CoverCard({
    super.key,
    required this.name,
    required this.isCentre,
    required this.showPortraits,
  });

  @override
  Widget build(BuildContext context) {
    final portrait = showPortraits ? demoPortraitAsset(name) : null;
    return Container(
      height: isCentre ? 220 : 190,
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        image: portrait == null
            ? null
            : DecorationImage(
                image: AssetImage(portrait),
                fit: BoxFit.cover,
                alignment: const Alignment(0, -0.6),
              ),
        gradient: portrait == null
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isCentre
                    ? [
                        AppColors.aliceForest,
                        AppColors.aliceGreenDeep,
                        AppColors.aliceInk,
                      ]
                    : [
                        AppColors.aliceSurface2,
                        AppColors.aliceInk,
                      ],
              )
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.aliceClear,
                  AppColors.aliceClear,
                  AppColors.pureBlack,
                ],
                stops: [0, 0.55, 1],
              ),
        border: Border.all(
          color: AppColors.aliceMint.withValues(
            alpha: isCentre ? 0.5 : 0.35,
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
        name,
        textAlign: TextAlign.center,
        style: _coverSerif.copyWith(
          fontSize: 21,
          fontWeight: FontWeight.w600,
          color: AppColors.aliceSage.withValues(
            alpha: isCentre ? 1 : 0.45,
          ),
          shadows: portrait == null
              ? null
              : [
                  const Shadow(
                    color: AppColors.pureBlack,
                    offset: Offset(0, 2),
                    blurRadius: 8,
                  ),
                ],
        ),
      ),
    );
  }
}
