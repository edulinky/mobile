import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class StepIndicator extends StatelessWidget {
  const StepIndicator({super.key, required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final active = i + 1 == current;
        final done   = i + 1 < current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width:  active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: (active || done) ? AppColors.skyDark : AppColors.skyLight,
          ),
        );
      }),
    );
  }
}
