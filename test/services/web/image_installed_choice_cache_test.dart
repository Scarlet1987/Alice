// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:front_porch_ai/services/image_gen_service.dart';
import 'package:front_porch_ai/services/storage_service.dart';
import 'package:front_porch_ai/services/web/facade/image_facade.dart';

void main() {
  test(
    'a downloaded file is selectable without a server re-read',
    () async {
      final dir = Directory.systemTemp.createTempSync('installed-cache');
      addTearDown(() => dir.deleteSync(recursive: true));
      final storage = StorageService.sandbox(dir.path);
      final image = ImageGenService(storage);
      final facade = ImageFacade(image, storage);

      final choice = await facade.installedChoice(
        workflowId: 'z_image_turbo',
        file: 'just-downloaded.safetensors',
        lora: false,
      );

      expect(choice['accept'], isTrue);
    },
  );
}
