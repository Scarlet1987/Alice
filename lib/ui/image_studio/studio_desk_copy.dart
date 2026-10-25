// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:convert';

import 'package:front_porch_ai/services/image/image.dart';
import 'package:front_porch_ai/services/storage/settings/image_gen_settings.dart';

/// Classical head-count proportions: 1 head = the character's head height.
/// The engine's reference key for humanoid bodies — pick the age range and
/// the prompt carries the count, so the model works from a real measurement
/// instead of guessing.
enum BodyProportion { off, child, teen, adult }

/// Stored setting value → [BodyProportion]. Unknown values fall back to adult.
BodyProportion bodyProportionFromSetting(String value) {
  switch (value) {
    case 'child':
      return BodyProportion.child;
    case 'teen':
      return BodyProportion.teen;
    case 'off':
      return BodyProportion.off;
    case 'adult':
    default:
      return BodyProportion.adult;
  }
}

/// Setting value for [BodyProportion].
String bodyProportionSetting(BodyProportion proportion) {
  switch (proportion) {
    case BodyProportion.child:
      return 'child';
    case BodyProportion.teen:
      return 'teen';
    case BodyProportion.off:
      return 'off';
    case BodyProportion.adult:
      return 'adult';
  }
}

/// Plain-English label with the head range, for the picker.
String bodyProportionLabel(BodyProportion proportion) {
  switch (proportion) {
    case BodyProportion.child:
      return 'Child (4–5 heads)';
    case BodyProportion.teen:
      return 'Teen (6–7 heads)';
    case BodyProportion.adult:
      return 'Adult (7–8 heads)';
    case BodyProportion.off:
      return 'Off';
  }
}

/// The prompt phrase the engine works from. Empty when off — nothing injected.
String bodyProportionPrompt(BodyProportion proportion) {
  switch (proportion) {
    case BodyProportion.child:
      return 'young child, about 5 heads tall, correct proportions for a child';
    case BodyProportion.teen:
      return 'teenager, about 6 heads tall, correct proportions for a teenager';
    case BodyProportion.adult:
      return 'adult, about 8 heads tall, heroic body proportions';
    case BodyProportion.off:
      return '';
  }
}

const String kBodyProportionKey =
    'Artists measure bodies in heads — 1 head = the height of the '
    'character\u2019s head. Pick the age range and we\u2019ll handle '
    'the proportions.';

/// Builds the locked-in appearance phrase for a prompt from a character's
/// stored details: "16 years old, blue eyes, black hair, scar on left cheek".
/// Empty when nothing is locked in.
String lockedAppearancePhrase({
  required String age,
  required String eyeColor,
  required String hair,
  required String features,
}) {
  final parts = <String>[];
  final a = age.trim();
  if (a.isNotEmpty) parts.add('$a years old');
  final e = eyeColor.trim();
  if (e.isNotEmpty) parts.add('$e eyes');
  final h = hair.trim();
  if (h.isNotEmpty) {
    parts.add(h.toLowerCase().contains('hair') ? h : '$h hair');
  }
  final f = features.trim();
  if (f.isNotEmpty) parts.add(f);
  return parts.join(', ');
}

const String kStudioCreateWell =
    'Start from a picture — optional. A reference here varies the Create '
    'model. It does not switch you to Edit.';

const String kStudioEditWell =
    'Portrait in this chat. Edit sends an instruction with this picture.';

const String kStudioCreatePack =
    'Pack uses this Create model to vary the portrait.';

const String kStudioEditPack = 'Pack uses this edit model.';

const String kStudioDropCopy =
    'Drop a ComfyUI graph, or an image that has one saved inside it.';

const String kStudioDropKind = 'JSON, or a PNG from Comfy’s Save.';

const String kStudioPngReject =
    'That image has no ComfyUI workflow saved inside it.';

const String kStudioFileReject = 'That file isn’t a ComfyUI graph.';

const String kStudioLoraFamilyNote =
    'These files do not set the LoRA family. The text encoder can be Qwen '
    'while the model is Z-Image.';

const String kStudioCheckpointSupport =
    'This checkpoint graph has no text encoder or VAE slot.';

const List<(int, int, String)> kStudioSizeChips = [
  (512, 512, '512×512'),
  (768, 768, '768×768'),
  (1024, 1024, '1024×1024'),
  (1536, 1024, '1536×1024'),
  (1024, 1536, '1024×1536'),
];

String studioBackendName(String backend) {
  switch (backend) {
    case 'comfyui':
      return 'ComfyUI';
    case 'a1111':
      return 'Automatic1111';
    case 'drawthings':
      return 'Draw Things';
    default:
      return 'Remote';
  }
}

String studioSizeNote(int width, int height) =>
    'Sends $width×$height. Each side snaps to a multiple of 64, from 256 to 2048.';

String studioAdvancedSummary({
  required int steps,
  required double cfg,
  required String sampler,
  required String scheduler,
  bool showSampler = true,
}) => showSampler
    ? '$steps steps · cfg $cfg · $sampler · $scheduler'
    : '$steps steps · cfg $cfg';

String studioWorkflowWhy({
  required String workflowId,
  required String primaryFile,
  required bool uploaded,
  String uploadedTitle = '',
  int uploadedNodes = 0,
}) {
  if (uploaded) {
    final title = uploadedTitle.trim().isEmpty
        ? 'workflow'
        : uploadedTitle.trim();
    return 'Workflow · your file · $title · $uploadedNodes nodes';
  }
  if (primaryFile.toLowerCase().endsWith('.gguf')) {
    return 'Workflow · GGUF · chosen for this file · $workflowId';
  }
  final task = workflowId == 'qwen_image_edit' || workflowId == 'flux_kontext'
      ? 'Edit'
      : 'Text to image';
  return 'Workflow · $task · $workflowId';
}

/// The one line under the connection that says why the graph cannot run.
String studioReadyStatus(StudioReadiness? ready) {
  switch (ready?.kind) {
    case StudioReady.unreachable:
      return 'ComfyUI can’t be reached.';
    case StudioReady.missingNodeClass:
      return 'Missing ${ready?.missingClass}.';
    case StudioReady.needsUnetGraph:
      return 'A GGUF file needs a diffusion graph.';
    case StudioReady.needsLoaderUpdate:
    case StudioReady.needsComfyRestart:
      return ready?.message ?? kCity96NeedsUpdate;
    case StudioReady.ready:
    case StudioReady.missingFile:
    case StudioReady.loraMismatch:
    case null:
      return '';
  }
}

String studioReadyLine({
  required bool ready,
  String? blockedLora,
  String missing = '',
  bool checking = false,
}) {
  if (checking) return 'Checking…';
  if (blockedLora != null && blockedLora.isNotEmpty && !ready) {
    return 'Not ready — LoRA architecture does not match $blockedLora.';
  }
  if (ready) return 'Ready to generate.';
  if (missing.trim().isNotEmpty) return missing.trim();
  return 'Not ready.';
}

const String kStudioQwen21Encoder =
    'Not ready — this model needs the Qwen3-VL 8B text encoder.';

String studioLoraBadge(LoraCompat compat) {
  switch (compat) {
    case LoraCompat.match:
      return 'match';
    case LoraCompat.certain:
      return 'other base';
    case LoraCompat.likely:
    case LoraCompat.unknown:
      return 'likely';
  }
}

const String kStudioLoraFactsKey = 'image_studio_lora_facts';

Map<String, DeskLoraCheck> storedLoraFacts(ImageGenSettings settings) {
  final raw = settings.prefs?.getString(settings.k(kStudioLoraFactsKey));
  if (raw == null || raw.isEmpty) return const {};
  final Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException {
    return const {};
  }
  if (decoded is! Map) return const {};
  final out = <String, DeskLoraCheck>{};
  for (final entry in decoded.entries) {
    final value = entry.value;
    if (value is! Map) continue;
    final familyName = value['family']?.toString() ?? '';
    final family = ModelFamily.values.asNameMap()[familyName];
    if (family == null) continue;
    out[entry.key.toString()] = DeskLoraCheck(
      entry.key.toString(),
      family,
      metadataBacked: value['meta'] == true,
    );
  }
  return out;
}

Future<void> saveLoraFacts(
  ImageGenSettings settings,
  List<DeskLoraCheck> checks,
) async {
  final body = {
    for (final row in checks)
      row.file: {'family': row.family.name, 'meta': row.metadataBacked},
  };
  await settings.prefs?.setString(
    settings.k(kStudioLoraFactsKey),
    jsonEncode(body),
  );
  settings.notify();
}

/// A text encoder or VAE the graph loads besides the diffusion file.
class StudioSupportRow {
  final String role;
  final String token;
  final String file;

  const StudioSupportRow(this.role, this.token, this.file);
}

/// Every model file the graph loads besides the primary diffusion or
/// checkpoint file, with what is stored for it. [slots] are the graph's own
/// slots (a saved or template graph has no bundled preset); until the graph
/// Obsolete: the native backend has no model slots. Always returns empty.
({bool checkpointOnly, List<StudioSupportRow> rows}) studioSupport({
  required bool edit,
  required String workflowId,
  required Map<String, String> choices,
  List<dynamic> slots = const [],
}) {
  return (checkpointOnly: false, rows: const <StudioSupportRow>[]);
}

/// Names the encoder when Qwen-Image 2.1 has no Qwen3-VL 8B file chosen.
String studioMissingEncoderLine({
  required String primary,
  required Iterable<StudioSupportRow> rows,
}) {
  if (!isQwenImage21(primary)) return '';
  for (final row in rows) {
    if (row.token == '%MODEL_CLIP%' && row.file.trim().isEmpty) {
      return kStudioQwen21Encoder;
    }
  }
  return '';
}

/// Short quant mark for a model row. Empty when the name has none.
String studioQuantBadge(String file) {
  final lower = file.toLowerCase();
  if (lower.endsWith('.gguf')) {
    final mark = RegExp(
      r'q\d[a-z0-9_]*',
      caseSensitive: false,
    ).firstMatch(file);
    return mark?.group(0) ?? 'gguf';
  }
  for (final tag in ['bf16', 'fp16', 'fp8', 'int8', 'int4', 'nf4']) {
    if (lower.contains(tag)) return tag;
  }
  return '';
}
