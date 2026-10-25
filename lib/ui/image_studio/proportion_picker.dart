// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:front_porch_ai/models/models.dart';
import 'package:front_porch_ai/services/services.dart';
import 'package:front_porch_ai/services/storage/settings/image_gen_settings.dart';
import 'package:front_porch_ai/ui/theme/app_colors.dart';

import 'studio_desk_copy.dart';

/// Body-proportion picker for the Image Studio: the classical head-count key.
///
/// Artists measure bodies in heads — 1 head = the character's head height.
/// The picked age range maps to a head count that rides along in the image
/// prompt, so the engine works from a real measurement instead of guessing.
///
/// "Lock in details" drills down: exact age, eye color, hair, distinguishing
/// features. Saved to the character card — the single source of truth the
/// image generator and chat context both read from. Set once, sticks everywhere.
class ProportionPicker extends StatefulWidget {
  const ProportionPicker({super.key, this.characterDbId, this.characterName});

  /// Library id of the character to save locked details to. Null hides the
  /// lock-in section (freeform / group shot / no character).
  final String? characterDbId;
  final String? characterName;

  @override
  State<ProportionPicker> createState() => _ProportionPickerState();
}

class _ProportionPickerState extends State<ProportionPicker> {
  bool _lockOpen = false;
  bool _loading = false;
  bool _saving = false;
  String? _savedSummary;

  final _age = TextEditingController();
  final _eyes = TextEditingController();
  final _hair = TextEditingController();
  final _features = TextEditingController();

  @override
  void dispose() {
    _age.dispose();
    _eyes.dispose();
    _hair.dispose();
    _features.dispose();
    super.dispose();
  }

  Future<void> _loadLocked() async {
    final dbId = widget.characterDbId;
    if (dbId == null || !mounted) return;
    setState(() => _loading = true);
    try {
      final card = await context
          .read<CharacterRepository>()
          .getCharacterCardById(dbId);
      if (!mounted) return;
      final ext = card?.frontPorchExtensions;
      if (ext != null) {
        _age.text = ext.appearanceAge;
        _eyes.text = ext.appearanceEyeColor;
        _hair.text = ext.appearanceHair;
        _features.text = ext.appearanceFeatures;
        final summary = lockedAppearancePhrase(
          age: ext.appearanceAge,
          eyeColor: ext.appearanceEyeColor,
          hair: ext.appearanceHair,
          features: ext.appearanceFeatures,
        );
        _savedSummary = summary.isEmpty ? null : summary;
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveLocked() async {
    final dbId = widget.characterDbId;
    if (dbId == null || !mounted) return;
    setState(() => _saving = true);
    try {
      final repo = context.read<CharacterRepository>();
      final card = await repo.getCharacterCardById(dbId);
      if (card == null || !mounted) return;
      final ext = card.frontPorchExtensions ?? FrontPorchExtensions();
      ext.appearanceAge = _age.text.trim();
      ext.appearanceEyeColor = _eyes.text.trim();
      ext.appearanceHair = _hair.text.trim();
      ext.appearanceFeatures = _features.text.trim();
      // The picked head-count range is the character's proportion key.
      final settings = context.read<StorageService>().imageGenSettings;
      ext.appearanceProportion = settings.imageGenProportion;
      card.frontPorchExtensions = ext;
      await repo.updateCharacter(card);
      if (!mounted) return;
      final summary = lockedAppearancePhrase(
        age: ext.appearanceAge,
        eyeColor: ext.appearanceEyeColor,
        hair: ext.appearanceHair,
        features: ext.appearanceFeatures,
      );
      setState(() {
        _savedSummary = summary.isEmpty ? null : summary;
        _lockOpen = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Details saved to character')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<StorageService>().imageGenSettings;
    final selected = bodyProportionFromSetting(settings.imageGenProportion);
    final canLock = widget.characterDbId != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Body proportions',
          style: TextStyle(
            color: AppColors.textSecondary(context),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          kBodyProportionKey,
          style: TextStyle(
            color: AppColors.textTertiary(context),
            fontSize: 10,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in BodyProportion.values)
              _chip(context, option, selected, settings),
          ],
        ),
        if (_savedSummary != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.lock_outline,
                size: 12,
                color: AppColors.textTertiary(context),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Locked in: $_savedSummary',
                  style: TextStyle(
                    color: AppColors.textTertiary(context),
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
        if (canLock) ...[
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: () {
              final opening = !_lockOpen;
              setState(() => _lockOpen = opening);
              if (opening) _loadLocked();
            },
            icon: Icon(
              _lockOpen ? Icons.expand_less : Icons.expand_more,
              size: 16,
            ),
            label: Text(
              _lockOpen ? 'Hide details' : 'Lock in details',
              style: const TextStyle(fontSize: 12),
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.formMasterAccent,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          if (_lockOpen) _lockForm(context),
        ],
      ],
    );
  }

  Widget _chip(
    BuildContext context,
    BodyProportion option,
    BodyProportion selected,
    ImageGenSettings settings,
  ) {
    final isSel = option == selected;
    final accent = AppColors.formMasterAccent;
    return OutlinedButton(
      onPressed: () =>
          settings.setImageGenProportion(bodyProportionSetting(option)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        side: BorderSide(color: isSel ? accent : AppColors.borderOf(context)),
        backgroundColor: isSel ? AppColors.cardOf(context) : null,
      ),
      child: Text(
        bodyProportionLabel(option),
        style: TextStyle(
          fontSize: 12,
          color: isSel
              ? AppColors.textPrimary(context)
              : AppColors.textSecondary(context),
          fontWeight: isSel ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _lockForm(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    final name = (widget.characterName ?? '').trim();
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerOf(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name.isEmpty
                ? 'These details save to the character and stick — every '
                      'picture and chat from now on.'
                : 'These details save to $name and stick — every picture '
                      'and chat from now on.',
            style: TextStyle(
              color: AppColors.textTertiary(context),
              fontSize: 10,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          _field(context, _age, 'Age', '16', TextInputType.number),
          const SizedBox(height: 6),
          _field(context, _eyes, 'Eye color', 'blue'),
          const SizedBox(height: 6),
          _field(context, _hair, 'Hair', 'long black hair'),
          const SizedBox(height: 6),
          _field(
            context,
            _features,
            'Distinguishing features',
            'scar on left cheek',
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _saveLocked,
              child: Text(_saving ? 'Saving…' : 'Save to character'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    BuildContext context,
    TextEditingController controller,
    String label,
    String hint, [
    TextInputType keyboard = TextInputType.text,
  ]) {
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
          keyboardType: keyboard,
          decoration: InputDecoration(
            hintText: hint,
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
