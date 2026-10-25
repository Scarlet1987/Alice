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

// Dead Dove checklist state: per-topic limit ticks (null = unchecked =
// anything goes), the fantasy text and stop word, the user's own models,
// and the compiled red/yellow/green lists. One topic holds one level at a
// time; setting a level clears any other.

import 'package:flutter/foundation.dart';

import 'dead_dove_topics.dart';

/// A user-supplied model running with zero app-added rails.
class DeadDoveOwnModel {
  DeadDoveOwnModel({
    required this.name,
    required this.kind,
    required this.location,
  });

  final String name;
  final String kind; // Text, Image, or Voice.
  final String location;
}

/// Holds the whole Dead Dove negotiation: ticks, fantasy, stop word,
/// compiled output, and the user's own models.
class DeadDoveChecklistState extends ChangeNotifier {
  /// Topic id -> level. Absent means unchecked (anything goes).
  final Map<String, DeadDoveLevel> _ticks = {};

  String fantasy = '';
  String stopWord = '';

  final List<DeadDoveOwnModel> ownModels = [];

  /// Snapshot of the last compile; null until the user compiles.
  DeadDoveCompiled? compiled;

  /// True when ticks changed after the last compile.
  bool get isStale {
    final c = compiled;
    if (c == null) return false;
    return !mapEquals(c.ticks, _ticks);
  }

  DeadDoveLevel? levelOf(String topicId) => _ticks[topicId];

  /// Set a topic's level; null clears it (back to unchecked).
  void setLevel(String topicId, DeadDoveLevel? level) {
    if (level == null) {
      if (_ticks.remove(topicId) != null) notifyListeners();
    } else if (_ticks[topicId] != level) {
      _ticks[topicId] = level;
      notifyListeners();
    }
  }

  /// Cycle: unchecked -> allow -> hard -> soft -> caution -> unchecked.
  void cycleLevel(String topicId) {
    final current = _ticks[topicId];
    DeadDoveLevel? resolved;
    switch (current) {
      case null:
        resolved = DeadDoveLevel.allow;
      case DeadDoveLevel.allow:
        resolved = DeadDoveLevel.hard;
      case DeadDoveLevel.hard:
        resolved = DeadDoveLevel.soft;
      case DeadDoveLevel.soft:
        resolved = DeadDoveLevel.caution;
      case DeadDoveLevel.caution:
        resolved = null;
    }
    setLevel(topicId, resolved);
  }

  int countOf(List<DeadDoveTopic> topics, DeadDoveLevel level) =>
      topics.where((t) => _ticks[t.id] == level).length;

  int uncheckedCount(List<DeadDoveTopic> topics) =>
      topics.where((t) => !_ticks.containsKey(t.id)).length;

  void setAll(List<DeadDoveTopic> topics, DeadDoveLevel? level) {
    var changed = false;
    for (final t in topics) {
      if (level == null) {
        if (_ticks.remove(t.id) != null) changed = true;
      } else if (_ticks[t.id] != level) {
        _ticks[t.id] = level;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  void setFantasy(String value) {
    if (fantasy != value) {
      fantasy = value;
      notifyListeners();
    }
  }

  void setStopWord(String value) {
    if (stopWord != value) {
      stopWord = value;
      notifyListeners();
    }
  }

  void addOwnModel(DeadDoveOwnModel model) {
    ownModels.add(model);
    notifyListeners();
  }

  void removeOwnModel(DeadDoveOwnModel model) {
    if (ownModels.remove(model)) notifyListeners();
  }

  /// Compile the ticks into the red/yellow/green lists the model follows.
  void compile() {
    compiled = DeadDoveCompiled(
      ticks: Map.of(_ticks),
      fantasy: fantasy,
      stopWord: stopWord,
    );
    notifyListeners();
  }

  List<DeadDoveTopic> topicsAt(
    List<DeadDoveTopic> topics,
    DeadDoveLevel level,
  ) =>
      topics.where((t) => _ticks[t.id] == level).toList();
}

/// Immutable snapshot of a compile.
class DeadDoveCompiled {
  DeadDoveCompiled({
    required this.ticks,
    required this.fantasy,
    required this.stopWord,
  });

  final Map<String, DeadDoveLevel> ticks;
  final String fantasy;
  final String stopWord;
}
