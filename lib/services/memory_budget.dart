// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// This file is part of Front Porch AI.
//
// Front Porch AI is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Front Porch AI is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with Front Porch AI. If not, see <https://www.gnu.org/licenses/>.

// Alice's harness memory budget: the app itself (its process, caches,
// queued work) plus the engines' harness-side overhead stays within
// [kDefaultMemoryBudgetMb] unless the user raises it in Settings → Engine
// resources. Model weights and KV cache are NOT in this number — they live
// in the VRAM budget the fit math manages (EngineResourcesSettings).
// The estimate is honest about what it cannot measure: per-process VRAM
// has no counter on every platform, so engines report their own overhead
// and the app's RAM is read from the OS.

import 'dart:io';

import 'package:flutter/foundation.dart';

/// Default harness memory budget in MB: 2 GB for the whole app.
const int kDefaultMemoryBudgetMb = 2048;

/// Rough harness-side cost of a running KoboldCpp in MB: the process, its
/// runtime, and launch buffers — not the model weights or KV cache, which
/// the VRAM budget owns. A documented estimate: no per-process counter
/// exists on every platform, so this is the fit math's kind of number, not
/// a measurement.
const int kKoboldHarnessOverheadMb = 256;

/// One engine's harness-side footprint, as reported by the engine itself.
class EngineFootprint {
  const EngineFootprint({this.ramMb = 0, this.vramMb = 0});

  final int ramMb;
  final int vramMb;

  int get totalMb => ramMb + vramMb;
}

/// The whole-app estimate behind the Settings budget bar: the Flutter
/// app's own RAM (measured) plus whatever engines have reported.
class MemoryUsageEstimate {
  MemoryUsageEstimate({
    required this.appRamMb,
    Map<String, EngineFootprint>? engines,
  }) : engines = Map.unmodifiable(engines ?? const {});

  final int appRamMb;
  final Map<String, EngineFootprint> engines;

  int get totalRamMb =>
      appRamMb + engines.values.fold(0, (sum, e) => sum + e.ramMb);
  int get totalVramMb => engines.values.fold(0, (sum, e) => sum + e.vramMb);
  int get totalMb => totalRamMb + totalVramMb;

  bool fitsInBudget(int budgetMb) => totalMb <= budgetMb;

  /// Plain-language name of the biggest consumer ('the app itself',
  /// 'the text engine', 'the image engine'). Null when nothing is tracked.
  String? get largestConsumer {
    String? name;
    var best = appRamMb;
    engines.forEach((key, footprint) {
      if (footprint.totalMb > best) {
        best = footprint.totalMb;
        name = key;
      }
    });
    return name ?? (appRamMb > 0 ? 'the app itself' : null);
  }

  /// Plain words when the estimate does not fit [budgetMb]; null when it
  /// fits. For the settings bar, the launch gate, and the log.
  String? shortfallMessage(int budgetMb) {
    if (fitsInBudget(budgetMb)) return null;
    return MemoryBudget.shortfallMessage(
      usedMb: totalMb,
      budgetMb: budgetMb,
      largest: largestConsumer,
    );
  }
}

/// Tracks the harness footprint against the budget. The app's RAM is
/// measured from the OS; engines register their harness-side overhead when
/// they start and clear it when they stop.
class MemoryBudget {
  MemoryBudget._();

  /// Registry key for the text engine (KoboldCpp); doubles as its
  /// plain-language name in the UI.
  static const String textEngine = 'the text engine';

  /// Registry key for the image engine; doubles as its plain-language name.
  static const String imageEngine = 'the image engine';

  static final Map<String, EngineFootprint> _engines = {};

  /// The Flutter app's own RAM in MB, read from the OS. 0 when it cannot
  /// be read — the estimate then understates, never crashes.
  static int appRamMb() {
    try {
      return ProcessInfo.currentRss ~/ (1024 * 1024);
    } catch (_) {
      return 0;
    }
  }

  static void reportEngine(String name, EngineFootprint footprint) {
    _engines[name] = footprint;
  }

  static void clearEngine(String name) {
    _engines.remove(name);
  }

  /// Test hook: start from an empty registry.
  @visibleForTesting
  static void debugClearAll() => _engines.clear();

  static MemoryUsageEstimate estimateNow() =>
      MemoryUsageEstimate(appRamMb: appRamMb(), engines: _engines);

  /// '1.2 GB of 2 GB used' label for the budget bar.
  static String usageLabel({required int usedMb, required int budgetMb}) =>
      'Memory budget: ${_gb(usedMb)} of ${_gb(budgetMb)} used';

  /// The words for an over-budget footprint, shared by the settings bar,
  /// the launch gate, and the log. Gigabytes, not jargon.
  static String shortfallMessage({
    required int usedMb,
    required int budgetMb,
    String? largest,
  }) {
    final who = largest == null ? '' : ' $largest is using the most.';
    return 'Alice is using about ${_gb(usedMb)} of memory, past the '
        '${_gb(budgetMb)} budget.$who Free up memory by unloading an idle '
        'engine, or raise the budget in Settings → Engine resources.';
  }

  static String _gb(int mb) => '${(mb / 1024).toStringAsFixed(1)} GB';
}
