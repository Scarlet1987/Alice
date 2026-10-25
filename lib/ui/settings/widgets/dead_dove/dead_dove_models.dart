// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// This file is part of Front Porch AI.
//
// Front Porch AI is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Front Porch AI is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with Front Porch AI. If not, see <https://www.gnu.org/licenses/>.

// Dead Dove step 6: the user's own models. Loaded models run with zero
// app-added rails; the compiled lists above govern them.

import 'package:flutter/material.dart';

import 'package:front_porch_ai/ui/theme/porch_design.dart';

import 'dead_dove_checklist_state.dart';

/// Step 6: your own models.
class DeadDoveModels extends StatefulWidget {
  const DeadDoveModels({super.key, required this.state});

  final DeadDoveChecklistState state;

  @override
  State<DeadDoveModels> createState() => _DeadDoveModelsState();
}

class _DeadDoveModelsState extends State<DeadDoveModels> {
  final _nameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  String _kind = 'Text';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  void _add() {
    final name = _nameCtrl.text.trim();
    final location = _locationCtrl.text.trim();
    if (name.isEmpty || location.isEmpty) return;
    widget.state.addOwnModel(
      DeadDoveOwnModel(name: name, kind: _kind, location: location),
    );
    _nameCtrl.clear();
    _locationCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) {
        final models = widget.state.ownModels;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your own models',
              style: PorchType.body(
                context,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              'Bring your own and run them as they are — 0 app-added rails. '
              'Your compiled lists above are what govern them.',
              style: PorchType.hint(context),
            ),
            const SizedBox(height: PorchSpacing.sm),
            Text(
              'No safety rails of its own on a model you supply — no '
              'filtering, no blocklists, no refusal logic. Your lists '
              'govern: hard stops it, soft asks first, yellow slows down, '
              'unchecked goes. Models run locally.',
              style: PorchType.bodySmall(context),
            ),
            const SizedBox(height: PorchSpacing.sm),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Model name',
                hintText: 'e.g. My uncensored local model',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: PorchSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _kind,
                    decoration: const InputDecoration(
                      labelText: 'Kind',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const ['Text', 'Image', 'Voice']
                        .map(
                          (k) =>
                              DropdownMenuItem(value: k, child: Text(k)),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _kind = v ?? 'Text'),
                  ),
                ),
                const SizedBox(width: PorchSpacing.sm),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _locationCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Where it lives on this machine',
                      hintText: 'Path or model file…',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: PorchSpacing.sm),
            ElevatedButton(onPressed: _add, child: const Text('Add model')),
            const SizedBox(height: PorchSpacing.sm),
            if (models.isEmpty)
              Text(
                'No models added yet. Models added here are offered in Chat '
                'and model features while Dead Dove is your zone.',
                style: PorchType.hint(context),
              )
            else
              for (final m in models)
                Card(
                  margin: const EdgeInsets.only(bottom: PorchSpacing.xs),
                  child: ListTile(
                    dense: true,
                    title: Text(m.name),
                    subtitle: Text('${m.kind} · ${m.location}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      tooltip: 'Remove model',
                      onPressed: () => widget.state.removeOwnModel(m),
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}
