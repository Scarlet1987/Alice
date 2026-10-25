// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice Chat screen — message list and bubbles. Part of alice_chat.dart.

part of 'alice_chat.dart';

/// Scrolling message list. AI messages get avatar + name header + styled
/// action/dialogue text; user messages are blue bubbles on the right.
/// Auto-scrolls to the newest message.
class _MessageList extends StatefulWidget {
  final ChatService chat;
  final bool shrinkWrap;

  const _MessageList({required this.chat, this.shrinkWrap = false});

  @override
  State<_MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<_MessageList> {
  final ScrollController _scroll = ScrollController();
  int _lastCount = 0;

  @override
  void initState() {
    super.initState();
    _lastCount = widget.chat.messages.length;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollToNewest(force: true),
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Smooth-scrolls to the newest message (bottom of the reversed list).
  /// Follows new arrivals only when the user is already near the bottom,
  /// so reading history isn't yanked away mid-scroll.
  void _scrollToNewest({bool force = false}) {
    if (!_scroll.hasClients || widget.shrinkWrap) return;
    final pos = _scroll.position;
    if (!force && pos.maxScrollExtent - pos.pixels > 160) return;
    _scroll.animateTo(
      pos.maxScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final chat = widget.chat;
    final messages = chat.messages;
    if (messages.length != _lastCount) {
      _lastCount = messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToNewest());
    }
    // Typing indicator: the AI is generating but has nothing visible yet —
    // either no AI message exists (newest is the user's) or the AI bubble
    // is still empty (stream target created, no tokens arrived).
    final generating = chat.isGenerating;
    final last = messages.isEmpty ? null : messages.last;
    final newestIsEmptyAi =
        last != null &&
        !last.isUser &&
        !last.isStatusBanner &&
        last.displayText.trim().isEmpty;
    final appendTyping = generating && (last == null || last.isUser);
    final swapNewestForTyping = generating && newestIsEmptyAi;
    if (messages.isEmpty && !appendTyping) {
      return Center(
        child: Text(
          'No messages yet — say hello.',
          style: TextStyle(color: Theme.of(context).hintColor),
        ),
      );
    }
    return ListView.builder(
      controller: _scroll,
      // Newest message at the bottom, standard chat order: index 0 is the
      // newest and sits at the bottom; _scrollToNewest targets
      // maxScrollExtent.
      reverse: true,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.shrinkWrap
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: messages.length + (appendTyping ? 1 : 0),
      itemBuilder: (context, i) {
        if (appendTyping && i == messages.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 5),
            child: _TypingIndicator(),
          );
        }
        if (swapNewestForTyping && i == 0) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 5),
            child: _TypingIndicator(),
          );
        }
        final msg = messages[messages.length - 1 - i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: _FadeIn(
            // Identity key: the same ChatMessage object mutates while
            // streaming, so text updates don't re-trigger the fade.
            key: ValueKey(msg),
            child: _MessageRow(message: msg),
          ),
        );
      },
    );
  }
}

/// One-shot fade-in for newly arrived rows: the message appears immediately
/// on send with a subtle 160ms fade. Keyed by message identity so it runs
/// once per message, not on every rebuild.
class _FadeIn extends StatelessWidget {
  final Widget child;

  const _FadeIn({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      builder: (context, value, child) =>
          Opacity(opacity: value, child: child!),
      child: child,
    );
  }
}

/// Typing indicator: three dots pulsing in opacity (one shared controller,
/// phase-offset per dot). Shown while the AI is generating but has no
/// visible text yet.
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AliceAvatar(name: 'AI', size: 32),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: AppColors.aiBubble,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++) _Dot(index: i, pulse: _pulse),
            ],
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final int index;
  final AnimationController pulse;

  const _Dot({required this.index, required this.pulse});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        final phase = (pulse.value + index / 3) % 1.0;
        final opacity =
            0.25 + 0.75 * (0.5 - 0.5 * math.cos(phase * 2 * math.pi));
        return Padding(
          padding: EdgeInsets.only(left: index == 0 ? 0 : 6),
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.aiText,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MessageRow extends StatelessWidget {
  final ChatMessage message;

  const _MessageRow({required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.isStatusBanner) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            message.displayText,
            style: TextStyle(
              fontSize: 12.5,
              fontStyle: FontStyle.italic,
              color: Theme.of(context).hintColor,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return message.isUser
        ? _UserBubble(message: message)
        : _AiBubble(message: message);
  }
}

class _UserBubble extends StatelessWidget {
  final ChatMessage message;

  const _UserBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.userBubble,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          message.displayText,
          style: const TextStyle(color: AppColors.userText, fontSize: 14),
        ),
      ),
    );
  }
}

class _AiBubble extends StatelessWidget {
  final ChatMessage message;

  const _AiBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final sender = message.sender.isNotEmpty ? message.sender : 'AI';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AliceAvatar(name: sender, size: 32),
        const SizedBox(width: 10),
        Flexible(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 620),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.aiBubble,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sender.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: Theme.of(context).hintColor,
                  ),
                ),
                const SizedBox(height: 4),
                _StyledStoryText(text: message.displayText),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Renders *actions* in italic and "dialogue" in the dialogue color,
/// everything else in the AI text color.
class _StyledStoryText extends StatelessWidget {
  final String text;

  const _StyledStoryText({required this.text});

  static final RegExp _seg = RegExp(r'(\*[^*\n]+\*|"[^"\n]+")');

  @override
  Widget build(BuildContext context) {
    final base = const TextStyle(
      color: AppColors.aiText,
      fontSize: 14,
      height: 1.45,
    );
    final spans = <TextSpan>[];
    var pos = 0;
    for (final m in _seg.allMatches(text)) {
      if (m.start > pos) {
        spans.add(TextSpan(text: text.substring(pos, m.start), style: base));
      }
      final chunk = m.group(0)!;
      if (chunk.startsWith('*')) {
        spans.add(
          TextSpan(
            text: chunk,
            style: base.copyWith(
              fontStyle: FontStyle.italic,
              color: AppColors.action,
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: chunk,
            style: base.copyWith(color: AppColors.dialogue),
          ),
        );
      }
      pos = m.end;
    }
    if (pos < text.length) {
      spans.add(TextSpan(text: text.substring(pos), style: base));
    }
    if (spans.isEmpty) spans.add(TextSpan(text: text, style: base));
    return SelectableText.rich(TextSpan(children: spans));
  }
}
