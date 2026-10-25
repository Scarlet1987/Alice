// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

part of 'studio_desk.dart';

extension on _StudioDeskState {
  ImageGenService? _service() {
    try {
      return context.read<ImageGenService>();
    } on ProviderNotFoundException {
      return null;
    }
  }

  void _applyCatalog({
    List<String> models = const [],
    List<String> loras = const [],
    List<String> clips = const [],
    List<String> vaes = const [],
    List<String> samplers = const [],
    List<String> schedulers = const [],
    bool remoteListed = false,
    String? url,
  }) {
    rebuildState(() {
      _models = models;
      _loras = loras;
      _clips = clips;
      _vaes = vaes;
      _samplers = samplers;
      _schedulers = schedulers;
      _remoteListed = remoteListed;
      _catalogUrl = url;
    });
  }

  void _rememberLoraFacts(
    Map<String, DeskLoraCheck> facts, {
    Map<String, String> dtLoraVersions = const {},
    Map<String, String> dtModelVersions = const {},
  }) {
    rebuildState(() {
      _loraFacts = facts;
      _dtLoraVersions = dtLoraVersions;
      _dtModelVersions = dtModelVersions;
    });
    _checkReady();
  }

  /// Lists what the connected backend has. Reading never writes a setting.
  Future<void> _refreshCatalog(
    ImageGenSettings settings, {
    bool force = false,
  }) async {
    final backend = settings.imageGenBackend;
    if (backend == 'a1111' || backend == 'drawthings') {
      await _refreshLocal(settings, force: force);
    } else if (backend == 'comfyui') {
      await _refreshComfy(settings, force: force);
    } else if (backend == 'remote') {
      await _refreshRemote(settings, force: force);
    }
  }

  Future<void> _refreshLocal(
    ImageGenSettings settings, {
    required bool force,
  }) async {
    final drawThings = settings.imageGenBackend == 'drawthings';
    final url = drawThings
        ? '${settings.drawThingsGrpcHost}:${settings.drawThingsGrpcPort}'
        : settings.localImageGenUrl;
    if (!force && _catalogUrl == url) return;
    final gen = _service();
    if (gen == null) return;
    final up = force ? await gen.testLocalConnection(url) : true;
    final models = !up
        ? const <String>[]
        : drawThings
        ? await _listedDrawThingsModels(gen, url)
        : await _listedA1111Models(gen, url);
    var listing = const DrawThingsLoraListing();
    var modelVersions = const <String, String>{};
    if (up && drawThings) {
      listing = drawThingsLoraListing(await gen.fetchDrawThingsLoras(url));
      modelVersions = await gen.fetchDrawThingsModelVersions(url);
    }
    final samplers = up && !drawThings
        ? await gen.fetchA1111Samplers(url)
        : const <String>[];
    final schedulers = up && !drawThings
        ? await gen.fetchA1111Schedulers(url)
        : const <String>[];
    // Automatic1111's own LoRA list, so the slots can be filled from it.
    // A server lists the LoRAs it found at start, so a re-check (and a finished
    // download) asks it to look at the folder again before listing.
    if (force && up && !drawThings) await gen.refreshA1111Loras(url);
    final a1111Loras = up && !drawThings
        ? [for (final l in await gen.fetchA1111Loras(url)) l.name]
        : const <String>[];
    if (!mounted) return;
    _applyCatalog(
      models: models,
      loras: drawThings ? listing.names : a1111Loras,
      samplers: samplers,
      schedulers: schedulers,
      url: force ? (up ? 'up:$url' : 'down:$url') : url,
    );
    if (drawThings) {
      _rememberLoraFacts(
        listing.facts,
        dtLoraVersions: listing.versions,
        dtModelVersions: modelVersions,
      );
    }
  }

  /// No-op: the ComfyUI server catalog is gone. The native backend lists
  /// local model files directly.
  Future<void> _refreshComfy(
    ImageGenSettings settings, {
    required bool force,
  }) async {
    return;
  }

  /// The Remote API's image models, for the host chosen on the stove.
  Future<void> _refreshRemote(
    ImageGenSettings settings, {
    required bool force,
  }) async {
    final url = settings.imageRemoteApiUrl;
    if (!force && _catalogUrl == url) return;
    _catalogUrl = url;
    final gen = _service();
    if (gen == null) return;
    final listed = await gen.fetchImageModels();
    if (!mounted) return;
    _applyCatalog(
      models: [for (final model in listed) model.id],
      remoteListed: listed.isNotEmpty,
      url: url,
    );
  }
}
