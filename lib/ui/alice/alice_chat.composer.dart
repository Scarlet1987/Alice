// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice Chat screen — composer. Part of alice_chat.dart.

part of 'alice_chat.dart';

/// Composer: illustrate button + text input + send. Enter sends, Shift+Enter
/// adds a newline. The send guard mirrors ChatService.sendMessage's guard
/// set exactly (same contract as the classic chat page) so refused sends
/// keep the typed text instead of consuming it.
class _Composer extends StatefulWidget {
  final ChatService chat;

  const _Composer({required this.chat});

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final chat = widget.chat;
    final text = _controller.text;
    if (text.trim().isEmpty ||
        chat.isGenerating ||
        chat.isLoadingSession ||
        chat.isGuestBusy ||
        chat.isPhotoTurnInFlight ||
        chat.entrancesInFlight ||
        (chat.activeCharacter == null && chat.activeGroup == null)) {
      return;
    }
    final refusal = chat.sendRefusal(text);
    if (refusal != null) {
      chat.announceLookupForce(refusal);
      return;
    }
    final lookupBlock = chat.lookupCommandBlock(text);
    if (lookupBlock != null) {
      chat.announceLookupForce(lookupBlock);
      return;
    }
    chat.sendMessage(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final chat = widget.chat;
    final canSend = !chat.isGenerating && !chat.isLoadingSession;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            icon: const Icon(Icons.image_outlined),
            tooltip: 'Illustrate the scene',
            onPressed: () => launchSceneIllustrator(context, chat),
          ),
          Expanded(
            child: Focus(
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.enter &&
                    !HardwareKeyboard.instance.isShiftPressed) {
                  _send();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 6,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Write as your persona…  (Enter to send)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.borderOf(context)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppColors.porchAmber,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send_rounded),
            tooltip: 'Send',
            color: AppColors.porchAmber,
            onPressed: canSend ? _send : null,
          ),
        ],
      ),
    );
  }
}

/// Helper line under the composer, from the preview.
class _ComposerHint extends StatelessWidget {
  const _ComposerHint();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 8, 2, 0),
      child: Text(
        'The image button builds a scene-aware prompt — place, cast, mood — '
        'from the last messages, for your local image engine.',
        style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
      ),
    );
  }
}
