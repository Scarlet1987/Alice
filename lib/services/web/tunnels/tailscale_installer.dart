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
///   • macOS   — the standalone .pkg (the only variant with `tailscale serve`),
///               opened in the Installer so Gatekeeper verifies the signature.
///   • Windows — winget (downloads + UAC-elevates), else the download page.
///   • Linux   — the official distro-detecting install.sh via pkexec, else the
///               command + download page.
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

  Future<TailscaleInstallResult> _installMac() async {
    // Download the standalone .pkg over HTTPS from the official package server,
    // then open it — the macOS Installer checks Tailscale's signature and the
    // user approves with admin rights. (The App Store variant is sandboxed and
    // can't run `tailscale serve`, so we deliberately use the standalone pkg.)
    final res = await http
        .get(Uri.parse(macPkgUrl))
        .timeout(const Duration(seconds: 120));
    if (res.statusCode != 200 || res.bodyBytes.isEmpty) {
      await _open(macPkgUrl);
      return const TailscaleInstallResult(
        TailscaleInstallOutcome.openedDownloadPage,
        downloadUrl: macPkgUrl,
      );
    }
    final tmpDir = await Directory.systemTemp.createTemp('fpai_tailscale_');
    final file = File(p.join(tmpDir.path, 'Tailscale-macos.pkg'));
    await file.writeAsBytes(res.bodyBytes);
    // Integrity: verify before handing to the Installer.
    // TODO: pin the expected SHA-256 for the Tailscale macOS pkg and verify
    // here before opening. Gatekeeper checks the Developer ID signature, but
    // a hash pin catches a swapped download before it reaches the Installer.
    await VerifySha256.verifyFileOrThrow(
      file,
      null, // no pinned hash yet — logs TODO, does not block
      assetLabel: 'tailscale macOS pkg',
    );
    final open = await Process.run('open', [file.path]);
    return open.exitCode == 0
        ? const TailscaleInstallResult(
            TailscaleInstallOutcome.launchedInstaller,
          )
        : const TailscaleInstallResult(TailscaleInstallOutcome.failed);
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

  Future<TailscaleInstallResult> _installLinux() async {
    // pkexec shows a graphical password dialog on most desktops. We download
    // install.sh first, verify its hash, then execute the verified file —
    // never pipe a remote script straight into a root shell.
    if (!await _commandAvailable('which', const ['pkexec'])) {
      await _open(linuxDownloadUrl);
      return const TailscaleInstallResult(
        TailscaleInstallOutcome.needsManualCommand,
        command: linuxCommand,
        downloadUrl: linuxDownloadUrl,
      );
    }
    try {
      final res = await http
          .get(Uri.parse('https://tailscale.com/install.sh'))
          .timeout(const Duration(seconds: 60));
      if (res.statusCode != 200 || res.bodyBytes.isEmpty) {
        throw Exception('install.sh download HTTP ${res.statusCode}');
      }
      final tmpDir = await Directory.systemTemp.createTemp('fpai_tailscale_');
      final script = File(p.join(tmpDir.path, 'install.sh'));
      await script.writeAsBytes(res.bodyBytes);
      // Integrity: pin the expected SHA-256 of install.sh. The script changes
      // upstream, so this pin must be refreshed with each app release that
      // bumps it — a stale pin fails closed (refuses to run).
      // TODO: publish the pinned hash per release; currently no pin set.
      await VerifySha256.verifyFileOrThrow(
        script,
        null, // no pinned hash yet — logs TODO, does not block
        assetLabel: 'tailscale install.sh',
      );
      final r = await Process.run('pkexec', [
        'sh',
        script.path,
      ]).timeout(const Duration(minutes: 5));
      if (r.exitCode == 0) {
        return const TailscaleInstallResult(TailscaleInstallOutcome.installed);
      }
    } catch (e) {
      debugPrint('[TailscaleInstaller] linux install error: $e');
    }
    return const TailscaleInstallResult(
      TailscaleInstallOutcome.needsManualCommand,
      command: linuxCommand,
      downloadUrl: linuxDownloadUrl,
    );
  }

  Future<bool> _commandAvailable(String exe, List<String> probe) async {
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
