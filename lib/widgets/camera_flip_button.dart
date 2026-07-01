import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CameraFlipButton extends StatefulWidget {
  final VoidCallback onFlip;

  const CameraFlipButton({super.key, required this.onFlip});

  @override
  State<CameraFlipButton> createState() => _CameraFlipButtonState();
}

class _CameraFlipButtonState extends State<CameraFlipButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _turns = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    setState(() => _turns += 0.5);
    widget.onFlip();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.white.withValues(alpha: 0.1),
          border: Border.all(
            color: AppColors.whiteHigh,
            width: 1.5,
          ),
        ),
        child: AnimatedRotation(
          turns: _turns,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: const Icon(
            Icons.flip_camera_ios_outlined,
            color: AppColors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}
