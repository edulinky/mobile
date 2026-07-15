import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A toggleable pill (subjects, filters).
///
/// Unselected pills sit on a light sky fill so they read as *buttons you can
/// press*, not as static labels — a plain white pill on the pale sky background
/// has almost no edge. Selected pills invert to the solid brand colour.
class SelectableChip extends StatelessWidget {
  const SelectableChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.skyDark
              : AppColors.skyLight.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.text2,
          ),
        ),
      ),
    );
  }
}
