// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// The individual screens of the Alice setup wizard. Part of
// alice_setup_wizard.dart — one screen, one action, plain language, every
// step skippable.

part of 'alice_setup_wizard.dart';

extension _AliceSetupWizardSteps on _AliceSetupWizardState {
  // ── Boot ─────────────────────────────────────────────────────────

  Widget _checkingStep() {
    return const _WizardFrame(
      title: 'Setting up…',
      primaryLabel: 'Please wait',
      child: _ProgressRow(progress: 0, label: 'Checking your computer…'),
    );
  }

  // ── Step 0: reinstall data choice ────────────────────────────────

  Widget _dataChoiceStep() {
    final existing = _existing;
    if (_wiping) {
      return _WizardFrame(
        title: 'Wiping everything…',
        primaryLabel: 'Working…',
        onPrimary: () {},
        primaryBusy: true,
        skipLabel: null,
        child: _ProgressRow(progress: 0, label: _wipeStatus),
      );
    }
    if (_wipeReport != null) {
      final report = _wipeReport!;
      return _WizardFrame(
        title: 'Fresh start ready',
        primaryLabel: 'Continue',
        onPrimary: () => _go(_WizardStep.welcome),
        skipLabel: null,
        child: _body(
          '${report.describe()}'
          '${report.leftAlone.isEmpty ? '' : '\n\nLeft alone (not ours to delete): ${report.leftAlone.join(', ')}'}',
        ),
      );
    }
    if (_importing) {
      return _WizardFrame(
        title: 'Keeping your data…',
        primaryLabel: 'Working…',
        onPrimary: () {},
        primaryBusy: true,
        skipLabel: null,
        child: _ProgressRow(progress: 0, label: _importStatus),
      );
    }
    return _WizardFrame(
      title: 'We found your old data',
      primaryLabel: 'Start fresh',
      onPrimary: _chooseBlankSlate,
      skipLabel: null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _body(
            'This looks like a reinstall — we found '
            '${existing?.describe() ?? 'existing data'} from a previous '
            'install. Nothing happens until you choose.',
          ),
          const SizedBox(height: 16),
          _OptionCard(
            icon: Icons.upload_rounded,
            title: 'Import existing',
            subtitle:
                'Keep your characters, chats, worlds, and settings exactly as they are.',
            onTap: _chooseImport,
          ),
          const SizedBox(height: 10),
          _body(
            '“Start fresh” below wipes everything — chats, characters, '
            'settings, downloaded models, the lot — and asks you to confirm '
            'first.',
            small: true,
          ),
        ],
      ),
    );
  }

  // ── 1. Welcome ───────────────────────────────────────────────────

  Widget _welcomeStep() {
    return _WizardFrame(
      title: 'Welcome to Alice.',
      primaryLabel: "Let's set up",
      onPrimary: () => _go(_WizardStep.hardware),
      skipLabel: 'Skip setup',
      onSkip: _skipAll,
      child: _body(
        'Alice is your own storytelling companion — characters, worlds, '
        'and chats that live on your computer. This will take a minute to '
        'get ready.',
      ),
    );
  }

  // ── 2. Hardware check ────────────────────────────────────────────

  Widget _hardwareStep() {
    final p = _profile;
    final found = p == null
        ? 'We could not read your hardware details.'
        : 'We found: ${_describeGpu(p)}, ${_gb(p.vramMb, 'graphics memory')}, '
              '${_gb(p.systemRamMb, 'system memory')}.';
    final verdict = switch (p?.capabilityTier) {
      'high' => 'This is a high-performance setup — Alice will fly here.',
      'low' =>
        'This is a modest setup — Alice will run fine and automatically keep things light.',
      _ => 'This is a standard setup — Alice will run great here.',
    };
    return _WizardFrame(
      title: 'Your computer',
      primaryLabel: 'Continue',
      onPrimary: () => _go(_WizardStep.downloadPrompt),
      onSkip: _skipAll,
      child: _body('$found\n\n$verdict'),
    );
  }

  // ── 3. Download prompt ───────────────────────────────────────────

  Widget _downloadPromptStep() {
    final bm = _backendManager();
    if (bm.isIntelMac) {
      return _WizardFrame(
        title: 'The AI engine',
        primaryLabel: 'Continue',
        onPrimary: () => _go(_WizardStep.textEngine),
        onSkip: _skipAll,
        child: _body(
          'This Mac can’t run the built-in engine, so there’s nothing to '
          'download. You can connect your own AI service later in '
          'Settings → Backend.',
        ),
      );
    }
    final gpu = _profile == null ? 'your hardware' : _describeGpu(_profile!);
    return _WizardFrame(
      title: 'Would you like to download the AI engine?',
      primaryLabel: 'Download',
      onPrimary: _startDownload,
      skipLabel: 'I’ll do it later',
      onSkip: () => _go(_WizardStep.textEngine),
      child: _body(
        'This is the brain that powers chat. It’s a one-time download of a '
        'few hundred megabytes, matched to $gpu.\n\n'
        'Nothing downloads until you say so.',
      ),
    );
  }

  // ── 4. Download progress ─────────────────────────────────────────

  Widget _downloadProgressStep() {
    final bm = Provider.of<BackendManager>(context);
    final done = !bm.isDownloading && bm.backendPath != null;
    final failed =
        !bm.isDownloading && bm.backendPath == null && bm.error != null;

    if (done) {
      return _WizardFrame(
        title: 'Engine downloaded',
        primaryLabel: 'Continue',
        onPrimary: () => _go(_WizardStep.textEngine),
        skipLabel: null,
        child: _body(
          'The AI engine is installed and matched to your computer. '
          'You’re one step closer to chatting.',
        ),
      );
    }
    if (failed) {
      return _WizardFrame(
        title: 'The download hit a snag',
        primaryLabel: 'Try again',
        onPrimary: _startDownload,
        skipLabel: 'Skip for now',
        onSkip: _abandonDownload,
        child: _body(
          '${_plainError(bm.error)}\n\n'
          'Check your internet connection and try again — or skip it and '
          'download later from Settings.',
        ),
      );
    }
    final pct = (bm.downloadProgress * 100).toStringAsFixed(0);
    final status = bm.statusMessage.isEmpty ? 'Downloading…' : bm.statusMessage;
    return _WizardFrame(
      title: 'Downloading the engine…',
      primaryLabel: 'Downloading… $pct%',
      onPrimary: () {},
      primaryBusy: true,
      skipLabel: null,
      child: _ProgressRow(progress: bm.downloadProgress, label: status),
    );
  }

  // ── 5a. Text engine ──────────────────────────────────────────────

  Widget _textEngineStep() {
    final bm = _backendManager();
    if (bm.isIntelMac) {
      return _WizardFrame(
        title: 'Chat engine',
        primaryLabel: 'Got it',
        onPrimary: () => _go(_WizardStep.imageGen),
        onSkip: _skipAll,
        child: _body(
          'This powers chat responses. This Mac can’t run the built-in '
          'engine, so connect your own AI service later in '
          'Settings → Backend.',
        ),
      );
    }
    final tier = _profile?.capabilityTier;
    final note = tier == 'low'
        ? 'Your computer can run it — Alice will automatically use lighter settings to keep it smooth.'
        : 'Your computer can run it entirely on its own — private, with no subscriptions.';
    return _WizardFrame(
      title: 'Chat engine',
      primaryLabel: 'Use the local engine',
      onPrimary: _confirmLocalEngine,
      onSkip: _skipAll,
      child: _body(
        'This powers chat responses. We recommend the built-in local engine. '
        '$note',
      ),
    );
  }

  // ── 5b. Image generation ─────────────────────────────────────────

  Widget _imageGenStep() {
    return _WizardFrame(
      title: 'Images',
      primaryLabel: 'Use the online service',
      onPrimary: _confirmImageBackend,
      onSkip: _skipAll,
      child: _body(
        'This creates pictures for your stories. The online service works '
        'right away on any hardware — your API key goes in Settings. '
        'Prefer free and private? Connect your own image server on this '
        'computer later in Settings.\n\n'
        'For pictures made on this computer: on graphics cards with 8 GB '
        'of memory or less, SD 1.5 and SDXL models are the right fit. The '
        'biggest models, like FLUX, need more memory — those come later, '
        'for stronger cards.',
      ),
    );
  }

  // ── 5c. Context storage ──────────────────────────────────────────

  Widget _contextStorageStep() {
    final root = _storage?.rootPath ?? 'your documents folder';
    return _WizardFrame(
      title: 'Your library',
      primaryLabel: 'Keep this folder',
      onPrimary: () => _go(_WizardStep.done),
      onSkip: _skipAll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _body(
            'This is where Alice remembers your world — your characters, '
            'chats, and worlds live in this folder:',
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderOf(context)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SelectableText(root),
          ),
          const SizedBox(height: 10),
          _body('You can move it later in Settings.', small: true),
        ],
      ),
    );
  }

  // ── 6. Done ──────────────────────────────────────────────────────

  Widget _doneStep() {
    final bm = _backendManager();
    final engineNote = bm.backendPath != null
        ? 'Your AI engine is installed.'
        : 'You can download the AI engine anytime from Settings.';
    return _WizardFrame(
      title: 'You’re all set.',
      primaryLabel: 'Start chatting',
      onPrimary: _finish,
      skipLabel: null,
      child: _body('Alice is ready. $engineNote'),
    );
  }

  // ── Plain-language helpers ───────────────────────────────────────

  Widget _body(String text, {bool small = false}) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: (small ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium)
          ?.copyWith(color: small ? theme.hintColor : null, height: 1.5),
    );
  }

  String _describeGpu(HardwareProfile p) {
    if (p.gpuVendor == 'None' || p.gpuName == 'Unknown GPU') {
      return 'no graphics card detected';
    }
    final vendor = p.gpuVendor == 'Unknown' ? '' : '${p.gpuVendor} ';
    return '$vendor${p.gpuName}'.trim();
  }

  String _gb(int mb, String what) {
    if (mb <= 0) return 'an unknown amount of $what';
    final gb = mb / 1024;
    final num = gb.toStringAsFixed(gb % 1 == 0 ? 0 : 1);
    return '$num GB of $what';
  }

  String _plainError(String? error) {
    if (error == null || error.isEmpty) return 'Something went wrong.';
    final e = error.replaceFirst(RegExp(r'^Error:\s*'), '');
    return e.length > 220 ? '${e.substring(0, 220)}…' : e;
  }
}

/// Tappable option card for the step-0 data choice.
class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderOf(context)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.porchAmber, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
