// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Native image generation backend for Alice.
//
// ARCHITECTURE
// ============
// Alice is the container; engines are swappable parts. This file is the
// built-in image engine — no server, no HTTP, no ports, no localhost.
//
// The stack, bottom to top:
//
//   ┌─────────────────────────────────────────────────┐
//   │  Dart (this file)                               │  Public API:
//   │  NativeImageBackend                             │  loadModel, generate,
//   │                                                 │  unloadModel, listModels
//   ├─────────────────────────────────────────────────┤
//   │  Native bridge (per-platform)                   │  Linux/Vulkan first.
//   │  - C++ core: model inference via FFI            │  Windows/Mac later.
//   │  - Python orchestration: prompt pipeline,       │
//   │    model management, via subprocess or embed    │
//   ├─────────────────────────────────────────────────┤
//   │  GPU (Vulkan / CUDA / Metal)                    │  Direct, no server.
//   └─────────────────────────────────────────────────┘
//
// The C++ core handles tensor compute (stable-diffusion.cpp style).
// Python handles orchestration: prompt expansion, sampler scheduling,
// LoRA weight merging, VAE decode coordination.
// Dart calls into them through the platform bridge defined below.
//
// MIGRATION NOTE
// ==============
// This replaces the ComfyUI server backend. The public method signatures
// on ImageGenService are unchanged — the UI calls the same methods.
// Only the transport changed: direct native calls instead of HTTP to
// localhost:8188.
//
// TODO markers below show exactly where per-platform code goes.

part of 'image_gen_service.dart';

// Note: dart:async and flutter/foundation.dart are imported by the
// parent library (image_gen_service.dart). Part files cannot have
// their own imports.

/// Parameters for a single image generation request.
/// Mirrors what the old ComfyUI backend accepted, minus workflow graphs.
class NativeGenerateParams {
  const NativeGenerateParams({
    required this.prompt,
    this.negativePrompt = '',
    this.width = 1024,
    this.height = 1024,
    this.steps = 20,
    this.cfg = 4.0,
    this.seed = -1,
    this.denoise = 1.0,
    this.referenceImage,
  });

  final String prompt;
  final String negativePrompt;
  final int width;
  final int height;
  final int steps;
  final double cfg;
  final int seed;
  final double denoise;
  final Uint8List? referenceImage;
}

/// Status of the native engine.
enum NativeEngineStatus {
  /// No model loaded. Engine is idle.
  idle,

  /// Model is loading (may take 10-30s for large models).
  loading,

  /// Model loaded, ready to generate.
  ready,

  /// Generation in progress.
  generating,

  /// Engine encountered an error.
  error,
}

/// The native image generation backend.
///
/// Replaces ComfyUiService. Same role in the architecture — the thing
/// ImageGenService calls to make pictures — but in-process instead of
/// over HTTP.
class NativeImageBackend extends ChangeNotifier {
  /// [modelsDir] supplies the folder the user chose for image models
  /// (Settings → Where things live). Read lazily on every scan so a
  /// folder change takes effect without recreating the backend.
  NativeImageBackend({String Function()? modelsDir}) : _modelsDir = modelsDir;

  final String Function()? _modelsDir;

  NativeEngineStatus _status = NativeEngineStatus.idle;
  NativeEngineStatus get status => _status;

  String? _loadedModelPath;
  String? get loadedModelPath => _loadedModelPath;

  String _statusMessage = '';
  String get statusMessage => _statusMessage;

  double? _progress;
  double? get progress => _progress;

  void _setStatus(NativeEngineStatus s, [String msg = '']) {
    _status = s;
    if (msg.isNotEmpty) _statusMessage = msg;
    notifyListeners();
  }

  /// Load a model file into the engine.
  ///
  /// [path] is the absolute path to a .safetensors, .gguf, or .ckpt file.
  /// Unloads any currently loaded model first.
  ///
  /// TODO(platform): Linux — call into the C++ core via FFI.
  ///   The C++ side exposes: native_load_model(const char* path, int* error).
  ///   Vulkan backend is selected automatically on AMD; CUDA on NVIDIA.
  /// TODO(platform): Windows — same FFI, DirectML fallback if no Vulkan/CUDA.
  /// TODO(platform): macOS — same FFI, Metal backend.
  Future<void> loadModel(String path) async {
    if (_loadedModelPath == path && _status == NativeEngineStatus.ready) {
      return; // Already loaded.
    }
    _setStatus(NativeEngineStatus.loading, 'Loading image model...');
    _progress = null;

    // TODO(native-bridge): Replace with actual FFI call.
    //   Example:
    //   final lib = DynamicLibrary.open(_nativeLibPath());
    //   final loadFn = lib.lookupFunction<
    //     Int32 Function(Pointer<Utf8>),
    //     int Function(Pointer<Utf8>)
    //   >('native_load_model');
    //   final err = loadFn(path.toNativeUtf8());
    //   if (err != 0) throw NativeEngineException('load failed: $err');
    await Future<void>.delayed(const Duration(milliseconds: 100));
    debugPrint(
      '[NativeImageBackend] TODO: loadModel($path) — bridge not yet implemented',
    );

    _loadedModelPath = path;
    _setStatus(NativeEngineStatus.ready, 'Model ready.');
  }

  /// Generate an image from [params].
  ///
  /// Returns the PNG bytes. Throws [NativeEngineException] on failure.
  ///
  /// TODO(platform): Linux — C++ FFI call:
  ///   native_generate(params_ptr, progress_callback, cancel_token)
  ///   Progress reports stream back through the callback (0.0–1.0).
  /// TODO(python): Prompt orchestration (upsampling, negative prompt
  ///   assembly, LoRA merging) runs in the Python layer before the
  ///   C++ call. The Python subprocess is managed by the bridge —
  ///   spawned on first use, reused across generations, killed on
  ///   engine shutdown. NOT a server: stdio pipes, no HTTP, no ports.
  Future<Uint8List> generate(
    NativeGenerateParams params, {
    void Function(double progress, Uint8List? preview)? onProgress,
    Future<bool> Function()? isCancelled,
  }) async {
    if (_status != NativeEngineStatus.ready || _loadedModelPath == null) {
      throw NativeEngineException('No model loaded. Call loadModel() first.');
    }
    _setStatus(NativeEngineStatus.generating, 'Generating...');
    try {
      // TODO(native-bridge): Replace with actual generation call.
      //   1. Python orchestration: expand prompt, assemble negative,
      //      merge LoRA weights, pick sampler schedule.
      //   2. C++ FFI: native_generate() with progress callback.
      //   3. VAE decode happens in C++ (or Python for exotic VAEs).
      debugPrint(
        '[NativeImageBackend] TODO: generate("${params.prompt.substring(0, params.prompt.length.clamp(0, 40))}...") '
        '— bridge not yet implemented',
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
      throw NativeEngineException(
        'Native image engine not yet implemented. '
        'The bridge (C++ FFI + Python orchestration) is stubbed.',
      );
    } finally {
      if (_status == NativeEngineStatus.generating) {
        _setStatus(NativeEngineStatus.ready);
      }
    }
  }

  /// Unload the current model, freeing VRAM.
  ///
  /// TODO(platform): C++ FFI call: native_unload_model().
  ///   Must ensure all tensors are freed before returning — no split
  ///   CPU/GPU allocations left behind (the bug the old backend hit
  ///   on Windows/nVidia).
  Future<void> unloadModel() async {
    if (_loadedModelPath == null) return;
    // TODO(native-bridge): Replace with actual FFI call.
    debugPrint(
      '[NativeImageBackend] TODO: unloadModel() — bridge not yet implemented',
    );
    _loadedModelPath = null;
    _setStatus(NativeEngineStatus.idle, 'Model unloaded.');
  }

  /// Free VRAM without fully unloading (for model swaps).
  /// Maps to the old `nudgeComfyFree` — hints the engine to release
  /// cached tensors before loading a different model.
  ///
  /// TODO(platform): C++ FFI call: native_free_cache().
  Future<void> freeMemory() async {
    // TODO(native-bridge): Replace with actual FFI call.
    debugPrint(
      '[NativeImageBackend] TODO: freeMemory() — bridge not yet implemented',
    );
  }

  /// List available model files in the user's image-models folder.
  /// Pure Dart directory scan (no FFI, no server): finds .safetensors,
  /// .gguf and .ckpt files, recursively, and returns their file names —
  /// the same shape the old server discovery returned.
  Future<List<String>> listModels() async {
    final root = _modelsDir?.call() ?? '';
    if (root.isEmpty) return const [];
    final dir = Directory(root);
    if (!await dir.exists()) return const [];
    final names = <String>[];
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final lower = entity.path.toLowerCase();
      if (lower.endsWith('.safetensors') ||
          lower.endsWith('.gguf') ||
          lower.endsWith('.ckpt')) {
        names.add(path.basename(entity.path));
      }
    }
    names.sort();
    return names;
  }

  /// Cancel the in-progress generation, if any.
  void cancel() {
    if (_status == NativeEngineStatus.generating) {
      // TODO(native-bridge): Set the cancel token the C++ side polls.
      _setStatus(NativeEngineStatus.ready, 'Cancelled.');
    }
  }
}

/// Exception thrown by the native image backend.
class NativeEngineException implements Exception {
  const NativeEngineException(this.message);
  final String message;

  @override
  String toString() => 'NativeEngineException: $message';
}
