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

import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:front_porch_ai/services/security/verify_sha256.dart';

/// Shared plumbing for fetching a published SHA-256 and verifying a staged
/// download against it. Used by the self-update, KoboldCpp, OpenCode, and
/// Tailscale pipelines so every download→execute path fails closed the same
/// way: a missing or mismatched checksum deletes the staged file and throws.
///
/// A checksum is only ever trusted from a file published alongside the
/// release it covers (a `SHA256SUMS` manifest or a per-asset `.sha256`).
/// Hash values are never hardcoded here.
final _sha256Hex = RegExp(r'^[0-9a-fA-F]{64}$');

/// Parses one entry out of a `SHA256SUMS`-style manifest (`<hex>  <name>` or
/// `<hex> *<name>`, one entry per line). Returns null when [assetName] has no
/// entry. Name comparison is case-insensitive; a leading `*` (binary mode)
/// or `./` prefix on the manifest name is ignored.
String? parseSha256Sums(String text, String assetName) {
  final want = assetName.toLowerCase();
  for (final rawLine in text.split('\n')) {
    final line = rawLine.trim();
    if (line.isEmpty) continue;
    final parts = line.split(RegExp(r'\s+'));
    if (parts.length < 2) continue;
    if (!_sha256Hex.hasMatch(parts[0])) continue;
    var name = parts.sublist(1).join(' ').trim();
    if (name.startsWith('*')) name = name.substring(1);
    if (name.startsWith('./')) name = name.substring(2);
    if (name.toLowerCase() == want) return parts[0].toLowerCase();
  }
  return null;
}

/// Parses a single-hash `.sha256` file: either a bare hex digest or the
/// `<hex>  <filename>` form. Returns null when no 64-hex token is present.
String? parseSha256File(String text) {
  for (final token in text.split(RegExp(r'\s+'))) {
    if (_sha256Hex.hasMatch(token.trim())) return token.trim().toLowerCase();
  }
  return null;
}

/// Finds the checksum source for [assetName] in a GitHub release asset list:
/// a per-asset `<assetName>.sha256` first, else a `SHA256SUMS` manifest.
/// Returns the asset's download URL, or null when the release publishes
/// neither. Each asset is expected to carry `name` and `browser_download_url`.
String? findChecksumAssetUrl(List<dynamic> assets, String assetName) {
  String? sumsUrl;
  for (final asset in assets) {
    if (asset is! Map) continue;
    final name = asset['name'] as String?;
    final url = asset['browser_download_url'] as String?;
    if (name == null || url == null) continue;
    if (name == '$assetName.sha256') return url;
    if (name == 'SHA256SUMS') sumsUrl = url;
  }
  return sumsUrl;
}

/// Fetches the expected SHA-256 for [assetName] from a published checksum
/// source. [sumsUrl] points at a `SHA256SUMS` manifest or a per-asset
/// `.sha256` file. Returns null when there is no source, the fetch fails, or
/// the asset has no entry — every one of those is a fail-closed case for the
/// caller, never a "proceed unverified" case.
Future<String?> fetchSha256ForAsset({
  required http.Client client,
  required String? sumsUrl,
  required String assetName,
}) async {
  if (sumsUrl == null || sumsUrl.isEmpty) return null;
  try {
    final res = await client
        .get(Uri.parse(sumsUrl))
        .timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) return null;
    if (sumsUrl.toLowerCase().endsWith('.sha256')) {
      return parseSha256File(res.body);
    }
    return parseSha256Sums(res.body, assetName);
  } catch (_) {
    return null;
  }
}

/// Fetches the expected SHA-256 from a single-hash `.sha256` URL (e.g. the
/// Tailscale `...pkg.sha256` endpoint). Returns null on any failure.
Future<String?> fetchSha256FromUrl({
  required http.Client client,
  required Uri url,
}) async {
  try {
    final res = await client.get(url).timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) return null;
    return parseSha256File(res.body);
  } catch (_) {
    return null;
  }
}

/// Follows one redirect without downloading the body: GETs [url] with
/// redirects disabled and returns the `Location` target, or null when the
/// response is not a redirect or carries no target. Used to resolve a
/// `...-latest-...` alias to the versioned artifact it points at, so the
/// versioned artifact's published `.sha256` can be fetched.
Future<Uri?> resolveRedirectTarget({
  required http.Client client,
  required Uri url,
}) async {
  try {
    final request = http.Request('GET', url)..followRedirects = false;
    final response = await client
        .send(request)
        .timeout(const Duration(seconds: 30));
    await response.stream.drain<void>();
    final status = response.statusCode;
    if (status != 301 &&
        status != 302 &&
        status != 303 &&
        status != 307 &&
        status != 308) {
      return null;
    }
    final location = response.headers['location'];
    if (location == null || location.isEmpty) return null;
    return url.resolve(location);
  } catch (_) {
    return null;
  }
}

/// Verifies [file] against a checksum fetched from [sumsUrl] and deletes the
/// file + throws when verification cannot pass: no checksum source, the
/// asset has no entry, the fetch failed, or the bytes do not match. The
/// caller passes an already-open [client] when it has one; otherwise a
/// short-lived client is created. [assetLabel] names the artifact in errors.
Future<void> verifyFileAgainstChecksumSource({
  required File file,
  required String assetName,
  required String? sumsUrl,
  required String assetLabel,
  http.Client? client,
}) async {
  final owned = client == null;
  final httpClient = client ?? http.Client();
  try {
    final expected = await fetchSha256ForAsset(
      client: httpClient,
      sumsUrl: sumsUrl,
      assetName: assetName,
    );
    await VerifySha256.verifyFileOrDelete(
      file,
      expected,
      assetLabel: assetLabel,
    );
  } finally {
    if (owned) httpClient.close();
  }
}
