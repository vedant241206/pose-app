import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class VibeFilter {
  final String name;
  final List<double>? colorMatrix;

  const VibeFilter({required this.name, this.colorMatrix});
}

class VibePills extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const List<VibeFilter> filters = [
    VibeFilter(name: 'Normal'),
    VibeFilter(
      name: 'LinkedIn',
      colorMatrix: [
        0.9, 0.05, 0.05, 0, 0,
        0.05, 0.9, 0.1, 0, 0,
        0.1, 0.1, 1.1, 0, 10,
        0, 0, 0, 1, 0,
      ],
    ),
    VibeFilter(
      name: 'Instagram',
      colorMatrix: [
        1.2, 0.1, 0, 0, 10,
        0, 1.0, 0, 0, 0,
        0, 0, 0.8, 0, 0,
        0, 0, 0, 1, 0,
      ],
    ),
    VibeFilter(
      name: 'Wedding',
      colorMatrix: [
        1.1, 0.1, 0.1, 0, 15,
        0.05, 1.05, 0.05, 0, 10,
        0.05, 0.05, 0.95, 0, 5,
        0, 0, 0, 1, 0,
      ],
    ),
    VibeFilter(
      name: 'Portrait',
      colorMatrix: [
        1.15, 0, 0, 0, 5,
        0, 1.1, 0, 0, 5,
        0, 0, 1.05, 0, 5,
        0, 0, 0, 1, 0,
      ],
    ),
    VibeFilter(
      name: 'Vintage',
      colorMatrix: [
        0.9, 0.15, 0.1, 0, 20,
        0.1, 0.85, 0.05, 0, 10,
        0.05, 0.1, 0.7, 0, 10,
        0, 0, 0, 1, 0,
      ],
    ),
    VibeFilter(
      name: 'Cinematic',
      colorMatrix: [
        1.1, 0, 0.1, 0, 0,
        0, 1.0, 0.05, 0, 0,
        0, 0.1, 1.2, 0, 10,
        0, 0, 0, 1, 0,
      ],
    ),
    VibeFilter(
      name: 'B&W',
      colorMatrix: [
        0.33, 0.33, 0.33, 0, 0,
        0.33, 0.33, 0.33, 0, 0,
        0.33, 0.33, 0.33, 0, 0,
        0, 0, 0, 1, 0,
      ],
    ),
  ];

  const VibePills({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;
          return GestureDetector(
            onTap: () => onSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accent.withValues(alpha: 0.15)
                    : AppColors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.pillSelected : AppColors.pillBorder,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  filters[index].name,
                  style: TextStyle(
                    color: isSelected ? AppColors.pillSelected : AppColors.white,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
