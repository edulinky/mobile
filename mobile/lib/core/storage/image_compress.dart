import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Max width/height an uploaded photo is resized to. 1440px is sharp on any
/// phone screen — including the gallery's pinch-zoom viewer — while being a
/// fraction of what a modern camera shoots: a 4032×3024 iPhone photo is
/// typically several MB; resized and re-encoded it lands under ~300KB, which
/// is what actually moves the needle on load times, not the JPEG quality knob.
const int kMaxUploadDimension = 1440;

/// JPEG quality after resize. 82 is the standard "visually lossless enough"
/// point for a photo — most people cannot tell it apart from 100 in a blind
/// comparison, and it is roughly a third of the file size.
const int kUploadJpegQuality = 82;

/// Resizes (if needed) and re-encodes as JPEG, off the UI isolate so a big
/// camera photo does not jank whatever spinner is already covering the upload.
///
/// Falls back to the original bytes if decoding fails — a compression bug
/// must never block an upload; a slightly larger file beats no photo at all.
Future<Uint8List> compressImageForUpload(
  Uint8List bytes, {
  int maxDimension = kMaxUploadDimension,
  int quality = kUploadJpegQuality,
}) {
  return compute(_compress, (bytes, maxDimension, quality));
}

Uint8List _compress((Uint8List, int, int) args) {
  final (bytes, maxDimension, quality) = args;
  try {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;

    final needsResize =
        decoded.width > maxDimension || decoded.height > maxDimension;
    final resized = needsResize
        ? img.copyResize(
            decoded,
            width: decoded.width >= decoded.height ? maxDimension : null,
            height: decoded.height > decoded.width ? maxDimension : null,
          )
        : decoded;

    return Uint8List.fromList(img.encodeJpg(resized, quality: quality));
  } catch (_) {
    return bytes;
  }
}
