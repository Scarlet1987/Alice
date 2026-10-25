// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// This file is part of Front Porch AI.
//
// Front Porch AI is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

import 'package:front_porch_ai/services/memory_budget.dart';

import 'settings_base.dart';

/// Where an engine keeps its heavyweight memory.
enum EngineMemoryPlacement {
  /// The app picks the best placement for the detected hardware.
  auto,

  /// Keep it on the graphics card (fastest, uses VRAM).
  vram,

  /// Keep it in system RAM (frees VRAM for active compute).
  ram,
}

/// Presentation copy for [EngineMemoryPlacement].
extension EngineMemoryPlacementLabel on EngineMemoryPlacement {
  String get label => switch (this) {
    EngineMemoryPlacement.auto => 'Auto',
    EngineMemoryPlacement.vram => 'Graphics card (VRAM)',
    EngineMemoryPlacement.ram => 'System RAM',
  };

  static EngineMemoryPlacement fromName(String? name) =>
      EngineMemoryPlacement.values.firstWhere(
        (v) => v.name == name,
        orElse: () => EngineMemoryPlacement.auto,
      );
}

/// Dual-engine memory policy: how the text (KoboldCpp) and image engines
/// share the machine's memory. The knobs are persisted here and applied by
/// the engines: the text placement feeds the KoboldCpp launch config
/// (see koboldAppConfig), the image placement drives per-generation
/// unload behaviour, and the queue toggle gates the image generation
/// queue. Stability first: generations queue with backpressure instead of
/// being dropped.
class EngineResourcesSettings with SettingsBase {
  /// Where the text engine runs. Auto lets the fit choose layers for the
  /// hardware; "System RAM" forces CPU-only (gpuLayers 0), freeing VRAM
  /// for the image engine. KoboldCpp cannot split KV cache to RAM while
  /// keeping compute on GPU — layers travel with their KV — so this knob
  /// controls layer placement, not KV placement.
  EngineMemoryPlacement _textKvCache = EngineMemoryPlacement.auto;

  /// Where the image engine parks model weights between generations.
  /// "System RAM" unloads weights after each local generation (ComfyUI
  /// /free, A1111 unload-checkpoint); "Graphics card" keeps them loaded.
  EngineMemoryPlacement _imageWeights = EngineMemoryPlacement.auto;

  /// Never drop a generation: queue work with backpressure instead.
  /// Wired to the image generation queue; the text path already serializes
  /// through KoboldRequestQueue.
  bool _queueWithBackpressure = true;

  /// VRAM budget in MB for both engines combined. 0 = auto (conservative
  /// split with safety headroom).
  int _vramBudgetMb = 0;

  /// Total harness memory budget in MB for the whole app: its own RAM plus
  /// the engines' harness-side overhead. Default 2048 (2 GB); the user can
  /// raise it in Settings → Engine resources. Model weights and KV cache
  /// are NOT in this number — they live in the VRAM budget above.
  int _totalMemoryBudgetMb = kDefaultMemoryBudgetMb;

  /// Free VRAM headroom in MB a local image model wants before a generation
  /// unloads the idle text engine to make room. Was a hardcoded constant in
  /// the arbitration; a setting now so the threshold is visible and tunable.
  int _imageModelHeadroomMb = 2048;

  EngineMemoryPlacement get textKvCache => _textKvCache;
  EngineMemoryPlacement get imageWeights => _imageWeights;
  bool get queueWithBackpressure => _queueWithBackpressure;
  int get vramBudgetMb => _vramBudgetMb;
  int get totalMemoryBudgetMb => _totalMemoryBudgetMb;
  int get imageModelHeadroomMb => _imageModelHeadroomMb;

  void load() {
    _textKvCache = EngineMemoryPlacementLabel.fromName(
      prefs?.getString(k('engine_text_kv_cache')),
    );
    _imageWeights = EngineMemoryPlacementLabel.fromName(
      prefs?.getString(k('engine_image_weights')),
    );
    _queueWithBackpressure =
        prefs?.getBool(k('engine_queue_backpressure')) ?? true;
    _vramBudgetMb = prefs?.getInt(k('engine_vram_budget_mb')) ?? 0;
    _totalMemoryBudgetMb =
        prefs?.getInt(k('engine_total_memory_budget_mb')) ??
        kDefaultMemoryBudgetMb;
    _imageModelHeadroomMb =
        prefs?.getInt(k('engine_image_headroom_mb')) ?? 2048;
  }

  Future<void> setTextKvCache(EngineMemoryPlacement value) async {
    if (_textKvCache == value) return;
    _textKvCache = value;
    // Notify synchronously so the UI updates immediately, even if the
    // prefs write below is slow or fails. Persistence is best-effort.
    notify();
    try {
      await prefs?.setString(k('engine_text_kv_cache'), value.name);
    } catch (_) {
      // Best-effort persistence: the in-memory value is already updated
      // and the UI already reflects it.
    }
  }

  Future<void> setImageWeights(EngineMemoryPlacement value) async {
    if (_imageWeights == value) return;
    _imageWeights = value;
    // Notify synchronously so the UI updates immediately, even if the
    // prefs write below is slow or fails. Persistence is best-effort.
    notify();
    try {
      await prefs?.setString(k('engine_image_weights'), value.name);
    } catch (_) {
      // Best-effort persistence: the in-memory value is already updated
      // and the UI already reflects it.
    }
  }

  Future<void> setQueueWithBackpressure(bool value) async {
    if (_queueWithBackpressure == value) return;
    _queueWithBackpressure = value;
    await prefs?.setBool(k('engine_queue_backpressure'), value);
    notify();
  }

  Future<void> setVramBudgetMb(int value) async {
    final v = value.clamp(0, 131072);
    if (_vramBudgetMb == v) return;
    _vramBudgetMb = v;
    await prefs?.setInt(k('engine_vram_budget_mb'), v);
    notify();
  }

  Future<void> setTotalMemoryBudgetMb(int value) async {
    final v = value.clamp(512, 131072);
    if (_totalMemoryBudgetMb == v) return;
    _totalMemoryBudgetMb = v;
    await prefs?.setInt(k('engine_total_memory_budget_mb'), v);
    notify();
  }

  Future<void> setImageModelHeadroomMb(int value) async {
    final v = value.clamp(0, 65536);
    if (_imageModelHeadroomMb == v) return;
    _imageModelHeadroomMb = v;
    await prefs?.setInt(k('engine_image_headroom_mb'), v);
    notify();
  }
}
