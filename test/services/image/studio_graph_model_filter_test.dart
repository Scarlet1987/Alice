// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:front_porch_ai/services/image/studio_desk_logic.dart';
import 'package:front_porch_ai/services/image/studio_graph_menu.dart';

void main() {
  List<String> ids({
    required String modelFile,
    bool edit = false,
    List<DeskGraphRow> templates = const [],
    List<DeskGraphRow> saved = const [],
    List<DeskGraphRow> unread = const [],
  }) {
    return [
      for (final row in deskGraphMenu(
        edit: edit,
        modelFile: modelFile,
        templates: templates,
        saved: saved,
        unread: unread,
      ))
        row.id,
    ];
  }

  test('the native backend offers no graphs', () {
    expect(
      ids(
        modelFile: 'z_image_turbo_bf16.safetensors',
        templates: const [
          DeskGraphRow('comfy:default:image_z_image_turbo', 'Z-Image Turbo'),
          DeskGraphRow('comfy:default:flux_schnell', 'Flux Schnell'),
        ],
        saved: const [
          DeskGraphRow('comfy:userdata:flux_evening', 'flux_evening'),
        ],
        unread: const [DeskGraphRow('comfy:userdata:closed', 'closed')],
      ),
      isEmpty,
    );
    expect(ids(edit: true, modelFile: 'flux1-dev.safetensors'), isEmpty);
    expect(ids(modelFile: ''), isEmpty);
  });
}
