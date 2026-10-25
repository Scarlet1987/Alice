// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice Chat screen — right sidebar. Part of alice_chat.dart.

part of 'alice_chat.dart';

/// Right sidebar: character state, story tools, journal & memory.
class _ChatSidebar extends StatelessWidget {
  final ChatService chat;

  const _ChatSidebar({required this.chat});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CharacterStateCard(chat: chat),
        const SizedBox(height: 12),
        _StoryToolsCard(chat: chat),
        const SizedBox(height: 12),
        _JournalCard(chat: chat),
      ],
    );
  }
}

/// Thin progress meter for bond / trust.
class _Meter extends StatelessWidget {
  final double value;
  final Color color;

  const _Meter({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6,
      margin: const EdgeInsets.only(top: 6, bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(99),
      ),
      child: FractionallySizedBox(
        widthFactor: value.clamp(0.0, 1.0),
        alignment: Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ),
    );
  }
}

/// Character state: mood, bond + meter, trust + meter. Advanced detail
/// level adds time of day and who is present.
class _CharacterStateCard extends StatelessWidget {
  final ChatService chat;

  const _CharacterStateCard({required this.chat});

  @override
  Widget build(BuildContext context) {
    final rel = chat.relationshipService;
    // Bond scale is ±300, trust is ±100.
    final bondValue = (rel.affectionScore + 300) / 600;
    final trustValue = (rel.trustLevel + 100) / 200;
    final advanced =
        context.watch<StorageService>().uiSettings.detailLevel ==
        DetailLevel.advanced;
    final present = <String>[
      for (final p in chat.cast) p.card.name,
      'You',
    ].join(' · ');
    return AliceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AliceSectionHead(
            title: 'Character state',
            barColor: AppColors.dialogue,
          ),
          const SizedBox(height: 8),
          AliceKeyValue(label: 'Mood', value: chat.moodLabel),
          AliceKeyValue(label: 'Bond', value: rel.shortTermTierName),
          _Meter(value: bondValue, color: AppColors.dialogue),
          AliceKeyValue(label: 'Trust', value: rel.trustTierName),
          _Meter(value: trustValue, color: AppColors.porchAmber),
          if (advanced) ...[
            const Divider(height: 16),
            // TODO: scene location — no public accessor on ChatService yet.
            AliceKeyValue(
              label: 'Time of day',
              value: chat.timeService.timeOfDay,
            ),
            AliceKeyValue(label: 'Present', value: present),
          ],
        ],
      ),
    );
  }
}

/// Story tools: illustrate, bring in an NPC, chaos spin.
class _StoryToolsCard extends StatelessWidget {
  final ChatService chat;

  const _StoryToolsCard({required this.chat});

  @override
  Widget build(BuildContext context) {
    return AliceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AliceSectionHead(
            title: 'Story tools',
            barColor: AppColors.porchAmber,
          ),
          const SizedBox(height: 8),
          _ToolButton(
            icon: Icons.image_outlined,
            label: 'Illustrate this scene',
            onPressed: () => launchSceneIllustrator(context, chat),
          ),
          _ToolButton(
            icon: Icons.person_add_outlined,
            label: 'Bring in an NPC',
            trailing: const GlossaryChip(term: 'NPC'),
            onPressed: () => _showNpcPicker(context, chat),
          ),
          _ToolButton(
            icon: Icons.casino_outlined,
            label: 'Chaos spin — twist the scene',
            // TODO: ChatService exposes chaosPressure but no public
            // trigger; wire once the engine offers one.
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Chaos spin is not wired up yet — the engine has no trigger for it.',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback onPressed;

  const _ToolButton({
    required this.icon,
    required this.label,
    this.trailing,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: AppColors.borderOf(context)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (trailing case final Widget t) t,
          ],
        ),
      ),
    );
  }
}

/// Journal & memory: pinned facts, lorebook entries in reach, and a manual
/// checkpoint button that pins a note to the character card.
class _JournalCard extends StatelessWidget {
  final ChatService chat;

  const _JournalCard({required this.chat});

  @override
  Widget build(BuildContext context) {
    final character = chat.activeCharacter;
    final entries = character?.lorebook?.entries ?? const [];
    final pinned = entries.where((e) => e.constant).length;
    return AliceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AliceSectionHead(
            title: 'Journal & memory',
            barColor: AppColors.action,
          ),
          const SizedBox(height: 8),
          AliceKeyValue(
            label: 'Pinned to ${character?.name ?? 'card'}',
            value: '$pinned fact${pinned == 1 ? '' : 's'}',
          ),
          AliceKeyValue(
            label: 'Lorebook entries in reach',
            value: '${entries.length}',
          ),
          const SizedBox(height: 10),
          AliceButton(
            label: 'Take a memory checkpoint',
            ghost: true,
            small: true,
            block: true,
            onPressed: character == null
                ? null
                : () => _pinMemoryDialog(context, character),
          ),
        ],
      ),
    );
  }
}

/// Manual memory checkpoint: pin a note as a constant lorebook entry on the
/// character card (same path the timed nudge uses).
Future<void> _pinMemoryDialog(
  BuildContext context,
  CharacterCard character,
) async {
  final controller = TextEditingController();
  final note = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Pin a memory'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What should ${character.name} always remember? It becomes a '
            'permanent note on their character card.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            autofocus: true,
            maxLines: 4,
            minLines: 2,
            decoration: const InputDecoration(
              hintText: 'e.g. They promised to visit the lighthouse at dawn…',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final text = controller.text.trim();
            Navigator.of(context).pop(text.isEmpty ? null : text);
          },
          child: const Text('Pin it'),
        ),
      ],
    ),
  );
  controller.dispose();
  if (note == null || !context.mounted) return;
  final book = character.lorebook ??= Lorebook(entries: []);
  book.entries.add(
    LorebookEntry(
      name:
          'Pinned memory — ${DateFormat('MMM d, yyyy').format(DateTime.now())}',
      content: note,
      enabled: true,
      constant: true,
    ),
  );
  await context.read<CharacterRepository>().updateCharacter(character);
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Pinned to ${character.name}\u2019s card.')),
    );
  }
}

/// Bring in an NPC: pick a library character and join them to the scene as
/// a scene guest, via the same join path as the /join command.
Future<void> _showNpcPicker(BuildContext context, ChatService chat) async {
  final candidates = chat.joinableGuestCharacters;
  if (candidates.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No other characters in your library to bring in.'),
        ),
      );
    }
    return;
  }
  final selected = await showDialog<CharacterCard>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('Bring in an NPC'),
      children: [
        for (final card in candidates)
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(card),
            child: Row(
              children: [
                AliceAvatar(name: card.name, size: 32),
                const SizedBox(width: 10),
                Expanded(child: Text(card.name)),
              ],
            ),
          ),
      ],
    ),
  );
  if (selected != null && context.mounted) {
    await chat.joinSceneGuest(selected);
  }
}

/// Launch the Image Studio with scene-aware context gathered from the last
/// messages (same context the classic chat page collects).
Future<void> launchSceneIllustrator(
  BuildContext context,
  ChatService chat,
) async {
  final personaService = Provider.of<UserPersonaService>(
    context,
    listen: false,
  );
  final llmProvider = Provider.of<LLMProvider>(context, listen: false);
  final character = chat.activeCharacter;
  final llmService = llmProvider.activeService.isReady
      ? llmProvider.activeService
      : null;

  String? worldInfo;
  try {
    final worlds = Provider.of<WorldRepository>(context, listen: false).worlds;
    if (worlds.isNotEmpty) worldInfo = worlds.first.description;
  } catch (_) {}

  List<String>? recentMessages;
  String? lastMessage;
  final messages = chat.messages;
  if (messages.isNotEmpty) {
    recentMessages = messages.reversed
        .take(12)
        .map((m) => m.displayText)
        .where((m) => m.isNotEmpty)
        .map(cleanVisualSourceText)
        .where((m) => m.isNotEmpty)
        .toList()
        .reversed
        .toList();
    final userName = personaService.persona.name;
    for (final m in messages.reversed) {
      final txt = cleanVisualSourceText(m.displayText);
      if (txt.isNotEmpty && m.sender != userName) {
        lastMessage = txt;
        break;
      }
    }
    lastMessage ??= cleanVisualSourceText(messages.last.displayText);
  }

  final imageGenService = Provider.of<ImageGenService>(context, listen: false);
  Future<void> onSendToChat(Uint8List bytes, String prompt) async {
    final path = await imageGenService.saveImageToDisk(bytes);
    if (path != null) {
      await chat.addGeneratedImageMessage(path, prompt);
    }
  }

  if (!context.mounted) return;
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => ImageStudio(
      mode: ImageGenMode.customPrompt,
      lastMessage: lastMessage,
      characterName: character?.name,
      characterDescription: character?.description,
      characterPersonality: character?.personality,
      characterDbId: character?.dbId,
      characterImagePath: character?.imagePath,
      scenario: cleanVisualSourceText(character?.scenario ?? ''),
      worldInfo: cleanVisualSourceText(worldInfo ?? ''),
      personaName: personaService.persona.name,
      personaText: personaService.persona.persona,
      recentMessages: recentMessages,
      llmService: llmService,
      onSendToChat: onSendToChat,
      currentExpression: chat.currentExpressionLabel,
      timeOfDay: chat.timeService.timeOfDay,
    ),
  );
}
