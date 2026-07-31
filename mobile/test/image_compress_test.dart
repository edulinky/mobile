import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:edulink/core/storage/image_compress.dart';

Uint8List _fakePhoto(int width, int height) {
  final image = img.Image(width: width, height: height);
  // A gradient, not a flat fill — a solid color JPEG-compresses to almost
  // nothing regardless of quality, which would hide a broken quality setting.
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      image.setPixelRgb(x, y, x % 256, y % 256, (x + y) % 256);
    }
  }
  return Uint8List.fromList(img.encodeJpg(image, quality: 100));
}

void main() {
  test('downsizes an oversized photo to the max dimension', () async {
    final original = _fakePhoto(4032, 3024); // a typical phone camera photo
    final result = await compressImageForUpload(original);

    final decoded = img.decodeImage(result)!;
    expect(decoded.width, kMaxUploadDimension);
    expect(decoded.height, lessThan(decoded.width));
    // The real point of this feature: the file must actually get smaller.
    expect(result.length, lessThan(original.length));
  });

  test('leaves a photo already under the max dimension alone in size', () async {
    final original = _fakePhoto(800, 600);
    final result = await compressImageForUpload(original);

    final decoded = img.decodeImage(result)!;
    expect(decoded.width, 800);
    expect(decoded.height, 600);
  });

  test('preserves aspect ratio for a portrait photo', () async {
    final original = _fakePhoto(3024, 4032); // portrait
    final result = await compressImageForUpload(original);

    final decoded = img.decodeImage(result)!;
    expect(decoded.height, kMaxUploadDimension);
    expect(decoded.width, lessThan(decoded.height));
  });

  test('falls back to the original bytes for undecodable input', () async {
    final garbage = Uint8List.fromList([1, 2, 3, 4, 5]);
    final result = await compressImageForUpload(garbage);
    expect(result, garbage);
  });
}
