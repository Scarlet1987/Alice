// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// MIGRATION NOTE: The City96 gate managed ComfyUI-GGUF loader compatibility.
// ComfyUI is gone, so the gate is obsolete. This is a minimal stub keeping
// the public API so callers compile. All checks report "ready".

import 'dart:async';

export 'city96_records.dart';

class ComfyLoaderUpdateNeeded implements Exception {
  const ComfyLoaderUpdateNeeded(this.message);
  final String message;
}

enum City96State { ready, needsUpdate, restartNeeded }

class City96Check {
  final City96State state;
  final String? message;
  final bool canUpdate;

  const City96Check(this.state, [this.message, this.canUpdate = false]);
}

class City96Question {
  final String title;
  final String message;
  final String comfyUrl;
  final String loaderPath;
  final bool othersCanWrite;

  const City96Question(
    this.title,
    this.message, {
    this.comfyUrl = '',
    this.loaderPath = '',
    this.othersCanWrite = false,
  });
}

typedef City96Asker = Future<bool?> Function(City96Question);
typedef City96Locator = Future<String?> Function(String url);

/// Obsolete stub: always reports ready.
class City96Gate {
  City96Gate();

  static City96Gate instance = City96Gate();

  City96Asker? ask;
  dynamic records;

  void setExistingSupport(String comfyUrl, {required bool confirmed}) {}

  bool hasExistingSupport(String comfyUrl) => false;

  Future<City96Check> check({
    required String comfyUrl,
    required Map<String, dynamic> graph,
  }) async {
    return const City96Check(City96State.ready);
  }

  Future<City96Check> ensure({
    required String comfyUrl,
    required Map<String, dynamic> graph,
    bool askAgain = false,
  }) async {
    return const City96Check(City96State.ready);
  }
}

const String kCity96NeedsUpdate = 'Loader update needed.';
const String kCity96OthersCanWrite = '';

/// Runs [fn] with the City96 ask dialog suppressed. Obsolete stub — just runs fn.
Future<T> withoutCity96Ask<T>(Future<T> Function() fn) async {
  return await fn();
}
