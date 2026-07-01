import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GalleryThumbnail extends StatelessWidget {
  final String? lastImagePath;
  final VoidCallback? onTap;

  const GalleryThumbnail({
    super.key,
    this.lastImagePath,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.whiteHigh,
            width: 2,
          ),
        ),
        child: ClipOval(
          child: lastImagePath != null
              ? Image.file(
                  File(lastImagePath!),
                  fit: BoxFit.cover,
                  width: 50,
                  height: 50,
                  errorBuilder: (_, __, ___) => _emptyPlaceholder(),
                )
              : _emptyPlaceholder(),
        ),
      ),
    );
  }

  Widget _emptyPlaceholder() {
    return Container(
      color: AppColors.surface,
      child: const Center(
        child: Icon(
          Icons.photo_outlined,
          color: AppColors.whiteLow,
          size: 20,
        ),
      ),
    );
  }
}
