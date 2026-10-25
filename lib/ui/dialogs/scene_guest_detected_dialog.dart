// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';

import 'package:front_porch_ai/services/chat/cast_detector.dart';
import 'package:front_porch_ai/ui/theme/app_colors.dart';

import 'npc_save_details.dart';

/// "New character appeared" popup for a [DetectedCharacter] (a recurring,
/// named side character the story introduced). Shows what the story said
/// about them, lets the user edit the details, and saves them as a real
/// character card — so the NPC stays constant from the card instead of
/// being reconstructed from context every time.
///
/// Returns the edited [NpcSaveDetails] on Save, null on dismiss (the NPC
/// stays context-only). Non-blocking: dismissing never deletes anything.
class SceneGuestDetectedDialog extends StatefulWidget {
  const SceneGuestDetectedDialog({
    super.key,
    required this.detected,
    required this.hostName,
  });

  final DetectedCharacter detected;
  final String hostName;

  @override
  State<SceneGuestDetectedDialog> createState() =>
      _SceneGuestDetectedDialogState();
}

class _SceneGuestDetectedDialogState extends State<SceneGuestDetectedDialog> {
  late final TextEditingController _name;
  late final TextEditingController _age;
  late final TextEditingController _eyes;
  late final TextEditingController _hair;
  late final TextEditingController _features;
  late final TextEditingController _personality;
  late final TextEditingController _about;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.detected.name);
    _age = TextEditingController();
    _eyes = TextEditingController();
    _hair = TextEditingController();
    _features = TextEditingController();
    _personality = TextEditingController();
    _about = TextEditingController(text: widget.detected.descriptor.trim());
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _eyes.dispose();
    _hair.dispose();
    _features.dispose();
    _personality.dispose();
    _about.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(
      NpcSaveDetails(
        name: name,
        age: _age.text.trim(),
        eyeColor: _eyes.text.trim(),
        hair: _hair.text.trim(),
        features: _features.text.trim(),
        personality: _personality.text.trim(),
        description: _about.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.relationshipAccent;
    return AlertDialog(
      backgroundColor: AppColors.backgroundOf(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.person_add_alt_1, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'New character appeared',
              style: TextStyle(
                color: AppColors.textPrimary(context),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '“${widget.detected.name}” showed up in your story. '
                'Check the details, fix anything, then save them as a '
                'character — they\u2019ll stay the same every time instead '
                'of being rebuilt from the story.',
                style: TextStyle(
                  color: AppColors.textSecondary(context),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              _field(context, 'Name', _name),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _field(context, 'Age', _age, hint: '24')),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _field(context, 'Eye color', _eyes, hint: 'green'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _field(context, 'Hair', _hair, hint: 'short red hair'),
              const SizedBox(height: 8),
              _field(
                context,
                'Distinguishing features',
                _features,
                hint: 'tattoo on right arm',
              ),
              const SizedBox(height: 8),
              _field(
                context,
                'Personality',
                _personality,
                hint: 'wry, loyal, quick to laugh',
              ),
              const SizedBox(height: 8),
              _field(
                context,
                'About them',
                _about,
                hint: 'What the story said about them',
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(
            'Not now',
            style: TextStyle(color: AppColors.textSecondary(context)),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save_outlined, size: 16),
          label: const Text('Save as character'),
        ),
      ],
    );
  }

  Widget _field(
    BuildContext context,
    String label,
    TextEditingController controller, {
    String hint = '',
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary(context),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint.isEmpty ? null : hint,
            isDense: true,
            hintStyle: TextStyle(
              color: AppColors.textTertiary(context),
              fontSize: 12,
            ),
          ),
          style: TextStyle(color: AppColors.textPrimary(context), fontSize: 13),
        ),
      ],
    );
  }
}
