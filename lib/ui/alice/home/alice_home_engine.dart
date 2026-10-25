// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice Home: Advanced-only engine status card. Part of alice_home.dart.

part of '../alice_home.dart';

/// Live engine status, shown only at the Advanced detail level.
extension _AliceHomeEngine on _AliceHomeScreenState {
  /// Advanced-only engine status, read live from the engine services.
  Widget _buildEngineStatus(BuildContext context, StorageService storage) {
    return Consumer3<KoboldService, ImageGenService, ChatService>(
      builder: (context, kobold, imageGen, chat, _) {
        final String engineState;
        if (kobold.isStarting) {
          engineState = 'Starting…';
        } else if (kobold.modelReady) {
          final model = kobold.loadedModelPath;
          engineState = model == null || model.isEmpty
              ? 'Ready'
              : 'Ready — ${p.basename(model)}';
        } else if (kobold.isRunning) {
          engineState = 'Running — model not loaded yet';
        } else {
          engineState = 'Not running';
        }

        final queueDepth =
            imageGen.imageQueueDepth + (chat.isGenerating ? 1 : 0);
        final queueState = queueDepth == 0
            ? 'Empty — nothing waiting'
            : '$queueDepth waiting';

        final checkpointMinutes =
            storage.memorySettings.memoryCheckpointMinutes;
        final checkpointState = checkpointMinutes <= 0
            ? 'Off'
            : 'Every $checkpointMinutes min, at a natural pause';

        return AliceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AliceSectionHead(
                title: 'Engine status',
                subtitle: 'Shown at the Advanced detail level',
              ),
              const SizedBox(height: 6),
              AliceKeyValue(
                label: 'Text engine (KoboldCpp)',
                value: engineState,
              ),
              // TODO(alice): per-role model routing (micro-models per NPC
              // role, main model narrates) is the planned architecture; it
              // has no live state to read yet, so this shows the loaded
              // main model until routing lands.
              AliceKeyValue(
                label: 'Model routing',
                value:
                    kobold.loadedModelPath == null ||
                        kobold.loadedModelPath!.isEmpty
                    ? 'No model loaded'
                    : 'Main model: ${p.basename(kobold.loadedModelPath!)}',
              ),
              AliceKeyValue(label: 'Generation queue', value: queueState),
              AliceKeyValue(
                label: 'Memory checkpoints',
                value: checkpointState,
              ),
            ],
          ),
        );
      },
    );
  }
}
