// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice v9 state (combined preview v9): the one owner of everything the
// v9 pages show and edit — page, Home loadout picks, Model selection,
// Creator (MC + NPC, tailor's measurements, sarcasm percent), and the
// User profile. Character cards come from [CharacterRepository] and
// stages from [WorldRepository]; this file never keeps a second copy of
// either list. Identity picks (including typed custom values) are saved
// to SharedPreferences as they change and written into the character
// card / user profile on Save, so a custom value is never lost.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:front_porch_ai/models/models.dart';
import 'package:front_porch_ai/ui/alice/v9/alice_v9_identity.dart';

part 'alice_v9_state_setters.dart';

/// v9 pages, in the preview's nav order.
enum V9Page { home, models, creator, profile }

/// Tailor's measurements, in the preview's file order, stored in cm.
/// Leg length is calculated from height and torso — no inseam field.
class V9Measurements {
  double waist;
  double shoulders;
  double height;
  double underbust;
  double bust;
  double thigh;
  double hips;
  String torsoLength; // short / average / long

  V9Measurements({
    this.waist = 70,
    this.shoulders = 42,
    this.height = 170,
    this.underbust = 75,
    this.bust = 90,
    this.thigh = 55,
    this.hips = 95,
    this.torsoLength = 'average',
  });

  double value(String id) {
    switch (id) {
      case 'waist':
        return waist;
      case 'shoulders':
        return shoulders;
      case 'height':
        return height;
      case 'underbust':
        return underbust;
      case 'bust':
        return bust;
      case 'thigh':
        return thigh;
      case 'hips':
        return hips;
      default:
        return 0;
    }
  }

  void set(String id, double cm) {
    switch (id) {
      case 'waist':
        waist = cm;
      case 'shoulders':
        shoulders = cm;
      case 'height':
        height = cm;
      case 'underbust':
        underbust = cm;
      case 'bust':
        bust = cm;
      case 'thigh':
        thigh = cm;
      case 'hips':
        hips = cm;
    }
  }

  String get line =>
      'Measurements (cm): waist ${waist.round()}, shoulders '
      '${shoulders.round()}, height ${height.round()}, underbust '
      '${underbust.round()}, bust ${bust.round()}, torso $torsoLength, '
      'thigh ${thigh.round()}, hips ${hips.round()}.';
}

class AliceV9State extends ChangeNotifier {
  AliceV9State() {
    // The live character preview reads these controllers; a keystroke
    // must rebuild it, so the controllers nudge the state themselves.
    for (final controller in [mcName, npcName]) {
      controller.addListener(notifyListeners);
    }
  }

  V9Page page = V9Page.home;
  String jumpNote = '';

  void setPage(V9Page next) {
    page = next;
    notifyListeners();
  }

  void note(String text) {
    jumpNote = text;
    notifyListeners();
  }

  // ── Home: selection + loadout ─────────────────────────────────────
  String? selectedStageName;
  String? selectedCharacterId;

  /// One pick per loadout slot id (see [kV9LoadoutSlots]); null = empty.
  final Map<String, String?> loadout = {};

  void selectStage(String? name) {
    selectedStageName = name;
    notifyListeners();
  }

  void selectCharacter(String? id) {
    if (selectedCharacterId != id) loadout.clear();
    selectedCharacterId = id;
    notifyListeners();
  }

  void setLoadout(String slotId, String? item) {
    loadout[slotId] = item;
    notifyListeners();
  }

  // ── Model selection ───────────────────────────────────────────────
  bool imageOn = true;
  bool textOn = true;
  bool voiceOn = true;
  String narrationPerson = 'first';
  String perspective = 'one point';
  String foreshortening = 'the golden rule';
  String codec = 'vlc';
  String? assetName;
  String assetCheckResult = 'Run a check to see the result here.';

  String get codecNote {
    switch (codec) {
      case 'built':
        return 'Alice Built in: for common files, no extra player needed.';
      case 'own':
        return 'Bring your own: you supply the player or codec.';
      default:
        return 'VLC codec, recommended. VLC runs headless behind the '
            'scenes, with Alice controls on top.';
    }
  }

  void setCodec(String next) {
    codec = next;
    notifyListeners();
  }

  // ── Creator: text fields ──────────────────────────────────────────
  final mcName = TextEditingController();
  final mcScenario = TextEditingController();
  final mcPersonality = TextEditingController();
  final mcTone = TextEditingController();
  final mcMission = TextEditingController();
  final mcGreeting = TextEditingController();
  final mcDialogue = TextEditingController();
  final npcName = TextEditingController();
  final npcConcept = TextEditingController();
  final npcRelationship = TextEditingController();
  String npcRole = 'Merchant';

  V9Identity mcGender = V9Identity(pick: 'male');
  V9Identity mcPronouns = V9Identity(pick: 'he/him');
  V9Identity npcGender = V9Identity(pick: 'male');
  V9Identity npcPronouns = V9Identity(pick: 'he/him');

  final measurements = V9Measurements();
  bool unitIsCm = true;

  String ethicalAxis = 'neutral'; // lawful / neutral / chaotic
  String moralAxis = 'good'; // good / neutral / evil
  String classChoice = 'royalty';

  /// Sarcasm level, percent (preview v9): a dropdown 0% to 100% in 10%
  /// steps, default 0%. Never a text input, never a 0-10 slider.
  int sarcasmPercent = 0;

  void setSarcasmPercent(int percent) {
    sarcasmPercent = (percent.clamp(0, 100) ~/ 10) * 10;
    notifyListeners();
  }

  void setMeasurement(String id, double cm) {
    measurements.set(id, cm);
    notifyListeners();
  }

  String formatMeasure(double cm, {bool isHeight = false}) {
    if (unitIsCm) return '${cm.round()} cm';
    if (isHeight) {
      final total = (cm / 2.54).round();
      return '${total ~/ 12} ft ${total % 12} inches';
    }
    return '${(cm / 2.54).toStringAsFixed(1)} in';
  }

  String get legLengthNote {
    final height = formatMeasure(measurements.height, isHeight: true);
    return 'Height $height, torso ${measurements.torsoLength}. Leg '
        'length is calculated from height and torso — no inseam field.';
  }

  /// Live character preview, as in the preview: updates as you type
  /// and pick, including a typed custom pronoun.
  String get characterPreview {
    final name = mcName.text.trim().isEmpty
        ? '(unnamed)'
        : mcName.text.trim();
    final height = formatMeasure(measurements.height, isHeight: true);
    return '$name — $classChoice, ${mcPronouns.resolved}, $height, '
        'sarcasm $sarcasmPercent%.';
  }

  // ── Creator: persistence (draft) + cards ──────────────────────────
  static const _kCreatorPrefix = 'alice_v9_creator_';
  bool creatorSaved = false;

  Future<void> loadCreatorDraft() async {
    final prefs = await SharedPreferences.getInstance();
    mcName.text = prefs.getString('${_kCreatorPrefix}mc_name') ?? '';
    mcGender = _identity(prefs, 'mc_gender', 'male');
    mcPronouns = _identity(prefs, 'mc_pronouns', 'he/him');
    npcName.text = prefs.getString('${_kCreatorPrefix}npc_name') ?? '';
    npcGender = _identity(prefs, 'npc_gender', 'male');
    npcPronouns = _identity(prefs, 'npc_pronouns', 'he/him');
    sarcasmPercent = prefs.getInt('${_kCreatorPrefix}sarcasm_percent') ?? 0;
    notifyListeners();
  }

  V9Identity _identity(
    SharedPreferences prefs,
    String key,
    String defaultPick,
  ) {
    final raw = prefs.getString('$_kCreatorPrefix$key');
    if (raw == null) return V9Identity(pick: defaultPick);
    final map = jsonDecode(raw);
    return V9Identity.fromJson(map is Map<String, dynamic> ? map : null);
  }

  /// Autosave the creator draft (identity picks + typed custom values
  /// included) so a typed custom value is never silently lost if the
  /// app closes before Save Character. The card record itself is only
  /// written by [buildMcCard]/[buildNpcCard] + Save.
  Future<void> saveCreatorDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_kCreatorPrefix}mc_name', mcName.text.trim());
    await prefs.setString(
      '${_kCreatorPrefix}mc_gender',
      jsonEncode(mcGender.toJson()),
    );
    await prefs.setString(
      '${_kCreatorPrefix}mc_pronouns',
      jsonEncode(mcPronouns.toJson()),
    );
    await prefs.setString('${_kCreatorPrefix}npc_name', npcName.text.trim());
    await prefs.setString(
      '${_kCreatorPrefix}npc_gender',
      jsonEncode(npcGender.toJson()),
    );
    await prefs.setString(
      '${_kCreatorPrefix}npc_pronouns',
      jsonEncode(npcPronouns.toJson()),
    );
    await prefs.setInt('${_kCreatorPrefix}sarcasm_percent', sarcasmPercent);
    creatorSaved = true;
    notifyListeners();
  }

  CharacterCard buildMcCard() {
    final appearance = [
      measurements.line,
      if (mcPersonality.text.trim().isNotEmpty) mcPersonality.text.trim(),
    ].join('\n');
    final personalityBits = [
      mcPersonality.text.trim(),
      if (mcTone.text.trim().isNotEmpty) 'Tone: ${mcTone.text.trim()}',
      'Sarcasm: $sarcasmPercent%. Ethical: $ethicalAxis. '
          'Moral: $moralAxis. Class: $classChoice.',
      if (mcMission.text.trim().isNotEmpty)
        'Core mission: ${mcMission.text.trim()}',
    ].where((s) => s.isNotEmpty).join('\n');
    return CharacterCard(
      name: mcName.text.trim(),
      description: appearance,
      personality: personalityBits,
      scenario: mcScenario.text.trim(),
      firstMessage: mcGreeting.text.trim(),
      mesExample: mcDialogue.text.trim(),
      systemPrompt:
          'Gender: ${mcGender.resolved} (${mcPronouns.resolved}).\n'
          '${measurements.line}',
      tags: const ['main-character'],
    );
  }

  CharacterCard buildNpcCard() {
    return CharacterCard(
      name: npcName.text.trim(),
      description:
          'Gender: ${npcGender.resolved} (${npcPronouns.resolved}).\n'
          'Role: $npcRole.\n${npcConcept.text.trim()}',
      personality: npcRelationship.text.trim().isEmpty
          ? ''
          : 'Relationship to MC: ${npcRelationship.text.trim()}',
      scenario: npcConcept.text.trim(),
      systemPrompt:
          'Gender: ${npcGender.resolved} (${npcPronouns.resolved}).',
      tags: const ['npc'],
    );
  }

  // ── User profile ──────────────────────────────────────────────────
  final userRealName = TextEditingController();
  final userBirthday = TextEditingController();
  final userBio = TextEditingController();
  V9Identity userGender = V9Identity(pick: 'male');
  V9Identity userPronouns = V9Identity(pick: 'he/him');
  bool profileSaved = false;

  int get bioWordCount {
    final text = userBio.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).length;
  }

  /// Profile storage keys are the same ones the old You pane uses for
  /// real name / birthday / bio / pronouns (one store, not two); the
  /// gender pick + custom values get new keys because the old pane
  /// never had a gender field.
  static const _kRealName = 'alice_user_real_name';
  static const _kBirthday = 'alice_user_birthday';
  static const _kPronouns = 'alice_user_pronouns';
  static const _kBio = 'alice_user_bio';
  static const _kGender = 'alice_v9_user_gender';
  static const _kGenderCustom = 'alice_v9_user_gender_custom';
  static const _kPronounsPick = 'alice_v9_user_pronouns_pick';
  static const _kPronounsCustom = 'alice_v9_user_pronouns_custom';

  Future<void> loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    userRealName.text = prefs.getString(_kRealName) ?? '';
    userBirthday.text = prefs.getString(_kBirthday) ?? '';
    userBio.text = prefs.getString(_kBio) ?? '';
    userGender = V9Identity(
      pick: prefs.getString(_kGender) ?? 'male',
      custom: prefs.getString(_kGenderCustom) ?? '',
    );
    final pick = prefs.getString(_kPronounsPick);
    if (pick == null) {
      // Old save: only a resolved pronoun text exists. Keep it as the
      // custom value so nothing is lost.
      final old = prefs.getString(_kPronouns) ?? '';
      userPronouns = V9Identity(
        pick: old.isEmpty ? 'he/him' : 'custom',
        custom: old,
      );
    } else {
      userPronouns = V9Identity(
        pick: pick,
        custom: prefs.getString(_kPronounsCustom) ?? '',
      );
    }
    notifyListeners();
  }

  /// Returns an error string when the bio is too long, null on success.
  Future<String?> saveUserProfile() async {
    if (bioWordCount > 300) {
      return 'That bio is $bioWordCount words — trim it to 300.';
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kRealName, userRealName.text.trim());
    await prefs.setString(_kBirthday, userBirthday.text.trim());
    await prefs.setString(_kPronouns, userPronouns.resolved);
    await prefs.setString(_kBio, userBio.text.trim());
    await prefs.setString(_kGender, userGender.pick);
    await prefs.setString(_kGenderCustom, userGender.custom.trim());
    await prefs.setString(_kPronounsPick, userPronouns.pick);
    await prefs.setString(_kPronounsCustom, userPronouns.custom.trim());
    profileSaved = true;
    notifyListeners();
    return null;
  }

  @override
  void dispose() {
    for (final controller in [
      mcName,
      mcScenario,
      mcPersonality,
      mcTone,
      mcMission,
      mcGreeting,
      mcDialogue,
      npcName,
      npcConcept,
      npcRelationship,
      userRealName,
      userBirthday,
      userBio,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }
}
