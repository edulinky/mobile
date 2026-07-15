import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/full_screen_gallery.dart';
import '../data/profile_repository.dart';

/// The gallery strip on a profile: thumbnails that open full screen.
///
/// The gallery holds Storage *paths*, not URLs (so nobody can point a profile at
/// a remote image), and every path has to be resolved to a download URL. They are
/// resolved **once, together** rather than per-thumbnail: the full-screen viewer
/// needs the whole list up front to swipe through, and resolving the same paths a
/// second time when a photo is tapped would put a visible stall in front of the
/// user for something we already had.
class GallerySection extends ConsumerStatefulWidget {
  const GallerySection({super.key, required this.paths});

  final List<String> paths;

  @override
  ConsumerState<GallerySection> createState() => _GallerySectionState();
}

class _GallerySectionState extends ConsumerState<GallerySection> {
  late Future<List<String>> _urls;

  @override
  void initState() {
    super.initState();
    _urls = _resolve();
  }

  @override
  void didUpdateWidget(GallerySection old) {
    super.didUpdateWidget(old);
    // A photo added or removed while the profile is open.
    if (old.paths.join() != widget.paths.join()) {
      _urls = _resolve();
    }
  }

  Future<List<String>> _resolve() {
    final repo = ref.read(profileRepositoryProvider);
    return Future.wait(widget.paths.map(repo.galleryPhotoUrl));
  }

  static const _gap = 8.0;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _urls,
      builder: (context, snap) {
        final urls = snap.data;
        final n = widget.paths.length;

        // The mosaic: one hero photo, then pairs, with a lone trailing photo
        // going full width rather than sitting next to a hole.
        //
        //   1 photo        2 photos        5 photos
        //   ┌───────┐      ┌───┬───┐       ┌───────┐
        //   │       │      │   │   │       │       │
        //   └───────┘      └───┴───┘       ├───┬───┤
        //                                  ├───┼───┤
        //                                  └───┴───┘
        if (n == 2) {
          return Row(
            children: [
              Expanded(child: _tile(context, urls, 0, height: 150)),
              const SizedBox(width: _gap),
              Expanded(child: _tile(context, urls, 1, height: 150)),
            ],
          );
        }

        final rest = <Widget>[];
        for (int i = 1; i < n; i += 2) {
          final isLastAlone = i == n - 1;
          rest.add(const SizedBox(height: _gap));
          rest.add(
            isLastAlone
                ? _tile(context, urls, i, height: 130)
                : Row(
                    children: [
                      Expanded(child: _tile(context, urls, i, height: 130)),
                      const SizedBox(width: _gap),
                      Expanded(child: _tile(context, urls, i + 1, height: 130)),
                    ],
                  ),
          );
        }

        return Column(
          children: [
            _tile(context, urls, 0, height: n == 1 ? 220 : 190),
            ...rest,
          ],
        );
      },
    );
  }

  Widget _tile(
    BuildContext context,
    List<String>? urls,
    int i, {
    required double height,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(kGalleryTileRadius),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: urls == null
            ? const GalleryTilePlaceholder()
            : GestureDetector(
                onTap: () => openGallery(context, urls: urls, initialIndex: i),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(urls[i], fit: BoxFit.cover),
                    // A small affordance: without it, nothing says the photo
                    // does anything when you touch it.
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.fullscreen_rounded,
                            size: 13, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
