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
// along with this program. If not, see <https://www.gnu.org/licenses/>.

// Queue, dual-engine VRAM arbitration, and per-session teardown for
// [ImageGenService]. Same library, so this extension sees the class's
// private members. Split out to keep the main file under the 500-line
// god-file ratchet. Queue state fields stay on the class itself
// (extensions cannot declare instance fields).

part of 'image_gen_service.dart';

/// One entry in the image generation queue.
class _ImageQueueEntry {
  _ImageQueueEntry(this.sessionId) : turn = Completer<void>();

  /// Server login session this generation belongs to, or null for the
  /// local desktop (which has no session and is never torn down).
  final String? sessionId;

  /// Completed when this entry reaches the head of the queue.
  final Completer<void> turn;

  /// Set by [ImageGenService.teardownEngineSession]; the entry is
  /// skipped instead of run when its turn comes.
  bool cancelled = false;
}

/// Queue, arbitration, and session-teardown members of [ImageGenService].
extension ImageGenServiceQueue on ImageGenService {
  /// Drop this session's WAITING image generations (a running one is
  /// left to finish — cancelling mid-flight risks backend state).
  /// Dropped entries are removed from the queue and woken so their
  /// futures resolve null instead of hanging on a turn that will never
  /// come. Called when a server login session ends.
  void teardownEngineSession(String sessionId) {
    var dropped = 0;
    final doomed = _imageQueue.where((e) => e.sessionId == sessionId).toList();
    for (final entry in doomed) {
      entry.cancelled = true;
      _imageQueue.remove(entry);
      dropped++;
      // Wake it so its future resolves (null, via the cancelled check).
      if (!entry.turn.isCompleted) entry.turn.complete();
    }
    if (dropped > 0) {
      debugPrint(
        '[ImageGen] session ended: $dropped queued generation(s) dropped.',
      );
      _notify();
    }
    _pumpImageQueue();
  }

  /// Wake the head waiter when no generation is running, keeping the queue
  /// moving after a direct-path generation finishes or a session teardown
  /// drops entries. The head entry stays in [_imageQueue] until its own
  /// finally removes it, so a newcomer racing the handoff still sees a
  /// non-empty queue and enqueues behind it instead of starting a second
  /// concurrent generation.
  void _pumpImageQueue() {
    if (_isGenerating || _imageQueue.isEmpty) return;
    final head = _imageQueue.first;
    if (!head.turn.isCompleted) head.turn.complete();
  }

  /// Run [job] when its turn comes. Waiters are woken in FIFO order; the
  /// handoff keeps [_isGenerating] true across jobs (the pump, not the
  /// job, owns the flag between turns) so a newcomer can't jump the queue
  /// in the microtask gap. Entries cancelled by a session teardown are
  /// skipped without running.
  Future<Uint8List?> _enqueueImageJob(
    Future<Uint8List?> Function() job, {
    String? sessionId,
  }) async {
    final entry = _ImageQueueEntry(sessionId);
    _imageQueue.add(entry);
    _statusMessage =
        'Queued for image generation (position ${_imageQueue.length}).';
    _notify();
    await entry.turn.future;
    try {
      if (entry.cancelled) return null;
      return await job();
    } finally {
      _imageQueue.remove(entry);
      _pumpImageQueue();
    }
  }

  /// Harness-budget pressure on the image path: when the app is over its
  /// memory budget, the idle text engine unloads first (the same unload
  /// the idle timer uses). The generation itself is never refused for
  /// memory — the backpressure queue holds it until there is room.
  Future<void> _releaseForHarnessBudget(ImageGenBackend backend) async {
    if (backend == ImageGenBackend.remote) return;
    final kobold = _koboldService;
    if (kobold == null) return;
    final budget = _storage.engineResourcesSettings.totalMemoryBudgetMb;
    if (MemoryBudget.estimateNow().fitsInBudget(budget)) return;
    final usedMb = MemoryBudget.estimateNow().totalMb;
    debugPrint(
      '[Memory] over harness budget '
      '(${(usedMb / 1024).toStringAsFixed(1)}GB > '
      '${(budget / 1024).toStringAsFixed(1)}GB), unloading idle text engine',
    );
    await kobold.unloadForEngineHandoff();
  }

  /// Dual-engine VRAM arbitration, run when a LOCAL image generation
  /// starts. If KoboldCpp holds its model and free VRAM is below what an
  /// image model needs, unload the text engine first — the next text
  /// request loads it back transparently. Remote backends use no local
  /// VRAM and skip this entirely.
  Future<void> _arbitrateVramForImage(ImageGenBackend backend) async {
    if (backend == ImageGenBackend.remote) return;
    final kobold = _koboldService;
    final hw = _hardwareService;
    if (kobold == null || hw == null) return;
    if (kobold.phase != KoboldPhase.ready) return;
    FreeMemoryMb free;
    try {
      free = await hw.readFreeMemory();
    } catch (e) {
      debugPrint('[ImageGen] VRAM read failed, skipping arbitration: $e');
      return;
    }
    // Headroom a local image model wants free before it unloads the text
    // engine to make room — a setting now, so the threshold is visible and
    // tunable instead of a hardcoded constant.
    final headroomMb = _storage.engineResourcesSettings.imageModelHeadroomMb;
    if ((free.graphics ?? 0) >= headroomMb) return;
    _statusMessage = 'Freeing graphics memory from the text engine…';
    _notify();
    final unloaded = await kobold.unloadForEngineHandoff();
    debugPrint(
      '[ImageGen] VRAM arbitration: text-engine unload '
      '${unloaded ? 'done' : 'not needed'}; '
      'free VRAM was ${free.graphics} MB.',
    );
  }

  /// Park image weights back in RAM after a local generation, when the
  /// placement knob asks for it. Best-effort: unsupported servers ignore
  /// the call.
  Future<void> _parkImageWeights(ImageGenBackend backend) async {
    if (_storage.engineResourcesSettings.imageWeights !=
        EngineMemoryPlacement.ram) {
      return;
    }
    try {
      switch (backend) {
        case ImageGenBackend.comfyUi:
        case ImageGenBackend.native:
          await _nativeBackend?.freeMemory();
        case ImageGenBackend.a1111:
        case ImageGenBackend.drawThings:
          final url = _storage.imageGenSettings.localImageGenUrl;
          if (url.isNotEmpty) await unloadLocalModel(url);
        case ImageGenBackend.remote:
          break;
      }
    } catch (e) {
      debugPrint('[ImageGen] park weights failed (ignored): $e');
    }
  }

  /// Generate an image from a prompt.
  ///
  /// Routes to the configured remote API (OpenRouter, Nano-GPT, etc.).
  ///
  /// Returns the image bytes on success, or null on failure.
  Future<Uint8List?> _generateImageQueueImpl({
    required String prompt,
    String? negativePrompt,
    String? size,
    Uint8List?
    referenceImage, // img2img reference: honored by all three local backends
    // (Draw Things, A1111, ComfyUI) at imageGenDenoise strength; remote APIs
    // have no img2img endpoint here, so they ignore it.
    String? model,
    bool isPortrait = false,
    // Per-call overrides for the stored seed/denoise settings; used by batch
    // flows (expression packs) that need a shared fixed seed and fixed denoise
    // across every image without touching the user's persisted settings.
    // Remote APIs ignore them (no seed/denoise support on those endpoints).
    int? seed,
    double? denoise,
    // Which surface asked. Create (default) keeps every existing path
    // byte-identical; Edit routes an edit-capable model to edit-conditioning
    // and resolves the EDIT model slot. Passed by the Studio's Edit tab and
    // by edit-first expression packs (Studio dialog + the creator panel).
    StudioIntent intent = StudioIntent.create,
    // Edit-only: how strongly the instruction changes the reference (higher =
    // more change). Overrides the edit profile's default strength when set, so
    // the Edit tab can offer a "how much should change" control. Ignored outside
    // the edit path.
    double? editStrength,
    // Server login session this generation belongs to (null = the local
    // desktop). A session teardown drops this session's waiting queue
    // entries; used by the server edition, always null on desktop.
    String? sessionId,
  }) async {
    // Backpressure: when "Never drop a generation" is on, a generation that
    // arrives while one is running (or waiting) queues FIFO instead of being
    // refused. When off, the previous behaviour stands: _generateImageImpl
    // refuses the overlap. Pack flights bypass the queue — they hold the
    // lock for their whole run via fromPack.
    if (_storage.engineResourcesSettings.queueWithBackpressure &&
        (_isGenerating || _imageQueue.isNotEmpty)) {
      return _enqueueImageJob(
        () => _generateImageImpl(
          prompt: prompt,
          negativePrompt: negativePrompt,
          size: size,
          referenceImage: referenceImage,
          model: model,
          isPortrait: isPortrait,
          seed: seed,
          denoise: denoise,
          intent: intent,
          editStrength: editStrength,
        ),
        sessionId: sessionId,
      );
    }
    try {
      return await _generateImageImpl(
        prompt: prompt,
        negativePrompt: negativePrompt,
        size: size,
        referenceImage: referenceImage,
        model: model,
        isPortrait: isPortrait,
        seed: seed,
        denoise: denoise,
        intent: intent,
        editStrength: editStrength,
      );
    } finally {
      // A direct-path generation finishing is what unblocks the queue:
      // wake the head waiter, if any.
      _pumpImageQueue();
    }
  }
}
