import 'package:flutter/material.dart';
import '../services/pose_retrieval_service.dart';
import '../theme/app_theme.dart';

/// Horizontally scrolling carousel of pose template categories.
///
/// Rendered directly above the shutter button so the user can manually select
/// a target pose for the silhouette overlay. The first item is always an
/// "Off" toggle to deactivate the overlay.
class PosePickerCarousel extends StatelessWidget {
  final List<PoseTemplate> poses;
  final PoseTemplate? selectedPose;
  final ValueChanged<PoseTemplate?> onPoseSelected;

  const PosePickerCarousel({
    super.key,
    required this.poses,
    required this.selectedPose,
    required this.onPoseSelected,
  });

  /// Maps a scene tag to a representative Material icon.
  static IconData _iconForTag(String tag) {
    switch (tag.toLowerCase()) {
      case 'linkedin':
        return Icons.business_center;
      case 'insta_casual':
        return Icons.camera_alt;
      case 'architecture':
        return Icons.architecture;
      case 'power':
        return Icons.bolt;
      case 'street':
        return Icons.directions_walk;
      case 'elegant':
        return Icons.accessibility_new;
      default:
        return Icons.person_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: poses.length + 1, // +1 for the "Off" toggle
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _PosePill(
              label: 'Off',
              icon: Icons.close_rounded,
              isSelected: selectedPose == null,
              onTap: () => onPoseSelected(null),
            );
          }
          final pose = poses[index - 1];
          final isSelected = selectedPose?.poseId == pose.poseId;
          return _PosePill(
            label: pose.displayName,
            icon: _iconForTag(pose.sceneTag),
            isSelected: isSelected,
            onTap: () => onPoseSelected(pose),
          );
        },
      ),
    );
  }
}

/// A single selectable pill chip for the pose picker.
class _PosePill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PosePill({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.whiteLow,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? AppColors.accent : AppColors.whiteMed,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.accent : AppColors.whiteMed,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
