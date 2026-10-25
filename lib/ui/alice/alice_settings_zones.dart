// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

part of 'alice_settings.dart';

/// Alice content-zone card: three radio cards wired to [UiSettings] through
/// the shared [selectContentZone] flow (18+ verification, then the Dead
/// Dove disclaimer). The negotiated-limits checklist is the existing
/// [DeadDovePanel] — embedded while Dead Dove is active, not rebuilt.
class AliceContentZoneCard extends StatelessWidget {
  const AliceContentZoneCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uiSettings = Provider.of<StorageService>(context).uiSettings;
    final zone = uiSettings.contentZone;
    return AliceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AliceSectionHead(
            title: 'Content zone',
            subtitle:
                'Picked at account creation; change it here. Adult '
                'zones are 18+ gated.',
            barColor: AppColors.negativeAccentOf(context),
          ),
          const SizedBox(height: 12),
          for (final z in ContentZone.values) ...[
            _ZoneCard(
              zone: z,
              selected: z == zone,
              onSelect: () => selectContentZone(context, uiSettings, z),
            ),
            const SizedBox(height: 8),
          ],
          if (zone == ContentZone.deadDove) ...[
            const SizedBox(height: 4),
            const DeadDovePanel(),
            const SizedBox(height: 4),
          ],
          Text(
            _activeNote(zone),
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 6),
          Text(
            'Whichever zone you pick, the golden rule above still holds — '
            'zones change content filtering, never the ceiling.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
        ],
      ),
    );
  }

  String _activeNote(ContentZone zone) => switch (zone) {
    ContentZone.commons =>
      'Safe Commons is active: prompts are reshaped toward SFW and '
          'generations are filtered before they reach you.',
    ContentZone.nsfw =>
      'NSFW is active: adult content is allowed; only the hard legal '
          'boundaries stay in place.',
    ContentZone.deadDove =>
      'Dead Dove is active: your compiled lists govern generations; the '
          'minor-safety floor still holds.',
  };
}

/// One zone radio card: label, 18+ chip for adult zones, description and
/// the bound that always holds.
class _ZoneCard extends StatelessWidget {
  const _ZoneCard({
    required this.zone,
    required this.selected,
    required this.onSelect,
  });

  final ContentZone zone;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = AppColors.porchAmberOf(context);
    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? accent : AppColors.borderOf(context),
            width: selected ? 2 : 1,
          ),
          color: selected ? accent.withValues(alpha: 0.08) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    zone.label,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (zone.requiresAdult) ...[
                  AliceChip(
                    label: '18+',
                    color: AppColors.negativeAccentOf(context),
                  ),
                  const SizedBox(width: 8),
                ],
                if (selected) Icon(Icons.check_circle, size: 20, color: accent),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _description(zone),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _boundary(zone),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Plain-English description of what the zone allows.
  String _description(ContentZone zone) => switch (zone) {
    ContentZone.commons =>
      'Full guardrails: SFW-only generation with strict legal filtering. '
          'The cozy default.',
    ContentZone.nsfw =>
      'Adult content allowed; keeps only the hard legal boundaries. '
          '18+ only.',
    ContentZone.deadDove =>
      'Consensual non-consent: the play can look like anything, because '
          'your limits below were negotiated first. Inside them, any fantasy '
          'you define goes. 18+ only.',
  };

  /// What stays blocked even in this zone.
  String _boundary(ContentZone zone) => switch (zone) {
    ContentZone.commons => 'Blocks adult content and anything illegal.',
    ContentZone.nsfw =>
      'Blocks illegal content, including sexual content involving minors.',
    ContentZone.deadDove =>
      'Blocks only the hard legal line: sexual content involving minors. '
          'Everything else passes through untouched.',
  };
}
