// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Part of alice_v9_state.dart: the widget-facing setters. Kept in a part
// file (not an extension) so the methods are AliceV9State methods and
// can call notifyListeners(), and so neither file reaches 500 lines.

part of 'alice_v9_state.dart';

  // ── Widget-facing setters ─────────────────────────────────────────
  // Widgets mutate state only through these methods. They update the
  // field (and autosave, where the field is persisted) and notify, so
  // no widget ever calls notifyListeners() itself — the analyzer
  // forbids that from outside the ChangeNotifier.

  /// Creator identity pick/custom: set the pick or typed value on the
  /// given identity, autosave the draft, and notify.
  void setCreatorIdentityPick(V9Identity identity, String pick) {
    identity.pick = pick;
    saveCreatorDraft();
    notifyListeners();
  }

  void setCreatorIdentityCustom(V9Identity identity, String text) {
    identity.custom = text;
    saveCreatorDraft();
    notifyListeners();
  }

  /// User-profile identity pick/custom: same shape, but the save goes
  /// to the profile record, not the creator draft.
  void setUserIdentityPick(V9Identity identity, String pick) {
    identity.pick = pick;
    saveUserProfile();
    notifyListeners();
  }

  void setUserIdentityCustom(V9Identity identity, String text) {
    identity.custom = text;
    saveUserProfile();
    notifyListeners();
  }

  void setUnitIsCm(bool value) {
    unitIsCm = value;
    notifyListeners();
  }

  void setTorsoLength(String value) {
    measurements.torsoLength = value;
    notifyListeners();
  }

  void setNpcRole(String role) {
    npcRole = role;
    notifyListeners();
  }

  void setEthicalAxis(String value) {
    ethicalAxis = value;
    notifyListeners();
  }

  void setMoralAxis(String value) {
    moralAxis = value;
    notifyListeners();
  }

  void setClassChoice(String choice) {
    classChoice = choice;
    notifyListeners();
  }

  void setImageOn(bool value) {
    imageOn = value;
    notifyListeners();
  }

  void setTextOn(bool value) {
    textOn = value;
    notifyListeners();
  }

  void setVoiceOn(bool value) {
    voiceOn = value;
    notifyListeners();
  }

  void setNarrationPerson(String value) {
    narrationPerson = value;
    notifyListeners();
  }

  void setPerspective(String value) {
    perspective = value;
    notifyListeners();
  }

  void setForeshortening(String value) {
    foreshortening = value;
    notifyListeners();
  }

  /// A picked model file: record it, and note it (note notifies).
  void pickModelAsset(String name, String kind) {
    assetName = name;
    assetCheckResult = 'Chosen: $name. Run a check to see it here.';
    note('Picked $name as the $kind model.');
  }

  void runAssetCheck() {
    if (assetName == null) {
      assetCheckResult = 'Pick or drop a file first, then run the check.';
    } else {
      assetCheckResult =
          'Preview check only: the chosen asset would be checked here in '
          'the real app. Alice won\'t pretend it played.';
    }
    notifyListeners();
  }

  void setUserBirthday(DateTime picked) {
    userBirthday.text =
        '${picked.year.toString().padLeft(4, '0')}-'
        '${picked.month.toString().padLeft(2, '0')}-'
        '${picked.day.toString().padLeft(2, '0')}';
    notifyListeners();
  }

  /// The bio word count is derived from the controller text; the page
  /// rebuilds through this state, so a keystroke needs a nudge.
  void bioChanged() {
    notifyListeners();
  }

