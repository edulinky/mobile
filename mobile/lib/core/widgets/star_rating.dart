import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StarRating extends StatelessWidget {
  const StarRating({super.key, required this.rating, this.size = 14});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating.floor();
        final half   = !filled && i < rating;
        return Icon(
          filled ? Icons.star_rounded : half ? Icons.star_half_rounded : Icons.star_outline_rounded,
          size: size,
          color: const Color(0xFFF59E0B),
        );
      }),
    );
  }
}

class RatingRow extends StatelessWidget {
  const RatingRow({super.key, required this.rating, required this.count, this.size = 13});

  final double rating;
  final int count;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StarRating(rating: rating, size: size),
        const SizedBox(width: 4),
        Text(
          '$rating ($count)',
          style: TextStyle(fontSize: size - 1, color: AppColors.text2, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
