// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice edition app shell: nav rail + the five Alice screens.
// This is the real Alice frontend — not a recolor of the old app.

import 'package:flutter/material.dart';
import 'package:front_porch_ai/providers/app_state.dart';
import 'package:front_porch_ai/ui/alice/alice_chat.dart';
import 'package:front_porch_ai/ui/alice/alice_creator.dart';
import 'package:front_porch_ai/ui/alice/alice_home.dart';
import 'package:front_porch_ai/ui/alice/alice_settings.dart';
import 'package:front_porch_ai/ui/alice/alice_worlds.dart';
import 'package:front_porch_ai/ui/theme/app_colors.dart';
import 'package:provider/provider.dart';

/// Alice navigation destinations, in rail order.
enum AliceDestination { home, chat, creator, worlds, settings }

class AliceShell extends StatelessWidget {
  const AliceShell({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final index = appState.selectedIndex.clamp(0, 4);

    return Scaffold(
      body: Row(
        children: [
          _AliceNavRail(selected: index, onSelect: (i) => appState.setIndex(i)),
          Expanded(
            child: _TabFade(
              index: index,
              children: const [
                AliceHomeScreen(),
                AliceChatScreen(),
                AliceCreatorScreen(),
                AliceWorldsScreen(),
                AliceSettingsScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tab transition: a quick 90ms dip (out + back, 180ms total) around the
/// [IndexedStack]. The stack itself stays mounted, so screen state
/// (chat scroll, composer text) survives the switch — this is a fade of
/// the whole content, not an AnimatedSwitcher child swap. Opacity-only,
/// no slide/scale/bounce.
class _TabFade extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const _TabFade({required this.index, required this.children});

  @override
  State<_TabFade> createState() => _TabFadeState();
}

class _TabFadeState extends State<_TabFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 90),
  );
  late int _shown = widget.index;
  int? _pending;
  bool _swapping = false;

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_TabFade oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _pending = widget.index;
      if (!_swapping) _swap();
    }
  }

  /// Fade out, swap the shown child, fade back in. Re-entrant: rapid tab
  /// taps queue the newest pending index and converge on it.
  Future<void> _swap() async {
    _swapping = true;
    await _fade.forward();
    if (!mounted) return;
    setState(() => _shown = _pending ?? widget.index);
    await _fade.reverse();
    _swapping = false;
    if (mounted && _pending != _shown) _swap();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(
        begin: 1,
        end: 0.45,
      ).animate(CurvedAnimation(parent: _fade, curve: Curves.easeOut)),
      child: IndexedStack(index: _shown, children: widget.children),
    );
  }
}

class _AliceNavRail extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;

  const _AliceNavRail({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 228,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardOf(context),
        border: Border(
          right: BorderSide(color: AppColors.borderSoftOf(context)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: AppColors.isLight(context) ? 0.12 : 0.4,
            ),
            offset: const Offset(4, 0),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Brand
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 2, 8, 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF5EEAD4),
                        Color(0xFF14B8A6),
                        Color(0xFF0F766E),
                      ],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '❋',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rabbit Hole',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      'Alice edition',
                      style: TextStyle(fontSize: 11.5, color: theme.hintColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _navButton(context, 0, Icons.home_rounded, 'Home'),
          _navButton(context, 1, Icons.chat_bubble_rounded, 'Chat'),
          _navButton(context, 2, Icons.person_add_rounded, 'Creator'),
          _navButton(context, 3, Icons.public_rounded, 'Worlds'),
          _navButton(context, 4, Icons.settings_rounded, 'Settings'),
          const Spacer(),
          // Backend status card at the bottom of the rail
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardOf(context),
              border: Border.all(color: AppColors.borderSoftOf(context)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.hintColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Backend',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 5, bottom: 10),
                  child: Text(
                    'Engines start on demand and unload when idle.',
                    style: TextStyle(fontSize: 12.5, color: theme.hintColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navButton(
    BuildContext context,
    int index,
    IconData icon,
    String label,
  ) {
    final isOn = selected == index;
    final theme = Theme.of(context);
    final accent = AppColors.porchAmberOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () => onSelect(index),
        hoverColor: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: isOn ? accent.withValues(alpha: 0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            // The preview keeps a 3px left bar in both states (accent
            // when active, transparent when not) so nothing shifts.
            border: Border(
              left: BorderSide(
                color: isOn ? accent : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isOn ? theme.colorScheme.onSurface : theme.hintColor,
              ),
              const SizedBox(width: 11),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: isOn ? FontWeight.w600 : FontWeight.w500,
                  color: isOn ? theme.colorScheme.onSurface : theme.hintColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
