import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// A detected pose with keypoints normalised to 0.0–1.0 display coordinates.
class NormalizedPose {
  /// Map of COCO keypoint name → normalised (x, y) offset.
  final Map<String, Offset> keypoints;

  /// Average landmark detection confidence (0.0–1.0).
  final double confidence;

  const NormalizedPose({required this.keypoints, required this.confidence});
}

/// Service that processes camera image stream frames through Google ML Kit
/// Pose Detection and emits [NormalizedPose] results.
///
/// Usage:
/// ```dart
/// final service = PoseDetectionService();
/// controller.startImageStream((image) async {
///   final pose = await service.processFrame(image, camera);
///   if (pose != null) { /* use pose */ }
/// });
/// service.dispose();
/// ```
class PoseDetectionService {
  late final PoseDetector _poseDetector;
  bool _isBusy = false;
  DateTime _lastProcessed = DateTime.fromMillisecondsSinceEpoch(0);

  /// Minimum interval between processed frames to avoid ML pipeline saturation.
  static const Duration _throttleDuration = Duration(milliseconds: 100);

  /// Mapping from ML Kit landmark types to COCO string identifiers.
  static const Map<PoseLandmarkType, String> _landmarkMapping = {
    PoseLandmarkType.nose: 'nose',
    PoseLandmarkType.leftEye: 'left_eye',
    PoseLandmarkType.rightEye: 'right_eye',
    PoseLandmarkType.leftEar: 'left_ear',
    PoseLandmarkType.rightEar: 'right_ear',
    PoseLandmarkType.leftShoulder: 'left_shoulder',
    PoseLandmarkType.rightShoulder: 'right_shoulder',
    PoseLandmarkType.leftElbow: 'left_elbow',
    PoseLandmarkType.rightElbow: 'right_elbow',
    PoseLandmarkType.leftWrist: 'left_wrist',
    PoseLandmarkType.rightWrist: 'right_wrist',
    PoseLandmarkType.leftHip: 'left_hip',
    PoseLandmarkType.rightHip: 'right_hip',
    PoseLandmarkType.leftKnee: 'left_knee',
    PoseLandmarkType.rightKnee: 'right_knee',
    PoseLandmarkType.leftAnkle: 'left_ankle',
    PoseLandmarkType.rightAnkle: 'right_ankle',
  };

  PoseDetectionService() {
    final options = PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.base,
    );
    _poseDetector = PoseDetector(options: options);
  }

  /// Processes a single camera frame for pose detection.
  ///
  /// Returns a [NormalizedPose] with display-oriented coordinates in 0.0–1.0,
  /// or `null` if detection fails, is throttled, or yields no person.
  Future<NormalizedPose?> processFrame(
    CameraImage image,
    CameraDescription camera,
  ) async {
    // ── Throttle gate ────────────────────────────────────────────────
    if (_isBusy) return null;
    final now = DateTime.now();
    if (now.difference(_lastProcessed) < _throttleDuration) return null;

    _isBusy = true;
    _lastProcessed = now;

    try {
      final inputImage = _convertToInputImage(image, camera);
      if (inputImage == null) {
        _isBusy = false;
        return null;
      }

      final poses = await _poseDetector.processImage(inputImage);
      _isBusy = false;

      if (poses.isEmpty) return null;
      return _normalizePose(poses.first, image, camera);
    } catch (e) {
      _isBusy = false;
      debugPrint('PoseDetectionService error: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // Private helpers
  // ─────────────────────────────────────────────────────────────────────

  /// Converts a [CameraImage] to an ML Kit [InputImage].
  ///
  /// Android delivers NV21 planes; iOS delivers BGRA8888.
  InputImage? _convertToInputImage(
    CameraImage image,
    CameraDescription camera,
  ) {
    final rotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    // Concatenate all plane bytes into a contiguous buffer
    final allBytes = WriteBuffer();
    for (final plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  /// Normalises ML Kit pose landmarks to 0.0–1.0 **display** coordinates.
  ///
  /// ML Kit returns coordinates in the raw image coordinate system.
  /// This method applies sensor rotation correction so that the normalised
  /// values correspond to the upright camera preview orientation.
  /// For the front camera the x-axis is also mirrored to match the
  /// mirrored preview the user sees on screen.
  NormalizedPose _normalizePose(
    Pose pose,
    CameraImage image,
    CameraDescription camera,
  ) {
    final Map<String, Offset> keypoints = {};
    double totalLikelihood = 0;
    int count = 0;

    final rotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
            InputImageRotation.rotation0deg;
    final isFront = camera.lensDirection == CameraLensDirection.front;
    final imgW = image.width.toDouble();
    final imgH = image.height.toDouble();

    for (final entry in _landmarkMapping.entries) {
      final landmark = pose.landmarks[entry.key];
      if (landmark == null) continue;

      double nx, ny;

      // Transform from raw-image coords → display-oriented normalised coords
      switch (rotation) {
        case InputImageRotation.rotation0deg:
          nx = landmark.x / imgW;
          ny = landmark.y / imgH;
        case InputImageRotation.rotation90deg:
          nx = landmark.y / imgH;
          ny = 1.0 - (landmark.x / imgW);
        case InputImageRotation.rotation180deg:
          nx = 1.0 - (landmark.x / imgW);
          ny = 1.0 - (landmark.y / imgH);
        case InputImageRotation.rotation270deg:
          nx = 1.0 - (landmark.y / imgH);
          ny = landmark.x / imgW;
      }

      // Mirror x for front-camera to match the mirrored live preview
      if (isFront) nx = 1.0 - nx;

      keypoints[entry.value] = Offset(
        nx.clamp(0.0, 1.0),
        ny.clamp(0.0, 1.0),
      );
      totalLikelihood += landmark.likelihood;
      count++;
    }

    return NormalizedPose(
      keypoints: keypoints,
      confidence: count > 0 ? totalLikelihood / count : 0,
    );
  }

  /// Releases the underlying ML Kit PoseDetector resources.
  void dispose() {
    _poseDetector.close();
  }
}
