// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice v9 shell, restyled to the Alice Demo Space (2026-11-09, the
// entire design): the Demo hero — big serif Alice, "Follow the white
// rabbit.", pitch left, buy-once card right — then the nav row and the
// four pages in an IndexedStack, so page state survives switching, and
// the Demo mint bar at the foot. No placeholder credits anywhere: the
// hero carries no credits, and credits live with FAQ on Home.

import 'package:flutter/material.dart';

import 'package:front_porch_ai/ui/alice/v9/alice_v9_creator.dart';
import 'package:front_porch_ai/ui/alice/v9/alice_v9_home.dart';
import 'package:front_porch_ai/ui/alice/v9/alice_v9_models.dart';
import 'package:front_porch_ai/ui/alice/v9/alice_v9_profile.dart';
import 'package:front_porch_ai/ui/alice/v9/alice_v9_state.dart';
import 'package:front_porch_ai/ui/alice/v9/alice_v9_widgets.dart';
import 'package:front_porch_ai/ui/theme/app_colors.dart';

class AliceV9Shell extends StatefulWidget {
  const AliceV9Shell({super.key});

  @override
  State<AliceV9Shell> createState() => _AliceV9ShellState();
}

class _AliceV9ShellState extends State<AliceV9Shell> {
  late final AliceV9State _state;

  @override
  void initState() {
    super.initState();
    _state = AliceV9State();
    // Restore the user profile and the creator draft before first paint
    // so a saved custom gender / pronoun is showing, not the default.
    _state.loadUserProfile();
    _state.loadCreatorDraft();
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _state,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.aliceInk,
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.aliceHeroDeep,
                  AppColors.aliceInk,
                  AppColors.aliceForest,
                ],
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // The overflow Elaina hit on metal (2026-11-13): a 393px
                // tall window is shorter than the full hero, so a fixed
                // Column overflowed by 240px and the content below the
                // hero was unreachable. In a short window the hero
                // compacts, and it scrolls inside its own space rather
                // than overflowing the shell.
                //
                // The scroll is compact-only, on purpose. In a tall
                // window the hero used to keep its own scroll view too,
                // so the mouse wheel over the hero scrolled the hero
                // away (hiding the Alice title) while the page below
                // stayed put — two scroll regions fighting over one
                // wheel, and the clipped tops Elaina saw on metal
                // (2026-11-13). In a tall window the hero is fixed and
                // the wheel belongs to the page.
                final compact = constraints.maxHeight < 650;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Tall window: the hero is a plain child that takes
                    // its natural height, and the page below takes the
                    // rest. It must NOT sit in a Flexible here — a
                    // Flexible shares the leftover height 50/50 with the
                    // page's Expanded, so the hero only got ~300px at
                    // 1280x720 and its card overflowed by 174px.
                    // Short window: compact + scrolled in its own space,
                    // as before.
                    if (compact)
                      Flexible(
                        fit: FlexFit.loose,
                        child: SingleChildScrollView(
                          child: _Hero(compact: true),
                        ),
                      )
                    else
                      const _Hero(),
                    _PageNav(state: _state),
                    Expanded(
                      child: IndexedStack(
                        index: _state.page.index,
                        children: [
                          AliceV9HomePage(state: _state),
                          AliceV9ModelsPage(state: _state),
                          AliceV9CreatorPage(state: _state),
                          AliceV9ProfilePage(state: _state),
                        ],
                      ),
                    ),
                    const _MintBar(),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// The Demo Space hero: big serif Alice in mint, italic tagline, the
/// pitch on the left with its fact pills, and the buy-once card on the
/// right. No credits in the hero — credits live with FAQ on Home.
class _Hero extends StatelessWidget {
  final bool compact;

  const _Hero({this.compact = false});

  static const _facts = [
    'Runs 100% on your machine',
    'Character chat & roleplay',
    'Image generation built in',
    'Voices with text-to-speech',
    'Open source · AGPL-3.0',
  ];

  static const _ownPoints = [
    'Buy it once — never rent it, never subscribe',
    'Chats stay on your disk, encrypted at rest',
    'Happy on everyday hardware — an 8 GB graphics card is plenty',
    'Source is free on GitHub — the \$25 buys the packaged installer',
  ];

  @override
  Widget build(BuildContext context) {
    final pitch = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alice',
          style: TextStyle(
            fontFamily: 'Cormorant Garamond',
            fontFamilyFallback: ['Georgia'],
            fontSize: compact ? 48 : 72,
            fontWeight: FontWeight.w700,
            height: 0.92,
            color: AppColors.aliceMint,
            shadows: [
              Shadow(
                color: AppColors.aliceGreen,
                offset: Offset(0, 6),
                blurRadius: 34,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '“Follow the white rabbit.”',
          style: TextStyle(
            fontFamily: 'Cormorant Garamond',
            fontFamilyFallback: ['Georgia'],
            fontStyle: FontStyle.italic,
            fontSize: compact ? 20 : 28,
            color: AppColors.aliceSage,
          ),
        ),
        SizedBox(height: compact ? 10 : 18),
        Text(
          'Alice is a local-first AI companion for character chat and '
          'storytelling. The characters, the model, and the conversation '
          'all live on your own computer — Windows, Mac, or Linux — with '
          'no account and no cloud in between.',
          style: TextStyle(
            fontSize: compact ? 15 : 18,
            color: AppColors.aliceLede,
          ),
        ),
        if (!compact) const SizedBox(height: 24),
        if (!compact)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final fact in _facts)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.aliceMint.withValues(alpha: 0.4),
                    ),
                    borderRadius: BorderRadius.circular(999),
                    color: AppColors.aliceMint.withValues(alpha: 0.08),
                  ),
                  child: Text(
                    fact,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.aliceMint,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
    final card = Container(
      padding: EdgeInsets.fromLTRB(22, compact ? 14 : 22, 22, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.aliceSage.withValues(alpha: 0.14),
            AppColors.aliceSage.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(color: AppColors.aliceMint.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'A program you own',
            style: TextStyle(
              fontFamily: 'Cormorant Garamond',
              fontFamilyFallback: ['Georgia'],
              fontSize: compact ? 22 : 27,
              fontWeight: FontWeight.w600,
              color: AppColors.aliceMint,
            ),
          ),
          if (!compact) const SizedBox(height: 6),
          if (!compact)
            const Text(
              'From Rabbit Hole — software you buy once and keep, the way '
              'programs used to work.',
              style: TextStyle(fontSize: 15, color: AppColors.aliceLede),
            ),
          if (!compact) const SizedBox(height: 14),
          if (!compact)
            for (final point in _ownPoints)
              Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '✓ ',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.aliceMint,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        point,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.aliceSage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          Container(
            margin: const EdgeInsets.only(top: 9),
            padding: const EdgeInsets.only(top: 14),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppColors.aliceMint.withValues(alpha: 0.25),
                ),
              ),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '\$25',
                  style: TextStyle(
                    fontFamily: 'Cormorant Garamond',
                    fontFamilyFallback: ['Georgia'],
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: AppColors.aliceMint,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'one-time purchase · pay what you want above the '
                    'minimum on itch.io',
                    style: TextStyle(fontSize: 14, color: AppColors.aliceLede),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(28, compact ? 16 : 32, 28, 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 900) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                pitch,
                SizedBox(height: compact ? 12 : 24),
                card,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 5, child: pitch),
              const SizedBox(width: 34),
              Expanded(flex: 3, child: card),
            ],
          );
        },
      ),
    );
  }
}

/// The Demo Space reverse bar: sage-to-dark mint band at the foot.
class _MintBar extends StatelessWidget {
  const _MintBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.aliceSage2,
            AppColors.aliceSage3,
            AppColors.aliceInk,
          ],
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              'One-time purchase. No subscription, no rent, no cloud.',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.aliceInk,
              ),
            ),
          ),
          SizedBox(width: 16),
          Text(
            'Windows · macOS · Linux   Yours forever',
            style: TextStyle(fontSize: 15, color: AppColors.aliceSage),
          ),
        ],
      ),
    );
  }
}

/// Nav row between hero and content: Home, Model selection, dead
/// space, Char creator, User profile. Selected page is the Demo
/// primary button; the rest are Demo ghost buttons.
class _PageNav extends StatelessWidget {
  final AliceV9State state;

  const _PageNav({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(28, 8, 28, 0),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _NavButton(
            label: 'Home',
            selected: state.page == V9Page.home,
            onTap: () => state.setPage(V9Page.home),
          ),
          const SizedBox(width: 14),
          _NavButton(
            label: 'Model selection',
            selected: state.page == V9Page.models,
            onTap: () => state.setPage(V9Page.models),
          ),
          const Spacer(),
          _NavButton(
            label: 'Char creator',
            selected: state.page == V9Page.creator,
            onTap: () => state.setPage(V9Page.creator),
          ),
          const SizedBox(width: 14),
          _NavButton(
            label: 'User profile',
            selected: state.page == V9Page.profile,
            onTap: () => state.setPage(V9Page.profile),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return V9Button(
      label: label,
      small: true,
      ghost: !selected,
      onPressed: onTap,
    );
  }
}
