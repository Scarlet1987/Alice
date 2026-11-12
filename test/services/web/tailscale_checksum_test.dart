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

// Finding 3 (Tailscale): macOS installs verify the versioned .pkg against
// its published `<pkg>.sha256` before the Installer opens it, and Linux
// installs go through the native package manager — install.sh is never
// downloaded or run as root. The platform-gated install entry points
// themselves cannot run under `flutter test` on the wrong OS, so these
// tests pin the pieces that decide them: alias resolution, the manager
// table, and manager detection.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:front_porch_ai/services/web/tunnels/tailscale_installer.dart';

Future<HttpServer> _startServer(
  FutureOr<void> Function(HttpRequest req) handler,
) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((req) async {
    try {
      await handler(req);
    } catch (_) {
      try {
        req.response.statusCode = 500;
        await req.response.close();
      } catch (_) {}
    }
  });
  return server;
}

Uri _url(HttpServer server, String path) =>
    Uri.parse('http://127.0.0.1:${server.port}$path');

void main() {
  // flutter_test mocks HttpClient by default (every request returns 400);
  // these tests talk real HTTP to a local server they control.
  setUpAll(() => HttpOverrides.global = null);

  group('resolveVersionedMacPkg', () {
    late HttpServer server;
    late http.Client client;

    setUp(() async {
      client = http.Client();
    });

    tearDown(() async {
      client.close();
      await server.close(force: true);
    });

    test('resolves the latest alias to the versioned pkg', () async {
      server = await _startServer((req) async {
        if (req.uri.path == '/latest') {
          req.response.statusCode = 302;
          req.response.headers.set(
            'location',
            'https://pkgs.tailscale.com/stable/Tailscale-1.104.5-macos.pkg',
          );
          await req.response.close();
        } else {
          req.response.statusCode = 404;
          await req.response.close();
        }
      });

      expect(
        await TailscaleInstaller.resolveVersionedMacPkg(
          client,
          latestUrl: _url(server, '/latest'),
        ),
        Uri.parse(
          'https://pkgs.tailscale.com/stable/Tailscale-1.104.5-macos.pkg',
        ),
      );
    });

    test('rejects a redirect that is not a versioned pkg', () async {
      server = await _startServer((req) async {
        req.response.statusCode = 302;
        req.response.headers.set(
          'location',
          'https://pkgs.tailscale.com/stable/Tailscale-latest-macos.pkg',
        );
        await req.response.close();
      });

      expect(
        await TailscaleInstaller.resolveVersionedMacPkg(
          client,
          latestUrl: _url(server, '/latest'),
        ),
        isNull,
      );
    });

    test('returns null when the alias does not redirect', () async {
      server = await _startServer((req) async {
        req.response.statusCode = 200;
        req.response.add(utf8.encode('body'));
        await req.response.close();
      });

      expect(
        await TailscaleInstaller.resolveVersionedMacPkg(
          client,
          latestUrl: _url(server, '/latest'),
        ),
        isNull,
      );
    });
  });

  group('Linux native package manager install', () {
    test('install argv installs the official tailscale package', () {
      expect(TailscaleInstaller.installArgvForManager('apt-get'), [
        'apt-get',
        'install',
        '-y',
        'tailscale',
      ]);
      expect(TailscaleInstaller.installArgvForManager('dnf'), [
        'dnf',
        'install',
        '-y',
        'tailscale',
      ]);
      expect(TailscaleInstaller.installArgvForManager('pacman'), [
        'pacman',
        '-S',
        '--noconfirm',
        'tailscale',
      ]);
      expect(TailscaleInstaller.installArgvForManager('zypper'), [
        'zypper',
        'install',
        '-y',
        'tailscale',
      ]);
      expect(TailscaleInstaller.installArgvForManager('yum'), [
        'yum',
        'install',
        '-y',
        'tailscale',
      ]);
    });

    test('unknown managers have no install argv', () {
      expect(TailscaleInstaller.installArgvForManager('brew'), isNull);
      expect(TailscaleInstaller.installArgvForManager(''), isNull);
      expect(TailscaleInstaller.installArgvForManager('apk'), isNull);
    });

    test('detection finds a supported manager or nothing at all', () async {
      final found = await TailscaleInstaller.detectLinuxPackageManager();
      expect(found, anyOf(isNull, 'apt-get', 'dnf', 'yum', 'pacman', 'zypper'));
      if (found != null) {
        expect(TailscaleInstaller.installArgvForManager(found), isNotNull);
      }
    });
  });
}
