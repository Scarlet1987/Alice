// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

part of 'alice_settings.dart';

/// Step for the budget stepper, in MB.
const int _kBudgetStepMb = 512;

/// The harness memory budget section of the Engine resources card: a live
/// bar of the app's own memory against the budget, a stepper to change the
/// budget, and a one-tap "Free up memory" when over budget. The estimate is
/// cheap (one RSS read plus the engine registry) and polls on the same
/// cadence as [_LiveMemoryBars]. Model weights are NOT in this number —
/// they live in the graphics budget the fit math manages.
class _MemoryBudgetSection extends StatefulWidget {
  const _MemoryBudgetSection();

  @override
  State<_MemoryBudgetSection> createState() => _MemoryBudgetSectionState();
}

class _MemoryBudgetSectionState extends State<_MemoryBudgetSection> {
  Timer? _timer;
  MemoryUsageEstimate? _estimate;
  bool _freeing = false;

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

  void _poll() {
    if (!mounted) return;
    setState(() => _estimate = MemoryBudget.estimateNow());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final engines = Provider.of<StorageService>(
      context,
    ).engineResourcesSettings;
    final budget = engines.totalMemoryBudgetMb;
    final estimate = _estimate;
    final used = estimate?.totalMb ?? 0;
    final over = estimate != null && !estimate.fitsInBudget(budget);
    // Promoted inside the ternary: no `?.` or `!` at the use site.
    final biggest = estimate == null ? null : estimate.largestConsumer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Memory budget',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'The most memory the app itself may hold. Model weights live in '
          'the graphics budget, not here.',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        ),
        const SizedBox(height: 8),
        _BudgetBar(usedMb: used, budgetMb: budget, over: over),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                _gb(budget),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: over ? AppColors.bondNegOf(context) : null,
                ),
              ),
            ),
            _BudgetStepButton(
              icon: Icons.remove,
              onTap: () =>
                  engines.setTotalMemoryBudgetMb(budget - _kBudgetStepMb),
            ),
            const SizedBox(width: 8),
            _BudgetStepButton(
              icon: Icons.add,
              onTap: () =>
                  engines.setTotalMemoryBudgetMb(budget + _kBudgetStepMb),
            ),
          ],
        ),
        if (over) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Over budget — ${biggest ?? 'the app itself'} '
                  'is using the most.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.bondNegOf(context),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _freeing ? null : _freeUpMemory,
                child: AliceChip(
                  label: _freeing ? 'Freeing…' : 'Free up memory',
                  color: AppColors.bondHighOf(context),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Unloads idle engines and clears the image cache, then says what
  /// happened in plain words. Never throws: a missing provider in a test
  /// rig simply means that engine is not there to free.
  Future<void> _freeUpMemory() async {
    setState(() => _freeing = true);
    var freed = false;
    try {
      freed =
          await Provider.of<KoboldService>(
            context,
            listen: false,
          ).unloadForEngineHandoff() ||
          freed;
    } catch (e) {
      debugPrint('[Memory] free-up: text engine unavailable: $e');
    }
    try {
      freed =
          await Provider.of<ImageGenService>(
            context,
            listen: false,
          ).releaseMemoryForBudget() ||
          freed;
    } catch (e) {
      debugPrint('[Memory] free-up: image engine unavailable: $e');
    }
    // Flutter's own image cache is harness memory too.
    imageCache.clear();
    if (mounted) setState(() => _freeing = false);
    _poll();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          freed
              ? 'Memory freed — idle engines were unloaded.'
              : 'Nothing idle to unload. What\u2019s in use is active.',
        ),
      ),
    );
  }
}

/// One budget bar: the used slice over the sunken track, red when over
/// budget. Widths are real megabytes, not mock percentages.
class _BudgetBar extends StatelessWidget {
  const _BudgetBar({
    required this.usedMb,
    required this.budgetMb,
    required this.over,
  });

  final int usedMb;
  final int budgetMb;
  final bool over;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final used = usedMb.clamp(0, budgetMb);
    final color = over
        ? AppColors.bondNegOf(context)
        : AppColors.porchAmberOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                MemoryBudget.usageLabel(usedMb: usedMb, budgetMb: budgetMb),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
            ),
            Text(
              'live',
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
                if (used > 0)
                  Expanded(
                    flex: used,
                    child: ColoredBox(color: color),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _LegendDot(color: color, label: 'Used — ${_gb(used)}'),
            const SizedBox(width: 14),
            _LegendDot(
              color: AppColors.borderOf(context),
              label: 'Free — ${_gb(budgetMb - used)}',
            ),
          ],
        ),
      ],
    );
  }
}

/// Small − / + button for the budget stepper.
class _BudgetStepButton extends StatelessWidget {
  const _BudgetStepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.sunkenSurfaceOf(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderOf(context)),
        ),
        child: Icon(icon, size: 16, color: AppColors.porchAmberOf(context)),
      ),
    );
  }
}
