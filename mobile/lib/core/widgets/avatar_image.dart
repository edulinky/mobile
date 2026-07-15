import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A user's photo, filling its box.
///
/// Handles the empty-URL case explicitly: a user with no photo has `photo_url:
/// ""`, and `Image.network("")` throws rather than failing gracefully — so the
/// placeholder must be chosen *before* the network widget is built, not left to
/// an errorBuilder.
class AvatarImage extends StatelessWidget {
  const AvatarImage({super.key, required this.url, this.iconSize = 80});

  final String url;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _placeholder();
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _placeholder(),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: AppColors.skyLight.withValues(alpha: 0.4),
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.skyLight,
        child: Icon(Icons.person_rounded,
            size: iconSize, color: AppColors.skyDark),
      );
}
