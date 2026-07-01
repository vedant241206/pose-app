import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../theme/app_theme.dart';
import '../services/pose_retrieval_service.dart';
import 'grid_overlay.dart';
import 'vibe_pills.dart';
import 'dynamic_silhouette_painter.dart';

class CameraPreviewArea extends StatelessWidget {
  final CameraController? controller;
  final bool isInitialized;
  final bool gridEnabled;
  final int selectedVibeIndex;
  final ValueChanged<int> onVibeSelected;
  final String currentAspectRatio;
  final String currentMode;

  // Pro mode controls state
  final double exposureOffset;
  final ValueChanged<double> onExposureChanged;
  final double zoomLevel;
  final ValueChanged<double> onZoomChanged;

  // Silhouette Overlay state
  final PoseTemplate? targetPose;
  final double alignmentScore;

  const CameraPreviewArea({
    super.key,
    required this.controller,
    required this.isInitialized,
    required this.gridEnabled,
    required this.selectedVibeIndex,
    required this.onVibeSelected,
    required this.currentAspectRatio,
    required this.currentMode,
    required this.exposureOffset,
    required this.onExposureChanged,
    required this.zoomLevel,
    required this.onZoomChanged,
    this.targetPose,
    this.alignmentScore = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    if (!isInitialized || controller == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.accent),
            SizedBox(height: 16),
            Text(
              'Initializing Camera Hardware...',
              style: TextStyle(color: AppColors.whiteMed, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxW = constraints.maxWidth;
        final double maxH = constraints.maxHeight;

        // Calculate aspect ratio double value
        double targetRatio = 4 / 3; // Default 4:3
        if (currentAspectRatio == '16:9') {
          targetRatio = 16 / 9;
        } else if (currentAspectRatio == '1:1') {
          targetRatio = 1.0;
        } else if (currentAspectRatio == 'Full') {
          targetRatio = maxW / maxH;
        }

        // Determine preview dimensions based on aspect ratio
        double previewW = maxW;
        double previewH = maxW / targetRatio;

        if (previewH > maxH) {
          previewH = maxH;
          previewW = maxH * targetRatio;
        }

        // Apply vibe filter matrix if any
        final activeMatrix = VibePills.filters[selectedVibeIndex].colorMatrix;
        Widget previewWidget = CameraPreview(controller!);

        if (activeMatrix != null) {
          previewWidget = ColorFiltered(
            colorFilter: ColorFilter.matrix(activeMatrix),
            child: previewWidget,
          );
        }

        return Container(
          color: AppColors.background,
          alignment: Alignment.center,
          child: Container(
            width: previewW,
            height: previewH,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: currentAspectRatio == 'Full' ? BorderRadius.zero : BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: currentAspectRatio == 'Full' ? BorderRadius.zero : BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Raw Camera Preview, cropped to match aspect ratio
                  _CameraCroppedPreview(
                    controller: controller!,
                    targetRatio: targetRatio,
                    child: previewWidget,
                  ),

                  // Mode Overlays (Portrait Blur Vignette, Beauty Tint, PRO Controls)
                  if (currentMode == 'PORTRAIT') _buildPortraitVignette(),
                  if (currentMode == 'BEAUTY') _buildBeautyGlowOverlay(),
                  if (currentMode == 'NIGHT') _buildNightVibeOverlay(),

                  // Silhouette Overlay
                  if (targetPose != null)
                    TweenAnimationBuilder<Color?>(
                      tween: ColorTween(
                        begin: Colors.white54,
                        end: alignmentScore >= 0.85
                            ? Colors.greenAccent
                            : Colors.white54,
                      ),
                      duration: const Duration(milliseconds: 200),
                      builder: (context, color, child) {
                        return CustomPaint(
                          painter: DynamicSilhouettePainter(
                            targetPose: targetPose!,
                            alignmentScore: alignmentScore,
                            contourColor: color ?? Colors.white54,
                          ),
                          size: Size.infinite,
                        );
                      },
                    ),

                  // 3x3 Grid Overlay
                  if (gridEnabled) const GridOverlay(),

                  // Floating Vibe Profile Pill Buttons (Upper Section)
                  Positioned(
                    top: 16,
                    left: 0,
                    right: 0,
                    child: VibePills(
                      selectedIndex: selectedVibeIndex,
                      onSelected: onVibeSelected,
                    ),
                  ),

                  // Pro Mode sliders overlay
                  if (currentMode == 'PRO')
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: _buildProControlsPanel(),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Draw portrait depth vignetting effect
  Widget _buildPortraitVignette() {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.85,
            colors: [
              AppColors.transparent,
              AppColors.background.withValues(alpha: 0.15),
              AppColors.background.withValues(alpha: 0.65),
            ],
            stops: const [0.4, 0.7, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildBeautyGlowOverlay() {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.pink.withValues(alpha: 0.04), // soft pink tint for beauty
        ),
        child: const Stack(
          children: [
            Positioned(
              top: 70,
              right: 16,
              child: Row(
                children: [
                  Icon(Icons.face_retouching_natural, color: AppColors.accent, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Smooth: On',
                    style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildNightVibeOverlay() {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.03), // soft cool dark tint
        ),
        child: const Stack(
          children: [
            Positioned(
              top: 70,
              right: 16,
              child: Row(
                children: [
                  Icon(Icons.nightlight_round, color: AppColors.accent, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Night Sight: Auto',
                    style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildProControlsPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.whiteLow, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Exposure Slider
          Row(
            children: [
              const Icon(Icons.exposure, color: AppColors.accent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: AppColors.accent,
                    inactiveTrackColor: AppColors.whiteLow,
                    thumbColor: AppColors.accent,
                    overlayColor: AppColors.accent.withValues(alpha: 0.2),
                    valueIndicatorColor: AppColors.surface,
                    valueIndicatorTextStyle: const TextStyle(color: AppColors.white),
                  ),
                  child: Slider(
                    value: exposureOffset,
                    min: -2.0,
                    max: 2.0,
                    divisions: 8,
                    label: '${exposureOffset > 0 ? "+" : ""}${exposureOffset.toStringAsFixed(1)} EV',
                    onChanged: onExposureChanged,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Zoom Slider
          Row(
            children: [
              const Icon(Icons.zoom_in, color: AppColors.accent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: AppColors.accent,
                    inactiveTrackColor: AppColors.whiteLow,
                    thumbColor: AppColors.accent,
                    overlayColor: AppColors.accent.withValues(alpha: 0.2),
                    valueIndicatorColor: AppColors.surface,
                    valueIndicatorTextStyle: const TextStyle(color: AppColors.white),
                  ),
                  child: Slider(
                    value: zoomLevel,
                    min: 1.0,
                    max: 5.0,
                    divisions: 16,
                    label: '${zoomLevel.toStringAsFixed(1)}x',
                    onChanged: onZoomChanged,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Sub-widget to properly scale and crop CameraPreview based on target aspect ratio
class _CameraCroppedPreview extends StatelessWidget {
  final CameraController controller;
  final double targetRatio;
  final Widget child;

  const _CameraCroppedPreview({
    required this.controller,
    required this.targetRatio,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Camera controller value aspect ratio is usually height/width on portrait.
    // e.g. 1920/1080 = 1.777 (16:9)
    final double cameraRatio = controller.value.aspectRatio;

    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          // We must design dimensions such that the camera stream fits perfectly
          // without stretching. Fitting it using cover inside the FittedBox solves this.
          width: 100,
          height: 100 * cameraRatio,
          child: child,
        ),
      ),
    );
  }
}
