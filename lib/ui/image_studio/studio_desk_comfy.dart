// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

part of 'studio_desk.dart';

/// ComfyUI server discovery.
///
/// MIGRATION NOTE: The ComfyUI server is gone. The native backend needs no
/// discovery — it is built in. This extension is kept as a no-op so the
/// desk state compiles; all methods return immediately.
extension _DeskComfy on _StudioDeskState {
  /// No-op: nothing to look for.
  Future<bool> _lookForComfy() async => true;

  /// No-op: nothing to watch.
  void _watchComfy(dynamic report) {}
}
