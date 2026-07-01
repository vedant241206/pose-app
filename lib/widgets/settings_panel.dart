import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../theme/app_theme.dart';

class SettingsPanel extends StatelessWidget {
  final bool gridEnabled;
  final ValueChanged<bool> onGridChanged;
  final bool audioEnabled;
  final ValueChanged<bool> onAudioChanged;
  final ResolutionPreset selectedPreset;
  final ValueChanged<ResolutionPreset> onPresetChanged;
  final bool mirrorFrontCamera;
  final ValueChanged<bool> onMirrorFrontCameraChanged;

  const SettingsPanel({
    super.key,
    required this.gridEnabled,
    required this.onGridChanged,
    required this.audioEnabled,
    required this.onAudioChanged,
    required this.selectedPreset,
    required this.onPresetChanged,
    required this.mirrorFrontCamera,
    required this.onMirrorFrontCameraChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.whiteLow,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Camera Settings',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Settings items
            _buildSwitchItem(
              icon: Icons.grid_on_outlined,
              title: '3x3 Grid Overlay',
              subtitle: 'Show grid lines on preview',
              value: gridEnabled,
              onChanged: onGridChanged,
            ),
            const Divider(color: AppColors.whiteLow, height: 20),

            _buildSwitchItem(
              icon: Icons.volume_up_outlined,
              title: 'Record Audio',
              subtitle: 'Enable microphone for videos',
              value: audioEnabled,
              onChanged: onAudioChanged,
            ),
            const Divider(color: AppColors.whiteLow, height: 20),

            _buildSwitchItem(
              icon: Icons.flip_camera_android_outlined,
              title: 'Mirror Front Camera',
              subtitle: 'Save selfies as displayed in preview',
              value: mirrorFrontCamera,
              onChanged: onMirrorFrontCameraChanged,
            ),
            const Divider(color: AppColors.whiteLow, height: 20),

            // Resolution Preset
            Row(
              children: [
                const Icon(Icons.slow_motion_video_outlined, color: AppColors.whiteHigh),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resolution Preset',
                        style: TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Select default video/photo quality',
                        style: TextStyle(color: AppColors.whiteMed, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                DropdownButton<ResolutionPreset>(
                  value: selectedPreset,
                  dropdownColor: AppColors.surface,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.arrow_drop_down, color: AppColors.accent),
                  style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
                  onChanged: (value) {
                    if (value != null) {
                      onPresetChanged(value);
                    }
                  },
                  items: ResolutionPreset.values.map((preset) {
                    return DropdownMenuItem<ResolutionPreset>(
                      value: preset,
                      child: Text(preset.name.toUpperCase()),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.whiteHigh),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              Text(
                subtitle,
                style: TextStyle(color: AppColors.whiteMed, fontSize: 12),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.accent,
          activeTrackColor: AppColors.accent.withValues(alpha: 0.3),
        ),
      ],
    );
  }
}
