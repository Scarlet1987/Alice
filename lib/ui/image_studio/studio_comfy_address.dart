// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';

/// The image engine address widget.
///
/// MIGRATION NOTE: The ComfyUI server is gone. The native backend needs no
/// address — it is built in. This widget is kept as a stub so existing
/// references compile; it displays a static "Built-in" line.
class StudioComfyAddress extends StatelessWidget {
  const StudioComfyAddress({
    super.key,
    required this.url,
    required this.explicit,
    required this.onSave,
    this.offer,
    this.answers,
  });

  final String url;
  final bool explicit;
  final Future<void> Function(String url) onSave;
  final String? offer;
  final Future<bool> Function(String url)? answers;

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Text(
        'Built-in engine — no address needed.',
        style: TextStyle(fontStyle: FontStyle.italic),
      ),
    );
  }
}
