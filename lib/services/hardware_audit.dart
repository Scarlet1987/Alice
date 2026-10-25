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

import 'package:flutter/foundation.dart';
import 'package:front_porch_ai/services/gpu_backend_resolver.dart';
import 'package:front_porch_ai/services/memory_budget.dart';

/// Capability tiers by VRAM. Elaina's 8GB baseline sits at the top of
/// 'standard' — the tier the engine budget enforcement is tuned for.
class CapabilityTier {
  static const low = 'low'; // < 4GB VRAM
  static const standard = 'standard'; // 4–8GB VRAM
  static const high = 'high'; // > 8GB VRAM

  static String forVram(int vramMb) {
    if (vramMb < 4096) return low;
    if (vramMb <= 8192) return standard;
    return high;
  }
}

/// The machine's capability profile, produced once at startup by
/// [HardwareAudit.run] before any backend touches the hardware.
///
/// Every probe has a fallback — a missing lspci, an unreadable sysfs, a
/// crashed nvidia-smi all degrade to safe defaults ('Unknown', 0) rather
/// than throwing. The app must launch on hardware it has never seen.
class HardwareProfile {
  /// 'Nvidia', 'AMD', 'Intel', 'Unknown', or 'None' (no discrete GPU found).
  final String gpuVendor;

  /// Best-effort GPU marketing name, or 'Unknown GPU'.
  final String gpuName;

  /// Total VRAM in MB, 0 when it could not be determined.
  final int vramMb;

  /// Total system RAM in MB, 0 when it could not be determined.
  final int systemRamMb;

  /// Logical CPU cores (always available via Platform.numberOfProcessors).
  final int cpuCores;

  /// NVIDIA driver present (nvidia-smi succeeded). Only probed on
  /// Nvidia/Unknown vendors — never on AMD/Intel.
  final bool hasCuda;

  /// ROCm runtime present (rocminfo succeeded). Linux + AMD only, advisory.
  final bool hasRocm;

  /// AMD gfx architecture from rocminfo (e.g. 'gfx803' for Polaris/RX 580),
  /// or null when not applicable/unknown.
  final String? gfxArch;

  /// True when ROCm can actually run compute on this GPU: the runtime is
  /// installed AND the gfx architecture is one ROCm's prebuilt kernels
  /// support (or can be coaxed via HSA_OVERRIDE_GFX_VERSION).
  ///
  /// Polaris (gfx803, e.g. RX 580) is NOT viable — AMD dropped it after
  /// ROCm 5.x. A present rocminfo binary does not mean the card works.
  bool get rocmComputeViable {
    if (!hasRocm || gfxArch == null) return false;
    final arch = gfxArch!.trim().toLowerCase();
    // Officially supported: no override needed.
    const supported = {
      'gfx900',
      'gfx906',
      'gfx908',
      'gfx90a',
      'gfx942',
      'gfx1030',
      'gfx1100',
      'gfx1201',
    };
    if (supported.contains(arch)) return true;
    // Coaxable via HSA_OVERRIDE_GFX_VERSION (RDNA2/3/4 families).
    return GpuBackendResolver.hsaOverrideForGfx(arch) != null;
  }

  /// [CapabilityTier.low], [standard], or [high].
  final String capabilityTier;

  /// Engine backends viable on this hardware, most capable first.
  final List<String> recommendedEngineModes;

  const HardwareProfile({
    required this.gpuVendor,
    required this.gpuName,
    required this.vramMb,
    required this.systemRamMb,
    required this.cpuCores,
    required this.hasCuda,
    required this.hasRocm,
    this.gfxArch,
    required this.capabilityTier,
    required this.recommendedEngineModes,
  });

  /// True when [requiredVramMb] fits in detected VRAM. A 0 vramMb (unknown)
  /// answers true — unknown hardware must not block the user, it just
  /// means we can't warn them.
  bool canRun(int requiredVramMb) {
    if (vramMb <= 0) return true;
    return vramMb >= requiredVramMb;
  }

  /// Null when [requiredVramMb] fits (or VRAM is unknown); otherwise a
  /// plain-English message naming the shortfall and what to do — for the
  /// backend to show instead of crashing or printing a stack trace.
  String? vramShortfallMessage(int requiredVramMb, {String? operation}) {
    if (canRun(requiredVramMb)) return null;
    final what = operation ?? 'this model';
    final haveGb = (vramMb / 1024).toStringAsFixed(1);
    final needGb = (requiredVramMb / 1024).toStringAsFixed(1);
    return 'Not enough VRAM for $what: it needs ${needGb}GB but this '
        'machine has ${haveGb}GB. Try a smaller model, or switch to a '
        'remote backend in Settings.';
  }

  /// Alice's harness memory budget in MB: the app itself (its process,
  /// caches, queued work) plus the engines' harness-side overhead stays
  /// within 2 GB. Model weights and KV cache are NOT in this number — they
  /// live in the VRAM budget the fit math manages. A getter, not a field:
  /// the cap is a product decision, not per-machine hardware. The user can
  /// raise it in Settings → Engine resources.
  int get memoryBudgetMb => 2048;

  /// True when a harness-side allocation of [ramMb] system RAM plus [vramMb]
  /// VRAM fits inside the [memoryBudgetMb] cap. This is the app's budget,
  /// not the machine's capacity — it says nothing about what the hardware
  /// has free.
  bool fitsInBudget({required int ramMb, required int vramMb}) =>
      ramMb + vramMb <= memoryBudgetMb;

  /// Plain words when an allocation does not fit the budget, for the UI or
  /// a log line instead of a crash. Null when it fits.
  String? budgetShortfallMessage({required int ramMb, required int vramMb}) {
    if (fitsInBudget(ramMb: ramMb, vramMb: vramMb)) return null;
    return MemoryBudget.shortfallMessage(
      usedMb: ramMb + vramMb,
      budgetMb: memoryBudgetMb,
    );
  }

  @override
  String toString() =>
      'HardwareProfile($gpuVendor $gpuName, VRAM: ${vramMb}MB, '
      'RAM: ${systemRamMb}MB, CPUs: $cpuCores, tier: $capabilityTier, '
      'CUDA: $hasCuda, ROCm: $hasRocm (viable: $rocmComputeViable), '
      'gfx: ${gfxArch ?? 'n/a'}, modes: $recommendedEngineModes)';
}

/// Runs once at startup, before any backend initializes, and produces the
/// [HardwareProfile] the rest of the app reads from [HardwareAudit.current].
///
/// This is the single place that spawns hardware-probing subprocesses at
/// launch. [HardwareService] and [BackendManager] consume [current] instead
/// of running their own duplicate probes.
class HardwareAudit {
  HardwareAudit._();

  static HardwareProfile? _current;

  /// The audit result, or null when [run] hasn't completed yet (tests,
  /// headless use). Consumers must handle null by falling back to their
  /// own detection — never crash on it.
  static HardwareProfile? get current => _current;

  /// Test hook: inject a profile without probing.
  @visibleForTesting
  static set testProfile(HardwareProfile? profile) => _current = profile;

  /// Probe the hardware once. Safe to call repeatedly (re-probes); the
  /// startup sequence calls it exactly once.
  static Future<HardwareProfile> run() async {
    // lspci output is reused by the vendor and name probes — one spawn.
    final lspciOutput = await _lspciOutput();
    final vendor = await _probeVendor(lspciOutput);
    final gpuName = _gpuNameFromLspciOutput(lspciOutput);
    final vramRes = await _probeVram(vendor);
    final vramMb = vramRes.vramMb;
    final systemRamMb = await _probeSystemRam();
    final cpuCores = Platform.numberOfProcessors;
    // CUDA is viable exactly when nvidia-smi ran successfully — _probeVram
    // already determined that above, so no second spawn. Never true on macOS.
    final hasCuda =
        !Platform.isMacOS &&
        (vendor == 'Nvidia' || vendor == 'Unknown') &&
        vramRes.nvidiaSmiOk;
    final rocm = await _probeRocm(vendor);
    final hasRocm = rocm.present;
    // Gfx arch matters for ROCm viability: Polaris (gfx803) has a rocminfo
    // binary but no usable compute. Parsed from the same rocminfo output —
    // no second spawn.
    final gfxArch = rocm.gfxArch;

    final tier = CapabilityTier.forVram(vramMb);
    final modes = _recommendedModes(
      vendor: vendor,
      hasCuda: hasCuda,
      hasRocm: hasRocm,
    );

    final profile = HardwareProfile(
      gpuVendor: vendor,
      gpuName: gpuName,
      vramMb: vramMb,
      systemRamMb: systemRamMb,
      cpuCores: cpuCores,
      hasCuda: hasCuda,
      hasRocm: hasRocm,
      gfxArch: gfxArch,
      capabilityTier: tier,
      recommendedEngineModes: modes,
    );
    _current = profile;
    debugPrint('[HardwareAudit] $profile');
    return profile;
  }

  // ── Probes (every one falls back, none throws) ──────────────────────────

  /// Raw lspci output on Linux, null on other platforms or when lspci is
  /// unavailable. Fetched once per audit run and shared by the vendor and
  /// GPU-name probes.
  static Future<String?> _lspciOutput() async {
    if (!Platform.isLinux) return null;
    try {
      final res = await Process.run(
        'lspci',
        [],
      ).timeout(const Duration(seconds: 5));
      if (res.exitCode == 0) return res.stdout.toString();
    } catch (_) {}
    return null;
  }

  static Future<String> _probeVendor(String? lspciOutput) async {
    if (lspciOutput != null) {
      String? vga;
      String? threeD;
      for (final line in lspciOutput.split('\n')) {
        if (line.contains('VGA') || line.contains('Display controller')) {
          vga ??= line;
        } else if (line.contains('3D controller')) {
          threeD ??= line;
        }
      }
      // Prefer the 3D controller (discrete GPU on hybrid laptops).
      final gpuLine = threeD ?? vga;
      if (gpuLine == null) return 'None';
      return _vendorFromName(gpuLine);
    }
    if (Platform.isMacOS) return 'Apple';
    if (Platform.isWindows) {
      try {
        final res = await Process.run('powershell', [
          '-command',
          r"Get-ItemProperty 'HKLM:\SYSTEM\ControlSet001\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\*' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty DriverDesc",
        ]).timeout(const Duration(seconds: 10));
        final vendor = _vendorFromName(res.stdout.toString());
        if (vendor != 'Unknown') return vendor;
      } catch (_) {}
    }
    return 'Unknown';
  }

  static String _gpuNameFromLspciOutput(String? output) {
    if (output == null) return 'Unknown GPU';
    for (final line in output.split('\n')) {
      if (line.contains('VGA') ||
          line.contains('3D controller') ||
          line.contains('Display controller')) {
        final idx = line.indexOf(':');
        if (idx >= 0) {
          var name = line.substring(idx + 1).trim();
          name = name.replaceAll(RegExp(r'\[.*?\]'), '').trim();
          if (name.isNotEmpty) return name;
        }
      }
    }
    return 'Unknown GPU';
  }

  static String _vendorFromName(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('nvidia') ||
        lower.contains('geforce') ||
        lower.contains('quadro') ||
        lower.contains('tesla')) {
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
        lower.contains('arc')) {
      return 'Intel';
    }
    if (lower.contains('apple')) return 'Apple';
    return 'Unknown';
  }

  /// NVIDIA VRAM + CUDA availability from a single nvidia-smi spawn.
  /// Returns both answers so callers never spawn nvidia-smi twice.
  static Future<({int vramMb, bool cudaOk})> _probeNvidia() async {
    try {
      final res = await Process.run('nvidia-smi', [
        '--query-gpu=memory.total',
        '--format=csv,noheader,nounits',
      ]).timeout(const Duration(seconds: 10));
      if (res.exitCode != 0) return (vramMb: 0, cudaOk: false);
      var best = 0;
      for (final line in res.stdout.toString().split('\n')) {
        final mb = int.tryParse(
          RegExp(r'(\d+)').firstMatch(line)?.group(1) ?? '',
        );
        if (mb != null && mb > best) best = mb;
      }
      return (vramMb: best, cudaOk: true);
    } catch (_) {
      return (vramMb: 0, cudaOk: false);
    }
  }

  static Future<({int vramMb, bool nvidiaSmiOk})> _probeVram(
    String vendor,
  ) async {
    // NVIDIA: nvidia-smi is authoritative.
    if (vendor == 'Nvidia' || vendor == 'Unknown') {
      final nvidia = await _probeNvidia();
      if (nvidia.vramMb > 0) return (vramMb: nvidia.vramMb, nvidiaSmiOk: true);
      // Unknown vendor: nvidia-smi failed, don't try other paths blindly.
      if (vendor == 'Nvidia') return (vramMb: 0, nvidiaSmiOk: nvidia.cudaOk);
    }
    // AMD: sysfs via the amdgpu driver.
    if (vendor == 'AMD' || vendor == 'Unknown') {
      try {
        final total = await _amdVramFromSysfs();
        if (total > 0) return (vramMb: total, nvidiaSmiOk: false);
      } catch (_) {}
    }
    return (vramMb: 0, nvidiaSmiOk: false);
  }

  /// Largest VRAM total across /sys/class/drm/cardN (amdgpu), in MB.
  static Future<int> _amdVramFromSysfs([String root = '/sys/class/drm']) async {
    final drm = Directory(root);
    if (!await drm.exists()) return 0;
    var bestMb = 0;
    await for (final entry in drm.list()) {
      final seg = entry.uri.pathSegments.where((s) => s.isNotEmpty).last;
      if (!RegExp(r'^card\d+$').hasMatch(seg)) continue;
      final totalFile = File('${entry.path}/device/mem_info_vram_total');
      if (!await totalFile.exists()) continue;
      final bytes = int.tryParse((await totalFile.readAsString()).trim());
      if (bytes != null && bytes > 0) {
        final mb = (bytes / (1024 * 1024)).round();
        if (mb > bestMb) bestMb = mb;
      }
    }
    return bestMb;
  }

  static Future<int> _probeSystemRam() async {
    try {
      if (Platform.isLinux) {
        final res = await Process.run('cat', [
          '/proc/meminfo',
        ]).timeout(const Duration(seconds: 5));
        if (res.exitCode == 0) {
          for (final line in res.stdout.toString().split('\n')) {
            if (line.startsWith('MemTotal:')) {
              final kb = int.tryParse(
                RegExp(r'(\d+)').firstMatch(line)?.group(1) ?? '',
              );
              if (kb != null) return (kb / 1024).round();
            }
          }
        }
      } else if (Platform.isMacOS) {
        final res = await Process.run('sysctl', [
          '-n',
          'hw.memsize',
        ]).timeout(const Duration(seconds: 5));
        if (res.exitCode == 0) {
          final bytes = int.tryParse(res.stdout.toString().trim());
          if (bytes != null) return (bytes / (1024 * 1024)).round();
        }
      } else if (Platform.isWindows) {
        final res = await Process.run('powershell', [
          '-command',
          r'(Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory',
        ]).timeout(const Duration(seconds: 10));
        final bytes = int.tryParse(res.stdout.toString().trim());
        if (bytes != null) return (bytes / (1024 * 1024)).round();
      }
    } catch (_) {}
    return 0;
  }

  /// Advisory only, Linux + AMD. Never decides the backend by itself.
  /// Single rocminfo spawn answering both presence and gfx architecture —
  /// a present binary does not imply a supported architecture (Polaris).
  static Future<({bool present, String? gfxArch})> _probeRocm(
    String vendor,
  ) async {
    if (!Platform.isLinux) return (present: false, gfxArch: null);
    if (vendor != 'AMD') return (present: false, gfxArch: null);
    try {
      final res = await Process.run(
        'rocminfo',
        [],
      ).timeout(const Duration(seconds: 10));
      if (res.exitCode != 0) return (present: false, gfxArch: null);
      return (
        present: true,
        gfxArch: GpuBackendResolver.gfxFromRocminfo(res.stdout.toString()),
      );
    } catch (_) {
      return (present: false, gfxArch: null);
    }
  }

  static List<String> _recommendedModes({
    required String vendor,
    required bool hasCuda,
    required bool hasRocm,
  }) {
    if (Platform.isMacOS) return const ['metal', 'cpu'];
    switch (vendor) {
      case 'Nvidia':
        return hasCuda ? const ['cuda', 'vulkan', 'cpu'] : const ['cpu'];
      case 'AMD':
        // ROCm is expert opt-in; Vulkan is the safe default on AMD.
        return const ['vulkan', 'cpu'];
      case 'Intel':
        return const ['vulkan', 'cpu'];
      case 'Apple':
        return const ['metal', 'cpu'];
      default:
        return const ['cpu'];
    }
  }
}
