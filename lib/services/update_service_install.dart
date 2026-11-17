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

part of 'update_service.dart';

/// Platform install / replace / relaunch after a completed download.
extension UpdateServiceInstall on UpdateService {
  /// Run the update immediately and exit (or relaunch on Linux).
  Future<void> _installNowImpl() async {
    if (_pendingInstallerPath == null) return;
    try {
      // Stop child processes (KoboldCPP, etc.) before exit(0) which
      // bypasses the window close handler entirely.
      if (_shutdownCallback != null) {
        await _shutdownCallback!();
      }
      if (Platform.isLinux) {
        await _replaceAppImage(_pendingInstallerPath!);
        await _relaunchAppImage();
      } else {
        await _launchWindowsInstaller(_pendingInstallerPath!);
      }
      exit(0);
    } catch (e) {
      debugPrint('Install now failed: $e');
      rethrow;
    }
  }

  /// Run the pending update on app close.
  /// Call this from the window close handler.
  Future<void> _installOnCloseImpl() async {
    if (_pendingInstallerPath == null) return;
    try {
      // Ensure child processes are stopped even if onWindowClose didn't
      // reach stopKobold() (e.g. crash or early return).
      if (_shutdownCallback != null) {
        await _shutdownCallback!();
      }
      if (Platform.isLinux) {
        await _replaceAppImage(_pendingInstallerPath!);
      } else {
        await _launchWindowsInstaller(_pendingInstallerPath!);
      }
    } catch (e) {
      debugPrint('Install on close failed: $e');
    }
  }

  Future<void> _launchWindowsInstaller(String path) async {
    // Use /SILENT (shows license page) for 0.8→0.9 upgrades (GPL→AGPL change)
    // Use /VERYSILENT (fully silent) for same-license upgrades
    final needsLicenseAcceptance = _currentVersion.startsWith('0.8');
    final silentFlag = needsLicenseAcceptance ? '/SILENT' : '/VERYSILENT';

    // Install in place, on top of the build that is actually running, by telling
    // the installer the current install directory via /DIR. This is the reliable
    // way to find AND honor a custom install location: resolvedExecutable is
    // "<installDir>\front_porch_ai.exe", so its parent is exactly the folder the
    // user originally chose — default OR a custom drive/path — and the running app
    // is the only component that authoritatively knows it. The installer can't
    // safely rediscover a custom Nightly folder from the registry (the pre-split
    // AppId was shared with Stable/Beta, so guessing risks installing over a
    // Stable install), so we source the truth here instead.
    //
    // Without /DIR, a /VERYSILENT update falls back to the installer's default
    // directory. After the channel AppId split that is how a Nightly update forked
    // a second copy into {localappdata} and left the running build (in the user's
    // chosen folder) untouched — the update loop. /DIR makes every channel update
    // exactly where it already lives, ending that whole class of bug.
    var installDir = File(Platform.resolvedExecutable).parent.path;
    // Defensive: a trailing backslash would escape the closing quote in the
    // generated command line. Install dirs never end in a separator in practice,
    // but strip it so the quoted /DIR value can never be malformed.
    while (installDir.endsWith('\\')) {
      installDir = installDir.substring(0, installDir.length - 1);
    }

    await Process.start(path, [
      silentFlag,
      '/DIR=$installDir',
      '/SUPPRESSMSGBOXES',
      '/NORESTART',
      '/CLOSEAPPLICATIONS',
    ]);
  }

  /// Replace the currently running AppImage with the downloaded update.
  /// Uses rm + cp instead of Dart's File.copy() because the destination
  /// may be a running executable — deleting first avoids write conflicts.
  Future<void> _replaceAppImage(String downloadedPath) async {
    final currentAppImage = Platform.environment['APPIMAGE'];
    if (currentAppImage == null || currentAppImage.isEmpty) {
      debugPrint('APPIMAGE env var not set — cannot replace');
      return;
    }
    debugPrint('Replacing AppImage: $currentAppImage with $downloadedPath');

    // Copy beside the target FIRST, then atomically rename over it. The old
    // order (rm the running AppImage, then cp) left the user with NO app at
    // all when the copy failed — a full disk or a bad download uninstalled
    // Front Porch. rename(2) on the same filesystem atomically replaces the
    // path while the running process keeps its unlinked inode.
    final staging = '$currentAppImage.new';
    final cpResult = await Process.run('cp', [downloadedPath, staging]);
    if (cpResult.exitCode != 0) {
      await Process.run('rm', ['-f', staging]);
      throw Exception('Failed to copy new AppImage: ${cpResult.stderr}');
    }
    await Process.run('chmod', ['+x', staging]);
    final mvResult = await Process.run('mv', ['-f', staging, currentAppImage]);
    if (mvResult.exitCode != 0) {
      await Process.run('rm', ['-f', staging]);
      throw Exception('Failed to swap new AppImage in: ${mvResult.stderr}');
    }
    debugPrint('AppImage replaced successfully');
  }

  /// Relaunch the AppImage after replacing it.
  Future<void> _relaunchAppImage() async {
    final currentAppImage = Platform.environment['APPIMAGE'];
    if (currentAppImage == null || currentAppImage.isEmpty) return;
    debugPrint('Relaunching AppImage: $currentAppImage');
    await Process.start(currentAppImage, [], mode: ProcessStartMode.detached);
  }
}
