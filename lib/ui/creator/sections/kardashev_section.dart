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

// Kardashev scale selector for the Main Character board: Type 0 / I / II /
// III / Beyond (user-defined). Radio behavior — exactly one type is always
// selected. Locks on save; changing it afterwards takes a deliberate
// unlock. Drives the gear loadout check.

import 'package:flutter/material.dart';

import 'package:front_porch_ai/ui/theme/app_colors.dart';
import 'package:front_porch_ai/ui/theme/porch_design.dart';

/// The Kardashev types.
enum KardashevType { type0, type1, type2, type3, beyond }

extension KardashevTypeLabel on KardashevType {
  String get label {
    switch (this) {
      case KardashevType.type0:
        return 'Type 0';
      case KardashevType.type1:
        return 'Type I';
      case KardashevType.type2:
        return 'Type II';
      case KardashevType.type3:
        return 'Type III';
      case KardashevType.beyond:
        return 'Beyond';
    }
  }

  String get description {
    switch (this) {
      case KardashevType.type0:
        return 'Tool creation, Stone Age to modern day. Humanity sits at '
            '~0.73, still running mostly on fossil fuels.';
      case KardashevType.type1:
        return 'Planetary — harnesses all energy reaching the home planet '
            'from its star plus the planet\u2019s own (≈10¹⁶ W).';
      case KardashevType.type2:
        return 'Stellar — captures the host star\u2019s entire output '
            '(≈10²⁶–10²⁸ W, e.g. a Dyson sphere).';
      case KardashevType.type3:
        return 'Galactic — commands a galaxy\u2019s total energy (≈10³⁶ W).';
      case KardashevType.beyond:
        return 'Your definition. Past Type III the app presets no wattage '
            '— your definition is the scale check here, under the same '
            'ceiling as every world.';
    }
  }
}

/// Golden-rule ceiling copy (Elaina's verbatim).
const String kKardashevCeiling =
    'The ceiling — the golden rule, for all settings: The scale stops at '
    'quantum entanglement — linked particles, instant correlation across any '
    'distance. That\u2019s the top reach, and it\u2019s not an absolute: no '
    'omnipotence, nothing from nothing, no rewriting reality at a word. '
    'Every power still needs energy in, matter to act on, or a signal to '
    'ride; if it needs nothing and answers to nothing, it isn\u2019t on the '
    'scale.';

/// Kardashev selector section.
class KardashevSection extends StatefulWidget {
  const KardashevSection({
    super.key,
    required this.selected,
    required this.locked,
    required this.onSelect,
    required this.onUnlock,
    this.beyondNameController,
    this.beyondScopeController,
    this.beyondGearController,
  });

  final KardashevType selected;
  final bool locked;
  final ValueChanged<KardashevType> onSelect;
  final VoidCallback onUnlock;

  /// Optional external controllers so a parent screen can read the
  /// user-defined Beyond definition when saving. Internal controllers are
  /// used when these are null.
  final TextEditingController? beyondNameController;
  final TextEditingController? beyondScopeController;
  final TextEditingController? beyondGearController;

  @override
  State<KardashevSection> createState() => _KardashevSectionState();
}

class _KardashevSectionState extends State<KardashevSection> {
  late final TextEditingController _beyondNameCtrl;
  late final TextEditingController _beyondScopeCtrl;
  late final TextEditingController _beyondGearCtrl;

  @override
  void initState() {
    super.initState();
    _beyondNameCtrl = widget.beyondNameController ?? TextEditingController();
    _beyondScopeCtrl = widget.beyondScopeController ?? TextEditingController();
    _beyondGearCtrl = widget.beyondGearController ?? TextEditingController();
  }

  @override
  void dispose() {
    if (widget.beyondNameController == null) _beyondNameCtrl.dispose();
    if (widget.beyondScopeController == null) _beyondScopeCtrl.dispose();
    if (widget.beyondGearController == null) _beyondGearCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'The base categories. Types 1 to 3 stay exactly as Kardashev '
          'defined them. Type 0 sits below; anything past Type 3 is yours '
          'to define.',
          style: PorchType.hint(context),
        ),
        const SizedBox(height: PorchSpacing.sm),
        PorchSegmentedControl<KardashevType>(
          options: KardashevType.values
              .map((t) => PorchSegmentOption(value: t, label: t.label))
              .toList(),
          value: widget.selected,
          onChanged: (t) {
            if (!widget.locked) widget.onSelect(t);
          },
        ),
        const SizedBox(height: PorchSpacing.sm),
        Text(widget.selected.description, style: PorchType.bodySmall(context)),
        if (widget.selected == KardashevType.beyond) ...[
          const SizedBox(height: PorchSpacing.sm),
          TextField(
            controller: _beyondNameCtrl,
            enabled: !widget.locked,
            decoration: const InputDecoration(
              labelText: 'Your type — name it',
              hintText: 'e.g. Type IV, Type 5, "The Makers"',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: PorchSpacing.sm),
          TextField(
            controller: _beyondScopeCtrl,
            enabled: !widget.locked,
            decoration: const InputDecoration(
              labelText: 'What it commands',
              hintText: 'e.g. a whole universe\u2019s energy…',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: PorchSpacing.sm),
          TextField(
            controller: _beyondGearCtrl,
            enabled: !widget.locked,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'What that means for gear',
              hintText: 'e.g. tools that reshape planets…',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ],
        const SizedBox(height: PorchSpacing.sm),
        Row(
          children: [
            if (widget.locked) ...[
              Icon(
                Icons.lock_outline,
                size: 14,
                color: AppColors.porchAmberOf(context),
              ),
              const SizedBox(width: 6),
              Text(
                'Scale locked',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.porchAmberOf(context),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: widget.onUnlock,
                child: const Text('Unlock scale'),
              ),
            ] else
              Text(
                'The scale locks in when you save your persona — after that, '
                'changing it takes a deliberate unlock.',
                style: PorchType.hint(context),
              ),
          ],
        ),
        const SizedBox(height: PorchSpacing.md),
        const Divider(),
        const SizedBox(height: PorchSpacing.sm),
        Text(
          'Where things sit',
          style: PorchType.bodySmall(
            context,
          ).copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        _Bullet(
          text:
              'A pocket in space-time is Type 3 tech; gravity control is '
              'Type 4. Manifesting a whole working ship molecule by molecule '
              'is banned at every type.',
        ),
        _Bullet(
          text:
              'No god mode: an extinction-level attack in a starting loadout '
              'gets flagged — power is reached through the story, step by step.',
        ),
        const SizedBox(height: PorchSpacing.sm),
        Container(
          padding: const EdgeInsets.all(PorchSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(PorchRadius.sm),
            color: AppColors.porchAmberOf(context).withValues(alpha: 0.08),
            border: Border.all(
              color: AppColors.porchAmberOf(context).withValues(alpha: 0.3),
            ),
          ),
          child: Text(kKardashevCeiling, style: PorchType.bodySmall(context)),
        ),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: PorchType.bodySmall(context)),
          Expanded(child: Text(text, style: PorchType.bodySmall(context))),
        ],
      ),
    );
  }
}
