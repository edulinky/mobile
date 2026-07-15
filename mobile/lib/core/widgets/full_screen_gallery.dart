import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Full-screen photo viewer: swipe left/right through the gallery, pinch to zoom.
///
/// Opened from a thumbnail, starting on the one that was tapped — a viewer that
/// always started at photo 1 would make the thumbnails decorative.
class FullScreenGallery extends StatefulWidget {
  const FullScreenGallery({
    super.key,
    required this.urls,
    this.initialIndex = 0,
  });

  final List<String> urls;
  final int initialIndex;

  @override
  State<FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<FullScreenGallery> {
  late final PageController _pages =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pages,
            itemCount: widget.urls.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) => InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(
                child: Image.network(
                  widget.urls[i],
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : const Center(
                          child: CircularProgressIndicator(color: Colors.white)),
                  errorBuilder: (_, _, _) => const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white38,
                      size: 48),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  if (widget.urls.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${_index + 1} / ${widget.urls.length}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dots under the thumbnails are not worth it, but a hint that a photo opens is.
const kGalleryTileRadius = 14.0;

Future<void> openGallery(
  BuildContext context, {
  required List<String> urls,
  required int initialIndex,
}) {
  if (urls.isEmpty) return Future.value();
  return Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => FullScreenGallery(urls: urls, initialIndex: initialIndex),
    ),
  );
}

/// Placeholder shown while a Storage path is still resolving to a URL.
class GalleryTilePlaceholder extends StatelessWidget {
  const GalleryTilePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(color: AppColors.skyLight.withValues(alpha: 0.4));
  }
}
