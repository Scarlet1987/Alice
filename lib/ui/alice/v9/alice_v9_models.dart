// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice v9 Model selection (combined preview v9): image / text / voice
// model on/off, narration person, perspective, foreshortening, codec
// choice with asset check, and the three preview panes. The preview
// panes follow the on/off selects on this same page. Browse-model picks
// a real model file; the asset check only reports what it found — it
// never pretends an asset played.

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:front_porch_ai/ui/alice/v9/alice_v9_state.dart';
import 'package:front_porch_ai/ui/alice/v9/alice_v9_models_panes.dart';
import 'package:front_porch_ai/ui/alice/v9/alice_v9_widgets.dart';

class AliceV9ModelsPage extends StatelessWidget {
  final AliceV9State state;

  const AliceV9ModelsPage({super.key, required this.state});

  Future<void> _browseModel(BuildContext context, String kind) async {
    // file_picker 13: static methods on FilePicker, no `.platform`.
    final result = await FilePicker.pickFiles(
      dialogTitle: 'Pick a $kind model',
    );
    if (result == null || result.files.isEmpty) return;
    state.pickModelAsset(result.files.first.name, kind);
  }

  void _runAssetCheck() {
    state.runAssetCheck();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _JumpPanel(state: state),
              const SizedBox(height: 16),
              V9Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const V9Heading('model selection and filters'),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final boxes = [
                          _ModelBox(
                            title: 'image model',
                            value: state.imageOn,
                            onChanged: (v) => state.setImageOn(v),
                            onBrowse: () => _browseModel(context, 'image'),
                          ),
                          _ModelBox(
                            title: 'text model',
                            value: state.textOn,
                            onChanged: (v) => state.setTextOn(v),
                            onBrowse: () => _browseModel(context, 'text'),
                          ),
                          _ModelBox(
                            title: 'voice engine',
                            value: state.voiceOn,
                            onChanged: (v) => state.setVoiceOn(v),
                            onBrowse: () => _browseModel(context, 'voice'),
                          ),
                        ];
                        if (constraints.maxWidth < 700) {
                          return Column(
                            children: [
                              for (final box in boxes) ...[
                                box,
                                const SizedBox(height: 12),
                              ],
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final box in boxes)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  child: box,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final boxes = [
                          ListBox(
                            title: 'narration style',
                            label: 'narration person',
                            options: const [
                              'first',
                              'second',
                              'third',
                            ],
                            labels: const [
                              'first person',
                              'second person',
                              'third person',
                            ],
                            selected: state.narrationPerson,
                            onSelect: (v) => state.setNarrationPerson(v),
                            preview: _personPreview(state.narrationPerson),
                          ),
                          ListBox(
                            title: 'perspective',
                            label: 'where lines converge',
                            options: const [
                              'one point',
                              'two point',
                              'three point',
                              'fish eye',
                              'atmospheric perspective',
                            ],
                            selected: state.perspective,
                            onSelect: (v) => state.setPerspective(v),
                          ),
                          ListBox(
                            title: 'foreshortening',
                            label: 'foreground background difference',
                            options: const [
                              'the golden rule',
                              'T-overlap',
                              'Form intersection',
                              'cross contour wraps',
                            ],
                            selected: state.foreshortening,
                            onSelect: (v) => state.setForeshortening(v),
                          ),
                        ];
                        if (constraints.maxWidth < 700) {
                          return Column(
                            children: [
                              for (final box in boxes) ...[
                                box,
                                const SizedBox(height: 12),
                              ],
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final box in boxes)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  child: box,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    V9Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const V9Heading('codec choice and asset check'),
                          const SizedBox(height: 12),
                          CodecBox(state: state),
                          const SizedBox(height: 12),
                          V9Card(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                              children: [
                                const V9Heading('asset select and drop in'),
                                const SizedBox(height: 8),
                                const V9Muted(
                                  'Drop an asset here, or use browse below.',
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  state.assetName == null
                                      ? 'No file chosen yet.'
                                      : 'Chosen: ${state.assetName}',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: V9Button(
                                        label: 'browse.....',
                                        onPressed: () =>
                                            _browseModel(context, 'asset'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 2,
                                      child: V9Button(
                                        label: 'run check on asset(s)',
                                        onPressed: _runAssetCheck,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                V9Muted(state.assetCheckResult),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              V9Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const V9Heading('preview panes for models'),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final textPane = PreviewPane(
                          title: 'text to user preview',
                          body: state.textOn
                              ? 'Text to user preview: "Here is a line of text from the model."'
                              : 'Text model off — no text preview.',
                        );
                        final voicePane = PreviewPane(
                          title: 'voice to user preview',
                          body: state.voiceOn
                              ? 'Voice to user preview: "Hello, I\'m here."'
                              : 'Voice model off — no voice preview.',
                        );
                        final imagePane = PreviewPane(
                          title: 'composite image to user preview',
                          body: state.imageOn
                              ? '[composite image preview placeholder]'
                              : 'Image model off — no image preview.',
                          large: true,
                        );
                        if (constraints.maxWidth < 700) {
                          return Column(
                            children: [
                              textPane,
                              const SizedBox(height: 12),
                              voicePane,
                              const SizedBox(height: 12),
                              imagePane,
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  textPane,
                                  const SizedBox(height: 12),
                                  voicePane,
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: imagePane),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    const V9Muted(
                      'Previews follow the on/off selects above, on this same page.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

String _personPreview(String person) {
  switch (person) {
    case 'second':
      return 'You walk into the room.';
    case 'third':
      return 'She walks into the room.';
    default:
      return 'I walk into the room.';
  }
}

class _JumpPanel extends StatelessWidget {
  final AliceV9State state;

  const _JumpPanel({required this.state});

  @override
  Widget build(BuildContext context) {
    return V9Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const V9Heading('settings jump panel'),
          const SizedBox(height: 12),
          const V9Muted('Character creator is on the other page.'),
          const SizedBox(height: 8),
          V9Button(
            label: 'character creator',
            onPressed: () => state.setPage(V9Page.creator),
          ),
        ],
      ),
    );
  }
}

class _ModelBox extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback onBrowse;

  const _ModelBox({
    required this.title,
    required this.value,
    required this.onChanged,
    required this.onBrowse,
  });

  @override
  Widget build(BuildContext context) {
    return V9Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          V9Heading(title),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$title on/off',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
          const SizedBox(height: 8),
          V9Button(label: 'browse model ......', onPressed: onBrowse),
        ],
      ),
    );
  }
}

