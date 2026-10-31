// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:front_porch_ai/services/image/model_family.dart';
import 'package:front_porch_ai/services/image/studio_desk_logic.dart';
import 'package:front_porch_ai/services/image_gen_service.dart';
import 'package:front_porch_ai/services/storage/settings/image_gen_settings.dart';
import 'package:front_porch_ai/services/storage_service.dart';
import 'package:front_porch_ai/services/image/draw_things_samplers.dart';
import 'package:front_porch_ai/ui/image_studio/image_studio.dart';
import 'package:front_porch_ai/ui/image_studio/studio_desk_copy.dart';

/// Draw Things is a gRPC server on this machine. A test never dials it: the
/// listings are answered as "nothing found" on the spot, so no client, socket
/// or timer is created.
class _NoGrpcImageGen extends ImageGenService {
  _NoGrpcImageGen(super.storage);

  @override
  Future<bool> testLocalConnection(String baseUrl) async => false;

  @override
  Future<List<String>> fetchDrawThingsModels(String baseUrl) async => const [];

  @override
  Future<Map<String, String>> fetchDrawThingsModelVersions(
    String baseUrl,
  ) async => const {};

  @override
  Future<List<LoraOption>> fetchDrawThingsLoras(String baseUrl) async =>
      const [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall call) async {
        return Directory.systemTemp.createTempSync('fpai_desk_').path;
      });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<StorageService> pumpDesk(
    WidgetTester tester,
    Size size, {
    Future<void> Function(StorageService storage)? prepare,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final dir = Directory.systemTemp.createTempSync('desk-dialog');
    addTearDown(() {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });
    final storage = StorageService.sandbox(dir.path);
    final prefs = await SharedPreferences.getInstance();
    storage.imageGenSettings.initializeBase(prefs, storage.notifyListeners);
    storage.imageGenSettings.load();
    if (prepare != null) await prepare(storage);
    final gen = _NoGrpcImageGen(storage);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<StorageService>.value(value: storage),
          ChangeNotifierProvider<ImageGenService>.value(value: gen),
        ],
        child: const MaterialApp(
          home: ImageStudio(
            mode: ImageGenMode.characterPortrait,
            characterName: 'Ada',
            characterDbId: 'ada-id',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    return storage;
  }

  Future<void> show(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
  }

  String fieldText(WidgetTester tester, Key key) {
    return tester.widget<TextField>(find.byKey(key)).controller!.text;
  }

  testWidgets('wide dialog is the two-column desk', (tester) async {
    await pumpDesk(
      tester,
      const Size(1040, 1600),
      prepare: (storage) async {
        await storage.imageGenSettings.setImageGenBackend('a1111');
        await storage.imageGenSettings.setImageGenModel(
          'z_image_turbo_bf16.safetensors',
        );
        await storage.imageGenSettings.setComfyCreateWorkflowId(
          'z_image_turbo',
        );
      },
    );

    expect(find.byKey(const Key('studio-desk-wide')), findsOneWidget);
    expect(find.byKey(const Key('studio-desk-narrow')), findsNothing);
    expect(find.text('Freeform'), findsOneWidget);
    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('Your persona'), findsOneWidget);
    expect(find.text('Write it for me'), findsOneWidget);
    expect(find.text(kStudioCreateWell), findsOneWidget);
    expect(find.text('Expression pack'), findsWidgets);
    expect(
      find.text('Pack uses this Create model to vary the portrait.'),
      findsOneWidget,
    );
    expect(find.text('make a new portrait'), findsOneWidget);
    expect(find.text('change this portrait'), findsOneWidget);
    expect(find.text('Connection'), findsOneWidget);
    expect(find.text('Change…'), findsOneWidget);
    expect(find.text('Change graph'), findsNothing);
    expect(find.text('Change model'), findsOneWidget);
    expect(find.text('Get a model from CivitAI'), findsOneWidget);
    expect(find.text('Get a LoRA from CivitAI'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
    expect(find.text('This graph also loads'), findsOneWidget);
    expect(find.text(kStudioLoraFamilyNote), findsOneWidget);
    expect(
      find.text('Workflow · Text to image · z_image_turbo'),
      findsOneWidget,
    );
    expect(find.text('Model search'), findsNothing);
    expect(find.text('Graph search'), findsNothing);
    expect(find.text('Graph upload'), findsNothing);
    expect(find.text('LoRA search'), findsNothing);
    expect(find.text('CivitAI sign-in'), findsNothing);

    await show(tester, find.textContaining('Advanced ▸'));
    expect(find.text('Steps'), findsNothing);
    await tester.tap(find.textContaining('Advanced ▸'));
    await tester.pump();
    expect(find.textContaining('Advanced ▾'), findsOneWidget);
    expect(find.text('Change graph'), findsNothing);
    expect(find.textContaining('Advanced ▸'), findsNothing);
    expect(find.text('Steps'), findsOneWidget);
    expect(find.text('CFG'), findsOneWidget);
    expect(find.text('Sampler'), findsOneWidget);
    expect(find.text('Scheduler'), findsOneWidget);
    // Every setting a generate reads has a control here.
    expect(find.text('Seed'), findsOneWidget);
    expect(find.text('Negative prompt'), findsOneWidget);
    expect(find.text('Review AI prompts before generating'), findsOneWidget);
    expect(find.text('Style'), findsOneWidget);
    expect(find.text('Prompt format'), findsOneWidget);

    await show(tester, find.text('512×512'));
    expect(find.text('768×768'), findsOneWidget);
    expect(find.text('1024×1024'), findsOneWidget);
    expect(find.text('1536×1024'), findsOneWidget);
    expect(find.text('1024×1536'), findsOneWidget);
    await tester.tap(find.text('512×512'));
    await tester.pump();
    expect(
      find.text(
        'Sends 512×512. Each side snaps to a multiple of 64, from 256 to 2048.',
      ),
      findsOneWidget,
    );
    expect(fieldText(tester, const Key('studio-width')), '512');
    expect(fieldText(tester, const Key('studio-height')), '512');

    await tester.enterText(find.byKey(const Key('studio-width')), '300');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(
      find.text(
        'Sends 320×512. Each side snaps to a multiple of 64, from 256 to 2048.',
      ),
      findsOneWidget,
    );
    expect(fieldText(tester, const Key('studio-width')), '320');
    expect(fieldText(tester, const Key('studio-height')), '512');

    expect(find.widgetWithText(FilledButton, 'Generate'), findsOneWidget);

    await show(tester, find.text('Change model'));
    await tester.tap(find.text('Change model'));
    await tester.pump();
    expect(find.text('Change model — Create'), findsOneWidget);
    expect(find.text('Search families or files'), findsOneWidget);
    await tester.tap(find.text('Close').last);
    await tester.pump();
    await show(tester, find.text('Get a model from CivitAI'));
    await tester.tap(find.text('Get a model from CivitAI'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Get a model from CivitAI'), findsWidgets);
    expect(find.text('On this computer'), findsNothing);
    // The adult box stays out of sight while the app's adult setting is off.
    expect(find.text('Include adult models from civitai.red'), findsNothing);
    expect(find.text('API key'), findsOneWidget);
    await tester.tap(find.byKey(const Key('studio-civitai-base')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Flux.1 Kontext'), findsOneWidget);
    expect(find.text('Flux.2 Klein 9B'), findsOneWidget);
    expect(find.text('Qwen 2.1'), findsOneWidget);
    expect(find.text('Qwen-Image, 2512, and Image Edit'), findsOneWidget);
    expect(find.text('Wan Video'), findsNothing);
    await tester.tap(find.text('Flux.1 Dev').last);
    await tester.pump();
    expect(find.text('CivitAI sign-in'), findsNothing);
    await tester.tap(find.text('Close').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await show(tester, find.text('change this portrait'));
    await tester.tap(find.text('change this portrait'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Portrait in this chat'), findsOneWidget);
    expect(
      find.textContaining('Edit sends an instruction with this picture.'),
      findsOneWidget,
    );
    // The Edit tab offers no Expression pack (the pack starts from Create).
    expect(find.text('Pack uses this edit model.'), findsNothing);
  });

  testWidgets('a GGUF model is picked directly, with no graph to leave', (
    tester,
  ) async {
    await pumpDesk(
      tester,
      const Size(1040, 1600),
      prepare: (storage) async {
        await storage.imageGenSettings.setImageGenBackend('comfyui');
        await storage.imageGenSettings.setComfyCreateWorkflowId('sd');
      },
    );
    // No graph picker exists on the native desk: Change workflow only
    // explains that the built-in engine picks models directly.
    await show(tester, find.text('Change model'));
    await tester.tap(find.text('Change model'));
    await tester.pump();
    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'Search by name',
      ),
      'z_image_turbo_q8.gguf',
    );
    await tester.pump();
    await tester.tap(find.text('Use this name'));
    await tester.pump();
    expect(find.text('z_image_turbo_q8.gguf'), findsOneWidget);
    await show(tester, find.textContaining('Advanced ▸'));
    await tester.tap(find.textContaining('Advanced ▸'));
    await tester.pump();
    expect(
      find.textContaining('GGUF · chosen for this file'),
      findsOneWidget,
    );
    expect(find.text('Change graph — Create'), findsNothing);
  });

  testWidgets('a saved GGUF file on the checkpoint graph is not swapped', (
    tester,
  ) async {
    final storage = await pumpDesk(
      tester,
      const Size(1040, 1600),
      prepare: (storage) async {
        await storage.imageGenSettings.setImageGenBackend('comfyui');
        await storage.imageGenSettings.setComfyCreateWorkflowId('sd');
        await storage.imageGenSettings.setImageGenModel(
          'z_image_turbo_q8.gguf',
        );
      },
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    // The desk reads; it does not pick another graph for the person.
    expect(storage.imageGenSettings.comfyCreateWorkflowId, 'sd');
    expect(
      storage.imageGenSettings.comfyCreateModelChoices,
      isEmpty,
      reason: 'nothing was written on the way to the first frame',
    );
  });

  testWidgets('Draw Things hides the text encoder and VAE', (tester) async {
    await pumpDesk(
      tester,
      const Size(1040, 1600),
      prepare: (storage) async {
        await storage.imageGenSettings.setImageGenBackend('drawthings');
        await storage.imageGenSettings.setComfyCreateWorkflowId(
          'z_image_turbo',
        );
      },
    );
    expect(find.text('This graph also loads'), findsNothing);
    expect(find.text('Text encoder'), findsNothing);
    expect(find.text('VAE'), findsNothing);
    expect(find.text('Change graph'), findsNothing);
    await show(tester, find.textContaining('Advanced ▸'));
    await tester.tap(find.textContaining('Advanced ▸'));
    await tester.pump();
    expect(find.text('Steps'), findsNothing);
    expect(find.text('CFG'), findsNothing);
    final menus = tester
        .widgetList<DropdownButton<int>>(find.byType(DropdownButton<int>))
        .toList();
    expect(
      menus.any((menu) => menu.items!.length == kDrawThingsSamplers.length),
      isTrue,
    );
  });

  testWidgets(
    'native has no encoder or VAE slots, so chosen support files are not shown',
    (tester) async {
      await pumpDesk(
        tester,
        const Size(1040, 1600),
        prepare: (storage) async {
          await storage.imageGenSettings.setImageGenBackend('comfyui');
          await storage.imageGenSettings.setComfyCreateWorkflowId(
            'z_image_turbo',
          );
          await storage.imageGenSettings.setComfyCreateModelChoice(
            'z_image_turbo',
            '%MODEL_DIFFUSION%',
            'z_image_turbo.safetensors',
          );
          await storage.imageGenSettings.setComfyCreateModelChoice(
            'z_image_turbo',
            '%MODEL_CLIP%',
            'clip_l.safetensors',
          );
          await storage.imageGenSettings.setComfyCreateModelChoice(
            'z_image_turbo',
            '%MODEL_VAE%',
            'qwen_image_vae.safetensors',
          );
        },
      );
      // The support section lives in Advanced; opening it proves the
      // section itself is absent, not just off-screen.
      await show(tester, find.textContaining('Advanced ▸'));
      await tester.tap(find.textContaining('Advanced ▸'));
      await tester.pump();
      expect(find.text('clip_l.safetensors'), findsNothing);
      expect(find.text('qwen_image_vae.safetensors'), findsNothing);
      expect(find.text('Extra files this setup loads'), findsNothing);
      expect(find.text('Not chosen'), findsNothing);
    },
  );

  testWidgets('narrow dialog stacks the same desk', (tester) async {
    await pumpDesk(tester, const Size(390, 1400));
    expect(find.byKey(const Key('studio-desk-narrow')), findsOneWidget);
    expect(find.byKey(const Key('studio-desk-wide')), findsNothing);
    expect(find.text('Write it for me'), findsOneWidget);
    // Native has no checkpoint graph, so its support note never renders.
    expect(find.text(kStudioCheckpointSupport), findsNothing);
    expect(find.text('Generate'), findsOneWidget);
    expect(find.textContaining('Advanced ▸'), findsOneWidget);
    await show(tester, find.textContaining('Advanced ▸'));
    await tester.tap(find.textContaining('Advanced ▸'));
    await tester.pump();
    expect(find.text(kStudioCheckpointSupport), findsNothing);
  });

  testWidgets('metadata clash keeps Generate off until Use anyway', (
    tester,
  ) async {
    await pumpDesk(
      tester,
      const Size(1040, 1600),
      prepare: (storage) async {
        await storage.imageGenSettings.setImageGenBackend('a1111');
        await storage.imageGenSettings.setImageGenModel(
          'z_image_turbo_bf16.safetensors',
        );
        await storage.imageGenSettings.setImageGenLoraSlot(
          0,
          file: 'qwen_image_lora.safetensors',
        );
        await saveLoraFacts(storage.imageGenSettings, [
          DeskLoraCheck(
            'qwen_image_lora.safetensors',
            ModelFamily.qwen,
            metadataBacked: true,
          ),
        ]);
      },
    );

    // LoRA badges live in Advanced, so open it before the badge expects.
    await show(tester, find.textContaining('Advanced ▸'));
    await tester.tap(find.textContaining('Advanced ▸'));
    await tester.pump();
    expect(find.text('other base'), findsOneWidget);
    expect(
      find.textContaining(
        'Generate is paused. Open Advanced to pick a matching one',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'Not ready — LoRA architecture does not match z_image_turbo_bf16.safetensors.',
      ),
      findsOneWidget,
    );
    final blocked = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Generate'),
    );
    expect(blocked.onPressed, isNull);

    await show(tester, find.text('Use anyway'));
    await tester.tap(find.text('Use anyway'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    final open = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Generate'),
    );
    expect(open.onPressed, isNotNull);
  });

  testWidgets('a name-only mismatch stays likely and can generate', (
    tester,
  ) async {
    await pumpDesk(
      tester,
      const Size(1040, 1600),
      prepare: (storage) async {
        await storage.imageGenSettings.setImageGenBackend('a1111');
        await storage.imageGenSettings.setImageGenModel(
          'z_image_turbo_bf16.safetensors',
        );
        await storage.imageGenSettings.setImageGenLoraSlot(
          0,
          file: 'qwen_image_lora.safetensors',
        );
      },
    );

    // The LoRA badge lives in Advanced, so open it before the badge expects.
    await show(tester, find.textContaining('Advanced ▸'));
    await tester.tap(find.textContaining('Advanced ▸'));
    await tester.pump();
    expect(find.text('likely'), findsOneWidget);
    expect(find.text('other base'), findsNothing);
    expect(find.text('Use anyway'), findsNothing);
    expect(find.text('Ready to generate.'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Generate'),
    );
    expect(button.onPressed, isNotNull);
  });
}
