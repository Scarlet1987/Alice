// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Desk picks for the Studio.
//
// MIGRATION NOTE: The ComfyUI workflow system is gone. The native backend
// picks model files directly — no workflows, no slots, no tokens.
// These functions are kept as stubs so callers compile.

/// Obsolete: the native backend has no workflows to keep.
bool deskKeepsWorkflow(String workflowId) => false;

/// Obsolete: the native backend has no model slots.
String deskPrimaryToken({
  required String workflowId,
  required String file,
  List<dynamic> slots = const [],
}) {
  return '';
}
