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

part of 'kobold_service.dart';

/// Process spawn, extracted from KoboldServiceProcess so that file stays
/// under the 500-line god-file bar. No behaviour change: the same _spawn,
/// moved whole into its own extension on KoboldService.
extension KoboldServiceSpawn on KoboldService {
  Future<KoboldLaunchResult> _spawn(
    String executablePath,
    String modelPath,
    String? kcppsPath,
    List<String> args,
    KoboldStagedRole? staged, {
    required int port,
    required bool useRocm,
    required int generation,
  }) async {
    try {
      // ROCm: consumer RDNA cards need HSA_OVERRIDE_GFX_VERSION or the
      // hipblas kernels abort at load — resolver detects the gfx arch and
      // supplies it (no-op when unnecessary or already exported).
      final extraEnv = useRocm
          ? await GpuBackendResolver.rocmEnvironment()
          : const <String, String>{};
      // The last wait before the process exists, so the last place a Stop
      // can still call the start off.
      if (generation != _startGeneration) return _refuse(_stopPressed);
      _lastFailure = null;
      _replyFinished = false;
      _rocmFlashAttentionLaunch =
          useRocm && staged != null && _flashAttentionIn(staged.key);
      _process = await Process.start(
        executablePath,
        args,
        workingDirectory: path.dirname(executablePath),
        environment: extraEnv.isEmpty ? null : extraEnv,
        includeParentEnvironment: true,
      );
      _isRunning = true;
      _modelLoadingStatus = 'Initializing model...';
      _modelReady = false;
      MemoryBudget.reportEngine(
        MemoryBudget.textEngine,
        const EngineFootprint(ramMb: kKoboldHarnessOverheadMb),
      );
      _speed.loads.started();
      _loadedModelPath = modelPath.isNotEmpty
          ? modelPath
          : _storageService.backendSettings.kcppsModelPath;
      _loadedKcppsPath = kcppsPath;
      _residentKey = staged?.key;
      _idleRestart();
      _loadGeneration++;
      _residentGeneration++; // a new process reads the file as it is now
      _followLaunchContext(_loadGeneration);
      _addLog('Starting Koboldcpp (PID: ${_process!.pid})...');
      _addLog('Command: $executablePath ${args.join(' ')}');
      notify();

      // Start periodic readiness probe — more reliable than log-watching.
      _startReadinessProbe();

      final launched = _process!;
      // Lines, not reads, for a reply's end: it can arrive in two reads.
      final outLines = KoboldOutputLines();
      final errLines = KoboldOutputLines();
      _process!.stdout
          .transform(const Utf8Decoder(allowMalformed: true))
          .listen((data) {
            _addLog(data);
            _parseLoadingStatus(data);
            _ingestLiveProgress(data);
            _speed.lines.add(data);
            _storageService.backendSettings.noteKoboldOutput(data);
            _noteReplyFinished(launched, outLines.add(data));
          });

      _process!.stderr
          .transform(const Utf8Decoder(allowMalformed: true))
          .listen((data) {
            _noteReplyFinished(launched, errLines.add(data));
            // Many backends log everything to stderr even if not an error.
            var cleanData = data.trim();
            if (cleanData.isNotEmpty) {
              // Strip ALL occurrences of ERR: and filter out progress dots
              cleanData = cleanData
                  .replaceAll('ERR: ', '')
                  .replaceAll('ERR:', '');
              if (cleanData != '.' && cleanData != '..' && cleanData != '...') {
                _addLog(cleanData);
                _parseLoadingStatus(cleanData);
                _ingestLiveProgress(cleanData);
              }
            }
          });

      launched.exitCode.then((code) {
        _addLog('Process exited with code $code');
        // Only the process we are still tracking may clear the state — a
        // late-dying orphan from an overlapping start must not report the
        // LIVE backend as stopped.
        if (!identical(_process, launched)) {
          notify();
          return;
        }
        final wasReady = _modelReady;
        _isRunning = false;
        _process = null;
        _residentKey = null;
        MemoryBudget.clearEngine(MemoryBudget.textEngine);
        _loadGeneration++;
        _idleStop(); // as a stop does: nothing to unload or load back

        // Exit 2 is KoboldCpp's "Cannot find text model file" path. The
        // pre-flight above catches most causes, but KoboldCpp resolves the
        // path through Python and can still reject a file we read fine, so
        // translate the bare exit code rather than leaving the user guessing.
        if (code == 2) {
          _addLog(ModelFileCheck.explainExitCode2(modelPath));
        }
        _noteExit(
          code,
          launched,
          wasReady: wasReady,
          executablePath: executablePath,
          port: port,
        );
        notify();
      });
      return const KoboldLaunchResult.started();
    } catch (e, stack) {
      debugPrint(
        '[KoboldService] start failed: $e (program present: '
        '${File(executablePath).existsSync()})\n$stack',
      );
      _addLog('Failed to start process: $e');
      _isRunning = false;
      return KoboldLaunchResult.refused(
        'KoboldCpp could not be started: its program could not be run '
        '(${e is ProcessException ? e.message : e}).',
      );
    }
  }

  /// Regex matching KoboldCPP per-token / per-batch progress messages.
  /// These are purely informational counters that fire for every token and
  /// would otherwise flood the log with thousands of identical-looking lines.
  static final RegExp _progressLinePattern = RegExp(
    r'^(Generating \(|Processing Prompt(?: \[BATCH\])? \()',
    caseSensitive: false,
  );

  /// [lines] from [from] finishing a reply, while [from] is still the
  /// process the app runs: from then on a crash is not a first-reply crash.
}
