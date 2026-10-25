// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

part of 'alice_settings.dart';

/// Opens a folder picker and hands the chosen directory to [apply].
/// Does nothing when the user cancels. GuardedPicker brings the app's
/// plain-English failure dialogs; a low-level failure falls through to
/// debugPrint so nothing is silently swallowed.
Future<void> _pickFolder(
  BuildContext context,
  Future<void> Function(String?) apply,
) async {
  try {
    final dir = await GuardedPicker.getDirectoryPath(
      context,
      category: 'alice_folder',
    );
    if (dir == null || dir.isEmpty) return;
    await apply(dir);
  } catch (e) {
    debugPrint('[AliceSettings] Folder picker failed: $e');
  }
}

/// Shows the home directory as ~ so paths read the way people write them.
String _prettyPath(String path) {
  final home =
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
  if (home != null && home.isNotEmpty && path.startsWith(home)) {
    return '~${path.substring(home.length)}';
  }
  return path;
}

/// One folder row: name, plain-English description, current path, and a
/// Change button that opens a folder picker — never a text field.
///
/// Rows whose folder is real but user-movable pass no [onChange]: the
/// Change button is replaced by an "App database" chip and the description
/// says plainly where the content actually lives.
class _PathRow extends StatelessWidget {
  final String name;
  final String? description;
  final String path;
  final VoidCallback? onChange;

  const _PathRow({
    required this.name,
    this.description,
    required this.path,
    this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onChange = this.onChange;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (description != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ),
                const SizedBox(height: 3),
                Text(
                  _prettyPath(path),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (onChange != null)
            AliceButton(
              label: 'Change',
              ghost: true,
              small: true,
              onPressed: onChange,
            )
          else
            const AliceChip(label: 'App database'),
        ],
      ),
    );
  }
}

/// "Where things live": the folders Alice reads from. Defaults work for
/// most people; Change opens a folder picker, never a text field.
///
/// Every row is genuinely wired: text models drive the existing models
/// plumbing (StorageService.customModelsPath — the folder the model
/// manager and downloads already read); image models feed the built-in
/// image engine's model scan; cards and worlds show their real asset
/// folders and say plainly that the cards themselves live in the
/// database (moving them to files is the bigger vessel job).
class AliceWhereThingsLiveCard extends StatelessWidget {
  const AliceWhereThingsLiveCard({super.key});

  /// The text-model folder: the existing models plumbing (model manager,
  /// downloads, KoboldCpp) already reads StorageService.modelsDir, which
  /// is customModelsPath when set. This row is the new surface for it.
  String _textModelsFolder(StorageService storage) =>
      storage.customModelsPath ?? path.join(storage.rootPath ?? '', 'models');

  @override
  Widget build(BuildContext context) {
    final storage = Provider.of<StorageService>(context);
    final settings = storage.pathSettings;
    return AliceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AliceSectionHead(
            title: 'Where things live',
            subtitle:
                'Alice is the container — these are the folders it reads '
                'from. Defaults work for most people.',
          ),
          _PathRow(
            name: 'Text engine models',
            description:
                'Where Alice looks for the AI that writes your stories.',
            path: _textModelsFolder(storage),
            onChange: () =>
                _pickFolder(context, (dir) => storage.setCustomModelsPath(dir)),
          ),
          _PathRow(
            name: 'Image engine models',
            description:
                'Put image models here — the built-in engine scans this '
                'folder for them.',
            path: settings.imageModelsPath,
            onChange: () => _pickFolder(context, settings.setImageModelsPath),
          ),
          _PathRow(
            name: 'My character cards',
            description:
                'Your characters live in Alice\u2019s database — this folder '
                'holds their portraits and files.',
            path: storage.charactersDir.path,
          ),
          _PathRow(
            name: 'My worlds',
            description:
                'Your worlds live in Alice\u2019s database — Alice keeps '
                'their data files here.',
            path: storage.worldsDir.path,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: AliceButton(
              label: 'Reset all to defaults',
              ghost: true,
              small: true,
              onPressed: () async {
                await storage.setCustomModelsPath(null);
                await settings.resetAllPaths();
                BackupService.dirOverride = null;
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Folders reset to their defaults.'),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Advanced paths, collapsed by default: backups and logs. Both are
/// genuinely wired — backups go through BackupService's folder override,
/// the text engine writes its session log straight into the logs folder.
class AliceAdvancedPathsSection extends StatefulWidget {
  const AliceAdvancedPathsSection({super.key});

  @override
  State<AliceAdvancedPathsSection> createState() =>
      _AliceAdvancedPathsSectionState();
}

class _AliceAdvancedPathsSectionState extends State<AliceAdvancedPathsSection> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = Provider.of<StorageService>(context).pathSettings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _open = !_open),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Text(
                  'Advanced',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  _open
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.keyboard_arrow_right_rounded,
                  color: theme.hintColor,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (_open)
          AliceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AliceSectionHead(title: 'Advanced paths'),
                _PathRow(
                  name: 'Backups',
                  description: 'Where automatic backups of your database go.',
                  path: settings.backupsPath,
                  onChange: () => _pickFolder(context, (dir) async {
                    await settings.setBackupsPath(dir);
                    BackupService.dirOverride = dir;
                  }),
                ),
                _PathRow(
                  name: 'Logs',
                  description: 'Where the text engine writes its session log.',
                  path: settings.logsPath,
                  onChange: () => _pickFolder(context, settings.setLogsPath),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
