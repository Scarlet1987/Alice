// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice edition Chat screen. Layout follows the GUI preview's Chat screen:
// header (avatar, name, MC glossary chip, backend chip), messages column +
// fixed sidebar, memory-checkpoint nudge, composer, and sidebar cards.
//
// Wiring is real, not mock: messages and sending go through ChatService,
// the nudge reuses the existing MemoryCheckpointNudge timer widget, the
// illustrate buttons launch the Image Studio with scene context, and
// character state reads the Realism relationship service. Nothing here
// rebuilds the chat engine.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:front_porch_ai/models/models.dart';
import 'package:front_porch_ai/services/services.dart';
import 'package:front_porch_ai/services/storage/storage.dart';
import 'package:front_porch_ai/services/storage/settings/detail_level.dart';
import 'package:front_porch_ai/services/image_prompt/image_prompt.dart';
import 'package:front_porch_ai/ui/theme/app_colors.dart';
import 'package:front_porch_ai/ui/widgets/glossary.dart';
import 'package:front_porch_ai/ui/chat/widgets/memory_checkpoint_nudge.dart';
import 'package:front_porch_ai/ui/image_studio/image_studio.dart';
import 'package:front_porch_ai/ui/alice/alice_widgets.dart';

part 'alice_chat.composer.dart';
part 'alice_chat.messages.dart';
part 'alice_chat.sidebar.dart';

/// Alice edition Chat screen.
class AliceChatScreen extends StatelessWidget {
  const AliceChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatService>(
      builder: (context, chat, _) {
        final character = chat.activeCharacter;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ChatHeader(chat: chat),
            const SizedBox(height: 12),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= 920) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _MessagesColumn(chat: chat)),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 300,
                          child: SingleChildScrollView(
                            child: _ChatSidebar(chat: chat),
                          ),
                        ),
                      ],
                    );
                  }
                  // Narrow: everything stacks in one scroll.
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        _MessageList(shrinkWrap: true, chat: chat),
                        _checkpointNudge(character),
                        _Composer(chat: chat),
                        const _ComposerHint(),
                        const SizedBox(height: 12),
                        _ChatSidebar(chat: chat),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Page header: avatar + name + location subtitle, MC chip with glossary,
/// backend status chip.
class _ChatHeader extends StatelessWidget {
  final ChatService chat;

  const _ChatHeader({required this.chat});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final character = chat.activeCharacter;
    final name = chat.isGroupMode
        ? 'Group chat'
        : (character?.name ?? 'No character');
    final subtitle = chat.isGroupMode
        ? '${chat.groupCharacters.length} in the scene'
        : _firstLine(character?.scenario);
    return Row(
      children: [
        AliceAvatar(name: name, size: 46),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        const AliceChip(label: 'MC'),
        const SizedBox(width: 6),
        const GlossaryChip(term: 'MC'),
        const SizedBox(width: 8),
        _BackendChip(chat: chat),
      ],
    );
  }

  static String _firstLine(String? text) {
    if (text == null || text.trim().isEmpty) return '';
    final line = text.trim().split('\n').first.trim();
    return line.length > 72 ? '${line.substring(0, 72)}…' : line;
  }
}

/// Backend status chip: generating phase, connection state, or idle.
class _BackendChip extends StatelessWidget {
  final ChatService chat;

  const _BackendChip({required this.chat});

  @override
  Widget build(BuildContext context) {
    return Consumer<LLMProvider>(
      builder: (context, llm, _) {
        final label = chat.isGenerating
            ? 'Generating…'
            : (llm.composerConnectionReady ? 'Backend ready' : 'Backend idle');
        return AliceChip(label: label);
      },
    );
  }
}

/// Messages column: scrolling list, checkpoint nudge, composer, hint.
class _MessagesColumn extends StatelessWidget {
  final ChatService chat;

  const _MessagesColumn({required this.chat});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _MessageList(chat: chat)),
        _checkpointNudge(chat.activeCharacter),
        _Composer(chat: chat),
        const _ComposerHint(),
      ],
    );
  }
}

/// The shared memory-checkpoint nudge (timer-driven, snoozable, pins to the
/// character card). Only present when a character is active.
Widget _checkpointNudge(CharacterCard? character) {
  if (character == null) return const SizedBox.shrink();
  return MemoryCheckpointNudge(character: character);
}
