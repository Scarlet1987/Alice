// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';

import 'package:front_porch_ai/services/web/tunnels/tailscale_provider.dart';

// Note: ngrok provider was removed (Tailscale-only decision, 2026-10-19).
// The NgrokProvider.parseTunnels group was deleted with it.
// (approved-test-change: Elaina, 2026-10-19)

void main() {
  group('TailscaleProvider.parseStatus', () {
    test('extracts MagicDNS name (trailing dot trimmed), IP, running', () {
      const json = '''
      {
        "BackendState": "Running",
        "Self": {
          "DNSName": "myhost.tail1234.ts.net.",
          "TailscaleIPs": ["100.101.102.103", "fd7a::1"]
        }
      }''';
      final s = TailscaleProvider.parseStatus(json);
      expect(s.running, isTrue);
      expect(s.magicDnsName, 'myhost.tail1234.ts.net');
      expect(s.ip, '100.101.102.103');
    });

    test('reports not-running when backend is stopped', () {
      const json = '{"BackendState": "Stopped", "Self": {}}';
      final s = TailscaleProvider.parseStatus(json);
      expect(s.running, isFalse);
    });

    test('garbage input is unavailable, not a throw', () {
      expect(TailscaleProvider.parseStatus('not json').running, isFalse);
    });
  });

  group('TailscaleProvider.classifyServeFailure', () {
    test('HTTPS-not-enabled messages map to httpsDisabled', () {
      const a = 'HTTPS is disabled on your tailnet; enable it in the admin '
          'console at https://login.tailscale.com/admin/dns';
      const b = 'error: HTTPS certificates are not available; enable the '
          'feature first';
      expect(TailscaleProvider.classifyServeFailure(a),
          TailscaleServeOutcome.httpsDisabled);
      expect(TailscaleProvider.classifyServeFailure(b),
          TailscaleServeOutcome.httpsDisabled);
    });

    test('unrelated errors map to failed (so we do not mis-guide the user)', () {
      const a = 'failed to connect to local tailscaled';
      const b = 'permission denied';
      expect(TailscaleProvider.classifyServeFailure(a),
          TailscaleServeOutcome.failed);
      expect(TailscaleProvider.classifyServeFailure(b),
          TailscaleServeOutcome.failed);
    });
  });
}
