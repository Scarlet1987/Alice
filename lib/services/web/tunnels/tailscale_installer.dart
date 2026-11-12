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

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

import 'package:front_porch_ai/services/security/release_checksums.dart';
import 'package:front_porch_ai/services/security/verify_sha256.dart';

/// How an install attempt resolved — drives what the tutorial tells the user
/// to do next.
enum TailscaleInstallOutcome {
  /// A package manager finished installing; a Re-check should now find it.
  installed,

  /// A graphical installer was launched; the user finishes it themselves
  /// (clicks through / enters an admin password), then Re-checks.
  launchedInstaller,

  /// We opened the official download page (no scripted path was available).
  openedDownloadPage,

  /// Linux without a graphical sudo (pkexec): hand over the exact command.
  needsManualCommand,

  /// Not a desktop platform we install on.
  unsupported,

  /// Something went wrong launching the install.
  failed,
}

/// Result of [TailscaleInstaller.install].
class TailscaleInstallResult {
  const TailscaleInstallResult(this.outcome, {this.command, this.downloadUrl});

  final TailscaleInstallOutcome outcome;

  /// The shell command to run by hand ([TailscaleInstallOutcome.needsManualCommand]).
  final String? command;

  /// The page we opened / that the user can fall back to.
  final String? downloadUrl;
}

/// "Install Tailscale for me", using each OS's official, blessed mechanism so
/// we never hand-roll downloads or silently elevate:
///   • macOS   — the versioned standalone .pkg (the only variant with
///               `tailscale serve`), verified against its published
///               `<pkg>.sha256` before the Installer opens it.
///   • Windows — winget (downloads + UAC-elevates), else the download page.
///   • Linux   — the official package via the native package manager
///               (apt/dnf/yum/pacman/zypper under pkexec), else the official
///               command + download page. install.sh is never downloaded or
///               run as root: Tailscale publishes no hash for it.
/// The two unavoidable human gates (admin approval, browser sign-in) are OS
/// security boundaries we deliberately keep, not automate around.
class TailscaleInstaller {
  static const String macPkgUrl =
      'https://pkgs.tailscale.com/stable/Tailscale-latest-macos.pkg';
  static const String wingetId = 'Tailscale.Tailscale';
  static const String linuxCommand =
      'curl -fsSL https://tailscale.com/install.sh | sh';
  static const String windowsDownloadUrl =
      'https://tailscale.com/download/windows';
  static const String linuxDownloadUrl = 'https://tailscale.com/download/linux';

  /// True on the three desktop platforms we can drive an install on.
  static bool get isSupported =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  Future<TailscaleInstallResult> install() async {
    try {
      if (Platform.isMacOS) return await _installMac();
      if (Platform.isWindows) return await _installWindows();
      if (Platform.isLinux) return await _installLinux();
    } catch (e) {
      debugPrint('[TailscaleInstaller] install error: $e');
      return const TailscaleInstallResult(TailscaleInstallOutcome.failed);
    }
    return const TailscaleInstallResult(TailscaleInstallOutcome.unsupported);
  }

  /// Resolves the versioned macOS pkg URL behind the `Tailscale-latest-`
  /// alias (the alias itself publishes no `.sha256`). Returns null when the
  /// alias does not redirect to a versioned `Tailscale-N.N.N-macos.pkg`.
  /// [latestUrl] overrides the alias URL; it is a test seam only.
  @visibleForTesting
  static Future<Uri?> resolveVersionedMacPkg(
    http.Client client, {
    Uri? latestUrl,
  }) async {
    final target = await resolveRedirectTarget(
      client: client,
      url: latestUrl ?? Uri.parse(macPkgUrl),
    );
    if (target == null) return null;
    if (!RegExp(
      r'Tailscale-[0-9]+\.[0-9]+\.[0-9]+-macos\.pkg$',
    ).hasMatch(target.path)) {
      return null;
    }
    return target;
  }

  Future<TailscaleInstallResult> _installMac() async {
    // The standalone .pkg (the only variant with `tailscale serve`) is
    // opened in the Installer so Gatekeeper verifies the signature — but
    // first the download itself is verified against the hash Tailscale
    // publishes at `<versioned-pkg-url>.sha256`. The `latest` alias has no
    // .sha256, so resolve it to the versioned pkg, fetch that pkg's hash,
    // download the versioned pkg, and verify before opening. Any failure
    // blocks the install: the unverified file is deleted, never opened.
    final client = http.Client();
    try {
      final pkgUrl = await resolveVersionedMacPkg(client);
      if (pkgUrl == null) {
        return const TailscaleInstallResult(TailscaleInstallOutcome.failed);
      }
      final expected = await fetchSha256FromUrl(
        client: client,
        url: Uri.parse('${pkgUrl.toString()}.sha256'),
      );
      if (expected == null) {
        return const TailscaleInstallResult(TailscaleInstallOutcome.failed);
      }
      final res = await client
          .get(pkgUrl)
          .timeout(const Duration(seconds: 120));
      if (res.statusCode != 200 || res.bodyBytes.isEmpty) {
        return const TailscaleInstallResult(TailscaleInstallOutcome.failed);
      }
      final tmpDir = await Directory.systemTemp.createTemp('fpai_tailscale_');
      final file = File(p.join(tmpDir.path, p.basename(pkgUrl.path)));
      await file.writeAsBytes(res.bodyBytes);
      await VerifySha256.verifyFileOrDelete(
        file,
        expected,
        assetLabel: 'tailscale macOS pkg',
      );
      final open = await Process.run('open', [file.path]);
      return open.exitCode == 0
          ? const TailscaleInstallResult(
              TailscaleInstallOutcome.launchedInstaller,
            )
          : const TailscaleInstallResult(TailscaleInstallOutcome.failed);
    } catch (e) {
      debugPrint('[TailscaleInstaller] mac install error: $e');
      return const TailscaleInstallResult(TailscaleInstallOutcome.failed);
    } finally {
      client.close();
    }
  }

  Future<TailscaleInstallResult> _installWindows() async {
    // winget downloads + UAC-elevates the official package for us.
    if (!await _commandAvailable('winget', const ['--version'])) {
      await _open(windowsDownloadUrl);
      return const TailscaleInstallResult(
        TailscaleInstallOutcome.openedDownloadPage,
        downloadUrl: windowsDownloadUrl,
      );
    }
    final r = await Process.run('winget', [
      'install',
      '--id',
      wingetId,
      '-e',
      '--accept-package-agreements',
      '--accept-source-agreements',
    ]);
    if (r.exitCode == 0) {
      return const TailscaleInstallResult(TailscaleInstallOutcome.installed);
    }
    // Non-zero usually means the UAC prompt was declined; offer the page.
    await _open(windowsDownloadUrl);
    return const TailscaleInstallResult(
      TailscaleInstallOutcome.openedDownloadPage,
      downloadUrl: windowsDownloadUrl,
    );
  }

  /// Native package managers that carry an official Tailscale package,
  /// with the argv that installs it (run under pkexec for the admin gate).
  /// No install.sh is ever downloaded or executed: Tailscale publishes no
  /// hash for it, so a script fetched over HTTPS cannot be verified before
  /// running it as root.
  static const Map<String, List<String>> _linuxPackageManagers = {
    'apt-get': ['apt-get', 'install', '-y', 'tailscale'],
    'dnf': ['dnf', 'install', '-y', 'tailscale'],
    'yum': ['yum', 'install', '-y', 'tailscale'],
    'pacman': ['pacman', '-S', '--noconfirm', 'tailscale'],
    'zypper': ['zypper', 'install', '-y', 'tailscale'],
  };

  /// The install argv for a detected package manager, or null when the
  /// manager is not one we install Tailscale through.
  @visibleForTesting
  static List<String>? installArgvForManager(String manager) =>
      _linuxPackageManagers[manager];

  /// First supported native package manager found on PATH, or null.
  static Future<String?> detectLinuxPackageManager() async {
    for (final manager in _linuxPackageManagers.keys) {
      if (await _commandAvailable('which', [manager])) return manager;
    }
    return null;
  }

  Future<TailscaleInstallResult> _installLinux() async {
    // Install the official Tailscale package through the distro's native
    // package manager under pkexec — never download install.sh and run it
    // as root (Tailscale publishes no hash for it). When no supported
    // manager is present, or the install fails, hand the user the official
    // command and download page instead of running anything ourselves.
    const manual = TailscaleInstallResult(
      TailscaleInstallOutcome.needsManualCommand,
      command: linuxCommand,
      downloadUrl: linuxDownloadUrl,
    );
    if (!await _commandAvailable('which', const ['pkexec'])) return manual;
    final manager = await detectLinuxPackageManager();
    if (manager == null) return manual;
    final argv = installArgvForManager(manager)!;
    try {
      final r = await Process.run(
        'pkexec',
        argv,
      ).timeout(const Duration(minutes: 5));
      if (r.exitCode == 0) {
        return const TailscaleInstallResult(TailscaleInstallOutcome.installed);
      }
      debugPrint('[TailscaleInstaller] $manager install failed: ${r.stderr}');
    } catch (e) {
      debugPrint('[TailscaleInstaller] linux install error: $e');
    }
    return manual;
  }

  static Future<bool> _commandAvailable(String exe, List<String> probe) async {
    try {
      return (await Process.run(
            exe,
            probe,
          ).timeout(const Duration(seconds: 10))).exitCode ==
          0;
    } catch (_) {
      return false;
    }
  }

  Future<void> _open(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}
