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

part of 'main.dart';

/// Core providers, extracted from _buildRootWidget so main.providers.dart
/// stays under the 500-line god-file bar. ORDER IS LOAD-BEARING: these
/// must stay first in the MultiProvider list, in this order, because
/// later providers read them. No behaviour change: the same providers,
/// in the same order, just returned by this function instead of written
/// inline.
List<SingleChildWidget> _coreProviders(AppDatabase db, bool needsMigration) {
  return [
        Provider<AppDatabase>.value(value: db),
        Provider<bool>.value(value: needsMigration), // migration flag
        ChangeNotifierProvider(create: (_) => StorageService()),
        // AppState owns only transient UI state (selected tab index).
        // Theme / dark mode is now driven exclusively by StorageService (single source of truth,
        // persisted, notifies after async prefs load). This eliminates the prior race + glue bugs.
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProxyProvider<StorageService, DownloadManager>(
          create: (context) => DownloadManager(
            targetDir: Provider.of<StorageService>(
              context,
              listen: false,
            ).modelsDir.path,
          ),
          // Re-point the target dir on every storage notify (notably the one
          // after async init sets rootPath) so downloads always land in the
          // configured models folder, not a relative path captured at create.
          update: (context, storage, previous) =>
              (previous ?? DownloadManager(targetDir: storage.modelsDir.path))
                ..targetDir = storage.modelsDir.path,
        ),
        ChangeNotifierProxyProvider<StorageService, KoboldService>(
          create: (context) => KoboldService(
            Provider.of<StorageService>(context, listen: false),
          ),
          update: (context, storage, previous) =>
              previous ?? KoboldService(storage),
        ),
        ChangeNotifierProvider(
          create: (context) {
            final hardware = HardwareService();
            context.read<KoboldService>()
              ..hardwareInfo = (() => hardware.hardwareInfo)
              ..hardwareWhenKnown = hardware.whenKnown
              ..readFreeMemory = () async {
                final storage = context.read<StorageService>();
                final free = await hardware.readFreeMemory(
                  gpuId: storage.backendSettings.gpuId,
                );
                hardware.freeBeforeEngine = free;
                return free;
              };
            return hardware;
          },
        ),
  ];
}
