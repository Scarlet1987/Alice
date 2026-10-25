// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:front_porch_ai/services/image/image.dart';
import 'package:front_porch_ai/services/services.dart';
import 'package:front_porch_ai/services/storage/settings/image_gen_settings.dart';

import 'studio_widgets.dart';

part 'studio_desk_actions.dart';
part 'studio_desk_catalog.dart';
part 'studio_desk_comfy.dart';
part 'studio_desk_ready.dart';

/// The studio desk. Reads and writes [StorageService] image settings.
///
/// Build only reads. Readiness is judged from state ([checkStudioReady]) when
/// a setting that it depends on changes, and the desk writes a setting only
/// when the person acts.
class StudioDesk extends StatefulWidget {
  const StudioDesk({
    super.key,
    this.onGenerate,
    this.onReadyChanged,
    this.showGenerate = true,
    this.errorText = '',
    this.generating = false,
    this.editMode,
  });

  /// When set, Create/Edit is fixed by the page. Null shows the desk toggle.
  final bool? editMode;

  /// The studio's real generate action. Disabled until the desk is Ready.
  final VoidCallback? onGenerate;

  /// The Studio page has its own Generate button. The desk hides this one there.
  final bool showGenerate;

  /// A backend refusal from the last generate, shown on the stove.
  final String errorText;

  final bool generating;

  /// Fired when readiness flips. The Edit tab uses this to block Apply.
  final ValueChanged<bool>? onReadyChanged;

  @override
  State<StudioDesk> createState() => _StudioDeskState();
}

class _StudioDeskState extends State<StudioDesk> {
  bool _edit = false;
  bool get _configurationLocked => !mounted || studioSettingsLocked(context);
  void _write(VoidCallback action) {
    if (!_configurationLocked) action();
  }

  bool get _editing => widget.editMode ?? _edit;
  bool _adult = false;
  List<String> _models = const [];
  List<String> _loras = const [];
  List<String> _clips = const [];
  List<String> _vaes = const [];
  List<String> _samplers = const [];
  List<String> _schedulers = const [];
  Map<String, DeskLoraCheck> _loraFacts = {};
  Map<String, String> _dtLoraVersions = const {};
  Map<String, String> _dtModelVersions = const {};
  String? _catalogUrl;
  bool _remoteListed = false;

  StudioReadyReport? _ready;
  String _readyKey = '';
  int _readySeq = 0;
  bool _fillWhenReady = false;
  ModelFamily? _checkedFamily;
  bool? _reportedReady;
  StorageService? _storage;
  Timer? _comfyUpWatch;
  bool _lookedForComfy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final storage = context.read<StorageService>();
    if (!identical(storage, _storage)) {
      _storage?.removeListener(_onStorage);
      _storage = storage..addListener(_onStorage);
    }
    final settings = storage.imageGenSettings;
    _adult =
        settings.prefs?.getBool(settings.k('image_studio_adult')) ?? _adult;
    _refreshCatalog(settings);
    _checkReady();
    if (!_lookedForComfy && settings.imageGenBackend == 'comfyui') {
      _lookedForComfy = true;
      _lookForComfy();
    }
  }

  @override
  void didUpdateWidget(StudioDesk oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.editMode != widget.editMode) _checkReady();
  }

  @override
  void dispose() {
    _storage?.removeListener(_onStorage);
    _comfyUpWatch?.cancel();
    super.dispose();
  }

  void rebuildState(VoidCallback fn) => setState(fn);

  void _onStorage() {
    if (!mounted) return;
    _checkReady();
  }

  Future<List<String>> _listedA1111Models(ImageGenService gen, String url) {
    return gen.fetchA1111Models(url);
  }

  Future<List<String>> _listedDrawThingsModels(
    ImageGenService gen,
    String url,
  ) {
    return gen.fetchDrawThingsModels(url);
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final settings = storage.imageGenSettings;
    final backend = settings.imageGenBackend;
    final editing = _editing;
    final report = _ready;
    final ready = report?.readiness;
    final workflowId = editing
        ? settings.comfyEditWorkflowId
        : settings.comfyCreateWorkflowId;
    final choices = editing
        ? settings.comfyEditModelChoices
        : settings.comfyCreateModelChoices;
    final primary = studioPrimaryFor(settings, edit: editing);
    final family = ImageModelFamily.detectFromName(primary);
    final loraChecks = _loraChecks(settings);
    final enabled = report?.ready ?? false;
    final parts = settings.imageGenSize.split('x');
    final width = int.tryParse(parts.first) ?? 1024;
    final height = parts.length > 1 ? int.tryParse(parts[1]) ?? 1024 : 1024;
    final uploadedGraph = false;
    final why = studioWorkflowWhy(
      workflowId: workflowId,
      primaryFile: primary,
      uploaded: uploadedGraph,
      uploadedTitle: '',
      uploadedNodes: 0,
    );
    final support = backend == 'drawthings' || uploadedGraph
        ? (checkpointOnly: false, rows: const <StudioSupportRow>[])
        : studioSupport(
            edit: editing,
            workflowId: workflowId,
            choices: choices,
            slots: ready?.slots ?? const [],
          );
    final stepCount = editing ? settings.editSteps : settings.imageGenSteps;
    final cfg = editing ? settings.editCfgScale : settings.imageGenCfgScale;
    final dtSampler = editing
        ? settings.editSampler
        : settings.drawThingsSampler;
    return StudioSettingsGate(
      busy: context.watch<ImageGenService?>()?.isGenerating ?? false,
      child: StudioStove(
        backendName: studioBackendName(backend),
        reachable: _reachable(backend, report),
        familyLabel: primary.isEmpty
            ? 'No drawing AI chosen yet'
            : (family == ModelFamily.unknown ? 'Model' : family.label),
        primaryFile: primary,
        why: why,
        onGraphs: () => openGraphs(settings),
        onModels: () => _openModels(settings),
        onGetModel: () => openCivitai(settings, lora: false),
        checkpointOnly: support.checkpointOnly,
        support: support.rows,
        onChangeSupport: (token) => _openModels(settings, token: token),
        loras: [
          for (final row in loraChecks)
            StudioStoveLora(
              row.file,
              studioLoraBadge(
                ImageModelFamily.compatibility(
                  row.family,
                  family,
                  metadataBacked: row.metadataBacked,
                ),
              ),
            ),
        ],
        loraBlocked: ready?.kind == StudioReady.loraMismatch,
        onAddLora: () => openLoras(settings, primary),
        onGetLora: () => openCivitai(settings, lora: true),
        onAnyway: () async {
          if (_configurationLocked) return;
          await settings.prefs?.setString(
            settings.k('image_studio_lora_override_family'),
            family.name,
          );
          settings.notify();
        },
        width: width,
        height: height,
        onSize: (nextWidth, nextHeight) =>
            _write(() => settings.setImageGenSize('${nextWidth}x$nextHeight')),
        steps: stepCount,
        cfg: cfg,
        sampler: settings.imageGenSampler,
        scheduler: settings.imageGenScheduler,
        samplers: _samplers,
        schedulers: _schedulers,
        onSteps: (value) {
          if (_configurationLocked) return;
          final parsed = int.tryParse(value);
          if (parsed == null) return;
          if (editing) {
            settings.setEditSteps(parsed);
          } else {
            settings.setImageGenSteps(parsed);
          }
        },
        onCfg: (value) {
          if (_configurationLocked) return;
          final parsed = double.tryParse(value);
          if (parsed == null) return;
          if (editing) {
            settings.setEditCfgScale(parsed);
          } else {
            settings.setImageGenCfgScale(parsed);
          }
        },
        onSampler: (value) => _write(() => settings.setImageGenSampler(value)),
        onScheduler: (value) =>
            _write(() => settings.setImageGenScheduler(value)),
        drawThings: backend == 'drawthings',
        drawThingsSampler: dtSampler,
        onDrawThingsSampler: (value) {
          if (_configurationLocked) return;
          if (editing) {
            settings.setEditSampler(value);
          } else {
            settings.setDrawThingsSampler(value);
          }
        },
        knobs: StudioDeskKnobs(
          canWrite: () => !_configurationLocked,
          settings: settings,
          edit: editing,
          comfyShiftGraph: null,
          comfyOwnShift: ready?.ownShift ?? kEditRecommendedShift,
        ),
        readyLine: studioReadyLine(
          ready: enabled,
          checking: report == null,
          blockedLora: ready?.kind == StudioReady.loraMismatch ? primary : null,
          missing: ready?.kind == StudioReady.missingFile
              ? studioMissingEncoderLine(primary: primary, rows: support.rows)
              : '',
        ),
        generateEnabled: enabled,
        onGenerate: widget.onGenerate,
        showGenerate: widget.showGenerate,
        errorText: widget.errorText,
        generating: widget.generating,
        showModes: widget.editMode == null,
        editing: editing,
        onMode: (value) {
          setState(() => _edit = value);
          _checkReady();
        },
        status: studioReadyStatus(ready),
        loaderSupportAction:
            backend == 'comfyui' &&
                (ready?.kind == StudioReady.needsLoaderUpdate ||
                    City96Gate.instance.hasExistingSupport(settings.comfyUiUrl))
            ? TextButton(
                onPressed: widget.generating
                    ? null
                    : () => _useExistingLoaderSupport(settings),
                child: Text(
                  City96Gate.instance.hasExistingSupport(settings.comfyUiUrl)
                      ? 'Recheck GGUF support'
                      : 'Use existing GGUF support…',
                ),
              )
            : null,
        onUpdateLoader:
            ready?.kind == StudioReady.needsLoaderUpdate &&
                ready!.canUpdateLoader
            ? () => _updateLoader(settings)
            : null,
      ),
    );
  }

  bool _reachable(String backend, StudioReadyReport? report) {
    if (backend == 'comfyui') return report?.objectInfo != null;
    if (backend == 'drawthings') return _drawThingsListed;
    if (backend == 'remote') return _remoteListed;
    return (_catalogUrl ?? '').startsWith('up:');
  }

  /// Draw Things shows its file counts after a listing, or after Check
  /// says the server is up. A failed Check stays down.
  bool get _drawThingsListed {
    final mark = _catalogUrl ?? '';
    if (mark.isEmpty || mark.startsWith('down:')) return false;
    if (mark.startsWith('up:')) return true;
    return _models.isNotEmpty || _loras.isNotEmpty;
  }

  /// One stored signature of everything the Ready verdict depends on.
  String _keyFor(ImageGenSettings settings) {
    final edit = _editing;
    final uploaded = edit
        ? settings.comfyEditUploadedWorkflow
        : settings.comfyCreateUploadedWorkflow;
    return jsonEncode([
      edit,
      settings.imageGenBackend,
      settings.comfyUiUrl,
      City96Gate.instance.hasExistingSupport(settings.comfyUiUrl),
      edit ? settings.comfyEditWorkflowId : settings.comfyCreateWorkflowId,
      edit ? settings.comfyEditModelChoices : settings.comfyCreateModelChoices,
      uploaded.length,
      uploaded.hashCode,
      settings.imageGenModel,
      settings.imageGenEditModel,
      settings.imageRemoteApiUrl,
      settings.remoteImageModelFor(settings.imageRemoteApiUrl, edit: edit),
      [
        for (final slot in settings.imageGenLoraSlots) [slot.file],
      ],
      settings.prefs?.getString(
        settings.k('image_studio_lora_override_family'),
      ),
      [
        for (final row in _loraFacts.values) [row.file, row.family.name],
      ],
    ]);
  }
}
