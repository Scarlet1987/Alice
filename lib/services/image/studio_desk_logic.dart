// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Desk logic for the Studio.
//
// MIGRATION NOTE: The ComfyUI workflow graph system is gone. The native
// backend picks a model file directly — no workflows, no slots, no graphs.
// This file keeps the model/LoRA compatibility logic; all workflow-specific
// functions now return neutral values.

import 'package:front_porch_ai/services/storage/settings/image_gen_settings.dart';

import 'model_family.dart';
import 'studio_readiness.dart';

/// The file this run actually loads. The native backend takes the model
/// directly — no workflow slots.
String deskPrimaryFile({
  required String backend,
  required bool edit,
  required String workflowId,
  required Map<String, String> choices,
  required String legacyModel,
}) {
  return legacyModel.trim();
}

/// One filled LoRA slot checked against the file that will actually load.
class DeskLoraCheck {
  final String file;
  final ModelFamily family;
  final bool metadataBacked;

  const DeskLoraCheck(this.file, this.family, {this.metadataBacked = false});
}

/// Draw Things LoRA names, family facts, and catalog versions.
class DrawThingsLoraListing {
  final List<String> names;
  final Map<String, DeskLoraCheck> facts;
  final Map<String, String> versions;

  const DrawThingsLoraListing({
    this.names = const [],
    this.facts = const {},
    this.versions = const {},
  });
}

/// Names for the connection count, plus the version each file was tagged with.
DrawThingsLoraListing drawThingsLoraListing(List<LoraOption> options) {
  final names = <String>[];
  final facts = <String, DeskLoraCheck>{};
  final versions = <String, String>{};
  for (final row in options) {
    final name = row.name.trim();
    if (name.isEmpty) continue;
    names.add(name);
    if (row.dtVersion.isNotEmpty) versions[name] = row.dtVersion;
    facts[name] = DeskLoraCheck(
      name,
      row.family,
      metadataBacked: row.familyFromMetadata,
    );
  }
  return DrawThingsLoraListing(names: names, facts: facts, versions: versions);
}

/// A graph row the desk may offer. Obsolete — the native backend has no graphs.
class DeskGraphRow {
  final String id;
  final String title;

  const DeskGraphRow(this.id, this.title);
}

/// No graphs for the native backend.
bool deskOffersGraphTitle(String title, {required bool edit}) => false;

/// No graphs for the native backend.
List<String> deskGraphChoices({
  required bool edit,
  required List<DeskGraphRow> live,
}) {
  return const <String>[];
}

/// A finished CivitAI file is accepted when it has a name.
bool deskAcceptsInstalledFile({
  required String backend,
  required String workflowId,
  required String file,
  required bool lora,
  required List<String> checkpoints,
  required List<String> diffusionModels,
  required List<String> ggufUnets,
  required List<String> loras,
}) {
  if (lora) return loras.contains(file);
  return file.trim().isNotEmpty;
}

/// What the desk should do with a file that just finished downloading.
class InstalledDeskChoice {
  final bool accept;
  final String kind;
  final String token;

  const InstalledDeskChoice({
    required this.accept,
    this.kind = '',
    this.token = '',
  });
}

/// Apply the installed-file choice. The native backend picks the file directly.
Future<void> applyInstalledDeskChoice({
  required ImageGenSettings settings,
  required InstalledDeskChoice choice,
  required String workflowId,
  required String file,
  required bool edit,
}) async {
  if (!choice.accept) return;
  if (edit) {
    await settings.setImageGenEditModel(file);
  } else {
    await settings.setImageGenModel(file);
  }
}

/// Model-family to workflow mapping. Obsolete — returns empty.
String workflowForModel({required bool edit, required String file}) => '';

/// Which choice token a picked file belongs in. Obsolete — returns empty.
String deskComfyToken({required String workflowId, required String file}) => '';

String? deskLoraBlocker(String primaryFile, List<DeskLoraCheck> loras) {
  final checkpoint = ImageModelFamily.detectFromName(primaryFile);
  for (final lora in loras) {
    if (lora.file.trim().isEmpty) continue;
    final compat = ImageModelFamily.compatibility(
      lora.family,
      checkpoint,
      metadataBacked: lora.metadataBacked,
    );
    if (compat == LoraCompat.certain) return lora.file;
  }
  return null;
}

bool deskLoraBlocks(String primaryFile, List<DeskLoraCheck> loras) =>
    deskLoraBlocker(primaryFile, loras) != null;

/// Metadata-free LoRA checks: family is detected from the filename.
Future<List<DeskLoraCheck>> deskLoraChecks({
  required ImageGenSettings settings,
}) async {
  final out = <DeskLoraCheck>[];
  for (final slot in settings.imageGenLoraSlots) {
    final file = slot.file.trim();
    if (file.isEmpty) continue;
    out.add(DeskLoraCheck(file, ImageModelFamily.detectFromName(file)));
  }
  return out;
}

/// Readiness for the native backend: a model file must be picked, and LoRAs
/// must be compatible. No workflow graphs involved.
StudioReadiness deskReadiness({
  required String backend,
  required String primaryFile,
  required Map<String, dynamic>? objectInfo,
  bool edit = false,
  String workflowId = '',
  String uploadedWorkflowJson = '',
  Map<String, String> modelChoices = const {},
  Map<String, dynamic>? liveTemplate,
  List<DeskLoraCheck> loras = const [],
  bool allowLoraMismatch = false,
}) {
  if (primaryFile.trim().isEmpty) {
    return const StudioReadiness(StudioReady.missingFile);
  }
  if (!allowLoraMismatch && deskLoraBlocks(primaryFile, loras)) {
    return const StudioReadiness(StudioReady.loraMismatch);
  }
  return const StudioReadiness(StudioReady.ready);
}
