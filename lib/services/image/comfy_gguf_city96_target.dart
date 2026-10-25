// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// MIGRATION NOTE: City96 target detection was for ComfyUI-GGUF loader
// management. ComfyUI is gone. Stub.

// ignore: unused_import
import 'dart:io';

class City96Target {
  final String? loader;
  final int? pid;
  final String? refusal;

  const City96Target({this.loader, this.pid, this.refusal});
}

Future<City96Target> city96TargetForUrl(String url, {dynamic probe}) async {
  return const City96Target();
}
