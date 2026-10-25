// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

part of 'alice_settings.dart';

/// Alice Image engine card: which drawing engine the app talks to and where
/// it lives. Moved here from the Image Studio — the Studio is for making
/// pictures; wiring up the engine is a Settings job.
class AliceImageEngineCard extends StatefulWidget {
  const AliceImageEngineCard({super.key});

  @override
  State<AliceImageEngineCard> createState() => _AliceImageEngineCardState();
}

class _AliceImageEngineCardState extends State<AliceImageEngineCard> {
  static const _backends = ['remote', 'native', 'a1111', 'drawthings'];
  static const _labels = ['Remote', 'Built-in', 'Automatic1111', 'Draw Things'];

  late final TextEditingController _urlController;
  String _lastBackend = '';

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  String _urlFor(String backend, dynamic settings) {
    switch (backend) {
      case 'native':
        return ''; // Built-in engine needs no address.
      case 'a1111':
        return settings.localImageGenUrl as String;
      case 'drawthings':
        return settings.drawThingsGrpcHost as String;
      default:
        return settings.imageRemoteApiUrl as String;
    }
  }

  Future<void> _saveUrl(String backend, dynamic settings, String value) {
    switch (backend) {
      case 'native':
        return Future.value(); // Nothing to save.
      case 'a1111':
        return settings.setLocalImageGenUrl(value);
      case 'drawthings':
        return settings.setDrawThingsGrpcHost(value);
      default:
        return settings.setImageRemoteApiUrl(value);
    }
  }

  String _addressLabel(String backend) {
    switch (backend) {
      case 'a1111':
        return 'Automatic1111 address';
      case 'drawthings':
        return 'Draw Things address';
      default:
        return 'Remote service address';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = Provider.of<StorageService>(context).imageGenSettings;
    final backend = settings.imageGenBackend;
    // Keep the address field in sync when the backend changes elsewhere.
    if (backend != _lastBackend) {
      _lastBackend = backend;
      _urlController.text = _urlFor(backend, settings);
    }
    return AliceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AliceSectionHead(
            title: 'Image engine',
            subtitle:
                'Which app draws your pictures and where it runs. The '
                'Image Studio shows whether it\u2019s connected.',
          ),
          const SizedBox(height: 12),
          Text(
            'Drawing app',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          AliceSegmentedControl<String>(
            values: _backends,
            labels: _labels,
            selected: backend,
            onChanged: (value) => settings.setImageGenBackend(value),
          ),
          const SizedBox(height: 12),
          if (backend != 'native') ...[
            Text(
              _addressLabel(backend),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: _urlFor(backend, settings),
                isDense: true,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check, size: 18),
                  tooltip: 'Save address',
                  onPressed: () =>
                      _saveUrl(backend, settings, _urlController.text.trim()),
                ),
              ),
              onSubmitted: (value) => _saveUrl(backend, settings, value.trim()),
            ),
            const SizedBox(height: 6),
            Text(
              'Leave the address alone unless you run the drawing app on '
              'another machine.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ] else
            Text(
              'The built-in engine runs inside Alice — no address, no server, '
              'no setup. Pick a model in the Image Studio and it just works.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
        ],
      ),
    );
  }
}
