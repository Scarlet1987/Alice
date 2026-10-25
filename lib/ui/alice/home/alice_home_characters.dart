// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice Home: Character cards card. Part of alice_home.dart.
//
// Empty state per the approved preview (🎭 "No characters yet" →
// "Create your first character"). Populated: a grid of character cards
// from CharacterRepository — tap opens the chat, Edit opens the real
// character editor, Delete runs the repository delete pipeline after a
// confirmation. A trailing tile starts a new character in the Creator.

part of '../alice_home.dart';

extension _AliceHomeCharacters on _AliceHomeScreenState {
  Widget _buildCharactersCard(
    BuildContext context,
    List<CharacterCard> characters,
  ) {
    return AliceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AliceSectionHead(
            title: 'Character cards',
            subtitle: 'Tap one to open the chat',
          ),
          const SizedBox(height: 10),
          if (characters.isEmpty)
            _buildCharactersEmpty(context)
          else
            _buildCharacterGrid(context, characters),
        ],
      ),
    );
  }

  Widget _buildCharactersEmpty(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            const Opacity(
              opacity: 0.4,
              child: Text('🎭', style: TextStyle(fontSize: 48)),
            ),
            const SizedBox(height: 12),
            const Text(
              'No characters yet',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Create your main character, add NPCs,\n'
              'and bring your world to life.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 16),
            AliceButton(
              label: 'Create your first character',
              onPressed: () => Provider.of<AppState>(
                context,
                listen: false,
              ).setIndex(_aliceCreatorIndex),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterGrid(
    BuildContext context,
    List<CharacterCard> characters,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / 216).floor().clamp(1, 6);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 228,
          ),
          itemCount: characters.length + 1,
          itemBuilder: (context, index) {
            if (index == characters.length) {
              return _buildNewCharacterTile(context);
            }
            return _buildCharacterTile(context, characters[index]);
          },
        );
      },
    );
  }

  Widget _buildCharacterTile(BuildContext context, CharacterCard character) {
    final theme = Theme.of(context);
    final tagline = character.personality.trim().isNotEmpty
        ? character.personality.trim().split('\n').first
        : character.description.trim().split('\n').first;
    final role = _homeRoleLabel(character);
    return InkWell(
      onTap: () => _openCharacter(character),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardOf(context),
          border: Border.all(color: AppColors.borderOf(context)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AliceAvatar(name: character.name, size: 48),
            const SizedBox(height: 10),
            Text(
              character.name,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                tagline.isEmpty ? 'No description yet.' : tagline,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (role != null) ...[
              const SizedBox(height: 8),
              AliceChip(
                label: role,
                color: role == 'Main Character'
                    ? AppColors.porchAmber
                    : AppColors.action,
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                AliceButton(
                  label: 'Edit',
                  ghost: true,
                  small: true,
                  onPressed: () => _editCharacterFromHome(context, character),
                ),
                const SizedBox(width: 6),
                AliceDangerButton(
                  label: 'Delete',
                  onPressed: () => _confirmDeleteCharacter(context, character),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewCharacterTile(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => Provider.of<AppState>(
        context,
        listen: false,
      ).setIndex(_aliceCreatorIndex),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderOf(context)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.borderOf(context),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '+',
                style: TextStyle(fontSize: 22, color: theme.hintColor),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'New character',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                'You author the main character — the AI helps with the '
                'rest of the cast.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            const AliceChip(label: 'Creator'),
          ],
        ),
      ),
    );
  }

  /// Opens the app's real character editor for [character] — the same
  /// page the library home pushes. (The Alice Creator screen creates
  /// new cards; it grows a load-an-existing-card path in its own
  /// rebuild step.)
  Future<void> _editCharacterFromHome(
    BuildContext context,
    CharacterCard character,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditCharacterPage(character: character),
      ),
    );
  }

  /// Delete with confirmation, then the repository pipeline (soft-delete
  /// row, portrait file, chat history, linked world) — the same
  /// [CharacterRepository.deleteCharacter] the library uses.
  Future<void> _confirmDeleteCharacter(
    BuildContext context,
    CharacterCard character,
  ) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${character.name}?'),
        content: const Text(
          'This deletes the character card, its portrait files, and its '
          'chat history. This can\u2019t be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final repo = Provider.of<CharacterRepository>(context, listen: false);
    final worldRepo = Provider.of<WorldRepository>(context, listen: false);
    final storage = Provider.of<StorageService>(context, listen: false);
    await repo.deleteCharacter(
      character,
      worldRepo: worldRepo,
      chatsDir: storage.chatsDir,
    );
  }
}

/// Honest role label for a card: MCs are tagged 'main-character' by the
/// Creator; NPCs are lite cards. Anything else gets no chip rather than
/// a wrong one.
String? _homeRoleLabel(CharacterCard character) {
  if (character.tags.contains('main-character')) return 'Main Character';
  if (character.isLite) return 'NPC';
  return null;
}
