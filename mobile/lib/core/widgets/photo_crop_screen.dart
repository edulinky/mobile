import 'dart:typed_data';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import '../extensions/l10n_extension.dart';

/// Full-screen photo cropper. The image is **pannable + pinch-zoomable inside a
/// FIXED frame** (Instagram/Twitter-style) — the frame stays put and the user
/// moves the picture to choose what shows.
///
/// The frame is circular for avatars and square for gallery photos: the user
/// must frame the shape they will actually see, or the corners they never
/// checked end up in the picture.
///
/// Returns the cropped image bytes via `Navigator.pop`, or null if cancelled.
class PhotoCropScreen extends StatefulWidget {
  const PhotoCropScreen({
    super.key,
    required this.imageBytes,
    this.circle = true,
    this.aspectRatio = 1,
  });

  final Uint8List imageBytes;

  /// Circular frame (avatar) vs rectangular (gallery).
  final bool circle;

  /// Frame shape. 1 = square (avatar); 3/4 = portrait, matching the discover
  /// card, so a gallery photo is never re-cropped where it is displayed.
  final double aspectRatio;

  /// Pushes the cropper and resolves to the cropped bytes (or null if cancelled).
  static Future<Uint8List?> push(
    BuildContext context,
    Uint8List bytes, {
    bool circle = true,
    double aspectRatio = 1,
  }) {
    return Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PhotoCropScreen(
          imageBytes: bytes,
          circle: circle,
          aspectRatio: aspectRatio,
        ),
      ),
    );
  }

  @override
  State<PhotoCropScreen> createState() => _PhotoCropScreenState();
}

class _PhotoCropScreenState extends State<PhotoCropScreen> {
  final _controller = CropController();
  bool _cropping = false;

  void _done() {
    setState(() => _cropping = true);
    _controller.crop(); // result delivered to onCropped below
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(context.l10n.adjustPhoto),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: _cropping ? null : () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _cropping ? null : _done,
            child: _cropping
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(context.l10n.done,
                    style: TextStyle(
                        color: Color(0xFF38BDF8),
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Crop(
              controller: _controller,
              image: widget.imageBytes,
              aspectRatio: widget.aspectRatio,
              withCircleUi: widget.circle,
              // Fill the viewport. The default leaves a wide margin, which makes
              // the frame small and the photo hard to position precisely.
              initialRectBuilder: InitialRectBuilder.withSizeAndRatio(
                size: 1,
                aspectRatio: widget.aspectRatio,
              ),
              interactive: true, // pan + pinch-zoom the image
              fixCropRect: true, // frame stays fixed; only the image moves
              baseColor: Colors.black,
              maskColor: Colors.black.withValues(alpha: 0.6),
              cornerDotBuilder: (size, edgeAlignment) => const SizedBox.shrink(),
              onCropped: (result) {
                if (!mounted) return;
                switch (result) {
                  case CropSuccess(:final croppedImage):
                    Navigator.of(context).pop(croppedImage);
                  case CropFailure():
                    setState(() => _cropping = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.l10n.errCropFailed)),
                    );
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
            child: Text(
              context.l10n.cropHint,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
