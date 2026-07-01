import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../theme/app_theme.dart';

class TopBar extends StatelessWidget {
  final VoidCallback onSettingsPressed;
  final FlashMode currentFlashMode;
  final ValueChanged<FlashMode> onFlashModeChanged;
  final bool hdrEnabled;
  final ValueChanged<bool> onHdrChanged;
  final String currentAspectRatio;
  final ValueChanged<String> onAspectRatioChanged;

  const TopBar({
    super.key,
    required this.onSettingsPressed,
    required this.currentFlashMode,
    required this.onFlashModeChanged,
    required this.hdrEnabled,
    required this.onHdrChanged,
    required this.currentAspectRatio,
    required this.onAspectRatioChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Settings Button
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              color: AppColors.white,
              onPressed: onSettingsPressed,
              tooltip: 'Settings',
            ),

            // Flash Button
            IconButton(
              icon: Icon(_getFlashIcon()),
              color: currentFlashMode == FlashMode.off
                  ? AppColors.whiteMed
                  : AppColors.accent,
              onPressed: () {
                final nextMode = _getNextFlashMode();
                onFlashModeChanged(nextMode);
              },
              tooltip: 'Flash Mode',
            ),

            // HDR Toggle Button
            GestureDetector(
              onTap: () => onHdrChanged(!hdrEnabled),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: hdrEnabled ? AppColors.accent : AppColors.whiteLow,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'HDR',
                  style: TextStyle(
                    color: hdrEnabled ? AppColors.accent : AppColors.whiteMed,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Aspect Ratio Button
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                side: const BorderSide(color: AppColors.whiteLow, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              onPressed: () {
                final nextRatio = _getNextAspectRatio();
                onAspectRatioChanged(nextRatio);
              },
              child: Text(
                currentAspectRatio,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFlashIcon() {
    switch (currentFlashMode) {
      case FlashMode.off:
        return Icons.flash_off_outlined;
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.torch:
        return Icons.flashlight_on;
      case FlashMode.auto:
        return Icons.flash_auto;
    }
  }

  FlashMode _getNextFlashMode() {
    switch (currentFlashMode) {
      case FlashMode.off:
        return FlashMode.auto;
      case FlashMode.auto:
        return FlashMode.always;
      case FlashMode.always:
        return FlashMode.torch;
      case FlashMode.torch:
        return FlashMode.off;
    }
  }

  String _getNextAspectRatio() {
    switch (currentAspectRatio) {
      case '4:3':
        return '16:9';
      case '16:9':
        return '1:1';
      case '1:1':
        return 'Full';
      case 'Full':
      default:
        return '4:3';
    }
  }
}
