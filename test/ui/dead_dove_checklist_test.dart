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

// Guards for the Dead Dove checklist state and gear scale check:
// tick cycling is one-level-at-a-time, counts are right, compile
// snapshots, and the gear check flags god-mode and over-scale items.

import 'package:flutter_test/flutter_test.dart';

import 'package:front_porch_ai/ui/creator/sections/gear_section.dart';
import 'package:front_porch_ai/ui/creator/sections/kardashev_section.dart';
import 'package:front_porch_ai/ui/settings/widgets/dead_dove/dead_dove_checklist_state.dart';
import 'package:front_porch_ai/ui/settings/widgets/dead_dove/dead_dove_topics.dart';

void main() {
  group('DeadDoveChecklistState', () {
    test('starts with nothing ticked', () {
      final state = DeadDoveChecklistState();
      expect(state.levelOf('dd-001'), isNull);
      expect(state.uncheckedCount(kDeadDoveTop100), 100);
      expect(state.compiled, isNull);
      state.dispose();
    });

    test('cycle goes allow -> hard -> soft -> caution -> unchecked', () {
      final state = DeadDoveChecklistState();
      const id = 'dd-001';
      state.cycleLevel(id);
      expect(state.levelOf(id), DeadDoveLevel.allow);
      state.cycleLevel(id);
      expect(state.levelOf(id), DeadDoveLevel.hard);
      state.cycleLevel(id);
      expect(state.levelOf(id), DeadDoveLevel.soft);
      state.cycleLevel(id);
      expect(state.levelOf(id), DeadDoveLevel.caution);
      state.cycleLevel(id);
      expect(state.levelOf(id), isNull);
      state.dispose();
    });

    test('one topic holds one level at a time', () {
      final state = DeadDoveChecklistState();
      const id = 'dd-001';
      state.setLevel(id, DeadDoveLevel.allow);
      state.setLevel(id, DeadDoveLevel.hard);
      expect(state.levelOf(id), DeadDoveLevel.hard);
      expect(state.countOf(kDeadDoveTop100, DeadDoveLevel.allow), 0);
      expect(state.countOf(kDeadDoveTop100, DeadDoveLevel.hard), 1);
      state.dispose();
    });

    test('counts track ticks across the list', () {
      final state = DeadDoveChecklistState();
      state.setLevel('dd-001', DeadDoveLevel.allow);
      state.setLevel('dd-002', DeadDoveLevel.hard);
      state.setLevel('dd-003', DeadDoveLevel.soft);
      state.setLevel('dd-004', DeadDoveLevel.caution);
      expect(state.countOf(kDeadDoveTop100, DeadDoveLevel.allow), 1);
      expect(state.countOf(kDeadDoveTop100, DeadDoveLevel.hard), 1);
      expect(state.countOf(kDeadDoveTop100, DeadDoveLevel.soft), 1);
      expect(state.countOf(kDeadDoveTop100, DeadDoveLevel.caution), 1);
      expect(state.uncheckedCount(kDeadDoveTop100), 96);
      state.dispose();
    });

    test('compile snapshots and stale detects later ticks', () {
      final state = DeadDoveChecklistState();
      state.setLevel('dd-001', DeadDoveLevel.hard);
      state.compile();
      expect(state.compiled, isNotNull);
      expect(state.isStale, isFalse);
      expect(
        state.compiled!.ticks['dd-001'],
        DeadDoveLevel.hard,
      );
      state.setLevel('dd-002', DeadDoveLevel.allow);
      expect(state.isStale, isTrue);
      state.dispose();
    });

    test('bulk set and clear work', () {
      final state = DeadDoveChecklistState();
      state.setAll(kDeadDoveStoryTopics, DeadDoveLevel.allow);
      expect(
        state.countOf(kDeadDoveStoryTopics, DeadDoveLevel.allow),
        48,
      );
      expect(state.uncheckedCount(kDeadDoveStoryTopics), 0);
      state.setAll(kDeadDoveStoryTopics, null);
      expect(state.uncheckedCount(kDeadDoveStoryTopics), 48);
      state.dispose();
    });

    test('own models add and remove', () {
      final state = DeadDoveChecklistState();
      final model = DeadDoveOwnModel(
        name: 'My model',
        kind: 'Text',
        location: '/models/foo.gguf',
      );
      state.addOwnModel(model);
      expect(state.ownModels, hasLength(1));
      state.removeOwnModel(model);
      expect(state.ownModels, isEmpty);
      state.dispose();
    });
  });

  group('checkGear', () {
    test('empty text fits', () {
      expect(
        checkGear('', KardashevType.type1),
        GearVerdict.fits,
      );
    });

    test('ordinary gear fits at any type', () {
      expect(
        checkGear('a steel sword and a leather jerkin', KardashevType.type0),
        GearVerdict.fits,
      );
    });

    test('extinction-level language is god mode', () {
      expect(
        checkGear(
          'a planet destroyer cannon',
          KardashevType.type3,
        ),
        GearVerdict.godMode,
      );
    });

    test('dyson tech is over scale below Type II', () {
      expect(
        checkGear('a dyson swarm harvester', KardashevType.type1),
        GearVerdict.overScale,
      );
      expect(
        checkGear('a dyson swarm harvester', KardashevType.type2),
        GearVerdict.fits,
      );
    });

    test('galactic tech is over scale below Type III', () {
      expect(
        checkGear('a black hole lance', KardashevType.type2),
        GearVerdict.overScale,
      );
      expect(
        checkGear('a black hole lance', KardashevType.type3),
        GearVerdict.fits,
      );
    });
  });

  group('Dead Dove topic data', () {
    test('Top 100 has exactly 100 topics', () {
      expect(kDeadDoveTop100, hasLength(100));
    });

    test('story list has exactly 48 topics', () {
      expect(kDeadDoveStoryTopics, hasLength(48));
    });

    test('topic ids are unique', () {
      final ids = <String>{};
      for (final t in [...kDeadDoveTop100, ...kDeadDoveStoryTopics]) {
        expect(ids.add(t.id), isTrue, reason: 'duplicate id ${t.id}');
      }
    });
  });
}
