import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'app.dart';
import 'services/pose_retrieval_service.dart';

List<CameraDescription> cameras = [];
final PoseRetrievalService poseRetrievalService = PoseRetrievalService();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Hide system UI overlays for immersive experience
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Get available cameras
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    debugPrint('Error discovering cameras: ${e.description}');
  }

  // Load pose templates from local asset bundle
  try {
    await poseRetrievalService.initialize();
    debugPrint('Loaded ${poseRetrievalService.templates.length} pose templates '
        'for scenes: ${poseRetrievalService.availableSceneTags.join(", ")}');
  } catch (e) {
    debugPrint('Failed to initialize PoseRetrievalService: $e');
  }

  runApp(PoseCameraApp(
    cameras: cameras,
    poseTemplates: poseRetrievalService.templates,
  ));
}
