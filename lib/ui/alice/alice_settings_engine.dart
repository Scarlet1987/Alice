// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

part of 'alice_settings.dart';

/// Formats megabytes as gigabytes for the memory readouts.
String _gb(int mb) {
  if (mb <= 0) return 'unknown';
  final gb = mb / 1024;
  return gb >= 10 ? '${gb.round()} GB' : '${gb.toStringAsFixed(1)} GB';
}

/// Alice Engine resources card: GPU well with auto-detect, live VRAM/RAM
/// bars from real hardware readings, and the placement knobs wired to
/// [EngineResourcesSettings]. The knobs persist here; the engines apply
/// them the next time each engine starts. Engine behavior (queueing,
/// VRAM arbitration, parking) is untouched — this is only the surface.
class AliceEngineResourcesCard extends StatelessWidget {
  const AliceEngineResourcesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final engines = Provider.of<StorageService>(
      context,
    ).engineResourcesSettings;
    return AliceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AliceSectionHead(
            title: 'Engine resources',
            subtitle:
                'How the text and image engines share your machine\u2019s '
                'memory. Applies the next time each engine starts.',
          ),
          const SizedBox(height: 12),
          const _GpuWell(),
          const SizedBox(height: 14),
          const _LiveMemoryBars(),
          const SizedBox(height: 14),
          const _MemoryBudgetSection(),
          const SizedBox(height: 14),
          _PlacementRow(
            title: 'Text engine placement',
            helper:
                'Where the model\u2019s layers live. System RAM offloads '
                'layers (and their KV cache — layers travel with their cache) '
                'to free VRAM for active compute. Applies on next launch.',
            values: const [
              EngineMemoryPlacement.auto,
              EngineMemoryPlacement.vram,
              EngineMemoryPlacement.ram,
            ],
            labels: const ['Auto', 'VRAM', 'RAM'],
            value: engines.textKvCache,
            onChanged: engines.setTextKvCache,
          ),
          const SizedBox(height: 12),
          _PlacementRow(
            title: 'Image engine placement',
            helper:
                'Where image weights park between generations. Parked '
                'weights stream to VRAM while generating.',
            values: const [
              EngineMemoryPlacement.auto,
              EngineMemoryPlacement.ram,
              EngineMemoryPlacement.vram,
            ],
            labels: const ['Auto', 'Park in RAM', 'VRAM'],
            value: engines.imageWeights,
            onChanged: engines.setImageWeights,
          ),
          const SizedBox(height: 12),
          Text(
            'Character cards are data, not models — one resident model serves '
            'every card by context swapping, so characters cost no VRAM. '
            'Generations queue with backpressure and are never dropped.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
        ],
      ),
    );
  }
}

/// Auto-detected GPU + system RAM, with a chip that re-runs detection.
/// Detection itself lives in [HardwareService]; this only surfaces it.
class _GpuWell extends StatefulWidget {
  const _GpuWell();

  @override
  State<_GpuWell> createState() => _GpuWellState();
}

class _GpuWellState extends State<_GpuWell> {
  bool _detecting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hw = Provider.of<HardwareService>(context).hardwareInfo;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.sunkenSurfaceOf(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.memory_outlined,
            size: 20,
            color: AppColors.porchAmberOf(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hw == null
                      ? 'Detecting hardware\u2026'
                      : '${hw.gpuName} · ${_gb(hw.vramMb)} VRAM',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hw == null
                      ? ''
                      : '${_gb(hw.ramMb)} system RAM · auto-detected',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
          AlicePressable(
            onTap: _detecting ? null : _redetect,
            child: AliceChip(
              label: _detecting ? 'Detecting\u2026' : 'Auto-detect',
              color: AppColors.bondHighOf(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _redetect() async {
    setState(() => _detecting = true);
    try {
      await Provider.of<HardwareService>(
        context,
        listen: false,
      ).detectHardware();
    } finally {
      if (mounted) setState(() => _detecting = false);
    }
  }
}

/// Live VRAM / system-RAM bars. Totals come from the auto-detected
/// [HardwareInfo]; the used slice is total minus the live free reading,
/// polled every few seconds while this card is visible — not a read-once
/// snapshot. The services don't expose a per-engine (model vs KV) split,
/// so the bars honestly show "in use by engines" vs free.
class _LiveMemoryBars extends StatefulWidget {
  const _LiveMemoryBars();

  @override
  State<_LiveMemoryBars> createState() => _LiveMemoryBarsState();
}

class _LiveMemoryBarsState extends State<_LiveMemoryBars> {
  Timer? _timer;
  FreeMemoryMb? _free;
  bool _polled = false;

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
      final free = await Provider.of<HardwareService>(
        context,
        listen: false,
      ).readFreeMemory();
      if (mounted) {
        setState(() {
          _free = free;
          _polled = true;
        });
      }
    } catch (_) {
      // Best-effort: keep the last reading up. The poll still counts as
      // settled — the bar must not sit on "reading…" forever when this
      // machine simply cannot report free graphics memory.
      if (mounted) setState(() => _polled = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hw = Provider.of<HardwareService>(context).hardwareInfo;
    final totalVram = hw?.vramMb ?? 0;
    final totalRam = hw?.ramMb ?? 0;
    final free = _free;
    return Column(
      children: [
        _MemoryBar(
          title: 'VRAM — ${_gb(totalVram)}',
          totalMb: totalVram,
          freeMb: free?.graphics,
          live: free?.graphics != null,
          settled: _polled,
        ),
        const SizedBox(height: 10),
        _MemoryBar(
          title: 'System RAM — ${_gb(totalRam)}',
          totalMb: totalRam,
          freeMb: free?.system,
          live: free?.system != null,
          settled: _polled,
        ),
      ],
    );
  }
}

/// One stacked memory bar: the used slice (teal) over the sunken track.
/// Widths are real megabytes, not mock percentages.
class _MemoryBar extends StatelessWidget {
  const _MemoryBar({
    required this.title,
    required this.totalMb,
    required this.freeMb,
    required this.live,
    required this.settled,
  });

  final String title;
  final int totalMb;
  final int? freeMb;
  final bool live;

  /// True once at least one free-memory poll has completed. Before that
  /// the bar honestly says "reading…"; after it, a missing reading says
  /// "unavailable" instead of pretending a reading is still coming.
  final bool settled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final free = freeMb;
    final used = (totalMb > 0 && free != null)
        ? (totalMb - free).clamp(0, totalMb)
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
            ),
            Text(
              live
                  ? 'live'
                  : settled
                  ? 'unavailable'
                  : 'reading\u2026',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.sunkenSurfaceOf(context),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: AppColors.borderOf(context)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: Row(
              children: [
                if (used != null && used > 0)
                  Expanded(
                    flex: used,
                    child: ColoredBox(color: AppColors.porchAmberOf(context)),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _LegendDot(
              color: AppColors.porchAmberOf(context),
              label: used == null
                  ? 'In use by engines'
                  : 'In use by engines — ${_gb(used)}',
            ),
            const SizedBox(width: 14),
            _LegendDot(
              color: AppColors.borderOf(context),
              label: used == null ? 'Free' : 'Free — ${_gb(totalMb - used)}',
            ),
          ],
        ),
      ],
    );
  }
}

/// Legend dot + label.
class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
        ),
      ],
    );
  }
}

/// Label + helper on the left, segmented placement control on the right.
class _PlacementRow extends StatelessWidget {
  const _PlacementRow({
    required this.title,
    required this.helper,
    required this.values,
    required this.labels,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String helper;
  final List<EngineMemoryPlacement> values;
  final List<String> labels;
  final EngineMemoryPlacement value;
  final ValueChanged<EngineMemoryPlacement> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                helper,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        AliceSegmentedControl<EngineMemoryPlacement>(
          values: values,
          labels: labels,
          selected: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
