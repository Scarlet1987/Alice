import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:front_porch_ai/services/image/comfy_catalog.dart';
import 'package:front_porch_ai/services/image/image_studio_remote.dart';
import 'package:front_porch_ai/services/image/model_family.dart';
import 'package:front_porch_ai/services/image/studio_desk_logic.dart';
import 'package:front_porch_ai/services/image/studio_readiness.dart';

void main() {
  test('GGUF unet names stay out of the older diffusion list', () {
    final catalog = assembleComfyCatalog(
      checkpoints: const ['sdxl.safetensors'],
      unetNames: const ['z_image_turbo_bf16.safetensors'],
      ggufNames: const ['model.gguf'],
      ggufAdvancedNames: const ['model.gguf', 'other.gguf'],
      textEncoders: const ['qwen_3_4b.safetensors'],
      vaes: const ['ae.safetensors'],
      loras: const [],
    );
    expect(catalog.diffusionModels, ['z_image_turbo_bf16.safetensors']);
    expect(catalog.ggufUnets, ['model.gguf', 'other.gguf']);
    expect(catalog.createDiscovery, [
      'sdxl.safetensors',
      'z_image_turbo_bf16.safetensors',
    ]);
    expect(catalog.deskDiscovery, [
      'sdxl.safetensors',
      'z_image_turbo_bf16.safetensors',
      'model.gguf',
      'other.gguf',
    ]);
    final source = File(
      'lib/services/image/comfy_catalog.dart',
    ).readAsStringSync();
    expect(source.contains('assembleComfyCatalog'), isTrue);
    expect(source.contains('unetNames:'), isTrue);
    expect(source.contains('diffusionModels: diffusion'), isFalse);
  });

  test('the native backend offers no graph choices', () {
    expect(
      deskGraphChoices(
        edit: false,
        live: const [DeskGraphRow('zit', 'Z Image Text to Image')],
      ),
      isEmpty,
    );
    expect(
      deskGraphChoices(edit: true, live: const []),
      isEmpty,
    );
  });

  const zitClasses = [
    'UNETLoader',
    'CLIPLoader',
    'VAELoader',
    'CLIPTextEncode',
    'ConditioningZeroOut',
    'EmptySD3LatentImage',
    'ModelSamplingAuraFlow',
    'KSampler',
    'VAEDecode',
    'SaveImage',
  ];

  Map<String, dynamic> zitInfo() => {
    for (final name in zitClasses) name: <String, dynamic>{},
  };

  test('a filled Z-Image workflow is ready when its classes are installed', () {
    final ready = deskReadiness(
      backend: 'comfyui',
      primaryFile: 'z_image_turbo_bf16.safetensors',
      objectInfo: zitInfo(),
      workflowId: 'z_image_turbo',
      modelChoices: const {
        'z_image_turbo/%MODEL_DIFFUSION%': 'z_image_turbo_bf16.safetensors',
        'z_image_turbo/%MODEL_CLIP%': 'qwen_3_4b.safetensors',
        'z_image_turbo/%MODEL_VAE%': 'ae.safetensors',
      },
    );
    expect(ready.kind, StudioReady.ready);
  });

  test('an uploaded graph is not retargeted onto a GGUF loader', () {
    const graph = {
      'unet': {
        'class_type': 'UNETLoader',
        'inputs': {'unet_name': '%MODEL_DIFFUSION%'},
      },
      'txt': {
        'class_type': 'CLIPTextEncode',
        'inputs': {'text': '%PROMPT%'},
      },
    };
    final ready = deskReadiness(
      backend: 'comfyui',
      primaryFile: 'model.gguf',
      objectInfo: const {
        'UNETLoader': <String, dynamic>{},
        'CLIPTextEncode': <String, dynamic>{},
      },
      workflowId: '__uploaded__',
      uploadedWorkflowJson: jsonEncode(graph),
      modelChoices: const {'__uploaded__/%MODEL_DIFFUSION%': 'model.gguf'},
    );
    expect(ready.kind, StudioReady.ready);
  });

  test('a picked file is accepted on the native desk', () {
    expect(
      deskAcceptsInstalledFile(
        backend: 'comfyui',
        workflowId: 'z_image_turbo',
        file: 'sdxl.safetensors',
        lora: false,
        checkpoints: const ['sdxl.safetensors'],
        diffusionModels: const ['z_image_turbo_bf16.safetensors'],
        ggufUnets: const [],
        loras: const [],
      ),
      isTrue,
    );
    expect(
      deskAcceptsInstalledFile(
        backend: 'comfyui',
        workflowId: 'z_image_turbo',
        file: 'z_image_turbo_bf16.safetensors',
        lora: false,
        checkpoints: const ['sdxl.safetensors'],
        diffusionModels: const ['z_image_turbo_bf16.safetensors'],
        ggufUnets: const [],
        loras: const [],
      ),
      isTrue,
    );
  });

  test('a remote model stored on the create slot is ready', () {
    final id = pickRemoteImageModelId(slotModel: 'vendor/flux', hostModel: '');
    expect(id, 'vendor/flux');
    final ready = deskReadiness(
      backend: 'remote',
      primaryFile: id!,
      objectInfo: null,
    );
    expect(ready.kind, StudioReady.ready);
    expect(generateEnabled(ready), isTrue);
  });

  test('a metadata-certain LoRA mismatch keeps Generate off', () {
    final blocked = deskReadiness(
      backend: 'a1111',
      primaryFile: 'z_image_turbo_bf16.safetensors',
      objectInfo: null,
      loras: const [
        DeskLoraCheck(
          'qwen_lora.safetensors',
          ModelFamily.qwen,
          metadataBacked: true,
        ),
      ],
    );
    expect(blocked.kind, StudioReady.loraMismatch);
    expect(generateEnabled(blocked), isFalse);

    final namedOnly = deskReadiness(
      backend: 'a1111',
      primaryFile: 'z_image_turbo_bf16.safetensors',
      objectInfo: null,
      loras: const [DeskLoraCheck('qwen_lora.safetensors', ModelFamily.qwen)],
    );
    expect(namedOnly.kind, StudioReady.ready);
  });
}
