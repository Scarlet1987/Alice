// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice first-run setup wizard (alice8): a modal flow over the AliceShell on
// first launch. Step 0 (reinstall only): blank-slate vs import choice.
// Then: welcome → hardware check → engine download prompt (never without
// asking) → guided setup of the chat engine, image generation, and context
// storage. Every step is skippable; finishing (or skipping) sets
// UiSettings.wizardCompleted so it never shows again.
//
// Mounted from main.dart's overlay Stack. The legacy SetupOverlay is gated
// off while the wizard owns the first run (one-shot _wizardTakeover); the
// legacy flow itself is untouched and resumes afterwards for whatever the
// user left undecided.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:front_porch_ai/services/backend_manager.dart';
import 'package:front_porch_ai/services/hardware_audit.dart';
import 'package:front_porch_ai/services/storage_service.dart';
import 'package:front_porch_ai/services/wizard_data_service.dart';
import 'package:front_porch_ai/ui/alice/alice_widgets.dart';
import 'package:front_porch_ai/ui/theme/app_colors.dart';

part 'alice_setup_wizard_steps.dart';

enum _WizardStep {
  dataChoice,
  welcome,
  hardware,
  downloadPrompt,
  downloadProgress,
  textEngine,
  imageGen,
  contextStorage,
  done,
}

class AliceSetupWizard extends StatefulWidget {
  const AliceSetupWizard({super.key});

  /// One-shot first-run gate, called once from main.dart after the first
  /// frame. Mirrors the legacy SetupService first-run condition (local
  /// backend, no engine installed, choice not yet made) so the wizard
  /// replaces — never fights — the old first-run choice. Upgrade users
  /// (choice made or engine present) never see the wizard.
  static Future<bool> shouldTakeOver(BuildContext context) async {
    final storage = Provider.of<StorageService>(context, listen: false);
    await storage.initialized;
    if (storage.uiSettings.wizardCompleted) return false;
    if (storage.backendSettings.backendChoiceDone) return false;
    final backendType = storage.backendSettings.backendType;
    if (backendType == 'openRouter' || backendType == 'omlx') return false;
    try {
      final bm = Provider.of<BackendManager>(context, listen: false);
      await bm.checkBackendAvailability();
      if (bm.backendPath != null) return false;
    } catch (_) {
      return false; // provider not ready — never gate the old flow on a guess
    }
    return true;
  }

  @override
  State<AliceSetupWizard> createState() => _AliceSetupWizardState();
}

class _AliceSetupWizardState extends State<AliceSetupWizard> {
  _WizardStep _step = _WizardStep.welcome;
  bool _booting = true;

  StorageService? _storage;
  ExistingDataSummary? _existing;
  HardwareProfile? _profile;

  // Download state.
  bool _engineChosen = false;

  // Step-0 (reinstall) state.
  bool _wiping = false;
  String _wipeStatus = '';
  WipeReport? _wipeReport;
  bool _importing = false;
  String _importStatus = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    final storage = Provider.of<StorageService>(context, listen: false);
    await storage.initialized;
    if (!mounted) return;
    final data = await WizardDataService(storage).detectExistingData();
    final profile = HardwareAudit.current ?? await HardwareAudit.run();
    if (!mounted) return;
    setState(() {
      _storage = storage;
      _existing = data;
      _profile = profile;
      _step = data.hasData ? _WizardStep.dataChoice : _WizardStep.welcome;
      _booting = false;
    });
  }

  void _go(_WizardStep step) {
    if (!mounted) return;
    setState(() => _step = step);
  }

  /// Done or skipped: the wizard never shows again. The engine choice is
  /// recorded only when the user affirmatively picked the managed engine —
  /// never on a skip — so the legacy flow can still ask afterwards instead
  /// of downloading behind the user's back.
  Future<void> _finish() async {
    final storage = _storage;
    if (storage != null) {
      if (_engineChosen && !storage.backendSettings.backendChoiceDone) {
        await storage.backendSettings.setBackendChoiceDone(true);
      }
      await storage.uiSettings.setWizardCompleted(true);
    }
    // The uiSettings notify rebuilds main.dart, which unmounts the wizard.
  }

  Future<void> _skipAll() => _finish();

  BackendManager _backendManager() =>
      Provider.of<BackendManager>(context, listen: false);

  /// The user explicitly asked for the engine: record the choice for the
  /// end of the wizard and start the fetch. Progress rides BackendManager's
  /// existing isDownloading/downloadProgress/statusMessage fields.
  void _startDownload() {
    setState(() {
      _engineChosen = true;
      _step = _WizardStep.downloadProgress;
    });
    unawaited(_backendManager().ensureEngineInstalled());
  }

  /// A failed download the user walks away from: un-choose the engine so a
  /// later launch asks again instead of fetching in the background.
  Future<void> _abandonDownload() async {
    setState(() => _engineChosen = false);
    _go(_WizardStep.imageGen);
  }

  // ── Step 0: reinstall data choice ────────────────────────────────

  Future<bool> _confirmWipe() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Start completely fresh?'),
        content: const Text(
          'This will permanently delete all existing data — chats, '
          'characters, worlds, settings, and downloaded models. '
          'This cannot be undone. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Yes, wipe it all'),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _chooseBlankSlate() async {
    if (!await _confirmWipe()) return;
    final storage = _storage;
    if (storage == null || !mounted) return;
    setState(() {
      _wiping = true;
      _wipeStatus = 'Getting ready…';
    });
    final report = await WizardDataService(storage).wipeAll(
      onProgress: (m) {
        if (mounted) setState(() => _wipeStatus = m);
      },
    );
    if (!mounted) return;
    setState(() {
      _wiping = false;
      _wipeReport = report;
    });
  }

  Future<void> _chooseImport() async {
    final storage = _storage;
    if (storage == null || !mounted) return;
    setState(() {
      _importing = true;
      _importStatus = 'Checking your data…';
    });
    await WizardDataService(storage).importExisting(
      onProgress: (step, current, total) {
        if (mounted) setState(() => _importStatus = step);
      },
    );
    if (!mounted) return;
    setState(() => _importing = false);
    _go(_WizardStep.welcome);
  }

  // ── Guided steps ─────────────────────────────────────────────────

  Future<void> _confirmLocalEngine() async {
    final bm = _backendManager();
    if (bm.backendPath == null && !bm.isIntelMac) {
      _startDownload();
    } else {
      _go(_WizardStep.imageGen);
    }
  }

  Future<void> _confirmImageBackend() async {
    final storage = _storage;
    if (storage != null) {
      await storage.imageGenSettings.setImageGenBackend('remote');
    }
    _go(_WizardStep.contextStorage);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.72),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: AliceCard(
              padding: const EdgeInsets.all(28),
              child: _booting ? _checkingStep() : _buildStep(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case _WizardStep.dataChoice:
        return _dataChoiceStep();
      case _WizardStep.welcome:
        return _welcomeStep();
      case _WizardStep.hardware:
        return _hardwareStep();
      case _WizardStep.downloadPrompt:
        return _downloadPromptStep();
      case _WizardStep.downloadProgress:
        return _downloadProgressStep();
      case _WizardStep.textEngine:
        return _textEngineStep();
      case _WizardStep.imageGen:
        return _imageGenStep();
      case _WizardStep.contextStorage:
        return _contextStorageStep();
      case _WizardStep.done:
        return _doneStep();
    }
  }
}

/// Shared chrome for one wizard screen: title, body, one primary action,
/// one skip link. No step numbers — the flow branches, so numbering lies.
class _WizardFrame extends StatelessWidget {
  final String title;
  final Widget child;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final bool primaryBusy;
  final String? skipLabel;
  final VoidCallback? onSkip;

  const _WizardFrame({
    required this.title,
    required this.child,
    required this.primaryLabel,
    this.onPrimary,
    this.primaryBusy = false,
    this.skipLabel = 'Skip',
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        child,
        const SizedBox(height: 24),
        AliceButton(
          label: primaryLabel,
          block: true,
          onPressed: primaryBusy ? null : onPrimary,
        ),
        if (skipLabel != null && onSkip != null) ...[
          const SizedBox(height: 4),
          Center(
            child: TextButton(onPressed: onSkip, child: Text(skipLabel!)),
          ),
        ],
      ],
    );
  }
}

/// Small labeled progress row used by the download and wipe steps.
class _ProgressRow extends StatelessWidget {
  final double progress;
  final String label;

  const _ProgressRow({required this.progress, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 10,
            backgroundColor: theme.dividerColor.withValues(alpha: 0.4),
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.porchAmber),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        ),
      ],
    );
  }
}
