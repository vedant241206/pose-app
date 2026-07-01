import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ShutterButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isRecording;

  const ShutterButton({
    super.key,
    required this.onPressed,
    this.isRecording = false,
  });

  @override
  State<ShutterButton> createState() => _ShutterButtonState();
}

class _ShutterButtonState extends State<ShutterButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _animController.forward();
      },
      onTapUp: (_) {
        _animController.reverse();
        widget.onPressed();
      },
      onTapCancel: () {
        _animController.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnim.value,
            child: child,
          );
        },
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.white,
              width: 3,
            ),
          ),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: widget.isRecording ? 30 : 64,
              height: widget.isRecording ? 30 : 64,
              decoration: BoxDecoration(
                color: widget.isRecording ? AppColors.error : AppColors.white,
                shape: widget.isRecording ? BoxShape.rectangle : BoxShape.circle,
                borderRadius: widget.isRecording
                    ? BorderRadius.circular(8)
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
