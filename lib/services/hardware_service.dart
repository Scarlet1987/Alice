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

import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:front_porch_ai/app_version.dart';
import 'package:front_porch_ai/models/models.dart';
import 'package:front_porch_ai/services/hardware_audit.dart';
import 'package:front_porch_ai/utils/utils.dart';

// HardwareInfo moved to models/hardware_info.dart (this file was one edit
// from the 1,000-line god-file bar). Re-exported so the ~7 consumers that
// import it from here keep compiling unchanged.
export 'package:front_porch_ai/models/hardware_info.dart';

part 'hardware_service.nvidia.dart';
part 'hardware_service.apple.dart';
part 'hardware_service.linux.dart';
part 'hardware_service.windows.dart';
part 'hardware_service.free.dart';

class HardwareService extends ChangeNotifier {
  HardwareInfo? _hardwareInfo;
  bool _isDetecting = false;

  /// Free memory read the last time this app's KoboldCpp was not running:
  /// what a model has to load into. Set by the launch and by the preset
  /// editor; null until one of them has read it.
  FreeMemoryMb? freeBeforeEngine;

  /// The detected hardware, with [testVramOverrideMb] applied when set.
  /// Applied at the READ because detection assigns `_hardwareInfo` several
  /// times while narrowing down the GPU and every interim value is 0 MB on a
  /// headless runner — a consumer rebuilding in that window (Model Manager
  /// reads it per build) sees 0, calls fit unknowable, and drops its
  /// VRAM-dependent affordances. Here no detection pass can race it.
  HardwareInfo? get hardwareInfo {
    final override = testVramOverrideMb;
    if (override == null) return _hardwareInfo;
    // JSON round-trip: other fields keep detected values, no copy to drift.
    final base = _hardwareInfo?.toJson() ?? {'gpuName': 'E2E Override GPU'};
    return HardwareInfo.fromJson({...base, 'vramMb': override});
  }

  bool get isDetecting => _isDetecting;

  bool _detectedOnce = false;

  /// The detected hardware, waiting for the first detection to answer when
  /// nothing is known yet (a first run has no cached answer). Null when
  /// detection found nothing or [timeout] ran out.
  Future<HardwareInfo?> whenKnown({
    Duration timeout = const Duration(seconds: 20),
  }) async {
    bool settled() => _hardwareInfo != null || _detectedOnce || _disposed;
    if (!settled()) {
      final done = Completer<void>();
      void check() {
        if (settled() && !done.isCompleted) done.complete();
      }

      addListener(check);
      try {
        await done.future.timeout(timeout);
      } on TimeoutException {
        // Still unknown: the caller goes on without it.
      } finally {
        removeListener(check);
      }
    }
    return hardwareInfo;
  }

  /// True when this machine can only run local models on the CPU, slowly.
  ///
  /// Trigger: the CPU lacks AVX2 (so the ONLY KoboldCpp build that will launch
  /// is the `oldpc` one) AND there is no NVIDIA GPU. The oldpc build is
  /// "Cuda11 + AVX1" — it keeps CUDA for older NVIDIA cards but has no ROCm and
  /// no Vulkan, so an AMD/Intel GPU (or no GPU) gets zero acceleration and
  /// inference falls entirely onto the CPU. Returns false until detection has
  /// run (so the warning never flashes prematurely) and on macOS (arm64/Metal,
  /// where AVX2 is irrelevant). Drives the "expect slow performance" warning in
  /// setup + model settings (desktop) and the web Models page.
  bool get cpuOnlyLowPerf {
    if (!Platform.isWindows && !Platform.isLinux) return false;
    final info = _hardwareInfo;
    if (info == null) return false;
    if (cpuHasAvx2()) return false;
    return info.vendor != 'Nvidia';
  }

  /// SharedPreferences key for the last successful detection. Beta builds keep
  /// their own copy (CLAUDE.md's data-isolation rule).
  static String get _cacheKey =>
      isPreRelease ? 'beta_hardware_info_cache' : 'hardware_info_cache';

  HardwareService() {
    // Serve the last known answer immediately, then re-detect once the app is
    // on screen.
    //
    // Detection is expensive and it used to run from this constructor — i.e.
    // while the provider tree was being built, competing with the library load
    // for the exact window the user is staring at an empty grid. On Windows it
    // shells out to PowerShell up to four times (plus nvidia-smi), and the
    // result was never persisted, so every single launch paid full price for an
    // answer that changes only when someone physically changes their hardware.
    //
    // Restoring the cache means VRAM estimates and the CPU-only warning are
    // correct from the first frame instead of popping in seconds later, and the
    // re-detect still runs on every launch, so a swapped GPU is picked up the
    // same session — it just no longer happens during startup.
    _restoreThenDetect();
  }

  // Detection spans awaits (process spawns, WMI — slow on Windows), so it can
  // resume after dispose; notifyListeners then throws use-after-dispose.
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _restoreThenDetect() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw != null && _hardwareInfo == null) {
        final cached = HardwareInfo.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
        if (cached != null && !_disposed) {
          _hardwareInfo = cached;
          StartupTrace.mark('HardwareService: restored cached hardware info');
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('[HardwareService] Could not restore cached info: $e');
    }

    // Re-detect after the first frame so the process spawns never compete with
    // painting the app and filling the library grid. Guarded because
    // WidgetsBinding.instance THROWS when no binding exists — this service must
    // keep working if it is ever constructed headlessly (a script, a test, the
    // web server host), where there are no frames to wait for.
    try {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) detectHardware();
      });
    } catch (_) {
      detectHardware();
    }
  }

  /// Forces reported VRAM to this value (MB). A headless CI runner detects
  /// 0 MB, which hides every VRAM-dependent surface (fit estimates, the
  /// oversize-download confirm) from the E2E suite. Null = real detection.
  @visibleForTesting
  static int? testVramOverrideMb;

  Future<void> detectHardware() async {
    if (_disposed) return;
    _isDetecting = true;
    notifyListeners();
    final traceStart = DateTime.now();

    // Prefer the startup hardware audit when it ran: it already probed
    // vendor, VRAM, RAM, CUDA, and ROCm with fallbacks, so re-probing here
    // would just spawn duplicate subprocesses. Fall back to local probing
    // when the audit didn't run (tests, headless use).
    final audit = HardwareAudit.current;
    String? vendor = audit?.gpuVendor;
    if (audit != null) {
      _hasCuda = audit.hasCuda;
      _hasRocm = audit.hasRocm;
      StartupTrace.mark('HardwareService: consumed HardwareAudit');
    }
    // Vendor probe (skipped when the audit already named the vendor):
    // _checkDrivers() spawns nvidia-smi, which is wasted and noisy on
    // AMD/Intel machines. Knowing the vendor upfront skips it entirely
    // on non-NVIDIA hardware.
    if (vendor == null || vendor == 'Unknown' || vendor == 'None') {
      if (Platform.isLinux) {
        vendor = await _probeLinuxVendor();
      } else if (Platform.isWindows) {
        vendor = await _probeWindowsVendor();
      }
    }
    // Driver probe (skipped when the audit already answered): sets _hasCuda
    // / _hasRocm via nvidia-smi / rocminfo.
    if (audit == null) {
      await _checkDrivers(vendor: vendor);
    }
    StartupTrace.mark('HardwareService._checkDrivers');

    try {
      if (Platform.isWindows) {
        await _detectWindows();
      } else if (Platform.isLinux) {
        await _detectLinux();
      } else if (Platform.isMacOS) {
        await _detectMac();
      }
    } catch (e) {
      print('Hardware detection failed: $e');
    } finally {
      _fillGapsFromAudit(audit);
      _isDetecting = false;
      _detectedOnce = true;
      if (!_disposed) notifyListeners();
      StartupTrace.mark(
        'HardwareService.detectHardware DONE in '
        '${DateTime.now().difference(traceStart).inMilliseconds}ms',
      );
      // Persist so the NEXT launch can show correct VRAM/warnings immediately
      // instead of shelling out before it can answer.
      final info = _hardwareInfo;
      if (info != null) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_cacheKey, jsonEncode(info.toJson()));
        } catch (e) {
          debugPrint('[HardwareService] Could not cache hardware info: $e');
        }
      }
    }
  }

  /// Fills gaps in the locally probed [_hardwareInfo] from the startup
  /// audit profile — the single source of truth for vendor, name, VRAM
  /// and RAM, consumed here the same way [detectHardware] already consumes
  /// its CUDA/ROCm answers.
  ///
  /// Local probing derives the vendor from a cleaned-up GPU name, and the
  /// cleanup strips the bracketed parts of the lspci string — on an
  /// Ellesmere RX 580 the name reduces to "Advanced Micro Devices, Inc.
  /// Ellesmere", which matches no vendor substring, so local detection
  /// reported vendor 'Unknown', never read AMD sysfs VRAM, and the
  /// Engine resources card sat at "unknown VRAM" with its bar stuck on
  /// "reading…" while the audit had logged the correct 8192 MB all
  /// along. The audit classifies from the full lspci line, brackets
  /// included. Local values win wherever they actually answered; the
  /// audit only fills gaps, and when it never ran (tests, headless)
  /// this is a no-op.
  void _fillGapsFromAudit(HardwareProfile? audit) {
    if (audit == null) return;
    final auditVendor = audit.gpuVendor == 'None' ? 'Unknown' : audit.gpuVendor;
    final info = _hardwareInfo;
    if (info == null) {
      _hardwareInfo = HardwareInfo(
        gpuName: audit.gpuName,
        vramMb: audit.vramMb,
        ramMb: audit.systemRamMb,
        vendor: auditVendor,
        hasCuda: audit.hasCuda,
        hasRocm: audit.hasRocm,
        hasMetal: Platform.isMacOS,
      );
      return;
    }
    final vramMb = info.vramMb > 0 ? info.vramMb : audit.vramMb;
    final ramMb = info.ramMb > 0 ? info.ramMb : audit.systemRamMb;
    final vendor = info.vendor != 'Unknown' ? info.vendor : auditVendor;
    final gpuName = info.gpuName != 'Unknown GPU'
        ? info.gpuName
        : audit.gpuName;
    if (vramMb == info.vramMb &&
        ramMb == info.ramMb &&
        vendor == info.vendor &&
        gpuName == info.gpuName) {
      return;
    }
    _hardwareInfo = HardwareInfo(
      gpuName: gpuName,
      vramMb: vramMb,
      ramMb: ramMb,
      vendor: vendor,
      hasCuda: info.hasCuda,
      hasRocm: info.hasRocm,
      hasMetal: info.hasMetal,
      isSharedMemory: info.isSharedMemory,
      linuxDistro: info.linuxDistro,
      cardCount: info.cardCount,
      smallestCardMb: info.smallestCardMb > 0 ? info.smallestCardMb : null,
    );
  }

  bool _hasCuda = false;
  bool _hasRocm = false;

  /// Whether an NVIDIA GPU with working drivers was detected (nvidia-smi).
  /// Read by BackendManager to pick the right KoboldCpp binary — it no
  /// longer spawns its own duplicate nvidia-smi probe.
  bool get hasCuda => _hasCuda;

  /// Whether the ROCm runtime was detected (Linux, advisory only).
  bool get hasRocm => _hasRocm;

  /// Whether two GPU names coming from different Windows sources describe the
  /// same adapter.
  ///
  /// `Win32_VideoController.Name` (WMI), `DriverDesc` (registry) and
  /// nvidia-smi's marketing name are all spelled differently for one card, and
  /// on AMD one source routinely includes the model number where another drops
  /// it ("AMD Radeon(TM) 780M Graphics" vs "AMD Radeon(TM) Graphics"). Exact
  /// string comparison therefore fails on exactly the hardware that most needs
  /// shared-memory detection.
  ///
  /// Compares normalized token sets and accepts a subset match, so the less
  /// specific name matches the more specific one. Requires at least two shared
  /// tokens, which keeps a discrete card from matching an iGPU purely because
  /// both start with "AMD" — "AMD Radeon RX 7900 XTX" and "AMD Radeon(TM)
  /// Graphics" stay distinct because "graphics" is absent from the former.
  static bool gpuNamesMatch(String a, String b) {
    final tokensA = _gpuNameTokens(a);
    final tokensB = _gpuNameTokens(b);
    if (tokensA.isEmpty || tokensB.isEmpty) return false;
    final smaller = tokensA.length <= tokensB.length ? tokensA : tokensB;
    final larger = identical(smaller, tokensA) ? tokensB : tokensA;
    // A single shared token ("amd", "intel") is not evidence of anything.
    if (smaller.length < 2) return false;
    return smaller.every(larger.contains);
  }

  /// Lowercase alphanumeric tokens of a GPU name, with the vendor trademark
  /// noise ("(tm)", "(r)") dropped so it never counts toward a match.
  static Set<String> _gpuNameTokens(String name) => name
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((t) => t.isNotEmpty && t != 'tm' && t != 'r')
      .toSet();

  /// Maps a GPU marketing name to one of 'Nvidia', 'AMD', 'Intel', 'Unknown'.
  ///
  /// Recognises a broad set of substrings so very new architectures (RTX
  /// 50-series "Blackwell", Intel Arc, AMD Radeon RX 7000) are still routed to
  /// the right backend even before driver-level identification kicks in.
  String _vendorFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('nvidia') ||
        lower.contains('geforce') ||
        lower.contains('quadro') ||
        lower.contains('rtx ') ||
        lower.contains('gtx ') ||
        lower.contains('tesla ')) {
      return 'Nvidia';
    }
    if (lower.contains('amd') ||
        lower.contains('radeon') ||
        lower.contains('ati ') ||
        lower.contains('firepro') ||
        lower.contains('instinct')) {
      return 'AMD';
    }
    if (lower.contains('intel') ||
        lower.contains('iris') ||
        lower.contains('uhd') ||
        lower.contains('arc ')) {
      return 'Intel';
    }
    return 'Unknown';
  }

  Future<void> _checkDrivers({String? vendor}) async {
    _hasCuda = false;
    _hasRocm = false;

    // CUDA Check (nvidia-smi) — skip on macOS where it doesn't exist, and
    // skip entirely when the vendor probe already told us this isn't NVIDIA
    // hardware (AMD/Intel boxes were spawning nvidia-smi just to watch it
    // fail, on every launch).
    // Use _runNvidiaSmi() so we still detect CUDA when the driver installed
    // nvidia-smi only under NVSMI/ (not in PATH).
    final isNvidia = vendor == null || vendor == 'Nvidia';
    if (!Platform.isMacOS && isNvidia) {
      final res = await _runNvidiaSmi([]);
      if (res != null) _hasCuda = true;
    }

    // ROCm runtime presence — Linux only, and purely ADVISORY: it enables
    // the expert opt-in chip in Settings and the guidance dialog. It never
    // selects the backend (see GpuBackendResolver). rocminfo succeeding
    // proves the runtime is installed, not that koboldcpp's hipblas
    // kernels support this card.
    //
    // Windows is deliberately always false: the old check keyed on
    // amdhip64.dll, which ships with EVERY standard Adrenalin driver, and
    // the mainline Windows koboldcpp.exe has no hipblas backend at all —
    // Windows AMD users belong on Vulkan.
    if (Platform.isLinux) {
      try {
        final res = await Process.run(
          'rocminfo',
          [],
        ).timeout(const Duration(seconds: 10));
        if (res.exitCode == 0) _hasRocm = true;
      } catch (_) {}
    }
  }
}
