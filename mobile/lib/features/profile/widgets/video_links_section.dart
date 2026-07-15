import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/extensions/l10n_extension.dart';
import '../../../core/theme/app_theme.dart';

/// A teacher's intro videos.
///
/// The links were written and validated server-side (`setVideoLinks`): https,
/// and YouTube or Vimeo only. That allowlist is what makes it safe to put them in
/// front of another user at all — an arbitrary URL here is a phishing surface, a
/// page dressed up as EduLinky asking for a password.
///
/// They open in the platform's video app or browser rather than an in-app
/// WebView: YouTube's embed is blocked in plain WebViews often enough to be
/// unreliable, and an intro video that silently fails to play is worse than one
/// that leaves the app to play properly.
class VideoLinksSection extends StatelessWidget {
  const VideoLinksSection({super.key, required this.links});

  final List<String> links;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: links.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) => _VideoTile(url: links[i]),
      ),
    );
  }
}

class _VideoTile extends StatelessWidget {
  const _VideoTile({required this.url});

  final String url;

  /// YouTube exposes a thumbnail at a predictable URL, so a real preview costs
  /// nothing. Vimeo does not (it needs an API call), so those get the fallback.
  String? get _youTubeThumb {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final host = uri.host.replaceFirst('www.', '');
    final id = switch (host) {
      'youtu.be' => uri.pathSegments.firstOrNull,
      'youtube.com' || 'm.youtube.com' => uri.queryParameters['v'] ??
          (uri.pathSegments.length > 1 && uri.pathSegments.first == 'embed'
              ? uri.pathSegments[1]
              : null),
      _ => null,
    };
    if (id == null || id.isEmpty) return null;
    return 'https://img.youtube.com/vi/$id/hqdefault.jpg';
  }

  Future<void> _open(BuildContext context) async {
    final uri = Uri.tryParse(url);
    final ok = uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.errOpenVideo)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final thumb = _youTubeThumb;
    return GestureDetector(
      onTap: () => _open(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 168,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (thumb != null)
                Image.network(thumb,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const _VideoFallback())
              else
                const _VideoFallback(),
              // Darken, so the play button reads on any thumbnail.
              Container(color: Colors.black.withValues(alpha: 0.25)),
              const Center(
                child: Icon(Icons.play_circle_fill_rounded,
                    size: 44, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoFallback extends StatelessWidget {
  const _VideoFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.skyLight,
      child: const Icon(Icons.videocam_rounded,
          size: 32, color: AppColors.skyDark),
    );
  }
}
