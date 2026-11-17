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

// Finding 3 (Tailscale): Linux installs go through the native package
// manager — install.sh is never downloaded or run as root. The
// platform-gated install entry points themselves cannot run under
// `flutter test` on the wrong OS, so these tests pin the pieces that
// decide them: the manager table, and manager detection.

import 'package:flutter_test/flutter_test.dart';

import 'package:front_porch_ai/services/web/tunnels/tailscale_installer.dart';

void main() {


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
