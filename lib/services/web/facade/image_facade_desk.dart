// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

part of 'image_facade.dart';

/// A request to the phone desk that is refused, with a stable [code] and
/// words for the person. Nothing has been changed when this is thrown.
class DeskRefused implements Exception {
  const DeskRefused(this.code, this.message, [this.status = 400]);

  final String code;
  final String message;
  final int status;

  @override
  String toString() => 'DeskRefused($code)';
}

/// The most a graph file, or a picture to edit, may weigh.
const int kMaxDeskGraphBytes = 8 * 1024 * 1024;
const int kMaxDeskPictureBytes = 12 * 1024 * 1024;

/// Whether a config write would store a ComfyUI graph the caller supplied.
/// A graph is what Comfy runs on this computer, so it is credential-grade.
bool imageConfigUploadsGraph(Map<String, dynamic> body) {
  for (final key in [
    'comfyCreateUploadedWorkflow',
    'comfyEditUploadedWorkflow',
  ]) {
    final value = body[key];
    if (value is String && value.trim().isNotEmpty) return true;
  }
  return false;
}

/// Obsolete: the native backend has no workflow graphs.
String checkedDeskGraph(String raw) {
  throw const DeskRefused('no_graphs', 'The built-in engine has no graphs.');
}

extension ImageStudioDesk on ImageFacade {
  ImageGenSettings get _s => _storage.imageGenSettings;

  /// Picks the primary model, the way the desktop desk does. A saved,
  /// template or legacy Comfy graph keeps its graph and takes the file in its
  /// own slot. A bundled graph follows the file's family, except that a file
  /// of no known family stays on the graph it was chosen on.
  Future<void> pickModel({required bool edit, required String file}) async {
    requireIdleImageSettings();
    final before = ImageModelFamily.detectFromName(
      studioPrimaryFor(_s, edit: edit),
    );
    await _pickModel(edit: edit, file: file);
    final after = ImageModelFamily.detectFromName(
      studioPrimaryFor(_s, edit: edit),
    );
    // "Use anyway" belongs to the model it was pressed for: it is dropped when
    // the model changes to another family.
    final key = _s.k('image_studio_lora_override_family');
    final override = _s.prefs?.getString(key) ?? '';
    if (before != after && override.isNotEmpty && override != after.name) {
      requireIdleImageSettings();
      await _s.prefs?.remove(key);
      _s.notify();
    }
  }

  Future<void> _pickModel({required bool edit, required String file}) async {
    requireIdleImageSettings();
    final name = _cleanName(file);
    if (_s.imageGenBackend == 'remote') {
      await _s.setRemoteImageModelFor(_s.imageRemoteApiUrl, name, edit: edit);
      requireIdleImageSettings();
      await (edit ? _s.setImageGenEditModel(name) : _s.setImageGenModel(name));
      return;
    }
    // Native backend (and others): pick the model file directly.
    await (edit ? _s.setImageGenEditModel(name) : _s.setImageGenModel(name));
  }

  /// Obsolete: the native backend has no graphs to pick.
  Future<void> pickGraph({required bool edit, required String id}) async {
    requireIdleImageSettings();
    throw const DeskRefused(
      'no_graphs',
      'The built-in engine has no graphs — pick a model directly.',
    );
  }

  /// Obsolete: the native backend has no model slots.
  Future<void> pickSupport({
    required bool edit,
    required String token,
    required String file,
  }) async {
    requireIdleImageSettings();
    throw const DeskRefused(
      'no_slots',
      'The built-in engine has no model slots.',
    );
  }

  String _cleanName(String value) {
    final name = value.trim();
    if (name.isEmpty ||
        name.length > 300 ||
        name.contains(RegExp(r'[\x00-\x1f]'))) {
      throw const DeskRefused('bad_request', 'That name is not usable.');
    }
    return name;
  }

  /// Stores a graph file the phone sent (`.json`, or a PNG Comfy saved).
  ///
  /// Nothing is stored when the file is not a graph, is too large, or is
  /// meant for the other mode and [useFor] does not say which mode to use it
  /// for. [edit] is the mode the desk is on. The answer says which mode the
  /// graph is for (`create`, `edit` or `unstated`) and whether it was stored.
  /// Obsolete: the native backend has no workflow graphs to store.
  Future<Map<String, dynamic>> saveGraphFile({
    required List<int> bytes,
    required String name,
    required bool edit,
    String? useFor,
  }) async {
    requireIdleImageSettings();
    throw const DeskRefused(
      'no_graphs',
      'The built-in engine has no graphs — workflow upload is not supported.',
    );
  }

  /// The picture an Edit works on, or a Create varies: a picture this app
  /// saved (by file name) or one the phone sent (a data URL).
  Future<Uint8List?> _reference(Map<String, dynamic> f) async {
    final saved = f['referenceFilename']?.toString() ?? '';
    final sent = f['referenceImage']?.toString() ?? '';
    Uint8List? bytes;
    if (saved.isNotEmpty) {
      final file = savedImageFile(saved);
      if (file == null) {
        throw const DeskRefused('no_picture', 'That picture is gone.', 404);
      }
      if (file.lengthSync() > kMaxDeskPictureBytes) {
        throw const DeskRefused('too_large', 'That picture is too large.', 413);
      }
      bytes = await file.readAsBytes();
    } else if (sent.isNotEmpty) {
      final comma = sent.indexOf(',');
      final head = comma < 0 ? '' : sent.substring(0, comma);
      if (!head.startsWith('data:image/') || !head.endsWith(';base64')) {
        throw const DeskRefused('bad_picture', 'That is not a picture.');
      }
      if (sent.length - comma > kMaxDeskPictureBytes * 4 ~/ 3 + 8) {
        throw const DeskRefused('too_large', 'That picture is too large.', 413);
      }
      try {
        bytes = base64Decode(sent.substring(comma + 1));
      } on FormatException {
        throw const DeskRefused('bad_picture', 'That is not a picture.');
      }
    }
    if (bytes != null && !_looksLikeImage(bytes)) {
      throw const DeskRefused('bad_picture', 'That is not a picture.');
    }
    return bytes;
  }

  bool _looksLikeImage(List<int> b) {
    if (b.length < 12) return false;
    final png = b[0] == 137 && b[1] == 80 && b[2] == 78 && b[3] == 71;
    final jpeg = b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF;
    final webp = b[0] == 0x52 && b[1] == 0x49 && b[8] == 0x57 && b[9] == 0x45;
    return png || jpeg || webp;
  }
}
