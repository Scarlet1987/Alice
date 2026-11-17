// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import 'expression_pack_base_check.dart';
import 'expression_pack_jpeg_check.dart';

/// How long a JPEG or WebP may take to become a PNG before the work is
/// stopped (a decode of a large photo in pure Dart takes several seconds).
const Duration kPackConvertTimeout = Duration(seconds: 8);

/// The most bytes of a JPEG or WebP that are taken for conversion.
const int kMaxConvertBytes = 48 * 1024 * 1024;

/// The long side the converted PNG is brought down to. A pack base is
/// brought to 768 anyway, so nothing that matters is lost, and the PNG stays
/// small to encode, check and send.
const int kConvertedLongSide = 1536;

/// What kind of picture [raw] says it is, from its first bytes.
enum PackPictureKind { png, jpeg, webp, other }

PackPictureKind packPictureKind(Uint8List raw) {
  if (raw.length > 8 &&
      raw[0] == 137 &&
      raw[1] == 80 &&
      raw[2] == 78 &&
      raw[3] == 71 &&
      raw[4] == 13 &&
      raw[5] == 10 &&
      raw[6] == 26 &&
      raw[7] == 10) {
    return PackPictureKind.png;
  }
  if (raw.length > 3 && raw[0] == 0xFF && raw[1] == 0xD8 && raw[2] == 0xFF) {
    return PackPictureKind.jpeg;
  }
  if (raw.length > 12 &&
      String.fromCharCodes(raw, 0, 4) == 'RIFF' &&
      String.fromCharCodes(raw, 8, 12) == 'WEBP') {
    return PackPictureKind.webp;
  }
  return PackPictureKind.other;
}

const _notPicture = PackBaseRefusal(
  'That file could not be read as a picture. Please use a PNG picture.',
);
const _animated = PackBaseRefusal(
  'That picture is animated. Please use a PNG, JPEG or still WebP picture.',
);
const _tookTooLong = PackBaseRefusal(
  'That picture took too long to convert. Please use a PNG picture.',
);

/// A JPEG or WebP made into a PNG, or why it was not.
class PackConversion {
  const PackConversion.png(Uint8List this.png) : refusal = null;
  const PackConversion.refused(PackBaseRefusal this.refusal) : png = null;

  final Uint8List? png;
  final PackBaseRefusal? refusal;
}

/// Turns a JPEG or a still WebP into a PNG, in this isolate. What is done
/// before a decoder allocates is what keeps this bounded: a JPEG is walked
/// strictly ([checkJpeg]), and a WebP has its own header read by the same code
/// that will decode it, and both are refused over [kMaxPackBasePixels]. A
/// picture that is animated, of another kind or broken is refused. Prefer
/// [convertPackBase], which does this where it can be stopped.
PackConversion convertPackBaseNow(Uint8List raw) {
  try {
    final kind = packPictureKind(raw);
    if (kind == PackPictureKind.jpeg) {
      final checked = checkJpeg(raw);
      return _finish(img.JpegDecoder().decode(checked.bytes));
    }
    if (kind == PackPictureKind.webp) return _webp(raw);
    return const PackConversion.refused(_notPicture);
  } on PackPictureRefused catch (e) {
    return PackConversion.refused(e.refusal);
  } catch (e) {
    debugPrint('[ExpressionPack] picture could not be converted: $e');
    return const PackConversion.refused(_notPicture);
  }
}

PackConversion _webp(Uint8List raw) {
  // The picture size is read from the RIFF chunks first, before any
  // decoder allocates: a lossy VP8 chunk carries its size in 16 bits a
  // side (only 14 are the size in the format — the top two are a scale,
  // and the decoder reads all 16), and a file can carry a small chunk
  // followed by a huge one. Any chunk over budget is refused as too
  // large here, with the size as written.
  _budgetWebpChunks(raw);
  final decoder = img.WebPDecoder();
  final info = decoder.startDecode(raw);
  if (info == null) return const PackConversion.refused(_notPicture);
  if (info.hasAnimation || info.format == img.WebPFormat.animated) {
    return const PackConversion.refused(_animated);
  }
  if (info.format != img.WebPFormat.lossy &&
      info.format != img.WebPFormat.lossless) {
    return const PackConversion.refused(_notPicture);
  }
  _budget(info.width, info.height);
  return _finish(decoder.decodeFrame(0));
}

/// Every size a WebP decoder might allocate for, read from the RIFF chunks:
/// the VP8X canvas, each lossy VP8 frame's raw 16-bit size, and each
/// lossless VP8L picture's size. A truncated chunk stops the walk and
/// leaves the file to the decoder, which refuses it as not a picture.
void _budgetWebpChunks(Uint8List raw) {
  var pos = 12;
  while (pos + 8 <= raw.length) {
    final type = String.fromCharCodes(raw, pos, pos + 4);
    final size = _u32(raw, pos + 4);
    final data = pos + 8;
    if (data + size > raw.length) break;
    if (type == 'VP8X' && size >= 10) {
      _budget(_u24(raw, data + 4) + 1, _u24(raw, data + 7) + 1);
    } else if (type == 'VP8 ' && size >= 10) {
      // A real lossy frame starts with its start code; anything else is
      // not a frame header, and the decoder will say so.
      if (raw[data + 3] == 0x9D &&
          raw[data + 4] == 0x01 &&
          raw[data + 5] == 0x2A) {
        _budget(_u16(raw, data + 6), _u16(raw, data + 8));
      }
    } else if (type == 'VP8L' && size >= 5 && raw[data] == 0x2F) {
      final packed = _u32(raw, data + 1);
      _budget((packed & 0x3FFF) + 1, ((packed >> 14) & 0x3FFF) + 1);
    }
    pos = data + size + (size.isOdd ? 1 : 0);
  }
}

int _u16(Uint8List raw, int at) => raw[at] | (raw[at + 1] << 8);

int _u24(Uint8List raw, int at) =>
    raw[at] | (raw[at + 1] << 8) | (raw[at + 2] << 16);

int _u32(Uint8List raw, int at) =>
    raw[at] |
    (raw[at + 1] << 8) |
    (raw[at + 2] << 16) |
    (raw[at + 3] << 24);

void _budget(int width, int height) {
  if (width <= 0 || height <= 0) {
    throw const PackPictureRefused(_notPicture);
  }
  if (width * height > kMaxPackBasePixels) {
    throw PackPictureRefused(packBaseTooLarge(width, height));
  }
}

PackConversion _finish(img.Image? decoded) {
  if (decoded == null) return const PackConversion.refused(_notPicture);
  _budget(decoded.width, decoded.height);
  final long = decoded.width > decoded.height ? decoded.width : decoded.height;
  final image = long <= kConvertedLongSide
      ? decoded
      : img.copyResize(
          decoded,
          width: decoded.width >= decoded.height ? kConvertedLongSide : null,
          height: decoded.height > decoded.width ? kConvertedLongSide : null,
          interpolation: img.Interpolation.average,
        );
  return PackConversion.png(img.encodePng(image, level: 1));
}

/// What an isolate is given to convert, and where to answer.
class PackConvertJob {
  const PackConvertJob(this.raw, this.reply);

  final Uint8List raw;
  final SendPort reply;
}

typedef PackConvertEntry = void Function(PackConvertJob job);

/// The isolate's entry: converts and answers `[png, message, tooLarge]`.
void packConvertEntry(PackConvertJob job) {
  final done = convertPackBaseNow(job.raw);
  job.reply.send([
    done.png,
    done.refusal?.message,
    done.refusal?.tooLarge ?? false,
  ]);
}

PackConversion _answer(Object? message) {
  if (message is List && message.length == 3) {
    final png = message[0];
    if (png is Uint8List) return PackConversion.png(png);
    return PackConversion.refused(
      PackBaseRefusal(
        message[1] as String? ?? _notPicture.message,
        tooLarge: message[2] == true,
      ),
    );
  }
  return const PackConversion.refused(_notPicture);
}

/// Turns a JPEG or a still WebP into a PNG in an isolate of its own, killed
/// if it has not answered within [timeout]. A timeout, a crash or a decode
/// that fails is a refusal (400); a picture over the pixel budget is
/// [PackBaseRefusal.tooLarge] (413). Nothing is written anywhere: the PNG is
/// returned and it is the only copy.
///
/// One conversion runs at a time in this process (a decode can take most of a
/// gigabyte, and this runs before a pack's own lock); others wait their turn,
/// and the timeout counts from when their isolate starts.
///
/// [entry] and [onSpawn] are for tests.
Future<PackConversion> convertPackBase(
  Uint8List raw, {
  Duration timeout = kPackConvertTimeout,
  @visibleForTesting PackConvertEntry entry = packConvertEntry,
  @visibleForTesting void Function(Isolate isolate)? onSpawn,
}) {
  final previous = _turn;
  // The turn is shared by everything in the process, so it belongs to no
  // zone that may end (a test's) before the next caller takes its turn.
  final done = Zone.root.run(() => Completer<void>());
  _turn = done.future;
  return previous
      .then((_) => _convert(raw, timeout, entry, onSpawn))
      .whenComplete(done.complete);
}

Future<void> _turn = Future<void>.value();

Future<PackConversion> _convert(
  Uint8List raw,
  Duration timeout,
  PackConvertEntry entry,
  void Function(Isolate isolate)? onSpawn,
) async {
  if (raw.length > kMaxConvertBytes) {
    return const PackConversion.refused(
      PackBaseRefusal(
        'That file is too large to convert. Please use a PNG picture.',
        tooLarge: true,
      ),
    );
  }
  final reply = ReceivePort();
  final failed = ReceivePort();
  final exited = ReceivePort();
  final answer = Completer<PackConversion>();
  void settle(PackConversion c) {
    if (!answer.isCompleted) answer.complete(c);
  }

  reply.listen((m) => settle(_answer(m)));
  failed.listen((_) => settle(const PackConversion.refused(_notPicture)));
  exited.listen((_) => settle(const PackConversion.refused(_notPicture)));
  Isolate? isolate;
  try {
    isolate = await Isolate.spawn(
      entry,
      PackConvertJob(raw, reply.sendPort),
      errorsAreFatal: true,
      onError: failed.sendPort,
      onExit: exited.sendPort,
    );
    onSpawn?.call(isolate);
    return await answer.future.timeout(
      timeout,
      onTimeout: () => const PackConversion.refused(_tookTooLong),
    );
  } catch (e) {
    debugPrint('[ExpressionPack] picture conversion failed: $e');
    return const PackConversion.refused(_notPicture);
  } finally {
    isolate?.kill(priority: Isolate.immediate);
    reply.close();
    failed.close();
    exited.close();
  }
}
