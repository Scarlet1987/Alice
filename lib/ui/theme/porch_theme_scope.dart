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

/// Carries the OLED true-black theme flag down the widget tree.
///
/// Placed above [MaterialApp] in main.dart so [AppColors.isOled] can resolve
/// OLED surface variants anywhere. Kept in its own file so
/// `ui/theme/app_colors.dart` can import it without a theme/services cycle.
class PorchThemeScope extends InheritedWidget {
  const PorchThemeScope({
    super.key,
    required this.oledBlack,
    required super.child,
  });

  /// True when the user enabled the OLED true-black variant (dark mode only).
  final bool oledBlack;

  static PorchThemeScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PorchThemeScope>();
    assert(scope != null, 'PorchThemeScope not found above MaterialApp');
    return scope!;
  }

  /// Null-safe read for contexts that may sit above the scope (tests).
  static bool oledBlackOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PorchThemeScope>();
    return scope?.oledBlack ?? false;
  }

  @override
  bool updateShouldNotify(PorchThemeScope oldWidget) =>
      oldWidget.oledBlack != oledBlack;
}
