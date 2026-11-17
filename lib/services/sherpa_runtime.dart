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

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

const _sherpaCApiLib = {
  'linux': 'libsherpa-onnx-c-api.so',
  'windows': 'sherpa-onnx-c-api.dll',
};

/// Directory holding the sherpa-onnx C API library, or null if it is not
/// next to the executable. `FP_SHERPA_LIB` overrides for tests/dev.
///
/// Do not pass this to `sherpa.initBindings` — use [initSherpaBindings] in
/// every isolate instead. Shared by the in-process Whisper STT and
/// Kokoro/Piper TTS engines (docs/design/sidecar-retirement.md phases 3–4).
String? sherpaNativeLibDir() {
  final env = Platform.environment['FP_SHERPA_LIB'];
  if (env != null && env.isNotEmpty) return env;
  final exeDir = File(Platform.resolvedExecutable).parent.path;
  final candidates = [
    if (Platform.isLinux) p.join(exeDir, 'lib'),
    if (Platform.isWindows) exeDir,
  ];
  final name = _sherpaCApiLib[Platform.operatingSystem];
  for (final c in candidates) {
    if (name != null && File(p.join(c, name)).existsSync()) return c;
  }
  return null;
}

/// Directory to pass to `sherpa.initBindings`, or null for process()/default.
///
/// Linux/Windows pass the folder that contains the `.so` / `.dll`.
String? sherpaInitBindingsDir(String operatingSystem, String? foundDir) {
  return foundDir;
}

/// Load the native sherpa-onnx C API in **this** isolate.
///
/// Each isolate has its own FFI binding state, so Kokoro/Piper/Whisper
/// workers must call this themselves.
void initSherpaBindings() {
  final found = sherpaNativeLibDir();
  sherpa.initBindings(sherpaInitBindingsDir(Platform.operatingSystem, found));
}
