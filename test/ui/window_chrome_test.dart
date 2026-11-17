// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:front_porch_ai/ui/theme/theme.dart';
import 'package:front_porch_ai/ui/window_chrome.dart';
import 'package:window_manager/window_manager.dart';

void main() {
  test('Windows and Linux chrome is not opaque porch charcoal', () {
    final options = mainWindowOptions();
    expect(options.titleBarStyle, TitleBarStyle.normal);
    expect(options.windowButtonVisibility, isTrue);
    expect(options.backgroundColor, isNot(AppColors.background));
    expect(
      options.backgroundColor == null || options.backgroundColor!.a < 1.0,
      isTrue,
      reason: 'Win/Linux must not paint porch charcoal on the native window',
    );
    expect(options.title, 'Rabbit Hole');
    expect(options.size, const Size(1280, 720));
    expect(options.center, isTrue);
    expect(options.skipTaskbar, isFalse);
  });

  test('forced size still keeps the title-bar rules', () {
    final win = mainWindowOptions(size: const Size(800, 600));
    expect(win.size, const Size(800, 600));
    expect(win.titleBarStyle, TitleBarStyle.normal);
    expect(win.backgroundColor, isNot(AppColors.background));
    expect(win.backgroundColor == null || win.backgroundColor!.a < 1.0, isTrue);
    expect(win.windowButtonVisibility, isTrue);
  });
}
