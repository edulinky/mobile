import 'package:flutter/material.dart';
import '../../features/discover/models/teacher_card_model.dart';
import '../../core/extensions/l10n_extension.dart';

class BadgeChip extends StatelessWidget {
  const BadgeChip({super.key, required this.status, this.isFeatured = false});

  final VerifiedStatus status;
  final bool isFeatured;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (isFeatured) {
      return _chip(Icons.star_rounded, l10n.featuredBadge, const Color(0xFFF59E0B), const Color(0xFFFEF3C7));
    }
    return switch (status) {
      VerifiedStatus.verified   => _chip(Icons.verified_rounded,    l10n.verifiedBadge,  const Color(0xFF0EA5E9), const Color(0xFFE0F2FE)),
      VerifiedStatus.pending    => _chip(Icons.hourglass_top_rounded, l10n.pendingBadge,  const Color(0xFFD97706), const Color(0xFFFEF3C7)),
      VerifiedStatus.unverified => const SizedBox.shrink(),
    };
  }

  Widget _chip(IconData icon, String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
