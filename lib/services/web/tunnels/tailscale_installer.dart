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
import 'package:url_launcher/url_launcher.dart';

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
///   • Windows — winget (downloads + UAC-elevates), else the download page.
///   • Linux   — the official package via the native package manager
///               (apt/dnf/yum/pacman/zypper under pkexec), else the official
///               command + download page. install.sh is never downloaded or
///               run as root: Tailscale publishes no hash for it.
/// The two unavoidable human gates (admin approval, browser sign-in) are OS
/// security boundaries we deliberately keep, not automate around.
class TailscaleInstaller {
  static const String wingetId = 'Tailscale.Tailscale';
  static const String linuxCommand =
      'curl -fsSL https://tailscale.com/install.sh | sh';
  static const String windowsDownloadUrl =
      'https://tailscale.com/download/windows';
  static const String linuxDownloadUrl = 'https://tailscale.com/download/linux';

  /// True on the desktop platforms we can drive an install on.
  static bool get isSupported => Platform.isWindows || Platform.isLinux;

  Future<TailscaleInstallResult> install() async {
    try {
      if (Platform.isWindows) return await _installWindows();
      if (Platform.isLinux) return await _installLinux();
    } catch (e) {
      debugPrint('[TailscaleInstaller] install error: $e');
      return const TailscaleInstallResult(TailscaleInstallOutcome.failed);
    }
    return const TailscaleInstallResult(TailscaleInstallOutcome.unsupported);
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
