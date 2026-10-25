// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

part of 'image_facade.dart';

/// MIGRATION NOTE: The ComfyUI catalog is gone. The native backend lists
/// local model files directly. These methods return empty data so the
/// phone API compiles; the phone should use the model list instead.
extension ImageComfyCatalog on ImageFacade {
  /// Obsolete: returns empty catalog.
  Future<Map<String, dynamic>> comfyCatalog({
    bool edit = false,
    String token = '',
    bool loraFacts = false,
  }) async {
    return {
      'checkpoints': const <String>[],
      'diffusionModels': const <String>[],
      'ggufUnets': const <String>[],
      'textEncoders': const <String>[],
      'vaes': const <String>[],
      'loras': const <String>[],
      'createDiscovery': const <String>[],
      'deskDiscovery': const <String>[],
      'templates': const <Map<String, dynamic>>[],
      'editTemplates': const <Map<String, dynamic>>[],
      'graphs': const <Map<String, dynamic>>[],
      'editGraphs': const <Map<String, dynamic>>[],
    };
  }

  /// Obsolete: the native backend has no workflow slots.
  Future<Map<String, dynamic>> comfyWorkflowSlots(
    String workflowId, {
    bool edit = false,
  }) async {
    return {'slots': const <Map<String, dynamic>>[]};
  }
}
