// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:front_porch_ai/services/storage/settings/image_gen_settings.dart';

import 'comfy_gguf_city96_gate.dart';
import 'image_studio_remote.dart';
import 'studio_desk_logic.dart';
import 'studio_readiness.dart';

/// The file this Create or Edit run loads. One rule for the desk, the phone,
/// expression packs and avatars.
String studioPrimaryFor(ImageGenSettings settings, {required bool edit}) {
  final backend = settings.imageGenBackend;
  final slot = edit ? settings.imageGenEditModel : settings.imageGenModel;
  final legacy = backend == 'remote'
      ? (pickRemoteImageModelId(
              slotModel: slot,
              hostModel: settings.remoteImageModelFor(
                settings.imageRemoteApiUrl,
                edit: edit,
              ),
            ) ??
            '')
      : slot;
  return deskPrimaryFile(
    backend: backend,
    edit: edit,
    workflowId: edit
        ? settings.comfyEditWorkflowId
        : settings.comfyCreateWorkflowId,
    choices: edit
        ? settings.comfyEditModelChoices
        : settings.comfyCreateModelChoices,
    legacyModel: legacy,
  );
}

/// One Ready verdict and what it rested on.
class StudioReadyReport {
  const StudioReadyReport({
    required this.readiness,
    required this.primaryFile,
    required this.workflowId,
    this.objectInfo,
  });

  final StudioReadiness readiness;
  final String primaryFile;
  final String workflowId;

  /// The node list the verdict used. Null off Comfy, or when Comfy could not
  /// be read.
  final Map<String, dynamic>? objectInfo;

  bool get ready => generateEnabled(readiness);
}

/// Whether a Create or Edit run can start, judged the way it will run.
///
/// The desk, the phone, expression packs and avatars all ask this. On Comfy it
/// reads `/object_info` and the workflow's live template once, converts the
/// graph the way a generate does (with that node list), and then asks the
/// GGUF loader gate about the graph that would be posted, without asking or
/// writing anything. A saved or template graph is judged on its own template,
/// so it can be Ready.
Future<StudioReadyReport> checkStudioReady({
  required ImageGenSettings settings,
  required bool edit,
  List<DeskLoraCheck> loras = const [],
  bool allowLoraMismatch = false,
  City96Gate? gate,
}) async {
  final backend = settings.imageGenBackend;
  final primary = studioPrimaryFor(settings, edit: edit);
  var verdict = deskReadiness(
    backend: backend,
    primaryFile: primary,
    objectInfo: const {},
    edit: edit,
    loras: loras,
    allowLoraMismatch: allowLoraMismatch,
  );
  return StudioReadyReport(
    readiness: verdict,
    primaryFile: primary,
    workflowId: '',
    objectInfo: const {},
  );
}
