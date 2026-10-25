// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Pins the built-in image engine's model scan: NativeImageBackend.listModels
// reads the user's image-models folder (Settings → Where things live) and
// returns the weight files it finds there. This is the real reader behind
// the "Image engine models" path row.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:front_porch_ai/services/image_gen_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NativeImageBackend.listModels', () {
    test('scans the configured folder for weight files', () async {
      final dir = await Directory.systemTemp.createTemp('native_models_');
      try {
        await File('${dir.path}/pony-v6.safetensors').create();
        await File('${dir.path}/qwen-image.gguf').create();
        await File('${dir.path}/notes.txt').create();
        final sub = await Directory('${dir.path}/loras').create();
        await File('${sub.path}/style-lora.safetensors').create();

        final backend = NativeImageBackend(modelsDir: () => dir.path);
        final models = await backend.listModels();

        expect(models, [
          'pony-v6.safetensors',
          'qwen-image.gguf',
          'style-lora.safetensors',
        ]);
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('returns empty when the folder is missing', () async {
      final backend = NativeImageBackend(
        modelsDir: () => '/does/not/exist/front-porch-ai-test',
      );
      expect(await backend.listModels(), isEmpty);
    });

    test('returns empty when no folder is configured', () async {
      final backend = NativeImageBackend();
      expect(await backend.listModels(), isEmpty);
    });
  });
}
