// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice v9 Creator: tailor's measurements (combined preview v9).
// Split from alice_v9_creator.dart to keep every file under 500 lines.

import 'package:flutter/material.dart';

import 'package:front_porch_ai/ui/alice/v9/alice_v9_state.dart';
import 'package:front_porch_ai/ui/alice/v9/alice_v9_widgets.dart';
import 'package:front_porch_ai/ui/theme/app_colors.dart';

/// Tailor's measurements in the preview's file order: waist / shoulders
/// / height, then underbust / bust / torso length, then thigh girth /
/// [empty] / hips. Stored in cm.
const List<(String, String, double, double, double)> kV9MeasureDefs = [
  ('waist', 'waist', 50, 120, 70),
  ('shoulders', 'shoulders', 30, 60, 42),
  ('height', 'height', 120, 210, 170),
  ('underbust', 'underbust', 55, 120, 75),
  ('bust', 'bust', 60, 130, 90),
  ('thigh', 'thigh girth', 35, 80, 55),
  ('hips', 'hips', 60, 140, 95),
];

class MeasurementsCard extends StatelessWidget {
  final AliceV9State state;

  const MeasurementsCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return V9Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const V9Heading("tailor's measurements"),
          const SizedBox(height: 8),
          const V9Muted(
            'Flat, in your file order — waist / shoulders / height, then '
            'underbust / bust / torso length, then thigh girth / [empty] / '
            'hips. No sub-groups.',
          ),
          const V9Muted(
            'Sliders, not text boxes. Values are stored in cm. Tap cm / in '
            'to change what the readout shows.',
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              V9Button(
                label: 'cm',
                small: true,
                onPressed: () => state.setUnitIsCm(true),
              ),
              const SizedBox(width: 10),
              V9Button(
                label: 'in',
                small: true,
                onPressed: () => state.setUnitIsCm(false),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final cells = <Widget>[];
              for (final def in kV9MeasureDefs) {
                cells.add(_MeasureCell(state: state, def: def));
                if (def.$1 == 'bust') {
                  cells.add(_TorsoCell(state: state));
                }
                if (def.$1 == 'thigh') {
                  cells.add(const SizedBox.shrink());
                }
              }
              if (constraints.maxWidth < 700) {
                return Column(children: cells);
              }
              return GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 8,
                childAspectRatio: 2.4,
                children: cells,
              );
            },
          ),
          const SizedBox(height: 8),
          V9Muted(state.legLengthNote),
        ],
      ),
    );
  }
}

class _MeasureCell extends StatelessWidget {
  final AliceV9State state;
  final (String, String, double, double, double) def;

  const _MeasureCell({required this.state, required this.def});

  @override
  Widget build(BuildContext context) {
    final value = state.measurements.value(def.$1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${def.$2} — ${state.formatMeasure(value, isHeight: def.$1 == 'height')}',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        Slider(
          value: value.clamp(def.$3, def.$4),
          min: def.$3,
          max: def.$4,
          onChanged: (v) => state.setMeasurement(def.$1, v),
        ),
      ],
    );
  }
}

class _TorsoCell extends StatelessWidget {
  final AliceV9State state;

  const _TorsoCell({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('torso length', style: Theme.of(context).textTheme.labelLarge),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: state.measurements.torsoLength,
          items: const [
            DropdownMenuItem(value: 'short', child: Text('short')),
            DropdownMenuItem(value: 'average', child: Text('average')),
            DropdownMenuItem(value: 'long', child: Text('long')),
          ],
          onChanged: (v) {
            if (v == null) return;
            state.setTorsoLength(v);
          },
          decoration: const InputDecoration(
            filled: true,
            fillColor: AppColors.alicePale,
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
      ],
    );
  }
}

