// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

part of 'alice_settings.dart';

/// "Engines": what's plugged into Alice at a glance. Alice is the
/// container; the engines make the quality happen. Swap jumps to the detail
/// card for that engine, further down this screen. The game engine slot is
/// reserved for Alice 9 — there is nothing to swap to yet.
class AliceEnginesCard extends StatelessWidget {
  final VoidCallback? onSwapText;
  final VoidCallback? onSwapImage;

  const AliceEnginesCard({super.key, this.onSwapText, this.onSwapImage});

  @override
  Widget build(BuildContext context) {
    final storage = Provider.of<StorageService>(context);
    final kobold = context.watch<KoboldService>();
    final backend = storage.imageGenSettings.imageGenBackend;
    return AliceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AliceSectionHead(
            title: 'Engines',
            subtitle:
                "What's plugged into Alice. Swap engines without Alice caring.",
          ),
          _EngineRow(
            name: 'Text engine — KoboldCpp',
            detail: _textEngineDetail(kobold),
            active: kobold.isReady || kobold.isRunning,
            onSwap: onSwapText,
          ),
          _EngineRow(
            name: 'Image engine — ${_imageEngineLabel(backend)}',
            detail: backend == 'native'
                ? 'Built-in · In development — it finds your models, '
                      'generation isn\u2019t wired yet'
                : 'Configured · Runs ${_imageEngineWhere(backend)}',
            active: true,
            onSwap: onSwapImage,
          ),
          const _EngineRow(
            name: 'Game engine — none',
            detail: 'Alice 9',
            active: false,
          ),
        ],
      ),
    );
  }

  static String _imageEngineLabel(String backend) {
    switch (backend) {
      case 'remote':
        return 'Remote';
      case 'native':
        return 'Built-in';
      case 'a1111':
        return 'Automatic1111';
      case 'drawthings':
        return 'Draw Things';
      default:
        return 'Built-in';
    }
  }

  static String _imageEngineWhere(String backend) {
    switch (backend) {
      case 'remote':
        return 'on another machine or service';
      case 'a1111':
        return 'inside Automatic1111';
      case 'drawthings':
        return 'inside Draw Things';
      default:
        return 'inside Alice';
    }
  }

  /// Real text-engine state from the KoboldCpp service: running or not,
  /// and the file name of the loaded model when there is one.
  static String _textEngineDetail(KoboldService kobold) {
    if (kobold.isReady) {
      final model = kobold.loadedModelPath;
      if (model != null && model.isNotEmpty) {
        return 'Running · ${path.basename(model)}';
      }
      return 'Running';
    }
    if (kobold.isRunning) return 'Starting up…';
    return 'Not running — it starts when your story needs it.';
  }
}

/// One engine row: status dot, name, detail line, optional Swap button.
class _EngineRow extends StatelessWidget {
  final String name;
  final String detail;
  final bool active;
  final VoidCallback? onSwap;

  const _EngineRow({
    required this.name,
    required this.detail,
    required this.active,
    this.onSwap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? AppColors.porchAmber : theme.dividerColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: active ? null : theme.hintColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
          if (onSwap != null) ...[
            const SizedBox(width: 10),
            AliceButton(
              label: 'Swap',
              ghost: true,
              small: true,
              onPressed: onSwap,
            ),
          ],
        ],
      ),
    );
  }
}
