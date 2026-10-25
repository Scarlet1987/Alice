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

// Dead Dove checklist topic data: the Top 100 fetish topics (10
// categories, most-common first) and the 48 story & content topics
// (8 groups). Labels are short and clinical; no "adult" qualifiers —
// the minor-safety floor carries the legal weight.

/// One checklist topic with its display label and category.
class DeadDoveTopic {
  const DeadDoveTopic({required this.id, required this.label, required this.category});

  /// Stable id like 'dd-001' or 'sc-001'.
  final String id;
  final String label;
  final String category;
}

/// The four limit levels. Unchecked (null in state) means "anything goes".
enum DeadDoveLevel {
  allow,
  hard,
  soft,
  caution,
}

extension DeadDoveLevelLabel on DeadDoveLevel {
  String get label {
    switch (this) {
      case DeadDoveLevel.allow:
        return 'Allow';
      case DeadDoveLevel.hard:
        return 'Hard limit';
      case DeadDoveLevel.soft:
        return 'Soft limit';
      case DeadDoveLevel.caution:
        return 'Caution';
    }
  }
}

/// Top 100 fetish topics, most common first.
const List<DeadDoveTopic> kDeadDoveTop100 = [
  // Power & control
  DeadDoveTopic(id: 'dd-001', label: 'Dominance & submission dynamics', category: 'Power & control'),
  DeadDoveTopic(id: 'dd-002', label: '24/7 power exchange', category: 'Power & control'),
  DeadDoveTopic(id: 'dd-003', label: 'Master/slave dynamics', category: 'Power & control'),
  DeadDoveTopic(id: 'dd-004', label: 'Caregiver dynamics (daddy/mommy)', category: 'Power & control'),
  DeadDoveTopic(id: 'dd-005', label: 'Pet play', category: 'Power & control'),
  DeadDoveTopic(id: 'dd-006', label: 'Pony play', category: 'Power & control'),
  DeadDoveTopic(id: 'dd-007', label: 'Service submission', category: 'Power & control'),
  DeadDoveTopic(id: 'dd-008', label: 'Protocol training', category: 'Power & control'),
  DeadDoveTopic(id: 'dd-009', label: 'Financial domination', category: 'Power & control'),
  DeadDoveTopic(id: 'dd-010', label: 'Orgasm control & denial', category: 'Power & control'),
  DeadDoveTopic(id: 'dd-011', label: 'Forced orgasms', category: 'Power & control'),
  DeadDoveTopic(id: 'dd-012', label: 'Edging', category: 'Power & control'),
  DeadDoveTopic(id: 'dd-013', label: 'Cuckolding', category: 'Power & control'),
  DeadDoveTopic(id: 'dd-014', label: 'Chastity play', category: 'Power & control'),
  DeadDoveTopic(id: 'dd-015', label: 'Collaring', category: 'Power & control'),
  // Bondage & restraint
  DeadDoveTopic(id: 'dd-016', label: 'Light bondage', category: 'Bondage & restraint'),
  DeadDoveTopic(id: 'dd-017', label: 'Rope bondage (shibari)', category: 'Bondage & restraint'),
  DeadDoveTopic(id: 'dd-018', label: 'Heavy bondage', category: 'Bondage & restraint'),
  DeadDoveTopic(id: 'dd-019', label: 'Handcuffs & metal restraints', category: 'Bondage & restraint'),
  DeadDoveTopic(id: 'dd-020', label: 'Mummification', category: 'Bondage & restraint'),
  DeadDoveTopic(id: 'dd-021', label: 'Sensory deprivation', category: 'Bondage & restraint'),
  DeadDoveTopic(id: 'dd-022', label: 'Gagging', category: 'Bondage & restraint'),
  DeadDoveTopic(id: 'dd-023', label: 'Breath play', category: 'Bondage & restraint'),
  DeadDoveTopic(id: 'dd-024', label: 'Suspension bondage', category: 'Bondage & restraint'),
  DeadDoveTopic(id: 'dd-025', label: 'Predicament bondage', category: 'Bondage & restraint'),
  // Impact & sensation
  DeadDoveTopic(id: 'dd-026', label: 'Spanking', category: 'Impact & sensation'),
  DeadDoveTopic(id: 'dd-027', label: 'Flogging', category: 'Impact & sensation'),
  DeadDoveTopic(id: 'dd-028', label: 'Caning', category: 'Impact & sensation'),
  DeadDoveTopic(id: 'dd-029', label: 'Paddling', category: 'Impact & sensation'),
  DeadDoveTopic(id: 'dd-030', label: 'Hair pulling', category: 'Impact & sensation'),
  DeadDoveTopic(id: 'dd-031', label: 'Biting', category: 'Impact & sensation'),
  DeadDoveTopic(id: 'dd-032', label: 'Scratching', category: 'Impact & sensation'),
  DeadDoveTopic(id: 'dd-033', label: 'Nipple play', category: 'Impact & sensation'),
  DeadDoveTopic(id: 'dd-034', label: 'Wax play', category: 'Impact & sensation'),
  DeadDoveTopic(id: 'dd-035', label: 'Temperature play (ice & heat)', category: 'Impact & sensation'),
  DeadDoveTopic(id: 'dd-036', label: 'Electroplay', category: 'Impact & sensation'),
  DeadDoveTopic(id: 'dd-037', label: 'Tickling', category: 'Impact & sensation'),
  DeadDoveTopic(id: 'dd-038', label: 'Knife play', category: 'Impact & sensation'),
  DeadDoveTopic(id: 'dd-039', label: 'Needle play', category: 'Impact & sensation'),
  DeadDoveTopic(id: 'dd-040', label: 'Blood play', category: 'Impact & sensation'),
  // Psychological play
  DeadDoveTopic(id: 'dd-041', label: 'Humiliation play', category: 'Psychological play'),
  DeadDoveTopic(id: 'dd-042', label: 'Degradation play', category: 'Psychological play'),
  DeadDoveTopic(id: 'dd-043', label: 'Praise kink', category: 'Psychological play'),
  DeadDoveTopic(id: 'dd-044', label: 'Dirty talk', category: 'Psychological play'),
  DeadDoveTopic(id: 'dd-045', label: 'Consensual non-consent (CNC)', category: 'Psychological play'),
  DeadDoveTopic(id: 'dd-046', label: 'Kidnapping scenes', category: 'Psychological play'),
  DeadDoveTopic(id: 'dd-047', label: 'Interrogation scenes', category: 'Psychological play'),
  DeadDoveTopic(id: 'dd-048', label: 'Fear play', category: 'Psychological play'),
  DeadDoveTopic(id: 'dd-049', label: 'Hypnosis play', category: 'Psychological play'),
  DeadDoveTopic(id: 'dd-050', label: 'Objectification', category: 'Psychological play'),
  DeadDoveTopic(id: 'dd-051', label: 'Sissification', category: 'Psychological play'),
  DeadDoveTopic(id: 'dd-052', label: 'Age play', category: 'Psychological play'),
  // Roleplay scenarios
  DeadDoveTopic(id: 'dd-053', label: 'Teacher/student roleplay', category: 'Roleplay scenarios'),
  DeadDoveTopic(id: 'dd-054', label: 'Medical play', category: 'Roleplay scenarios'),
  DeadDoveTopic(id: 'dd-055', label: 'Boss/employee roleplay', category: 'Roleplay scenarios'),
  DeadDoveTopic(id: 'dd-056', label: 'Stranger scenes', category: 'Roleplay scenarios'),
  DeadDoveTopic(id: 'dd-057', label: 'Client & sex worker scenes', category: 'Roleplay scenarios'),
  DeadDoveTopic(id: 'dd-058', label: 'Prison scenes', category: 'Roleplay scenarios'),
  DeadDoveTopic(id: 'dd-059', label: 'Maid/servant roleplay', category: 'Roleplay scenarios'),
  DeadDoveTopic(id: 'dd-060', label: 'Authority figure roleplay', category: 'Roleplay scenarios'),
  DeadDoveTopic(id: 'dd-061', label: 'Cross-dressing', category: 'Roleplay scenarios'),
  DeadDoveTopic(id: 'dd-062', label: 'Monster/creature roleplay', category: 'Roleplay scenarios'),
  // Body & material fetish
  DeadDoveTopic(id: 'dd-063', label: 'Foot worship', category: 'Body & material fetish'),
  DeadDoveTopic(id: 'dd-064', label: 'Latex & rubber', category: 'Body & material fetish'),
  DeadDoveTopic(id: 'dd-065', label: 'Leather', category: 'Body & material fetish'),
  DeadDoveTopic(id: 'dd-066', label: 'Lingerie & stockings', category: 'Body & material fetish'),
  DeadDoveTopic(id: 'dd-067', label: 'Footwear (heels, boots)', category: 'Body & material fetish'),
  DeadDoveTopic(id: 'dd-068', label: 'Uniforms', category: 'Body & material fetish'),
  DeadDoveTopic(id: 'dd-069', label: 'Corsetry', category: 'Body & material fetish'),
  DeadDoveTopic(id: 'dd-070', label: 'Hair fetish', category: 'Body & material fetish'),
  DeadDoveTopic(id: 'dd-071', label: 'Body worship', category: 'Body & material fetish'),
  DeadDoveTopic(id: 'dd-072', label: 'Muscle worship', category: 'Body & material fetish'),
  DeadDoveTopic(id: 'dd-073', label: 'Feeder/feedee dynamics', category: 'Body & material fetish'),
  DeadDoveTopic(id: 'dd-074', label: 'Lactation play', category: 'Body & material fetish'),
  DeadDoveTopic(id: 'dd-075', label: 'Pregnancy', category: 'Body & material fetish'),
  // Group & public
  DeadDoveTopic(id: 'dd-076', label: 'Threesomes', category: 'Group & public'),
  DeadDoveTopic(id: 'dd-077', label: 'Group sex', category: 'Group & public'),
  DeadDoveTopic(id: 'dd-078', label: 'Swinging', category: 'Group & public'),
  DeadDoveTopic(id: 'dd-079', label: 'Consensual voyeurism', category: 'Group & public'),
  DeadDoveTopic(id: 'dd-080', label: 'Consensual exhibitionism', category: 'Group & public'),
  DeadDoveTopic(id: 'dd-081', label: 'Public play', category: 'Group & public'),
  DeadDoveTopic(id: 'dd-082', label: 'Glory holes', category: 'Group & public'),
  // Oral & penetration
  DeadDoveTopic(id: 'dd-083', label: 'Oral sex', category: 'Oral & penetration'),
  DeadDoveTopic(id: 'dd-084', label: 'Deep throating', category: 'Oral & penetration'),
  DeadDoveTopic(id: 'dd-085', label: 'Rimming', category: 'Oral & penetration'),
  DeadDoveTopic(id: 'dd-086', label: 'Anal sex', category: 'Oral & penetration'),
  DeadDoveTopic(id: 'dd-087', label: 'Anal play (plugs & beads)', category: 'Oral & penetration'),
  DeadDoveTopic(id: 'dd-088', label: 'Pegging & strap-on play', category: 'Oral & penetration'),
  DeadDoveTopic(id: 'dd-089', label: 'Double penetration', category: 'Oral & penetration'),
  DeadDoveTopic(id: 'dd-090', label: 'Fisting', category: 'Oral & penetration'),
  DeadDoveTopic(id: 'dd-091', label: 'Squirting', category: 'Oral & penetration'),
  DeadDoveTopic(id: 'dd-092', label: 'Internal ejaculation', category: 'Oral & penetration'),
  DeadDoveTopic(id: 'dd-093', label: 'Facials', category: 'Oral & penetration'),
  DeadDoveTopic(id: 'dd-094', label: 'Bukkake', category: 'Oral & penetration'),
  // Fluids & mess
  DeadDoveTopic(id: 'dd-095', label: 'Food play', category: 'Fluids & mess'),
  DeadDoveTopic(id: 'dd-096', label: 'Wet & messy play', category: 'Fluids & mess'),
  DeadDoveTopic(id: 'dd-097', label: 'Water sports', category: 'Fluids & mess'),
  DeadDoveTopic(id: 'dd-098', label: 'Scat play', category: 'Fluids & mess'),
  // Romance & story
  DeadDoveTopic(id: 'dd-099', label: 'Romance between characters', category: 'Romance & story'),
  DeadDoveTopic(id: 'dd-100', label: 'Explicit romance between characters', category: 'Romance & story'),
];

/// Story & content checklist: 48 topics in 8 groups. Same mechanics as
/// the Top 100; compiles into the story brief, not the fetish list.
const List<DeadDoveTopic> kDeadDoveStoryTopics = [
  // Death & loss
  DeadDoveTopic(id: 'sc-001', label: 'Main character can die', category: 'Death & loss'),
  DeadDoveTopic(id: 'sc-002', label: 'Major NPCs can die', category: 'Death & loss'),
  DeadDoveTopic(id: 'sc-003', label: 'Anyone can die (no plot armor)', category: 'Death & loss'),
  DeadDoveTopic(id: 'sc-004', label: 'Deaths are permanent (no resurrection)', category: 'Death & loss'),
  DeadDoveTopic(id: 'sc-005', label: 'Resurrection is possible', category: 'Death & loss'),
  DeadDoveTopic(id: 'sc-006', label: 'Grief & mourning explored', category: 'Death & loss'),
  // Conflict types
  DeadDoveTopic(id: 'sc-007', label: 'Physical combat & duels', category: 'Conflict types'),
  DeadDoveTopic(id: 'sc-008', label: 'Large-scale war & battles', category: 'Conflict types'),
  DeadDoveTopic(id: 'sc-009', label: 'Political intrigue', category: 'Conflict types'),
  DeadDoveTopic(id: 'sc-010', label: 'Mystery & investigation', category: 'Conflict types'),
  DeadDoveTopic(id: 'sc-011', label: 'Interpersonal drama', category: 'Conflict types'),
  DeadDoveTopic(id: 'sc-012', label: 'Survival situations', category: 'Conflict types'),
  DeadDoveTopic(id: 'sc-013', label: 'Betrayal', category: 'Conflict types'),
  DeadDoveTopic(id: 'sc-014', label: 'Rivalry & competition', category: 'Conflict types'),
  // Tone
  DeadDoveTopic(id: 'sc-015', label: 'Grimdark', category: 'Tone'),
  DeadDoveTopic(id: 'sc-016', label: 'Dark & serious', category: 'Tone'),
  DeadDoveTopic(id: 'sc-017', label: 'Hopeful & uplifting', category: 'Tone'),
  DeadDoveTopic(id: 'sc-018', label: 'Comedic & lighthearted', category: 'Tone'),
  DeadDoveTopic(id: 'sc-019', label: 'Tragic', category: 'Tone'),
  DeadDoveTopic(id: 'sc-020', label: 'Romantic', category: 'Tone'),
  DeadDoveTopic(id: 'sc-021', label: 'Horror', category: 'Tone'),
  DeadDoveTopic(id: 'sc-022', label: 'Cozy / slice of life', category: 'Tone'),
  // Stakes
  DeadDoveTopic(id: 'sc-023', label: 'Low stakes (personal, everyday)', category: 'Stakes'),
  DeadDoveTopic(id: 'sc-024', label: 'City / kingdom at stake', category: 'Stakes'),
  DeadDoveTopic(id: 'sc-025', label: 'World-ending stakes', category: 'Stakes'),
  // Endings
  DeadDoveTopic(id: 'sc-026', label: 'Happy endings', category: 'Endings'),
  DeadDoveTopic(id: 'sc-027', label: 'Bittersweet endings', category: 'Endings'),
  DeadDoveTopic(id: 'sc-028', label: 'Tragic endings', category: 'Endings'),
  DeadDoveTopic(id: 'sc-029', label: 'Open / cliffhanger endings', category: 'Endings'),
  // Intensity
  DeadDoveTopic(id: 'sc-030', label: 'Graphic violence', category: 'Intensity'),
  DeadDoveTopic(id: 'sc-031', label: 'Gore', category: 'Intensity'),
  DeadDoveTopic(id: 'sc-032', label: 'Body horror', category: 'Intensity'),
  DeadDoveTopic(id: 'sc-033', label: 'Psychological horror', category: 'Intensity'),
  DeadDoveTopic(id: 'sc-034', label: 'Cosmic horror', category: 'Intensity'),
  DeadDoveTopic(id: 'sc-035', label: 'Fade-to-black violence', category: 'Intensity'),
  // Themes
  DeadDoveTopic(id: 'sc-036', label: 'Revenge', category: 'Themes'),
  DeadDoveTopic(id: 'sc-037', label: 'Redemption', category: 'Themes'),
  DeadDoveTopic(id: 'sc-038', label: 'Coming of age', category: 'Themes'),
  DeadDoveTopic(id: 'sc-039', label: 'Corruption (moral decay)', category: 'Themes'),
  DeadDoveTopic(id: 'sc-040', label: 'Sacrifice', category: 'Themes'),
  DeadDoveTopic(id: 'sc-041', label: 'Found family', category: 'Themes'),
  DeadDoveTopic(id: 'sc-042', label: 'Forbidden love', category: 'Themes'),
  DeadDoveTopic(id: 'sc-043', label: 'Power fantasy', category: 'Themes'),
  // World behavior
  DeadDoveTopic(id: 'sc-044', label: 'NPCs act on their own', category: 'World behavior'),
  DeadDoveTopic(id: 'sc-045', label: 'World moves without the MC', category: 'World behavior'),
  DeadDoveTopic(id: 'sc-046', label: 'Actions have lasting consequences', category: 'World behavior'),
  DeadDoveTopic(id: 'sc-047', label: 'Slow-burn pacing', category: 'World behavior'),
  DeadDoveTopic(id: 'sc-048', label: 'Fast-paced action', category: 'World behavior'),
];
