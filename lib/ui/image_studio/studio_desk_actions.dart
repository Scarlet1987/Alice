// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

part of 'studio_desk.dart';

/// What the person does on the desk. Every write here answers a tap; nothing
/// in `build` or in a passive read calls these.
extension on _StudioDeskState {
  /// Fills the graph's empty text-encoder and VAE slots from the installed
  /// files. A slot that holds a file is left as it is.
  Future<void> _fillSupport(
    ImageGenSettings settings,
    List<dynamic> slots,
  ) async {
    // No-op: the native backend has no workflow graph slots to fill.
    return;
  }

  /// Picks the primary model. The native backend takes the file directly;
  /// no workflow graph involved.
  Future<void> _pickModel(ImageGenSettings settings, String file) async {
    if (_configurationLocked) return;
    if (settings.imageGenBackend == 'remote') {
      await settings.setRemoteImageModelFor(
        settings.imageRemoteApiUrl,
        file,
        edit: _editing,
      );
      return;
    }
    if (_editing) {
      await settings.setImageGenEditModel(file);
    } else {
      await settings.setImageGenModel(file);
    }
  }

  Future<void> _openModels(ImageGenSettings settings, {String? token}) {
    final primary = studioPrimaryFor(settings, edit: _editing);
    final role = token == null
        ? ''
        : token.contains('VAE')
        ? 'VAE'
        : token.contains('CLIP')
        ? 'Text encoder'
        : '';
    final pool = role == 'VAE'
        ? _vaes
        : role == 'Text encoder'
        ? _clips
        : _models;
    // A name is a guess, so nothing is hidden: files that look wrong for
    // this model are listed last and marked.
    final unfit = role.isEmpty
        ? const <String>{}
        : {
            for (final file in pool)
              if (!supportFileFits(primary: primary, file: file, role: role))
                file,
          };
    final items = [
      for (final file in pool)
        if (!unfit.contains(file)) file,
      for (final file in pool)
        if (unfit.contains(file)) file,
    ];
    return showDialog<void>(
      context: context,
      builder: (context) => StudioModelSheet(
        edit: _editing,
        items: items,
        unfit: unfit,
        onPick: (file) {
          if (_configurationLocked) return;
          _pickModel(settings, file);
        },
      ),
    );
  }

  /// No-op: GGUF loader support was a ComfyUI concept.
  Future<void> _useExistingLoaderSupport(ImageGenSettings settings) async {
    return;
  }

  /// No-op: loader updates were a ComfyUI concept.
  Future<void> _updateLoader(ImageGenSettings settings) async {
    return;
  }

  Future<void> openGraphs(ImageGenSettings settings) async {
    // No-op: the native backend has no workflow graphs. The model is picked
    // directly via Change model.
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(
        content: Text('The built-in engine picks models directly — no graphs.'),
      ),
    );
  }

  Future<void> openLoras(ImageGenSettings settings, String primary) {
    return showDialog<void>(
      context: context,
      builder: (context) => StudioLoraSheet(
        slots: settings.imageGenLoraSlots,
        files: deskLoraFiles(
          backend: settings.imageGenBackend,
          files: _loras,
          loraVersions: _dtLoraVersions,
          modelVersions: _dtModelVersions,
          modelFile: primary,
        ),
        primaryFile: primary,
        facts: _loraFacts,
        onPick: (index, file) =>
            _write(() => settings.setImageGenLoraSlot(index, file: file)),
        onWeight: (index, weight) =>
            _write(() => settings.setImageGenLoraSlot(index, weight: weight)),
      ),
    );
  }

  Future<void> openCivitai(ImageGenSettings settings, {required bool lora}) {
    final deskContext = context;
    final adultAllowed = context
        .read<StorageService>()
        .realismSettings
        .adultThemesEnabled;
    return showDialog<void>(
      context: deskContext,
      useRootNavigator: true,
      builder: (context) => Dialog.fullscreen(
        child: StudioCivitaiGet(
          lora: lora,
          adult: _adult,
          adultAllowed: adultAllowed,
          backend: settings.imageGenBackend,
          onAdultChanged: (value) async {
            await settings.prefs?.setBool(
              settings.k('image_studio_adult'),
              value,
            );
            _adult = value;
          },
          onInstalled: (file) =>
              _afterInstall(deskContext, settings, file, lora),
        ),
      ),
    );
  }

  /// A finished download is picked directly — no workflow graph involved.
  Future<void> _afterInstall(
    BuildContext deskContext,
    ImageGenSettings settings,
    String file,
    bool lora,
  ) async {
    if (_configurationLocked) return;
    await _refreshCatalog(settings, force: true);
    if (!mounted) return;
    // For the native backend, a downloaded model is picked directly.
    if (!lora) {
      await _pickModel(settings, file);
      return;
    }
    ScaffoldMessenger.maybeOf(deskContext)?.showSnackBar(
      const SnackBar(
        content: Text(
          'Saved to your models folder on this computer. Pick it with Add under LoRA.',
        ),
      ),
    );
  }
}
