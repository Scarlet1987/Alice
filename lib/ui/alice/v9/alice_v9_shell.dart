// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice v9 shell (combined preview v9): the v9 front end in one screen.
// Banner — hardware credits left, Rabbit Hole / Alice / Follow the
// White Rabbit centre, software credits right — then the nav row (Home,
// Model selection, dead space, Char creator, User profile) and the four
// pages in an IndexedStack, so page state survives switching. This is
// the v9 front end; the older Alice shell stays reachable from the rail
// until its own rebuild (see the Verse V note in the Bible checklist).

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
          backgroundColor: AppColors.aliceDeep,
          appBar: AppBar(
            backgroundColor: AppColors.aliceDeep,
            foregroundColor: AppColors.pureWhite,
            title: const Text(
              'Alice — v9',
              style: TextStyle(fontFamily: 'Georgia'),
            ),
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.aliceDeep,
                  AppColors.aliceDark,
                  AppColors.aliceDeep,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(28, 12, 28, 0),
                  child: Text(
                    'Home page',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.alicePale,
                    ),
                  ),
                ),
                _Banner(),
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
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The v9 banner: hardware credits left, Rabbit Hole / Alice / Follow
/// the White Rabbit centre, software credits right.
class _Banner extends StatelessWidget {
  const _Banner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(28, 12, 28, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.aliceDark, AppColors.aliceGreen],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.pureBlack.withValues(alpha: 0.25),
            offset: const Offset(0, 10),
            blurRadius: 24,
          ),
        ],
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  'hardware credits',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.pureWhite,
                  ),
                ),
                Text(
                  'Hardware credits, as in your sketch, left of the banner.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.alicePale, fontSize: 16),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Text(
                  'Rabbit Hole',
                  style: TextStyle(color: AppColors.alicePale, fontSize: 22),
                ),
                Text(
                  'Alice',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 44,
                    fontWeight: FontWeight.w700,
                    color: AppColors.pureWhite,
                  ),
                ),
                Text(
                  'Follow the White Rabbit',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.pureWhite,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'software credits',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.pureWhite,
                  ),
                ),
                Text(
                  'Software credits, as in your sketch, right of the banner.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.alicePale, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Nav row between banner and content: Home, Model selection, dead
/// space, Char creator, User profile. Home is green with white words
/// when active, like every other nav button in v9.
class _PageNav extends StatelessWidget {
  final AliceV9State state;

  const _PageNav({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(28, 16, 28, 0),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.aliceGreen, width: 2),
        ),
      ),
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
    // Active page: green with a pale outline (preview v9 nav), not an
    // inverted white button — every nav button stays green/white.
    final button = V9Button(label: label, small: true, onPressed: onTap);
    if (!selected) return button;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.alicePale, width: 3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: button,
    );
  }
}
