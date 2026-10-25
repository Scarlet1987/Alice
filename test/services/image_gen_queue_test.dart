// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// This file is part of Front Porch AI.
//
// Front Porch AI is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Front Porch AI is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with Front Porch AI. If not, see <https://www.gnu.org/licenses/>.

// Guards for the image generation queue (image_gen_service.queue.dart):
// backpressure FIFO instead of refusal, per-session scoping, and session
// teardown dropping only the ended session's WAITING entries.
//
// Talks to an in-process loopback HttpServer standing in for an
// AUTOMATIC1111-style local server. No real network. The server holds each
// txt2img response behind a gate the test opens, so generations can be
// overlapped deterministically.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:front_porch_ai/services/image_gen_service.dart';
import 'package:front_porch_ai/services/storage_service.dart';
import 'package:front_porch_ai/services/storage/settings/backend_settings.dart';
import 'package:front_porch_ai/services/storage/settings/engine_resources_settings.dart';
import 'package:front_porch_ai/services/storage/settings/image_gen_settings.dart';

/// flutter_test's binding replaces every HttpClient with a mock that always
/// returns 400; an un-overridden HttpOverrides restores the real client so
/// the test can talk to its own loopback server. Same pattern as
/// test/services/image_gen_generate_test.dart.
class _RealHttpOverrides extends HttpOverrides {}

Future<T> _withRealHttp<T>(Future<T> Function() body) =>
    HttpOverrides.runWithHttpOverrides(body, _RealHttpOverrides());

/// Minimal A1111-shaped server. Each txt2img waits on [_gate] before
/// responding, so the test controls exactly when a generation finishes.
class _GatedA1111 {
  _GatedA1111._(this._server);

  final HttpServer _server;
  final _gate = Completer<void>();
  int txt2imgCount = 0;
  final List<String> prompts = [];

  String get baseUrl => 'http://127.0.0.1:${_server.port}';

  static Future<_GatedA1111> start() async {
    final server = await HttpServer.bind('127.0.0.1', 0);
    final fake = _GatedA1111._(server);
    server.listen(fake._handle);
    return fake;
  }

  void openGate() {
    if (!_gate.isCompleted) _gate.complete();
  }

  Future<void> close() => _server.close(force: true);

  Future<void> _handle(HttpRequest req) async {
    if (req.method == 'POST' && req.uri.path == '/sdapi/v1/txt2img') {
      txt2imgCount++;
      final body = await utf8.decoder.bind(req).join();
      try {
        prompts.add(
          (jsonDecode(body) as Map<String, dynamic>)['prompt']?.toString() ??
              '',
        );
      } catch (_) {
        prompts.add('');
      }
      await _gate.future;
      // 1x1 PNG.
      const pngB64 =
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
      req.response.headers.contentType = ContentType.json;
      req.response.write(jsonEncode({
        'images': [pngB64],
      }));
      await req.response.close();
      return;
    }
    req.response.statusCode = 404;
    await req.response.close();
  }
}

class _FakeStorageForQueue extends ChangeNotifier implements StorageService {
  @override
  final EngineResourcesSettings engineResourcesSettings =
      EngineResourcesSettings();

  @override
  final ImageGenSettings imageGenSettings = ImageGenSettings();

  @override
  final BackendSettings backendSettings = BackendSettings();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _GatedA1111 fake;
  late _FakeStorageForQueue storage;
  late ImageGenService service;

  setUp(() async {
    fake = await _withRealHttp(() => _GatedA1111.start());
    storage = _FakeStorageForQueue();
    await storage.imageGenSettings.setImageGenBackend('a1111');
    await storage.imageGenSettings.setLocalImageGenUrl(fake.baseUrl);
    // Backpressure on (the default) — the queue is the path under test.
    service = ImageGenService(storage);
  });

  tearDown(() async {
    fake.openGate();
    await fake.close();
    service.dispose();
    storage.dispose();
  });

  test(
    'a second generation queues FIFO instead of being refused',
    () => _withRealHttp(() async {
      final first = service.generateImage(prompt: 'first');
      // Let the first generation start (server is gated).
      await Future.delayed(const Duration(milliseconds: 200));
      expect(service.imageQueueDepth, 1);

      final second = service.generateImage(prompt: 'second');
      await Future.delayed(const Duration(milliseconds: 200));
      // Running + one waiting.
      expect(service.imageQueueDepth, 2);

      fake.openGate();
      final results = await Future.wait([first, second]);
      expect(results[0], isNotNull);
      expect(results[1], isNotNull);
      expect(fake.txt2imgCount, 2);
      // FIFO: first prompt ran first.
      expect(fake.prompts, ['first', 'second']);
      expect(service.imageQueueDepth, 0);
    }),
  );

  test(
    'teardownEngineSession drops only that session\'s waiting entries',
    () => _withRealHttp(() async {
      final running = service.generateImage(
        prompt: 'running',
        sessionId: 'session-a',
      );
      await Future.delayed(const Duration(milliseconds: 200));

      final waitingA = service.generateImage(
        prompt: 'waiting-a',
        sessionId: 'session-a',
      );
      final waitingB = service.generateImage(
        prompt: 'waiting-b',
        sessionId: 'session-b',
      );
      await Future.delayed(const Duration(milliseconds: 200));
      expect(service.imageQueueDepth, 3);

      // Session A ends: its WAITING entry is dropped; the running one and
      // session B's entry survive.
      service.teardownEngineSession('session-a');
      expect(service.imageQueueDepth, 2);

      fake.openGate();
      final runningResult = await running;
      final bResult = await waitingB;
      final aResult = await waitingA;
      expect(runningResult, isNotNull);
      expect(bResult, isNotNull);
      // The dropped entry resolves null without ever hitting the backend.
      expect(aResult, isNull);
      expect(fake.txt2imgCount, 2);
      expect(fake.prompts, ['running', 'waiting-b']);
    }),
  );

  test(
    'teardownEngineSession with no entries for the session is a no-op',
    () async {
      service.teardownEngineSession('nobody');
      expect(service.imageQueueDepth, 0);
    },
  );
}
