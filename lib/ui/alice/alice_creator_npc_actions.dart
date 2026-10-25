// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice Character Creator: NPC drafting actions — AI naming, full-card draft,
// load/save/edit NPC card flows.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:front_porch_ai/models/models.dart';
import 'package:front_porch_ai/services/character_gen_service.dart';
import 'package:front_porch_ai/services/character_repository.dart';
import 'package:front_porch_ai/services/llm_provider.dart';
import 'package:front_porch_ai/services/llm_service.dart';
import 'package:front_porch_ai/ui/alice/alice_creator_draft.dart';

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
  );
}

/// NPC drafting actions on the shared draft: AI naming, full-card draft
/// via the existing chargen service, and saving the drafted card.
extension NpcDraftActions on AliceCreatorDraft {
  /// "Let the AI name them": one short generation, name only.
  Future<void> suggestNpcName(BuildContext context) async {
    final llm = context.read<LLMProvider>().activeService;
    if (!llm.isReady) {
      _snack(
        context,
        'No AI backend is ready. Start one in Settings, then try again.',
      );
      return;
    }
    npcNaming = true;
    touch();
    try {
      final concept = npcConcept.text.trim();
      final prompt =
          'Suggest one fitting name for a roleplay NPC. Role: $npcRole.'
          '${concept.isEmpty ? '' : ' Concept: $concept'}'
          ' Reply with ONLY the name — no quotes, no explanation.';
      final buf = StringBuffer();
      await for (final chunk in llm.generateStream(
        GenerationParams(prompt: prompt, maxLength: 24, temperature: 0.9),
      )) {
        buf.write(chunk);
        if (buf.length > 80) break;
      }
      final name = buf
          .toString()
          .trim()
          .split('\n')
          .first
          .trim()
          .replaceAll(RegExp('^["\u201c]|["\u201d.\$]'), '');
      if (name.isNotEmpty) npcName.text = name;
    } catch (_) {
      // Naming is a nicety — the draft button below still works.
    } finally {
      npcNaming = false;
      touch();
    }
  }

  /// "Draft this NPC with AI": full card via the existing chargen service.
  Future<void> draftNpc(BuildContext context) async {
    final llm = context.read<LLMProvider>().activeService;
    if (!llm.isReady) {
      _snack(
        context,
        'No AI backend is ready. Start one in Settings, then draft your NPC.',
      );
      return;
    }
    npcDrafting = true;
    npcDraft = null;
    touch();
    try {
      final name = npcName.text.trim();
      final conceptBits = <String>[
        'Supporting NPC.',
        'Role: $npcRole.',
        npcConcept.text.trim(),
      ].where((s) => s.trim().isNotEmpty).join(' ');
      final card = await CharacterGenService(llm).generateCharacter(
        name: name.isEmpty ? 'A new NPC' : name,
        concept: conceptBits,
        relationship: npcRelationship.text.trim(),
        generateLorebook: false,
        altGreetingCount: 1,
      );
      npcDraft = card;
      if (card == null && context.mounted) {
        _snack(context, 'The AI could not draft that NPC. Try again.');
      }
    } finally {
      npcDrafting = false;
      touch();
    }
  }

  /// Persist the drafted NPC card. If an NPC was loaded via "Load NPC",
  /// updates that card instead of creating a duplicate.
  Future<void> saveNpcCard(BuildContext context) async {
    final repo = Provider.of<CharacterRepository>(context, listen: false);
    final loadedId = npcLoadedDbId;
    if (loadedId != null) {
      final existing = await repo.getCharacterCardById(loadedId);
      if (existing != null) {
        existing.name = npcName.text.trim().isEmpty
            ? existing.name
            : npcName.text.trim();
        await repo.updateCharacter(existing);
        if (context.mounted) _snack(context, 'NPC card updated.');
        return;
      }
    }
    final card = npcDraft;
    if (card == null) return;
    await repo.addCharacter(card);
    if (context.mounted) {
      _snack(context, 'NPC card saved.');
      npcDraft = null;
      npcLoadedDbId = null;
      touch();
    }
  }

  /// "Load NPC": pick a saved NPC card to edit, or start from scratch.
  Future<void> loadNpcPicker(BuildContext context) async {
    final repo = Provider.of<CharacterRepository>(context, listen: false);
    final npcs = repo.characters
        .where((c) => c.frontPorchExtensions?.tier == 'lite')
        .toList();
    // Sentinel distinguishes "Start from scratch" (explicit) from dialog
    // dismiss (Cancel/X → null → do nothing).
    const scratchSentinel = '__scratch__';
    final picked = await showDialog<dynamic>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Load NPC'),
        content: SizedBox(
          width: 380,
          height: 320,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(scratchSentinel),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Start from scratch'),
              ),
              const SizedBox(height: 8),
              if (npcs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No saved NPCs yet. Draft one below and save it.',
                    textAlign: TextAlign.center,
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final npc in npcs)
                        ListTile(
                          title: Text(npc.name),
                          subtitle: npc.description.trim().isEmpty
                              ? null
                              : Text(
                                  npc.description
                                      .replaceAll(RegExp(r'\s+'), ' ')
                                      .trim(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                          onTap: () => Navigator.of(dialogContext).pop(npc),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    if (picked == scratchSentinel) {
      // "Start from scratch" — blank slate.
      npcLoadedDbId = null;
      npcName.clear();
      npcConcept.clear();
      npcRelationship.clear();
      npcDraft = null;
      touch();
    } else if (picked is CharacterCard) {
      npcLoadedDbId = picked.dbId;
      npcName.text = picked.name;
      npcConcept.text = picked.description
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      npcDraft = picked;
      touch();
      _snack(context, 'Loaded ${picked.name}.');
    }
    // Dialog dismiss (null) → do nothing.
  }

  /// "Edit NPC": edit the loaded/drafted NPC's look and details.
  Future<void> editNpcDetails(BuildContext context) async {
    final card = npcDraft;
    if (card == null || !context.mounted) return;
    final ext = card.frontPorchExtensions ?? FrontPorchExtensions();
    final age = TextEditingController(text: ext.appearanceAge);
    final eyes = TextEditingController(text: ext.appearanceEyeColor);
    final hair = TextEditingController(text: ext.appearanceHair);
    final features = TextEditingController(text: ext.appearanceFeatures);
    try {
      final saved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Edit ${card.name}'),
          content: SizedBox(
            width: 380,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _editField('Age', age, '24'),
                  const SizedBox(height: 8),
                  _editField('Eye color', eyes, 'green'),
                  const SizedBox(height: 8),
                  _editField('Hair', hair, 'long black hair'),
                  const SizedBox(height: 8),
                  _editField(
                    'Distinguishing features',
                    features,
                    'scar on left cheek',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Save changes'),
            ),
          ],
        ),
      );
      if (saved == true) {
        ext.appearanceAge = age.text.trim();
        ext.appearanceEyeColor = eyes.text.trim();
        ext.appearanceHair = hair.text.trim();
        ext.appearanceFeatures = features.text.trim();
        card.frontPorchExtensions = ext;
        touch();
        _snack(context, 'Details updated. Save the NPC card to keep them.');
      }
    } finally {
      age.dispose();
      eyes.dispose();
      hair.dispose();
      features.dispose();
    }
  }

  Widget _editField(
    String label,
    TextEditingController controller,
    String hint,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 2),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
