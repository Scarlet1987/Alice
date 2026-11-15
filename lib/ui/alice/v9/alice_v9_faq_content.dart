// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// FAQ copy, from the approved preview (Space alice-faq-feedback-preview,
// Elaina 2026-11-14: "that is perfect lets do this as the faq feature"):
// the policy questions, the draft guide in its two audience groups, the
// suggestion-box field hints, and the out-of-beta done-list. The guide
// is a draft for her approval — its questions are anticipated from what
// Alice does, not asked by anyone yet — and the simpler app in the
// basics group stays unnamed: do not guess which one it is.

/// One pre-answered question.
class FaqQA {
  const FaqQA(this.question, this.answer);

  final String question;
  final String answer;
}

/// The policy questions: free in beta, large jumps, how feedback is
/// used, and what out-of-beta means.
const kFaqPolicy = <FaqQA>[
  FaqQA(
    'Is Alice free?',
    'Yes — Alice is free while it\'s in beta. Charging starts at '
        'version 2.0, when it leaves beta: a one-time purchase of \$25. '
        'No subscription, no renting the software.',
  ),
  FaqQA(
    'How does Alice change during the beta?',
    'In large jumps, not a drip of tiny updates. Each jump is shaped '
        'by user feedback — grouped by the categories requests arrive '
        'in through the suggestion box on this page.',
  ),
  FaqQA(
    'What happens when I send a complaint or request?',
    'It is appended to one running file that keeps collecting every '
        'request, heavily organized: entries grouped by category, each '
        'one carrying who, what, when, where, why, and how. That file '
        'is what gets uploaded and worked through, category by category.',
  ),
  FaqQA(
    'What decides whether a jump is a version change or out of beta?',
    'Not how much code changed — not an overhaul, not a percentage. '
        'Out of beta means the program is finished: everything it '
        'ships with works, no placeholders are left, and it\'s ready '
        'to be charged for. Until that\'s true, a jump is a version '
        'change — still beta, still free. Every batch in the file '
        'carries a mark saying which one it is, so it\'s certain, not '
        'a judgment call.',
  ),
];

/// The draft guide, first group: the basics, for people coming from a
/// much simpler app.
const kFaqBasics = <FaqQA>[
  FaqQA(
    'How do I install Alice?',
    'Download the installer for your system — Windows, Mac, or Linux '
        '— and run it. There\'s no account to make and nothing to sign '
        'up for; when it finishes, Alice is on your machine and ready '
        'to open.',
  ),
  FaqQA(
    'Does Alice need the internet?',
    'No. Alice runs locally, on your own computer. You\'ll want a '
        'connection to download the installer and a model the first '
        'time; after that, chatting, voice, and images all work offline.',
  ),
  FaqQA(
    'Where does my data live?',
    'On your computer, and nowhere else. Your chats, characters, and '
        'settings are stored locally — Alice is local-first, so your '
        'conversations aren\'t uploaded to anyone\'s cloud.',
  ),
  FaqQA(
    'What model does Alice use? Can I choose?',
    'You choose the model. Alice manages a local backend (KoboldCpp) '
        'for you and runs the model you pick on your own hardware — a '
        'smaller model for a lighter machine, a bigger one if yours can '
        'carry it. Swapping models doesn\'t touch your characters or '
        'chats.',
  ),
  FaqQA(
    'What kind of computer do I need?',
    'An ordinary desktop or laptop is the target — Alice is built to '
        'do more with less, including on older hardware. A graphics '
        'card with 8 GB of memory is a comfortable place to land; '
        'smaller models ask for less, and the program scales down '
        'before it gives up.',
  ),
  FaqQA(
    'How do I add a character?',
    'Characters live in the Party row. Add a character there — name, '
        'picture, and who they are — and it joins the row; tap a '
        'character to set the party and bring them onto the Stage, '
        'where the talking, voice, and pictures happen.',
  ),
  FaqQA(
    'What does Alice cost?',
    'Nothing while it\'s in beta. When Alice reaches version 2.0 and '
        'leaves beta, it becomes a one-time purchase of \$25 — you buy '
        'it once and own it, no subscription.',
  ),
];

/// The draft guide, second group: the common things SillyTavern has,
/// and where each one lives in Alice.
const kFaqSillyTavern = <FaqQA>[
  FaqQA(
    'Can I bring my characters over?',
    'Bring the details across: add the character in the Party row with '
        'the name, picture, and description from your card, and '
        'they\'re in Alice with everything that made them them. '
        'There\'s no separate card library to manage — a character '
        'lives in the Party, and tapping them sets the party and '
        'brings them onto the Stage.',
  ),
  FaqQA(
    'Do I need an API key or a backend of my own?',
    'No. SillyTavern has you wire up a backend yourself; Alice '
        'manages a local KoboldCpp backend for you and runs the model '
        'you pick on your own hardware. No API key, no account, and '
        'nothing billed per message.',
  ),
  FaqQA(
    'Where are the presets and sampler settings?',
    'You won\'t find SillyTavern\'s preset stack and wall of sliders '
        'here. Because the backend is managed for you, the setup comes '
        'down to one choice: which model you run. Pick it, and Alice '
        'handles the connection and the running of it.',
  ),
  FaqQA(
    'Is there a lorebook or world info?',
    'Not as a separate book you attach to a chat. What a character '
        'knows, and how they speak, goes in who they are when you add '
        'them in the Party — the same place their name, picture, and '
        'description live — so it travels with the character.',
  ),
  FaqQA(
    'Can several characters be in a scene together?',
    'Yes — that\'s what the Party is for. Set the party in the Party '
        'row and those characters come onto the Stage together, where '
        'the talking, voice, and pictures happen.',
  ),
];

/// The out-of-beta test, in fuller words than the file's export lines:
/// shown on screen when a batch is marked out of beta.
const kFaqDoneList = <String>[
  'Everything Alice ships with works — every feature in the box does '
      'what it says.',
  'No placeholders left — nothing stubbed, greyed-out, or “coming soon.”',
  'Ready to charge for — finished enough that \$25 one-time is a fair ask.',
];

/// One suggestion-box field: short label, the question it asks, the
/// hint under it, and the placeholder in the box.
class FaqField {
  const FaqField({
    required this.id,
    required this.label,
    required this.question,
    required this.hint,
    required this.placeholder,
  });

  final String id;
  final String label;
  final String question;
  final String hint;
  final String placeholder;
}

/// The six fields, in order. What is the only required one.
const kFaqFields = <FaqField>[
  FaqField(
    id: 'who',
    label: 'Who',
    question: 'Who is this from?',
    hint: 'name or handle, so we can follow up',
    placeholder: 'e.g. Sam R.',
  ),
  FaqField(
    id: 'what',
    label: 'What',
    question: 'What happened, or what do you want?',
    hint: 'required',
    placeholder: 'e.g. Replies stop mid-sentence on long chats',
  ),
  FaqField(
    id: 'when',
    label: 'When',
    question: 'When did it happen?',
    hint: 'date, time, how often',
    placeholder: 'e.g. Nov 12, evening — three times that night',
  ),
  FaqField(
    id: 'where',
    label: 'Where',
    question: 'Where in Alice?',
    hint: 'screen, character, feature',
    placeholder: 'e.g. On the Stage, chatting with the Hatter',
  ),
  FaqField(
    id: 'why',
    label: 'Why',
    question: 'Why does it matter?',
    hint: 'what it cost you, or what it would give you',
    placeholder: 'e.g. It breaks the scene every time the story gets going',
  ),
  FaqField(
    id: 'how',
    label: 'How',
    question: 'How does it happen — or how should it work?',
    hint: 'steps to reproduce, or the fix you imagine',
    placeholder: 'e.g. Start a chat, talk for ~20 minutes, replies start '
        'cutting off',
  ),
];
