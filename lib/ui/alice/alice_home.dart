// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice Home screen ("On your porch"): greeting header with the real
// detail-level setting, then the two porch areas from the approved
// preview — a Worlds card (empty state, or every place world as a labeled
// collapsible hierarchy panel) and a Character cards card (empty state,
// or a grid of character cards with Edit + Delete). Continue-chatting
// (real recent sessions) and the Advanced-only engine status stay below.

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import 'package:front_porch_ai/models/models.dart';
import 'package:front_porch_ai/providers/app_state.dart';
import 'package:front_porch_ai/services/services.dart';
import 'package:front_porch_ai/services/storage/storage.dart';
import 'package:front_porch_ai/ui/alice/alice_motion.dart';
import 'package:front_porch_ai/ui/alice/alice_widgets.dart';
import 'package:front_porch_ai/ui/pages/edit_character_page.dart';
import 'package:front_porch_ai/ui/theme/app_colors.dart';
import 'package:front_porch_ai/utils/utils.dart';

part 'home/alice_home_characters.dart';
part 'home/alice_home_worlds.dart';
part 'home/alice_home_engine.dart';

/// Alice navigation destinations in rail order (see [AliceShell]).
/// Kept in sync with AliceDestination: home 0, chat 1, creator 2, worlds 3.
const _aliceChatIndex = 1;
const _aliceCreatorIndex = 2;
const _aliceWorldsIndex = 3;

/// One recent chat session, tagged with the character it belongs to.
class _RecentStory {
  final CharacterCard character;
  final String sessionId;
  final DateTime date;
  final String preview;

  const _RecentStory({
    required this.character,
    required this.sessionId,
    required this.date,
    required this.preview,
  });
}

/// Alice Home: "On your porch".
class AliceHomeScreen extends StatefulWidget {
  const AliceHomeScreen({super.key});

  @override
  State<AliceHomeScreen> createState() => _AliceHomeScreenState();
}

class _AliceHomeScreenState extends State<AliceHomeScreen> {
  /// Blocks stacked open-chat taps while setActiveCharacter / loadSession
  /// runs (same race home_page guards against).
  bool _openingChat = false;

  Future<List<_RecentStory>>? _recentStories;
  int? _storiesForCharacterCount;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final characters = Provider.of<CharacterRepository>(context).characters;
    if (_storiesForCharacterCount != characters.length) {
      _storiesForCharacterCount = characters.length;
      _recentStories = _loadRecentStories(characters);
    }
  }

  /// Gathers sessions across every character, newest first, top 3.
  /// TODO(alice): add a cross-character "most recent sessions" query to the
  /// DB so this stops fanning out one query per character on big libraries.
  Future<List<_RecentStory>> _loadRecentStories(
    List<CharacterCard> characters,
  ) async {
    final chatService = Provider.of<ChatService>(context, listen: false);
    final stories = <_RecentStory>[];
    for (final character in characters) {
      final ownerId = character.stableGroupId;
      if (ownerId.isEmpty) continue;
      final sessions = await chatService.getSessionsForId(ownerId);
      for (final s in sessions) {
        final date = s['date'];
        if (date is! DateTime) continue;
        stories.add(
          _RecentStory(
            character: character,
            sessionId: '${s['id']}',
            date: date,
            preview: '${s['preview'] ?? 'New conversation'}',
          ),
        );
      }
    }
    stories.sort((a, b) => b.date.compareTo(a.date));
    return stories.take(3).toList();
  }

  void _goChat() =>
      Provider.of<AppState>(context, listen: false).setIndex(_aliceChatIndex);

  Future<void> _openCharacter(CharacterCard character) async {
    if (_openingChat || !mounted) return;
    _openingChat = true;
    try {
      // setActiveCharacter resumes the character's most recent session.
      await Provider.of<ChatService>(
        context,
        listen: false,
      ).setActiveCharacter(character);
      if (!mounted) return;
      _goChat();
    } finally {
      _openingChat = false;
    }
  }

  /// Opens one specific recent session, like the old home's history dialog.
  Future<void> _openStory(_RecentStory story) async {
    if (_openingChat || !mounted) return;
    _openingChat = true;
    try {
      final chatService = Provider.of<ChatService>(context, listen: false);
      chatService.beginSessionLoad();
      try {
        await chatService.setActiveCharacter(story.character);
        await chatService.loadSession(story.sessionId);
      } finally {
        chatService.endSessionLoad();
      }
      if (!mounted) return;
      _goChat();
    } finally {
      _openingChat = false;
    }
  }

  String _greetingWord() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final detailLevel = storage.uiSettings.detailLevel;
    final personaName = context.watch<UserPersonaService>().defaultPersona.name;
    final characters = context.watch<CharacterRepository>().characters;

    final greeting = (personaName.isNotEmpty && personaName != 'User')
        ? '${_greetingWord()}, $personaName'
        : _greetingWord();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, greeting, detailLevel, storage),
          const SizedBox(height: 18),
          _buildWorldsCard(context),
          const SizedBox(height: 18),
          _buildCharactersCard(context, characters),
          const SizedBox(height: 18),
          AliceCard(child: _buildContinueChatting(context)),
          if (detailLevel.reveals(DetailLevel.advanced)) ...[
            const SizedBox(height: 18),
            _buildEngineStatus(context, storage),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String greeting,
    DetailLevel detailLevel,
    StorageService storage,
  ) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 640;
        final segBlock = Column(
          crossAxisAlignment: narrow
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.end,
          children: [
            AliceSegmentedControl<DetailLevel>(
              values: DetailLevel.values,
              labels: [for (final d in DetailLevel.values) d.label],
              selected: detailLevel,
              onChanged: storage.uiSettings.setDetailLevel,
            ),
            const SizedBox(height: 4),
            Text(
              detailLevel.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ],
        );
        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AliceScreenTitle(title: 'On your porch'),
              const SizedBox(height: 4),
              Text(
                '$greeting — pick up a story where you left off, or start '
                'a new one on the porch.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),
              const SizedBox(height: 12),
              segBlock,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AliceScreenTitle(title: 'On your porch'),
                  const SizedBox(height: 4),
                  Text(
                    '$greeting — pick up a story where you left off, or '
                    'start a new one on the porch.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            segBlock,
          ],
        );
      },
    );
  }

  Widget _buildContinueChatting(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AliceSectionHead(
          title: 'Continue chatting',
          subtitle: 'Your most recent stories',
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<_RecentStory>>(
          future: _recentStories,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: AliceSkeleton(lines: 3),
              );
            }
            final stories = snapshot.data!;
            if (stories.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No stories yet — tap a character on your porch to '
                  'start one.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              );
            }
            return Column(
              children: [
                for (final story in stories) _buildStoryRow(context, story),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStoryRow(BuildContext context, _RecentStory story) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => _openStory(story),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            AliceAvatar(name: story.character.name, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    story.character.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    story.preview,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              formatRelativeTime(story.date),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
