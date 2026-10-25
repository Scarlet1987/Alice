// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// The 2 GB harness memory budget: the profile's cap, the fit check, the
// plain-language shortfall, the persisted setting, and the live estimate.

import 'package:flutter_test/flutter_test.dart';
import 'package:front_porch_ai/services/hardware_audit.dart';
import 'package:front_porch_ai/services/memory_budget.dart';
import 'package:front_porch_ai/services/storage/settings/engine_resources_settings.dart';

HardwareProfile _profile() => const HardwareProfile(
  gpuVendor: 'AMD',
  gpuName: 'Radeon RX 580',
  vramMb: 8192,
  systemRamMb: 32768,
  cpuCores: 8,
  hasCuda: false,
  hasRocm: false,
  capabilityTier: CapabilityTier.standard,
  recommendedEngineModes: ['vulkan', 'cpu'],
);

void main() {
  test('the harness budget is 2 GB', () {
    expect(_profile().memoryBudgetMb, 2048);
    expect(kDefaultMemoryBudgetMb, 2048);
  });

  test('fitsInBudget holds RAM plus VRAM against the cap', () {
    final profile = _profile();
    expect(profile.fitsInBudget(ramMb: 1024, vramMb: 1024), isTrue);
    expect(profile.fitsInBudget(ramMb: 2048, vramMb: 0), isTrue);
    expect(profile.fitsInBudget(ramMb: 2048, vramMb: 1), isFalse);
    expect(profile.fitsInBudget(ramMb: 0, vramMb: 0), isTrue);
  });

  test('budgetShortfallMessage is null when it fits, plain when not', () {
    final profile = _profile();
    expect(profile.budgetShortfallMessage(ramMb: 100, vramMb: 100), isNull);
    final message = profile.budgetShortfallMessage(ramMb: 2048, vramMb: 2048)!;
    expect(message, contains('4.0 GB'));
    expect(message, contains('2.0 GB'));
    expect(message, contains('Settings'));
    for (final jargon in ['heap', 'malloc', 'pages', 'resident set']) {
      expect(message.toLowerCase(), isNot(contains(jargon)));
    }
  });

  test('totalMemoryBudgetMb defaults to 2 GB and clamps', () async {
    final settings = EngineResourcesSettings();
    settings.load();
    expect(settings.totalMemoryBudgetMb, 2048);
    await settings.setTotalMemoryBudgetMb(100);
    expect(settings.totalMemoryBudgetMb, 512);
    await settings.setTotalMemoryBudgetMb(1 << 20);
    expect(settings.totalMemoryBudgetMb, 131072);
    await settings.setTotalMemoryBudgetMb(4096);
    expect(settings.totalMemoryBudgetMb, 4096);
  });

  test('imageModelHeadroomMb defaults to 2 GB and clamps', () async {
    final settings = EngineResourcesSettings();
    settings.load();
    expect(settings.imageModelHeadroomMb, 2048);
    await settings.setImageModelHeadroomMb(-10);
    expect(settings.imageModelHeadroomMb, 0);
    await settings.setImageModelHeadroomMb(4096);
    expect(settings.imageModelHeadroomMb, 4096);
  });

  test('estimateNow counts the app plus reported engines', () {
    MemoryBudget.debugClearAll();
    addTearDown(MemoryBudget.debugClearAll);
    final before = MemoryBudget.estimateNow();
    expect(before.appRamMb, greaterThan(0));
    expect(before.engines, isEmpty);

    MemoryBudget.reportEngine(
      MemoryBudget.textEngine,
      // Absurdly large on purpose: the test runner's own RSS must never
      // beat it, so the assertion below is deterministic.
      const EngineFootprint(ramMb: 65536),
    );
    final after = MemoryBudget.estimateNow();
    expect(after.totalMb, before.totalMb + 65536);
    expect(after.largestConsumer, MemoryBudget.textEngine);

    MemoryBudget.clearEngine(MemoryBudget.textEngine);
    expect(MemoryBudget.estimateNow().totalMb, before.totalMb);
  });

  test('shortfallMessage names the biggest consumer in plain words', () {
    MemoryBudget.debugClearAll();
    addTearDown(MemoryBudget.debugClearAll);
    MemoryBudget.reportEngine(
      MemoryBudget.textEngine,
      // Absurdly large on purpose: the test runner's own RSS must never
      // beat it, so the largest-consumer assertion below is deterministic.
      const EngineFootprint(ramMb: 65536),
    );
    final estimate = MemoryBudget.estimateNow();
    expect(estimate.fitsInBudget(2048), isFalse);
    final message = estimate.shortfallMessage(2048)!;
    expect(message, contains('the text engine'));
    expect(message, contains('2.0 GB'));
    expect(estimate.shortfallMessage(1 << 20), isNull);
  });
}
