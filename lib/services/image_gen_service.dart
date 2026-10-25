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

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:front_porch_ai/services/storage_service.dart';
import 'package:front_porch_ai/services/storage/storage.dart';
import 'package:front_porch_ai/services/llm_service.dart';
import 'package:front_porch_ai/services/kobold_service.dart';
import 'package:front_porch_ai/services/hardware_service.dart';
import 'package:front_porch_ai/services/memory_budget.dart';
import 'package:front_porch_ai/services/grpc/draw_things_grpc_service.dart';
import 'package:front_porch_ai/services/image_prompt/image_prompt.dart';
import 'package:front_porch_ai/services/image/image.dart';
import 'package:front_porch_ai/services/capability/capability.dart';

// ImageGenMode / ImageGenBackend / ImageModelInfo now live in the pure leaf
// image/image_gen_types.dart (imported above via the image/ barrel);
// re-exported so every existing importer of this file stays unaffected.
export 'image/image_gen_types.dart';

part 'image_gen_service.generate.dart';
part 'image_gen_service.queue.dart';
part 'image_gen_service.studio.dart';
part 'image_gen_service.prompt.dart';
part 'image_gen_service.local_admin.dart';
part 'image_gen_service.backends.dart';
part 'image_gen_service.backends.generate.dart';
part 'image_gen_service.catalog.dart';
part 'image_gen_service.nano_models.dart';
part 'image_gen_service.payload.dart';
part 'image_gen_service.native.dart';
part 'image_gen_service.clients.dart';

/// Service for generating images via the remote API. Studio's host is
/// [ImageGenSettings.imageRemoteApiUrl] (Nano / OpenRouter chips); keys
/// still come from [RemoteApiKeyVault]. Chat's mouth URL is not rewritten.
///
/// Split-god-file shell: the 19 members the 3 protected test fakes
/// `implements ImageGenService` override stay literal instance members here
/// (9 as one-line stubs into `_xImpl` parts); everything unfaked moved out.
class ImageGenService extends ChangeNotifier {
  final StorageService _storage;

  bool _isGenerating = false;

  /// True while [startExpressionPack] holds the lock, so the frames it runs
  /// can go through it without refusing themselves.
  bool _packFlight = false;
  String _statusMessage = '';
  Uint8List? _lastGeneratedImage;
  String? _lastSavedPath;

  /// Live generation progress (0..1) and the latest in-progress preview
  /// frame, so the UI can show the image "coming to life" instead of a
  /// spinner. Fed per backend: A1111 polls /sdapi/v1/progress (percent +
  /// preview), ComfyUI streams its WebSocket (percent + preview when the
  /// server has previews enabled), Draw Things reports sampling steps
  /// (percent only). Remote APIs return in one shot — both stay null there
  /// (indeterminate). Cleared at the start and end of every generation.
  double? _genProgress;
  Uint8List? _genPreview;
  double? get genProgress => _genProgress;
  Uint8List? get genPreview => _genPreview;

  void _updateGenProgress(double? progress, [Uint8List? preview]) {
    _genProgress = progress;
    if (preview != null) _genPreview = preview;
    notifyListeners();
  }

  // Extensions can't call @protected notifyListeners(); this is the forwarder.
  void _notify() => notifyListeners();

  /// The checkpoint name that is currently loaded on the local A1111 server.
  /// Used to skip redundant unload→reload cycles that can leave tensors
  /// split across CPU and CUDA on Windows/nVidia setups.
  String? _lastLoadedCheckpoint;

  bool get isGenerating => _isGenerating;
  String get statusMessage => _statusMessage;
  Uint8List? get lastGeneratedImage => _lastGeneratedImage;
  String? get lastSavedPath => _lastSavedPath;

  /// Whether image gen is configured and ready to use.
  bool get isConfigured => _isConfiguredImpl;

  DrawThingsGrpcService? _drawThingsGrpc;

  /// Built-in native image backend. Replaces the old ComfyUI server client.
  /// In-process: no HTTP, no server, no ports.
  NativeImageBackend? _nativeBackend;

  // Thin delegation hook for prompt construction.
  // Full ownership of ImageGenContext mapping semantics, mode contracts
  // (no-personality portraits, and customPrompt's scene-distillation fallback
  // when the prompt is empty but recent chat narrative is present), style
  // enforcement, LLM smart path, and static fallbacks lives in ImagePromptBuilder.
  // Keep prompt blocks in sync: changes to ctx construction here must be mirrored in
  // any direct ImageGenContext sites and the builder's own
  // _buildStatic / buildPrompt / _generateSmartWith. The builder is stateless/prompt-only
  // (no reset calls needed). ImageGenService owns no prompt scalars that require zeroing
  // on chat startNew / setActive / load (per-call snapshot from _storage is authoritative).
  // See ImagePromptBuilder for the authoritative mode semantics and style rules.
  late final ImagePromptBuilder _promptBuilder = ImagePromptBuilder();

  ImageGenService(this._storage);

  /// The text engine, wired by the app shell (see main.dart). Used for
  /// dual-engine VRAM arbitration: image generation unloads KoboldCpp's
  /// model first when VRAM is tight. Null until wired or in tests.
  KoboldService? _koboldService;

  /// Hardware readings for arbitration. Null until wired or in tests.
  HardwareService? _hardwareService;

  /// Wire collaborators. Follows the setImageGenService pattern.
  void setKoboldService(KoboldService service) => _koboldService = service;
  void setHardwareService(HardwareService service) =>
      _hardwareService = service;

  /// FIFO of image generations waiting for the running one. Only used
  /// when "Never drop a generation" is on; otherwise a busy engine
  /// refuses (the previous behaviour). Entries carry an optional
  /// session id so a server login teardown can drop its own waiting
  /// jobs (see image_gen_service.queue.dart).
  final Queue<_ImageQueueEntry> _imageQueue = Queue();

  /// Generations running or waiting, for the engine health row.
  int get imageQueueDepth => _imageQueue.length + (_isGenerating ? 1 : 0);

  /// Best-effort ComfyUI VRAM nudge before a create→edit model swap (the
  /// creator pack's "Switching to edit model" stage). No-op on every other
  /// backend — DT/remote load-unload per request on their own.
  Future<void> nudgeComfyFree() => _nudgeComfyFreeImpl();

  /// Generate an image from a prompt.
  ///
  /// Instance-member stub (see class doc): the test fakes override this, so
  /// it must stay a literal instance member for virtual dispatch. Delegates
  /// to [_generateImageQueueImpl] in image_gen_service.queue.dart.
  Future<Uint8List?> generateImage({
    required String prompt,
    String? negativePrompt,
    String? size,
    Uint8List? referenceImage,
    String? model,
    bool isPortrait = false,
    int? seed,
    double? denoise,
    StudioIntent intent = StudioIntent.create,
    double? editStrength,
    String? sessionId,
  }) => _generateImageQueueImpl(
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
    sessionId: sessionId,
  );

  /// Fetch available image models.
  ///
  /// Behavior depends on which API backend is configured:
  ///
  /// **OpenRouter** (detected by URL containing "openrouter.ai"):
  /// - Calls `/models?output_modalities=image` to get real image-capable models
  /// - Returns what OpenRouter provides (includes pricing info from their API)
  /// - If API fails: returns empty list with error logged
  ///
  /// **Nano-GPT and others**:
  /// - GET `{apiUrl}/image-models`. A failed or empty response falls back
  ///   to the bundled snapshot in `_commonImageModels`.
  Future<List<ImageModelInfo>> fetchImageModels() async {
    final account = _imageRemoteAccount;
    final apiUrl = account.url;
    final apiKey = account.key;
    // No account = no models. This used to fall back to the curated catalog,
    // which is how the Remote API option showed a real-looking model menu to
    // a user with no key configured at all — who reasonably concluded the
    // whole thing was free and ready, then hit "No API key configured." on
    // Generate (maintainer report, 2026-08-13). The bundled list is the
    // offline fallback for a CONFIGURED provider whose listing fetch fails,
    // never a stand-in for having an account.
    if (apiUrl.isEmpty || apiKey.isEmpty) return const [];

    if (_isOpenRouterStyle(apiUrl)) {
      return _fetchOpenRouterImageModels(apiUrl, apiKey);
    }
    return _fetchNanoImageModels(apiUrl, apiKey);
  }

  /// Available style labels for UI display.
  static const Map<String, String> styleLabels = {
    'photorealistic': 'Photorealistic',
    'anime': 'Anime / Manga',
    'fantasy_art': 'Fantasy Art',
    'oil_painting': 'Oil Painting',
    'digital_art': 'Digital Art',
    'watercolor': 'Watercolor',
  };

  /// Use the active LLM to craft a concise, effective image prompt from raw context.
  ///
  /// Thin delegation to ImagePromptBuilder — see there for mode semantics and style rules
  /// (portrait = appearance + expression only; customPrompt = the user's text verbatim, or,
  /// when that text is empty, a distilled visualization of the current scene from the
  /// supplied recent chat narrative; style enforcement for both paradigms, etc.).
  /// Keep prompt blocks in sync with ImagePromptBuilder (and ctx construction in call sites
  /// like chat_page._showImageGenDialog and the /image slash command). Builder is stateless/prompt-only.
  ///
  /// The flat params are assembled into a typed [ImageGenContext] by the tiny pure helper
  /// [_buildPromptContext] (data-bag assembly + the custom-vs-lastMessage rule only — zero
  /// prompt/distillation/style/LLM logic, which all lives in ImagePromptBuilder).
  ///
  /// [userInstruction] is free text the user typed in the studio box before Craft; it is
  /// forwarded to the LLM as extra guidance so it "parses into the image prompt".
  Future<String> generateSmartPrompt({
    required ImageGenMode mode,
    required String style,
    LLMService? llmService,
    String? customPrompt,
    String? lastMessage,
    String? characterName,
    String? characterDescription,
    String?
    characterPersonality, // kept for signature compatibility during transition (ignored for visuals)
    String? scenario,
    String? worldInfo,
    String? personaName,
    String? personaText,
    List<String>? recentMessages,
    // Stage 4: richer optional fields for better prompts (expression/pose, time/lighting, group speaker targeting).
    // Forwarded to thin ctx builder. Keep in sync with buildPrompt sig, _buildPromptContext, studio craft/ctor/show, chat_page launch.
    String? currentExpression,
    String? timeOfDay,
    String? lightingHint,
    bool isGroupNonObserver = false,
    String? currentSpeakerId,
    // Text the user typed in the studio box pre-Craft (passed to the LLM as an
    // instruction to "parse into" the image prompt).
    String? userInstruction,
  }) => _generateSmartPromptImpl(
    mode: mode,
    style: style,
    llmService: llmService,
    customPrompt: customPrompt,
    lastMessage: lastMessage,
    characterName: characterName,
    characterDescription: characterDescription,
    characterPersonality: characterPersonality,
    scenario: scenario,
    worldInfo: worldInfo,
    personaName: personaName,
    personaText: personaText,
    recentMessages: recentMessages,
    currentExpression: currentExpression,
    timeOfDay: timeOfDay,
    lightingHint: lightingHint,
    isGroupNonObserver: isGroupNonObserver,
    currentSpeakerId: currentSpeakerId,
    userInstruction: userInstruction,
  );

  /// Test whether a local image-gen server is reachable.
  ///
  /// For Draw Things, uses gRPC. For ComfyUI, GET /system_stats. For A1111,
  /// GET /sdapi/v1/sd-models.
  Future<bool> testLocalConnection(String baseUrl) =>
      _testLocalConnectionImpl(baseUrl);

  /// Fetch available checkpoints from an A1111 / Draw Things server.
  ///
  /// For Draw Things, uses gRPC. For A1111, uses HTTP.
  Future<List<String>> fetchA1111Models(String baseUrl) =>
      _fetchA1111ModelsImpl(baseUrl);

  /// Fetch models from a Draw Things server.
  ///
  /// Uses the Draw Things gRPC CLI to fetch available .ckpt models (via the
  /// special Echo('models') response). LoRAs come from [fetchDrawThingsLoras].
  Future<List<String>> fetchDrawThingsModels(String baseUrl) async {
    try {
      final grpcService = _ensureDrawThingsGrpc;
      return await grpcService.fetchModels();
    } catch (e) {
      debugPrint('ImageGen: fetchDrawThingsModels failed: $e');
      return [];
    }
  }

  /// `custom.json` version of each local checkpoint. The passed URL is
  /// ignored; the host comes from settings, same as [fetchDrawThingsLoras].
  Future<Map<String, String>> fetchDrawThingsModelVersions(
    String baseUrl,
  ) async {
    try {
      return await _ensureDrawThingsGrpc.fetchModelVersions();
    } catch (e) {
      debugPrint('ImageGen: fetchDrawThingsModelVersions failed: $e');
      return const {};
    }
  }

  /// Fetch LoRA files from a Draw Things server (gRPC CLI op 'loras' — the
  /// same Echo('models') listing as [fetchDrawThingsModels], filtered to
  /// LoRAs). The selected name is applied natively via the generation config.
  ///
  /// Draw Things records the base model on each LoRA in `custom_lora.json`
  /// (`version`). That id is passed as metadata so the picker can keep the
  /// checkpoint's family and tuck the other bases away. A bare file name is
  /// still only a guess.
  Future<List<LoraOption>> fetchDrawThingsLoras(String baseUrl) async {
    try {
      final grpcService = _ensureDrawThingsGrpc;
      final rows = await grpcService.fetchLoras();
      return [
        for (final row in rows)
          ImageModelFamily.classifyLora(
            row.file,
            metadata: row.version.isEmpty
                ? null
                : {'dt_base_model': row.version},
          ),
      ];
    } catch (e) {
      debugPrint('ImageGen: fetchDrawThingsLoras failed: $e');
      return [];
    }
  }

  /// Native backend model discovery — lists model files from the configured
  /// model directories. Replaces the old ComfyUI /object_info discovery.
  /// [baseUrl] is ignored (kept for signature compatibility).
  Future<List<String>> fetchComfyModels(String baseUrl) =>
      _ensureNative.listModels();

  /// Model catalog from the native backend's model directories.
  /// [baseUrl] is ignored (kept for signature compatibility).
  Future<ComfyFileCatalog> fetchComfyCatalog(String baseUrl) async {
    final models = await _ensureNative.listModels();
    return ComfyFileCatalog(checkpoints: models);
  }

  /// Workflow templates do not exist in the native backend.
  /// Returns empty. [baseUrl] is ignored (kept for signature compatibility).
  Future<List<dynamic>> fetchComfyCreateTemplates(String baseUrl) async => [];

  /// LoRAs from the native backend's model directories.
  /// [baseUrl] is ignored (kept for signature compatibility).
  Future<List<LoraOption>> fetchComfyLoras(String baseUrl) async {
    final models = await _ensureNative.listModels();
    final loraFiles = models
        .where((m) => m.toLowerCase().contains('lora'))
        .toList();
    return loraFiles.map((n) => ImageModelFamily.classifyLora(n)).toList();
  }

  /// Samplers supported by the native backend.
  /// [baseUrl] is ignored (kept for signature compatibility).
  Future<List<String>> fetchComfySamplers(String baseUrl) async => const [
    'euler',
    'euler_ancestral',
    'dpmpp_2m',
    'dpmpp_sde',
    'ddim',
  ];

  /// Schedulers supported by the native backend.
  /// [baseUrl] is ignored (kept for signature compatibility).
  Future<List<String>> fetchComfySchedulers(String baseUrl) async => const [
    'normal',
    'karras',
    'exponential',
    'sgm_uniform',
  ];

  /// Fetch LoRAs from an A1111 / Forge / SD.Next server, enriched with
  /// base-model family.
  ///
  /// Endpoint: GET /sdapi/v1/loras — each entry carries a `metadata` block that
  /// usually includes `ss_base_model_version` / `modelspec.architecture`, which
  /// gives an authoritative family (this is the same field A1111's own UI uses).
  /// When a LoRA exposes no metadata we fall back to file-name detection.
  /// Draw Things uses [fetchDrawThingsLoras] instead (no HTTP endpoint).
  Future<List<LoraOption>> fetchA1111Loras(String baseUrl) =>
      _fetchA1111LorasImpl(baseUrl);

  /// Unload the currently active model from memory on a local server.
  ///
  /// Calls `POST /sdapi/v1/unload-checkpoint` (standard A1111 endpoint).
  /// Draw Things may support this via its A1111-compat layer.
  /// If the server doesn't support it the error is silently ignored —
  /// model switching via [switchLocalModel] will still proceed.
  ///
  /// Returns true if the server acknowledged the unload (HTTP 200).
  Future<bool> unloadLocalModel(String baseUrl) =>
      _unloadLocalModelImpl(baseUrl);

  /// Best-effort memory release for the harness budget: when no generation
  /// is running, ask the local image server to drop its weights from VRAM
  /// (ComfyUI /free, A1111 / Draw Things unload-checkpoint). Remote
  /// backends hold nothing local. Returns true when anything was released.
  /// Used by the budget gate before a text-engine start and the Settings
  /// "Free up memory" button — never mid-generation.
  Future<bool> releaseMemoryForBudget() async {
    if (_isGenerating) return false;
    final backend = ImageGenBackend.fromKey(
      _storage.imageGenSettings.imageGenBackend,
    );
    try {
      switch (backend) {
        case ImageGenBackend.comfyUi:
        case ImageGenBackend.native:
          await _nativeBackend?.freeMemory();
        case ImageGenBackend.a1111:
        case ImageGenBackend.drawThings:
          final url = _storage.imageGenSettings.localImageGenUrl;
          if (url.isEmpty) return false;
          await unloadLocalModel(url);
        case ImageGenBackend.remote:
          return false;
      }
    } catch (e) {
      debugPrint('[Memory] image weight release failed: $e');
      return false;
    }
    MemoryBudget.clearEngine(MemoryBudget.imageEngine);
    debugPrint('[Memory] image engine weights released for the budget.');
    return true;
  }

  /// Switch the active checkpoint on a local A1111 / Draw Things server.
  ///
  /// Sequence:
  ///   1. `POST /sdapi/v1/unload-checkpoint` — free current model from memory
  ///      (silently ignored if not supported by the server)
  ///   2. `POST /sdapi/v1/options` with the new model name — trigger model load
  ///   3. Poll `GET /sdapi/v1/options` to confirm the model is fully loaded
  ///      on the GPU before returning, preventing tensor device mismatches.
  ///
  /// Returns true if the model was successfully switched and confirmed ready.
  Future<bool> switchLocalModel(String baseUrl, String modelName) =>
      _switchLocalModelImpl(baseUrl, modelName);

  /// Fetch available samplers from an A1111 / Draw Things server.
  ///
  /// Endpoint: GET /sdapi/v1/samplers
  /// Returns sampler names (the `name` field from each entry).
  Future<List<String>> fetchA1111Samplers(String baseUrl) =>
      _fetchA1111SamplersImpl(baseUrl);

  /// Fetch available schedulers from an A1111 / Forge / SD.Next server.
  ///
  /// Endpoint: GET /sdapi/v1/schedulers
  /// Returns scheduler names (the `name` field from each entry). Older forks
  /// (and Draw Things' A1111 shim) predate this endpoint and answer 404 — that
  /// degrades silently to an empty list, so the UI simply offers only
  /// 'Automatic' there.
  Future<List<String>> fetchA1111Schedulers(String baseUrl) =>
      _fetchA1111SchedulersImpl(baseUrl);

  /// Build the AUTOMATIC1111 generation payload shared by the txt2img and
  /// img2img endpoints. Pure — unit-tested. When [referenceImageB64] is
  /// non-null/non-empty the caller must POST to `/sdapi/v1/img2img`, and this
  /// adds `init_images` + `denoising_strength` ([denoise]); otherwise it is a
  /// plain txt2img payload for `/sdapi/v1/txt2img`.
  static Map<String, dynamic> buildA1111Payload({
    required String prompt,
    required String negativePrompt,
    required int width,
    required int height,
    required int steps,
    required double cfgScale,
    required String samplerName,
    required String scheduler,
    required int seed,
    String? referenceImageB64,
    double denoise = 0.5,
  }) => _buildA1111PayloadImpl(
    prompt: prompt,
    negativePrompt: negativePrompt,
    width: width,
    height: height,
    steps: steps,
    cfgScale: cfgScale,
    samplerName: samplerName,
    scheduler: scheduler,
    seed: seed,
    referenceImageB64: referenceImageB64,
    denoise: denoise,
  );
}
