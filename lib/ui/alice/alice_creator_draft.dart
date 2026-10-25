// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice Character Creator: the shared draft behind the Main Character /
// NPC / You tabs. Owns every controller and scalar field so collapsing a
// section never loses what was typed, and builds the Tavern V2 card when
// the user saves.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:front_porch_ai/models/models.dart';
import 'package:front_porch_ai/providers/app_state.dart';
import 'package:front_porch_ai/services/character_repository.dart';
import 'package:front_porch_ai/ui/creator/sections/kardashev_section.dart';

/// Which creator tab is showing.
enum CreatorTab { mc, npc, user }

/// Gender identity options on the MC board.
enum GenderIdentity { male, female, nonbinary, custom }

extension GenderIdentityLabel on GenderIdentity {
  String get label {
    switch (this) {
      case GenderIdentity.male:
        return 'Male';
      case GenderIdentity.female:
        return 'Female';
      case GenderIdentity.nonbinary:
        return 'Non-binary';
      case GenderIdentity.custom:
        return 'Custom';
    }
  }
}

/// Pronoun options on the MC board.
enum PronounSet { he, she, they, custom }

extension PronounSetLabel on PronounSet {
  String get label {
    switch (this) {
      case PronounSet.he:
        return 'He/him';
      case PronounSet.she:
        return 'She/her';
      case PronounSet.they:
        return 'They/them';
      case PronounSet.custom:
        return 'Custom';
    }
  }
}

/// Genital selection on the appearance section.
enum GenitalOption { male, female }

extension GenitalOptionLabel on GenitalOption {
  String get label => this == GenitalOption.male ? 'Male' : 'Female';
}

/// NPC roles offered in the dropdown.
const List<String> kNpcRoles = [
  'Ally',
  'Villain',
  'Merchant',
  'Mentor',
  'Rival',
  'Comic relief',
  'Love interest',
  'Wildcard',
];

/// The shared draft for the whole creator screen.
class AliceCreatorDraft extends ChangeNotifier {
  CreatorTab tab = CreatorTab.mc;

  /// "Show every field anyway" — reveals the Balanced+ gated fields.
  /// Detail level is a default, never a cage.
  bool showAllFields = false;

  void setTab(CreatorTab t) {
    tab = t;
    notifyListeners();
  }

  void toggleShowAllFields() {
    showAllFields = !showAllFields;
    notifyListeners();
  }

  // ── Main Character: core ──────────────────────────────────────────
  final mcName = TextEditingController();
  final mcRole = TextEditingController();
  final mcScenario = TextEditingController();

  GenderIdentity gender = GenderIdentity.female;
  final genderCustom = TextEditingController();
  PronounSet pronouns = PronounSet.she;
  final pronounCustom = TextEditingController();

  void setGender(GenderIdentity g) {
    gender = g;
    notifyListeners();
  }

  void setPronouns(PronounSet p) {
    pronouns = p;
    notifyListeners();
  }

  // ── Main Character: Kardashev ─────────────────────────────────────
  KardashevType kardashev = KardashevType.type1;
  bool kardashevLocked = false;
  final beyondName = TextEditingController();
  final beyondScope = TextEditingController();
  final beyondGear = TextEditingController();

  void setKardashev(KardashevType t) {
    if (kardashevLocked) return;
    kardashev = t;
    notifyListeners();
  }

  void unlockKardashev() {
    kardashevLocked = false;
    notifyListeners();
  }

  // ── Main Character: gear ──────────────────────────────────────────
  final gearOffense = TextEditingController();
  final gearDefense = TextEditingController();
  final gearClothing = TextEditingController();

  // ── Main Character: personality ───────────────────────────────────
  final personality = TextEditingController();
  final tone = TextEditingController();
  double sarcasm = 6; // 0 = plays it straight, 10 = dripping
  double alignment = 3; // 0 = good, 10 = evil
  final mission = TextEditingController();

  void setSarcasm(double v) {
    sarcasm = v;
    notifyListeners();
  }

  void setAlignment(double v) {
    alignment = v;
    notifyListeners();
  }

  String get alignmentLabel {
    if (alignment <= 2) return 'Good';
    if (alignment <= 4) return 'Leans good';
    if (alignment < 6) return 'Neutral';
    if (alignment < 8) return 'Leans evil';
    return 'Evil';
  }

  // ── Main Character: appearance ────────────────────────────────────
  final hairColor = TextEditingController();
  final eyeColor = TextEditingController();
  final lipColor = TextEditingController();
  final scars = TextEditingController();
  final appearanceNotes = TextEditingController();
  final bust = TextEditingController();
  final hips = TextEditingController();
  bool bustInches = true;
  bool hipsInches = true;
  GenitalOption topGenital = GenitalOption.male;
  GenitalOption bottomGenital = GenitalOption.female;

  void setBustInches(bool v) {
    bustInches = v;
    notifyListeners();
  }

  void setHipsInches(bool v) {
    hipsInches = v;
    notifyListeners();
  }

  void setTopGenital(GenitalOption v) {
    topGenital = v;
    notifyListeners();
  }

  void setBottomGenital(GenitalOption v) {
    bottomGenital = v;
    notifyListeners();
  }

  // ── Main Character: greeting, voice & dialogue ────────────────────
  final greeting = TextEditingController();
  bool voiceOn = true;
  String? voiceModel; // static catalog pick, shared with Model features
  final voiceSpeech = TextEditingController();
  final exampleDialogue = TextEditingController();
  String? imageModel; // static catalog pick, shared with Model features

  void setVoiceOn(bool v) {
    voiceOn = v;
    notifyListeners();
  }

  void setVoiceModel(String? v) {
    voiceModel = v;
    notifyListeners();
  }

  void setImageModel(String? v) {
    imageModel = v;
    notifyListeners();
  }

  // ── Main Character: world ─────────────────────────────────────────
  final universe = TextEditingController();
  final planet = TextEditingController();
  final continent = TextEditingController();
  final city = TextEditingController();
  final village = TextEditingController();
  final lorebookLinks = TextEditingController();

  // ── NPC ───────────────────────────────────────────────────────────
  final npcName = TextEditingController();
  String npcRole = 'Merchant';
  final npcConcept = TextEditingController();
  final npcRelationship = TextEditingController();
  bool npcDrafting = false;
  bool npcNaming = false;
  CharacterCard? npcDraft;

  /// DbId of the NPC card loaded via "Load NPC". Null = working from scratch.
  String? npcLoadedDbId;

  void setNpcRole(String r) {
    npcRole = r;
    notifyListeners();
  }

  // ── You (User) ────────────────────────────────────────────────────
  final userRealName = TextEditingController();
  final userBirthday = TextEditingController();
  final userPersonaName = TextEditingController();
  final userPronouns = TextEditingController();
  final userBio = TextEditingController();

  int get bioWordCount {
    final t = userBio.text.trim();
    if (t.isEmpty) return 0;
    return t.split(RegExp(r'\s+')).length;
  }

  /// Nudge listeners (e.g. the bio word counter) without touching fields.
  void touch() => notifyListeners();

  static const _kRealName = 'alice_user_real_name';
  static const _kBirthday = 'alice_user_birthday';
  static const _kPersonaName = 'alice_user_persona_name';
  static const _kPronouns = 'alice_user_pronouns';
  static const _kBio = 'alice_user_bio';

  Future<void> loadUserPersona() async {
    final prefs = await SharedPreferences.getInstance();
    userRealName.text = prefs.getString(_kRealName) ?? '';
    userBirthday.text = prefs.getString(_kBirthday) ?? '';
    userPersonaName.text = prefs.getString(_kPersonaName) ?? '';
    userPronouns.text = prefs.getString(_kPronouns) ?? '';
    userBio.text = prefs.getString(_kBio) ?? '';
    notifyListeners();
  }

  /// Returns an error string when the bio is too long, null on success.
  Future<String?> saveUserPersona() async {
    if (bioWordCount > 300) {
      return 'That bio is $bioWordCount words — trim it to 300.';
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kRealName, userRealName.text.trim());
    await prefs.setString(_kBirthday, userBirthday.text.trim());
    await prefs.setString(_kPersonaName, userPersonaName.text.trim());
    await prefs.setString(_kPronouns, userPronouns.text.trim());
    await prefs.setString(_kBio, userBio.text.trim());
    return null;
  }

  // ── MC card assembly + save ───────────────────────────────────────

  CharacterCard buildMcCard() {
    final genderLabel =
        gender == GenderIdentity.custom && genderCustom.text.trim().isNotEmpty
        ? genderCustom.text.trim()
        : gender.label;
    final pronounLabel =
        pronouns == PronounSet.custom && pronounCustom.text.trim().isNotEmpty
        ? pronounCustom.text.trim()
        : pronouns.label;

    final appearance = [
      if (hairColor.text.trim().isNotEmpty) 'Hair: ${hairColor.text.trim()}',
      if (eyeColor.text.trim().isNotEmpty) 'Eyes: ${eyeColor.text.trim()}',
      if (lipColor.text.trim().isNotEmpty) 'Lips: ${lipColor.text.trim()}',
      if (scars.text.trim().isNotEmpty) 'Scars & marks: ${scars.text.trim()}',
      if (bust.text.trim().isNotEmpty)
        'Bust: ${bust.text.trim()} ${bustInches ? 'in' : 'cm'}',
      if (hips.text.trim().isNotEmpty)
        'Hips: ${hips.text.trim()} ${hipsInches ? 'in' : 'cm'}',
      'Top: ${topGenital.label}; bottom: ${bottomGenital.label}',
      if (appearanceNotes.text.trim().isNotEmpty) appearanceNotes.text.trim(),
    ].join('\n');

    final gear = [
      if (gearOffense.text.trim().isNotEmpty)
        'Offensive: ${gearOffense.text.trim()}',
      if (gearDefense.text.trim().isNotEmpty)
        'Defensive: ${gearDefense.text.trim()}',
      if (gearClothing.text.trim().isNotEmpty)
        'Clothing: ${gearClothing.text.trim()}',
    ].join('\n');

    final scaleLine =
        kardashev == KardashevType.beyond && beyondName.text.trim().isNotEmpty
        ? 'Beyond — ${beyondName.text.trim()}'
              '${beyondScope.text.trim().isEmpty ? '' : ' (${beyondScope.text.trim()})'}'
        : kardashev.label;

    final worldBits = [
      if (universe.text.trim().isNotEmpty) 'Universe: ${universe.text.trim()}',
      if (planet.text.trim().isNotEmpty) 'Planet: ${planet.text.trim()}',
      if (continent.text.trim().isNotEmpty)
        'Continent: ${continent.text.trim()}',
      if (city.text.trim().isNotEmpty) 'City: ${city.text.trim()}',
      if (village.text.trim().isNotEmpty) 'Village: ${village.text.trim()}',
      if (lorebookLinks.text.trim().isNotEmpty)
        'Lorebook: ${lorebookLinks.text.trim()}',
    ];

    final personalityBits = [
      personality.text.trim(),
      if (tone.text.trim().isNotEmpty) 'Tone: ${tone.text.trim()}',
      'Sarcasm: ${sarcasm.round()}/10. Alignment: $alignmentLabel.',
      if (mission.text.trim().isNotEmpty)
        'Core mission: ${mission.text.trim()}',
    ].where((s) => s.isNotEmpty).join('\n');

    final rules = [
      'Kardashev scale: $scaleLine.',
      if (beyondGear.text.trim().isNotEmpty)
        'Beyond gear definition: ${beyondGear.text.trim()}',
      'Gender: $genderLabel ($pronounLabel).',
      if (gear.isNotEmpty) 'Gear loadout:\n$gear',
      if (worldBits.isNotEmpty) 'World:\n${worldBits.join('\n')}',
    ].join('\n');

    return CharacterCard(
      name: mcName.text.trim(),
      description: appearance,
      personality: personalityBits,
      scenario: mcScenario.text.trim(),
      firstMessage: greeting.text.trim(),
      mesExample: exampleDialogue.text.trim(),
      systemPrompt: rules,
      ttsVoice: voiceOn ? voiceModel : null,
      tags: const ['main-character'],
      worldNames: [
        universe.text.trim(),
        planet.text.trim(),
        continent.text.trim(),
        city.text.trim(),
        village.text.trim(),
      ].where((s) => s.isNotEmpty).toList(),
    );
  }

  /// Save the MC card; locks the Kardashev scale on success.
  Future<bool> saveMcCard(BuildContext context) async {
    if (mcName.text.trim().isEmpty) {
      _snack(context, 'Give your main character a name first.');
      return false;
    }
    final repo = Provider.of<CharacterRepository>(context, listen: false);
    await repo.addCharacter(buildMcCard());
    kardashevLocked = true;
    notifyListeners();
    if (context.mounted) _snack(context, 'Character card saved.');
    return true;
  }

  /// Jump to the Chat tab (index 1 in the Alice shell).
  void goToChat(BuildContext context) {
    Provider.of<AppState>(context, listen: false).setIndex(1);
  }

  static void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  void dispose() {
    for (final c in [
      mcName,
      mcRole,
      mcScenario,
      genderCustom,
      pronounCustom,
      beyondName,
      beyondScope,
      beyondGear,
      gearOffense,
      gearDefense,
      gearClothing,
      personality,
      tone,
      mission,
      hairColor,
      eyeColor,
      lipColor,
      scars,
      appearanceNotes,
      bust,
      hips,
      greeting,
      voiceSpeech,
      exampleDialogue,
      universe,
      planet,
      continent,
      city,
      village,
      lorebookLinks,
      npcName,
      npcConcept,
      npcRelationship,
      userRealName,
      userBirthday,
      userPersonaName,
      userPronouns,
      userBio,
    ]) {
      c.dispose();
    }
    super.dispose();
  }
}
