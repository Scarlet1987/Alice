// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Graph menu for the Studio desk.
//
// MIGRATION NOTE: The ComfyUI workflow graph system is gone. The native
// backend has no graphs to choose from — the model file is picked directly.
// This file keeps the DeskGraphChoice data class (used by the UI sheet and
// web facade) and returns empty menus. The "Change graph" UI will show no
// graphs for the native backend, which is correct: there is nothing to change.

import 'package:front_porch_ai/services/image/image.dart';

/// One row in Change graph. [title] is what a person reads. [id] is what
/// the desk stores. [detail] says where the row came from.
class DeskGraphChoice {
  final String id;
  final String title;
  final String detail;
  final String group;

  const DeskGraphChoice({
    required this.id,
    required this.title,
    required this.detail,
    required this.group,
  });
}

/// A stored id or a bare stem is not a title. Spaces stay as written.
String readableGraphTitle(String id, String title) {
  final clean = title.trim();
  final stem = id.split(':').last.split('/').last.replaceAll('.json', '');
  final raw = clean.isEmpty || clean == id || clean.startsWith('comfy:')
      ? stem
      : clean;
  if (raw.contains(' ')) return raw;
  return raw.replaceAll('_', ' ');
}

/// No graphs for the native backend — the model is picked directly.
/// Returns an empty list; the UI shows "no graphs available" honestly.
List<DeskGraphChoice> deskGraphMenu({
  required bool edit,
  required List<DeskGraphRow> templates,
  required List<DeskGraphRow> saved,
  List<DeskGraphRow> unread = const [],
  String modelFile = '',
}) {
  return const <DeskGraphChoice>[];
}

/// Secondary line under a graph title: the task, then the stored id.
String graphRowDetail({required bool edit, required String id}) {
  final task = edit ? 'Edit' : 'Text to image';
  return '$task · $id';
}
