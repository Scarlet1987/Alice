// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Memory-checkpoint nudge: every N minutes of chatting (configurable,
// default 30, 0 = off), a gentle, non-blocking, snoozable banner invites the
// user to pin important context to the MC's character card. Pinning adds a
// constant (always-injected) lorebook entry to the card so the character
// remembers it in every future chat.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:front_porch_ai/models/character_card.dart';
import 'package:front_porch_ai/models/lorebook.dart';
import 'package:front_porch_ai/services/services.dart';
import 'package:front_porch_ai/services/storage/storage.dart';
import 'package:front_porch_ai/ui/theme/app_colors.dart';
import 'package:front_porch_ai/ui/theme/porch_design.dart';
import 'package:front_porch_ai/ui/widgets/warm_dialog.dart';

/// Shows [MemoryCheckpointBanner] on a timer driven by
/// [MemorySettings.memoryCheckpointMinutes].
///
/// Set [defer] while the user is actively typing or a reply is streaming:
/// the nudge waits for a natural pause instead of ambushing mid-thought.
class MemoryCheckpointNudge extends StatefulWidget {
  final CharacterCard character;
  final bool defer;

  const MemoryCheckpointNudge({
    super.key,
    required this.character,
    this.defer = false,
  });

  @override
  State<MemoryCheckpointNudge> createState() => _MemoryCheckpointNudgeState();
}

class _MemoryCheckpointNudgeState extends State<MemoryCheckpointNudge> {
  Timer? _timer;
  Timer? _deferTimer;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _arm();
  }

  @override
  void didUpdateWidget(MemoryCheckpointNudge oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new chat session restarts the checkpoint clock.
    if (oldWidget.character != widget.character) {
      _disarm();
      setState(() => _visible = false);
      _arm();
    }
    // A natural pause arrived while we were deferring: show the nudge now.
    if (oldWidget.defer && !widget.defer && _deferTimer != null) {
      _deferTimer?.cancel();
      _deferTimer = null;
      if (mounted) setState(() => _visible = true);
    }
  }

  @override
  void dispose() {
    _disarm();
    super.dispose();
  }

  void _arm() {
    final minutes = context
        .read<StorageService>()
        .memorySettings
        .memoryCheckpointMinutes;
    if (minutes <= 0) return;
    _timer = Timer(Duration(minutes: minutes), _onFire);
  }

  void _onFire() {
    if (!mounted) return;
    // Respect the user's flow: if they're typing or a reply is streaming,
    // wait for a natural pause (didUpdateWidget fires the nudge when defer
    // clears). Backstop: show anyway after 5 minutes.
    if (widget.defer) {
      _deferTimer = Timer(const Duration(minutes: 5), () {
        if (mounted) setState(() => _visible = true);
      });
      return;
    }
    setState(() => _visible = true);
  }

  void _disarm() {
    _timer?.cancel();
    _timer = null;
    _deferTimer?.cancel();
    _deferTimer = null;
  }

  void _snooze() {
    setState(() => _visible = false);
    _disarm();
    _arm();
  }

  Future<void> _pinNote() async {
    final controller = TextEditingController();
    final note = await showWarmDialog<String>(
      context,
      title: 'Pin a memory',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What should ${widget.character.name} always remember? '
            'It becomes a permanent note on their character card.',
            style: PorchType.body(context),
          ),
          const SizedBox(height: PorchSpacing.sm),
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
        warmDialogCancel(context),
        warmDialogConfirm(
          context,
          label: 'Pin it',
          onPressed: () {
            final text = controller.text.trim();
            Navigator.of(context).pop(text.isEmpty ? null : text);
          },
        ),
      ],
    );
    controller.dispose();
    if (note == null || !mounted) return;

    final character = widget.character;
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

    if (!mounted) return;
    _snooze();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pinned to ${character.name}\u2019s card.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: _visible
          ? _MemoryCheckpointBanner(
              characterName: widget.character.name,
              onPin: _pinNote,
              onSnooze: _snooze,
              onDismiss: _snooze,
            )
          : const SizedBox.shrink(),
    );
  }
}

class _MemoryCheckpointBanner extends StatelessWidget {
  final String characterName;
  final VoidCallback onPin;
  final VoidCallback onSnooze;
  final VoidCallback onDismiss;

  const _MemoryCheckpointBanner({
    required this.characterName,
    required this.onPin,
    required this.onSnooze,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PorchSpacing.md,
        PorchSpacing.sm,
        PorchSpacing.md,
        0,
      ),
      child: PorchCard(
        padding: const EdgeInsets.all(PorchSpacing.sm),
        child: Row(
          children: [
            Icon(
              Icons.push_pin_outlined,
              color: AppColors.porchAmberOf(context),
              size: 20,
            ),
            const SizedBox(width: PorchSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Memory checkpoint',
                    style: PorchType.bodySmall(
                      context,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Anything $characterName should always remember? '
                    'Pin it to their card.',
                    style: PorchType.hint(context),
                  ),
                ],
              ),
            ),
            TextButton(onPressed: onPin, child: const Text('Pin a note')),
            TextButton(onPressed: onSnooze, child: const Text('Snooze')),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: 'Dismiss',
              onPressed: onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}
