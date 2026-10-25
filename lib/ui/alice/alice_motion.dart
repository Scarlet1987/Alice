// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice edition motion primitives. Subtle and cheap only: opacity and
// sub-100ms scale tweens, no shadows, no blur, no shimmer gradients, no
// per-frame setState loops. Everything here is cross-platform Flutter.

import 'package:flutter/material.dart';

/// Press wrapper for GestureDetector-style buttons: a subtle 4% shrink
/// while pressed, 100ms ease-out. Buttons that already use InkWell get
/// their ripple from Material and don't need this.
class AlicePressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const AlicePressable({super.key, required this.child, this.onTap});

  @override
  State<AlicePressable> createState() => _AlicePressableState();
}

class _AlicePressableState extends State<AlicePressable> {
  bool _down = false;

  void _setDown(bool value) {
    if (_down != value) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: enabled ? (_) => _setDown(true) : null,
      onTapUp: enabled ? (_) => _setDown(false) : null,
      onTapCancel: () => _setDown(false),
      child: AnimatedScale(
        scale: _down ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Skeleton placeholder: pulsing grey bars. Opacity-only pulse (900ms) —
/// deliberately NOT a shimmer gradient, which costs GPU. Replaces
/// spinners in loading states.
class AliceSkeleton extends StatefulWidget {
  final int lines;

  const AliceSkeleton({super.key, this.lines = 3});

  @override
  State<AliceSkeleton> createState() => _AliceSkeletonState();
}

class _AliceSkeletonState extends State<AliceSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final barColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        return Opacity(
          opacity: 0.45 + 0.35 * _pulse.value,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < widget.lines; i++)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: i == widget.lines - 1 ? 0 : 10,
                  ),
                  child: FractionallySizedBox(
                    widthFactor: i == widget.lines - 1 ? 0.65 : 1.0,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
