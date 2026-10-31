// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// What the phone's Image Studio asks of the server: choosing a model, graph
// or encoder by the desktop's own rules. Real routes over a real (sandboxed)
// storage, against a real loopback ComfyUI.

import 'package:flutter_test/flutter_test.dart';

import 'image_desk_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DeskHarness h;

  Future<void> boot() async {
    final comfy = await DeskComfy.start(
      unet: const ['z_image_turbo_bf16.safetensors'],
      clip: const ['clip_l.safetensors', 'qwen_3_4b.safetensors'],
      vae: const ['ae.safetensors', 'sdxl_vae.safetensors'],
    );
    h = await DeskHarness.boot(comfy: comfy);
  }

  group('choosing a model', () {
    test(
      'picking a model stores the file and leaves the workflow alone',
      () async {
        await boot();
        await h.settings.setComfyCreateWorkflowId('sd');

        final (status, config) = await h
            .call('POST', '/api/image/studio/pick', {
              'kind': 'model',
              'mode': 'create',
              'file': 'z_image_turbo_bf16.safetensors',
            });

        expect(status, 200);
        expect(config['comfyCreateWorkflowId'], 'sd');
        expect(config['model'], 'z_image_turbo_bf16.safetensors');
        expect(h.choices(), isEmpty);
      },
    );

    test('never replaces an encoder the person already picked', () async {
      await boot();
      final s = h.settings;
      await s.setComfyCreateWorkflowId('z_image_turbo');
      await s.setComfyCreateModelChoice(
        'z_image_turbo',
        '%MODEL_CLIP%',
        'my_own_encoder.safetensors',
      );

      final (status, config) = await h.call('POST', '/api/image/studio/pick', {
        'kind': 'model',
        'mode': 'create',
        'file': 'z_image_turbo_bf16.safetensors',
      });

      expect(status, 200);
      expect(
        h.choices()['z_image_turbo/%MODEL_CLIP%'],
        'my_own_encoder.safetensors',
      );
      expect(h.choices()['z_image_turbo/%MODEL_VAE%'], isNull);
      expect(config['model'], 'z_image_turbo_bf16.safetensors');
    });

    test('a saved Comfy graph stays on the desk', () async {
      await boot();
      final s = h.settings;
      const saved = 'comfy:userdata:my_flow.json';
      await s.setComfyCreateWorkflowId(saved);

      final (status, config) = await h.call('POST', '/api/image/studio/pick', {
        'kind': 'model',
        'mode': 'create',
        'file': 'z_image_turbo_bf16.safetensors',
      });

      expect(status, 200);
      expect(config['comfyCreateWorkflowId'], saved);
      expect(config['model'], 'z_image_turbo_bf16.safetensors');
      expect(h.choices()['$saved/%MODEL_DIFFUSION%'], isNull);
    });

    test('Edit keeps its own model, apart from Create', () async {
      await boot();
      final s = h.settings;
      await s.setComfyCreateWorkflowId('z_image_turbo');
      await s.setComfyEditWorkflowId('qwen_image_edit');

      final (status, config) = await h.call('POST', '/api/image/studio/pick', {
        'kind': 'model',
        'mode': 'edit',
        'file': 'qwen_image_edit_2509_fp8.safetensors',
      });

      expect(status, 200);
      expect(config['comfyEditWorkflowId'], 'qwen_image_edit');
      expect(config['editModel'], 'qwen_image_edit_2509_fp8.safetensors');
      expect(config['comfyCreateWorkflowId'], 'z_image_turbo');
      expect(h.choices(), isEmpty);
      expect(h.choices(edit: true), isEmpty);
    });

    test(
      'a name with a control character is refused, nothing stored',
      () async {
        await boot();
        final (status, body) = await h.call('POST', '/api/image/studio/pick', {
          'kind': 'model',
          'mode': 'create',
          'file': 'a\nb.safetensors',
        });

        expect(status, 400);
        expect(body['code'], 'bad_request');
        expect(h.choices(), isEmpty);
      },
    );
  });

  group('choosing a graph', () {
    test('a bundled graph is refused: the native engine has no graphs',
        () async {
      await boot();
      final s = h.settings;
      await s.setComfyCreateWorkflowId('sd');
      await s.setComfyCreateModelChoice(
        'z_image_turbo',
        '%MODEL_DIFFUSION%',
        'z_image_turbo_bf16.safetensors',
      );

      final (status, body) = await h.call('POST', '/api/image/studio/pick', {
        'kind': 'graph',
        'mode': 'create',
        'id': 'z_image_turbo',
      });

      expect(status, 400);
      expect(body['code'], 'no_graphs');
    });

    test('a name that is on no list is refused', () async {
      await boot();
      final s = h.settings;
      await s.setComfyCreateWorkflowId('sd');
      await s.setComfyCreateModelChoice(
        'z_image_turbo',
        '%MODEL_DIFFUSION%',
        'z_image_turbo_bf16.safetensors',
      );

      final (status, body) = await h.call('POST', '/api/image/studio/pick', {
        'kind': 'graph',
        'mode': 'create',
        'id': 'evil_graph',
      });

      expect(status, 400);
      expect(body['code'], 'no_graphs');
      expect(h.settings.comfyCreateWorkflowId, 'sd');
    });

    test('an uploaded graph is refused: no graphs on native', () async {
      await boot();
      final s = h.settings;
      await s.setComfyCreateWorkflowId('sd');
      await s.setComfyCreateModelChoice(
        'z_image_turbo',
        '%MODEL_DIFFUSION%',
        'z_image_turbo_bf16.safetensors',
      );

      final (status, body) = await h.call('POST', '/api/image/studio/pick', {
        'kind': 'graph',
        'mode': 'create',
        'id': '__uploaded__',
      });

      expect(status, 400);
      expect(body['code'], 'no_graphs');
    });
  });

  group('choosing a slot', () {
    test('a slot pick is refused: no slots on native', () async {
      await boot();
      final s = h.settings;
      await s.setComfyCreateWorkflowId('z_image_turbo');

      final (status, body) = await h.call('POST', '/api/image/studio/pick', {
        'kind': 'support',
        'mode': 'create',
        'token': '%MODEL_CLIP%',
        'file': 'clip_l.safetensors',
      });

      expect(status, 400);
      expect(body['code'], 'no_slots');
    });

    test('a token that is not a model slot is refused', () async {
      await boot();
      final s = h.settings;
      await s.setComfyCreateWorkflowId('z_image_turbo');

      final (status, body) = await h.call('POST', '/api/image/studio/pick', {
        'kind': 'support',
        'mode': 'create',
        'token': '%MODEL_LORA%',
        'file': 'clip_l.safetensors',
      });

      expect(status, 400);
      expect(body['code'], 'no_slots');
    });
  });

  test('anything but a model, a graph or a slot is refused', () async {
    await boot();
    final (status, body) = await h.call('POST', '/api/image/studio/pick', {
      'kind': 'backend',
      'file': 'x',
    });

    expect(status, 400);
    expect(body['code'], 'bad_request');
  });
}
