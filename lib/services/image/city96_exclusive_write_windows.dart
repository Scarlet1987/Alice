// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// MIGRATION NOTE: Windows-exclusive City96 loader writing was for ComfyUI-GGUF.
// ComfyUI is gone. Stub.

// ignore: unused_import
import 'dart:io';

Future<void> writeNewFileExclusiveWindows(
  String path,
  List<int> bytes, {
  void Function(String path)? afterCreate,
}) async {}
