// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

part of 'alice_settings.dart';

/// About & License: the Alice edition credits plus the license line.
class AliceAboutSection extends StatelessWidget {
  const AliceAboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AliceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AliceSectionHead(
            title: 'About & License',
            subtitle: 'Who built this edition, and the license it ships under.',
          ),
          const SizedBox(height: 12),
          const AliceEditionCreditsCard(),
          const SizedBox(height: 10),
          Text(
            'Rabbit Hole is free software, licensed under the GNU Affero '
            'General Public License v3.0.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
        ],
      ),
    );
  }
}

/// Credits for the Alice edition re-engineering: the design lead who
/// directed the engine overhaul, the GUI redesign, and the creator systems.
/// Shared with Settings > General > About & License — shown on the Alice
/// branch only.
class AliceEditionCreditsCard extends StatelessWidget {
  const AliceEditionCreditsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardOf(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.porchAmberOf(context), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                size: 18,
                color: AppColors.porchAmberOf(context),
              ),
              const SizedBox(width: 8),
              Text(
                'The Alice edition',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'This build is the Alice edition — a ground-up re-engineering '
            'of Front Porch AI, directed by Scarlet1987: the engine overhaul '
            'under the hood, the full interface redesign, the Dead Dove '
            'negotiated-limits model, the Main Character board, and the '
            'Kardashev civilization system.',
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Front Porch AI was created by linux4life1. Alice is an '
            'independent edition, and its updates are published from '
            "Scarlet1987's repository.",
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
