// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:front_porch_ai/ui/theme/app_colors.dart';

/// Pins the Alice reskin palette: teal primary, deep-teal dark grounds,
/// mint-white light grounds, pink/blue secondary accents. Guards against
/// regression to the warm-porch amber palette.
void main() {
  group('Alice reskin palette', () {
    test('primary accent is teal, not amber', () {
      // Teal #2DD4BF — the old warm amber was #F4A259.
      expect(AppColors.porchAmber, const Color(0xFF2DD4BF));
      expect(AppColors.porchAmberLight, const Color(0xFF0E7A6D));
      expect(AppColors.formMasterAccent, const Color(0xFF2DD4BF));
    });

    test('dark grounds are deep teal', () {
      expect(AppColors.background, const Color(0xFF04231F));
      expect(AppColors.card, const Color(0xFF08302A));
      expect(AppColors.surface, const Color(0xFF0B3A33));
      expect(AppColors.sunkenSurface, const Color(0xFF03201B));
    });

    test('light grounds are mint white', () {
      expect(AppColors.lightBackground, const Color(0xFFF4FAF8));
      expect(AppColors.lightSurface, const Color(0xFFE7F3F0));
      expect(AppColors.lightCard, Colors.white);
    });

    test('secondary accents are pink and blue, not warm', () {
      // Terracotta -> pink, honey -> sky blue.
      expect(AppColors.porchTerracotta, const Color(0xFFFB8FAB));
      expect(AppColors.porchHoney, const Color(0xFF7DD3FC));
      expect(AppColors.lustAccent, const Color(0xFFF472B6));
      expect(AppColors.journalAccent, const Color(0xFF5EEAD4));
    });

    test('chat bubbles match preview', () {
      expect(AppColors.userBubble, const Color(0xFF2F7FE0));
      expect(AppColors.aiBubble, const Color(0xFF0E3F38));
      expect(AppColors.dialogue, const Color(0xFFF9A8D4));
      expect(AppColors.action, const Color(0xFF93C5FD));
    });
  });
}
