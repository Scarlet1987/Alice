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

// Gear loadout for the Main Character board: offensive gear, defensive
// gear, and clothing, each checked against the Kardashev scale as the
// user types. Flags over-scale items and god-mode jumps.

import 'package:flutter/material.dart';

import 'package:front_porch_ai/ui/theme/app_colors.dart';
import 'package:front_porch_ai/ui/theme/porch_design.dart';

import 'kardashev_section.dart';

/// Result of checking a gear entry against the scale.
enum GearVerdict { fits, overScale, godMode }

/// Very small heuristic check: looks for extinction-level / god-tier
/// language and for tech far beyond the selected type.
GearVerdict checkGear(String text, KardashevType type) {
  final t = text.toLowerCase();
  if (t.trim().isEmpty) return GearVerdict.fits;
  // God-mode: extinction-level attacks in a starting loadout.
  const godWords = [
    'extinction',
    'planet destroy',
    'planet-destroy',
    'destroy planets',
    'galaxy destroy',
    'omnipotent',
    'omnipotence',
    'godlike',
    'god-tier',
    'reality warp',
    'rewrite reality',
    'create from nothing',
    'manifest',
  ];
  if (godWords.any(t.contains)) return GearVerdict.godMode;
  // Over-scale markers by type.
  final typeIndex = type.index; // type0=0 .. beyond=4
  const dysonWords = ['dyson', 'star lift', 'stellar engine'];
  const galacticWords = ['galaxy', 'galactic', 'black hole'];
  if (typeIndex < 2 && dysonWords.any(t.contains)) {
    return GearVerdict.overScale;
  }
  if (typeIndex < 3 && galacticWords.any(t.contains)) {
    return GearVerdict.overScale;
  }
  return GearVerdict.fits;
}

/// Gear loadout section.
class GearSection extends StatefulWidget {
  const GearSection({
    super.key,
    required this.kardashevType,
    this.offensiveController,
    this.defensiveController,
    this.clothingController,
  });

  final KardashevType kardashevType;

  /// Optional external controllers so a parent screen can read the gear
  /// text when saving the card. When null, internal controllers are used.
  final TextEditingController? offensiveController;
  final TextEditingController? defensiveController;
  final TextEditingController? clothingController;

  @override
  State<GearSection> createState() => _GearSectionState();
}

class _GearSectionState extends State<GearSection> {
  late final TextEditingController _offenseCtrl;
  late final TextEditingController _defenseCtrl;
  late final TextEditingController _clothingCtrl;

  @override
  void initState() {
    super.initState();
    _offenseCtrl = widget.offensiveController ?? TextEditingController();
    _defenseCtrl = widget.defensiveController ?? TextEditingController();
    _clothingCtrl = widget.clothingController ?? TextEditingController();
  }

  @override
  void dispose() {
    if (widget.offensiveController == null) _offenseCtrl.dispose();
    if (widget.defensiveController == null) _defenseCtrl.dispose();
    if (widget.clothingController == null) _clothingCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GearBox(
          title: 'Offensive gear',
          label: 'Weapons you carry',
          hint: 'long distance and up close',
          controller: _offenseCtrl,
          kardashevType: widget.kardashevType,
        ),
        const SizedBox(height: PorchSpacing.md),
        _GearBox(
          title: 'Defensive gear',
          label: 'Armor & protection',
          hint: 'chest plate and the rest',
          controller: _defenseCtrl,
          kardashevType: widget.kardashevType,
        ),
        const SizedBox(height: PorchSpacing.md),
        _GearBox(
          title: 'Clothing',
          label: 'What you wear',
          hint: 'everyday, under or instead of armor',
          controller: _clothingCtrl,
          kardashevType: widget.kardashevType,
          checkScale: false,
        ),
      ],
    );
  }
}

class _GearBox extends StatefulWidget {
  const _GearBox({
    required this.title,
    required this.label,
    required this.hint,
    required this.controller,
    required this.kardashevType,
    this.checkScale = true,
  });

  final String title;
  final String label;
  final String hint;
  final TextEditingController controller;
  final KardashevType kardashevType;
  final bool checkScale;

  @override
  State<_GearBox> createState() => _GearBoxState();
}

class _GearBoxState extends State<_GearBox> {
  GearVerdict _verdict = GearVerdict.fits;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_recheck);
  }

  @override
  void didUpdateWidget(covariant _GearBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The scale selector lives in a sibling section, so the type can
    // change while the text stays put — recheck against the new type.
    if (oldWidget.kardashevType != widget.kardashevType) _recheck();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_recheck);
    super.dispose();
  }

  void _recheck() {
    final v = widget.checkScale
        ? checkGear(widget.controller.text, widget.kardashevType)
        : GearVerdict.fits;
    if (v != _verdict) setState(() => _verdict = v);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: PorchType.bodySmall(
            context,
          ).copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: widget.controller,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            border: const OutlineInputBorder(),
          ),
        ),
        if (widget.checkScale && _verdict != GearVerdict.fits)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(
                  _verdict == GearVerdict.godMode
                      ? Icons.block
                      : Icons.warning_amber_outlined,
                  size: 14,
                  color: _verdict == GearVerdict.godMode
                      ? AppColors.negativeAccentOf(context)
                      : AppColors.porchHoneyOf(context),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _verdict == GearVerdict.godMode
                        ? 'God-mode flag: an extinction-level attack in a '
                              'starting loadout — power is reached through the '
                              'story, step by step.'
                        : 'Over scale: this looks beyond what a '
                              '${widget.kardashevType.label} civilization fields.',
                    style: PorchType.caption(context).copyWith(
                      color: _verdict == GearVerdict.godMode
                          ? AppColors.negativeAccentOf(context)
                          : AppColors.porchHoneyOf(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
