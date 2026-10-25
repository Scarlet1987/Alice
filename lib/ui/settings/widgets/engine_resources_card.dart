// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// This file is part of Front Porch AI.
//
// Front Porch AI is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:front_porch_ai/services/services.dart';
import 'package:front_porch_ai/services/storage/storage.dart';
import 'package:front_porch_ai/ui/theme/app_colors.dart';
import 'package:front_porch_ai/ui/theme/porch_design.dart';
import 'package:front_porch_ai/ui/widgets/detail_level_control.dart';

/// Settings → Backend: the Engine resources card.
///
/// Dual-engine memory policy, surfaced as knobs: where the text engine
/// places model layers (VRAM vs system RAM) and where the image engine
/// parks model weights between generations, over auto-detected VRAM/RAM.
/// Stability first: generations queue with backpressure instead of being
/// dropped. The knobs persist here; the engines apply them at launch.
class EngineResourcesCard extends StatelessWidget {
  const EngineResourcesCard({super.key});

  static String _gb(int mb) {
    if (mb <= 0) return 'unknown';
    final gb = mb / 1024;
    return gb >= 10 ? '${gb.round()} GB' : '${gb.toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final storage = Provider.of<StorageService>(context);
    final engines = storage.engineResourcesSettings;
    final hw = Provider.of<HardwareService>(context).hardwareInfo;

    return PorchCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PorchSectionHeader(
            title: 'Engine resources',
            helper:
                'How the text and image engines share your machine\u2019s '
                'memory. Applies the next time each engine starts.',
          ),
          // Auto-detected hardware line.
          Container(
            padding: const EdgeInsets.all(PorchSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.sunkenSurfaceOf(context),
              borderRadius: BorderRadius.circular(PorchRadius.md),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.memory_outlined,
                  size: 20,
                  color: AppColors.porchAmberOf(context),
                ),
                const SizedBox(width: PorchSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hw == null
                            ? 'Detecting hardware…'
                            : '${hw.gpuName} · ${_gb(hw.vramMb)} VRAM',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hw == null
                            ? ''
                            : '${_gb(hw.ramMb)} system RAM · auto-detected',
                        style: PorchType.caption(context),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: PorchSpacing.sm,
                    vertical: PorchSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bondHighOf(
                      context,
                    ).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(PorchRadius.pill),
                  ),
                  child: Text(
                    'Auto-detect',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.bondHighOf(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: PorchSpacing.lg),
          // Live memory: refreshes while engines run, not read-once.
          const _LiveMemoryRow(),
          const SizedBox(height: PorchSpacing.md),
          // Engine health: live state from both engines; the scheduler
          // note explains what's happening in plain language.
          _HealthRow(engines: engines),
          const SizedBox(height: PorchSpacing.md),
          // Character cards are data, not models: one resident model serves
          // every card via context swapping. Adding cards costs no VRAM.
          Container(
            padding: const EdgeInsets.all(PorchSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.sunkenSurfaceOf(context),
              borderRadius: BorderRadius.circular(PorchRadius.md),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: AppColors.textSecondary(context),
                ),
                const SizedBox(width: PorchSpacing.sm),
                Expanded(
                  child: Text(
                    'Character cards are data, not models — one model '
                    'resident in VRAM serves every character card via '
                    'context swapping. Adding character cards doesn\u2019t '
                    'cost VRAM.',
                    style: PorchType.caption(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: PorchSpacing.lg),
          _PlacementRow(
            title: 'Text engine — layer placement',
            helper:
                'Where the model\u2019s layers live. System RAM offloads '
                'layers (and their KV cache — layers travel with their '
                'cache) to free VRAM for active compute. Applies on next '
                'launch.',
            value: engines.textKvCache,
            onChanged: engines.setTextKvCache,
          ),
          const SizedBox(height: PorchSpacing.md),
          _PlacementRow(
            title: 'Image engine — model weights',
            helper:
                'Where image weights park between generations. Parked weights '
                'stream to VRAM while generating.',
            value: engines.imageWeights,
            onChanged: engines.setImageWeights,
          ),
          const SizedBox(height: PorchSpacing.md),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Never drop a generation',
              style: TextStyle(color: AppColors.textPrimary(context)),
            ),
            subtitle: Text(
              'Queue work with backpressure instead of failing when both '
              'engines are busy. Stability first, speed second.',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary(context),
              ),
            ),
            value: engines.queueWithBackpressure,
            onChanged: engines.setQueueWithBackpressure,
          ),
          // Advanced: detail→context linkage.
          DetailGate(
            required: DetailLevel.advanced,
            label: 'Show engine tuning',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: PorchSpacing.md),
                Text(
                  'Detail level → context',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 2),
                Consumer<StorageService>(
                  builder: (context, s, _) {
                    final level = s.uiSettings.detailLevel;
                    return Text(
                      'Detail level ${level.label}: collapsed sections page '
                      'in only their broad slice; expanded sections page in '
                      'the deeper slice. Context is never spent on detail '
                      'you aren\u2019t looking at.',
                      style: PorchType.caption(context),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Live free-memory readout. Polls the hardware service every few seconds
/// while this card is visible so the numbers track engines loading and
/// unloading — not a read-once snapshot.
class _LiveMemoryRow extends StatefulWidget {
  const _LiveMemoryRow();

  @override
  State<_LiveMemoryRow> createState() => _LiveMemoryRowState();
}

class _LiveMemoryRowState extends State<_LiveMemoryRow> {
  Timer? _timer;
  FreeMemoryMb? _free;

  @override
  void initState() {
    super.initState();
    _poll();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _poll());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    if (!mounted) return;
    try {
      final hw = Provider.of<HardwareService>(context, listen: false);
      final free = await hw.readFreeMemory();
      if (mounted) setState(() => _free = free);
    } catch (_) {
      // Best-effort: leave the last reading up.
    }
  }

  @override
  Widget build(BuildContext context) {
    final free = _free;
    return Container(
      padding: const EdgeInsets.all(PorchSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.sunkenSurfaceOf(context),
        borderRadius: BorderRadius.circular(PorchRadius.md),
      ),
      child: Row(
        children: [
          Icon(
            Icons.monitor_heart_outlined,
            size: 20,
            color: AppColors.porchAmberOf(context),
          ),
          const SizedBox(width: PorchSpacing.md),
          Expanded(
            child: Text(
              free == null
                  ? 'Reading live memory…'
                  : '${EngineResourcesCard._gb(free.graphics ?? 0)} VRAM free'
                      ' · ${EngineResourcesCard._gb(free.system ?? 0)} RAM free',
              style: PorchType.caption(context),
            ),
          ),
          const SizedBox(width: PorchSpacing.sm),
          Text('live', style: PorchType.caption(context)),
        ],
      ),
    );
  }
}

class _HealthRow extends StatelessWidget {  const _HealthRow({required this.engines});

  final EngineResourcesSettings engines;

  @override
  Widget build(BuildContext context) {
    // Live engine state, not just the toggle: text engine phase plus
    // image queue depth and current status.
    final koboldPhase = context.select<KoboldService, KoboldPhase>(
      (k) => k.phase,
    );
    final imgDepth = context.select<ImageGenService, int>(
      (i) => i.imageQueueDepth,
    );
    final imgStatus = context.select<ImageGenService, String>(
      (i) => i.statusMessage,
    );
    final textUp = koboldPhase == KoboldPhase.ready;
    final queueOn = engines.queueWithBackpressure;
    final stable = queueOn && (textUp || imgDepth == 0);
    final color = stable
        ? AppColors.bondHighOf(context)
        : AppColors.negativeAccentOf(context);
    final detail = StringBuffer();
    detail.write('Text engine: ${koboldPhase.name}. ');
    if (imgDepth > 0) {
      detail.write('Image: $imgDepth queued/active. ');
    }
    if (imgStatus.isNotEmpty) detail.write(imgStatus);
    if (!queueOn) {
      detail.write('Queue-don\u2019t-drop is off: a busy engine may fail '
          'a generation instead of queueing it.');
    }
    return Container(
      padding: const EdgeInsets.all(PorchSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(PorchRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            stable ? Icons.check_circle_outline : Icons.warning_amber_outlined,
            size: 20,
            color: color,
          ),
          const SizedBox(width: PorchSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stable ? 'Engines stable' : 'Engines busy',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail.toString().trim(),
                  style: PorchType.caption(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlacementRow extends StatelessWidget {
  const _PlacementRow({
    required this.title,
    required this.helper,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String helper;
  final EngineMemoryPlacement value;
  final ValueChanged<EngineMemoryPlacement> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(helper, style: PorchType.caption(context)),
            ],
          ),
        ),
        const SizedBox(width: PorchSpacing.md),
        DropdownButton<EngineMemoryPlacement>(
          value: value,
          dropdownColor: AppColors.surfaceContainerOf(context),
          style: TextStyle(color: AppColors.textPrimary(context), fontSize: 13),
          underline: const SizedBox.shrink(),
          items: [
            for (final p in EngineMemoryPlacement.values)
              DropdownMenuItem(value: p, child: Text(p.label)),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }
}
