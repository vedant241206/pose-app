import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'services/pose_retrieval_service.dart';
import 'theme/app_theme.dart';
import 'screens/camera_screen.dart';

class PoseCameraApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  final List<PoseTemplate> poseTemplates;

  const PoseCameraApp({
    super.key,
    required this.cameras,
    required this.poseTemplates,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pose Camera',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: CameraScreen(
        cameras: cameras,
        poseTemplates: poseTemplates,
      ),
    );
  }
}
