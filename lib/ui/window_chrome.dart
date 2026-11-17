// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// Desktop window chrome for [window_manager]. Desktop-only — the PWA never
/// calls this (window_manager is not on web).
///
/// Windows/Linux must NOT paint the app background color onto
/// the native window — that makes caption buttons low-contrast and kills
/// hover. They stay a normal decorated window with a transparent background.
WindowOptions mainWindowOptions({Size? size}) {
  return WindowOptions(
    size: size ?? const Size(1280, 720),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    windowButtonVisibility: true,
    title: 'Rabbit Hole',
  );
}
