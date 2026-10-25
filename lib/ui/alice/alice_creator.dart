// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice Character Creator screen: "Character creator". You author the
// main character and yourself; the AI writes the supporting cast.
// Tabs: Main Character | NPC | You (User).

import 'package:flutter/material.dart';

import 'package:front_porch_ai/ui/alice/alice_creator_draft.dart';
import 'package:front_porch_ai/ui/alice/alice_creator_mc.dart';
import 'package:front_porch_ai/ui/alice/alice_creator_npc.dart';
import 'package:front_porch_ai/ui/alice/alice_creator_user.dart';
import 'package:front_porch_ai/ui/alice/alice_widgets.dart';

/// Plain-English glossary for the creator screen.
const _glossary = <String, String>{
  'Main Character':
      'The protagonist of the story — the character who interacts with the '
      'world. Their whole board lives on the Main Character tab.',
  'NPC':
      'A supporting character. You give the spark (a name and a one-line '
      'concept); the AI writes the rest.',
  'You (User)':
      'Your real-world self — how other users see you. Nothing about any '
      'character lives here.',
  'Persona': 'The name other users see, which can differ from your real name.',
  'Greeting':
      'The character\u2019s first message — what they say when a chat opens.',
  'Lorebook':
      'Pinned world facts you save as you play, so the world stays '
      'consistent from session to session.',
  'Kardashev scale':
      'How much energy a civilization commands — from Type 0 (Stone Age to '
      'modern day) up past Type III (a whole galaxy). It drives what gear '
      'makes sense.',
};

/// The Alice Character Creator screen.
class AliceCreatorScreen extends StatefulWidget {
  const AliceCreatorScreen({super.key});

  @override
  State<AliceCreatorScreen> createState() => _AliceCreatorScreenState();
}

class _AliceCreatorScreenState extends State<AliceCreatorScreen> {
  late final AliceCreatorDraft _draft;

  @override
  void initState() {
    super.initState();
    _draft = AliceCreatorDraft()..loadUserPersona();
  }

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  void _showGlossary() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('What do these words mean?'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final entry in _glossary.entries) ...[
                Text(
                  entry.key,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(entry.value),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String get _tabDescription {
    switch (_draft.tab) {
      case CreatorTab.mc:
        return 'The protagonist of the story — the character who interacts '
            'with the world. Their whole board lives here.';
      case CreatorTab.npc:
        return 'The supporting cast. The AI writes them — you just give '
            'the spark.';
      case CreatorTab.user:
        return 'Your real-world self. Slim by design — nothing about any '
            'character lives here.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: _draft,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AliceScreenTitle(title: 'Character creator'),
                            const SizedBox(height: 2),
                            Text(
                              'You author the main character and yourself; '
                              'the AI writes the supporting cast.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.hintColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AliceButton(
                        label: 'What do these words mean?',
                        ghost: true,
                        small: true,
                        onPressed: _showGlossary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AliceSegmentedControl<CreatorTab>(
                    values: CreatorTab.values,
                    labels: const ['Main Character', 'NPC', 'You (User)'],
                    selected: _draft.tab,
                    onChanged: _draft.setTab,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _tabDescription,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  const SizedBox(height: 14),
                  switch (_draft.tab) {
                    CreatorTab.mc => McPane(draft: _draft),
                    CreatorTab.npc => NpcPane(draft: _draft),
                    CreatorTab.user => UserPane(draft: _draft),
                  },
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
