import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/pose_retrieval_service.dart';
import 'mode_carousel.dart';
import 'shutter_button.dart';
import 'gallery_thumbnail.dart';
import 'camera_flip_button.dart';
import 'pose_picker_carousel.dart';

class BottomControls extends StatelessWidget {
  final int selectedModeIndex;
  final ValueChanged<int> onModeChanged;
  final String? lastImagePath;
  final VoidCallback onGalleryTap;
  final VoidCallback onShutterPressed;
  final bool isRecording;
  final VoidCallback onFlipPressed;

  // Pose Picker Carousel state
  final List<PoseTemplate> poses;
  final PoseTemplate? selectedPose;
  final ValueChanged<PoseTemplate?> onPoseSelected;

  const BottomControls({
    super.key,
    required this.selectedModeIndex,
    required this.onModeChanged,
    required this.lastImagePath,
    required this.onGalleryTap,
    required this.onShutterPressed,
    required this.isRecording,
    required this.onFlipPressed,
    required this.poses,
    required this.selectedPose,
    required this.onPoseSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Mode Carousel
          ModeCarousel(
            selectedIndex: selectedModeIndex,
            onModeChanged: onModeChanged,
          ),
          const SizedBox(height: 16),

          // Pose Picker Carousel
          PosePickerCarousel(
            poses: poses,
            selectedPose: selectedPose,
            onPoseSelected: onPoseSelected,
          ),
          const SizedBox(height: 16),

          // Row 2: Shutter and Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Gallery Thumbnail Preview
                SizedBox(
                  width: 60,
                  height: 60,
                  child: Center(
                    child: GalleryThumbnail(
                      lastImagePath: lastImagePath,
                      onTap: onGalleryTap,
                    ),
                  ),
                ),

                // Core Shutter Button
                ShutterButton(
                  onPressed: onShutterPressed,
                  isRecording: isRecording,
                ),

                // Camera Flip Switch Button
                SizedBox(
                  width: 60,
                  height: 60,
                  child: Center(
                    child: CameraFlipButton(
                      onFlip: onFlipPressed,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
