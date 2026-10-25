// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Shared living background for Home and Creator, from the approved
// previews: the dark teal forest image at 80% opacity, under a dark
// overlay, so the background is apparent in the margins while card
// text still reads at a glance. The image itself is an asset, never
// base64 in code. The preview's slow 40s drift is intentionally not
// reproduced here: a moving background behind scrolling content
// competes with the words, and the preview's own rule is movement,
// not chaos.

import 'dart:ui';

import 'package:flutter/material.dart';

/// Forest background behind [child], at the preview's locked opacity.
class AliceForestBackground extends StatelessWidget {
  final Widget child;

  const AliceForestBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Opacity(
            opacity: 0.80,
            child: Image.asset(
              'assets/images/creator-forest.webp',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => const SizedBox.shrink(),
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromRGBO(8, 13, 12, 0.30),
                  Color.fromRGBO(22, 33, 30, 0.55),
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// A card that lets the forest show through a little, with a blur so
/// the background never competes with the text on it: the preview's
/// 88% card opacity, in Dart form.
class AliceTranslucentCard extends StatelessWidget {
  final Widget child;

  const AliceTranslucentCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF22332D).withValues(alpha: 0.88),
            border: Border.all(color: const Color(0xFF35473F)),
            borderRadius: BorderRadius.circular(28),
          ),
          child: child,
        ),
      ),
    );
  }
}
