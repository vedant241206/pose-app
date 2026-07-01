import 'package:flutter/material.dart';
import '../services/pose_retrieval_service.dart';

/// Renders a hollow body-contour silhouette from a target pose template.
///
/// **Rendering algorithm:**
/// 1. [canvas.saveLayer] isolates the compositing layer to prevent DstOut
///    from producing black artifacts against the camera background.
/// 2. Outer pass draws thick (50px) rounded body segments → solid blob.
/// 3. Inner pass re-draws at 42px with [BlendMode.dstOut] → erases interior.
/// 4. [canvas.restore] composites the hollow 4px contour onto the real canvas.
class DynamicSilhouettePainter extends CustomPainter {
  final PoseTemplate targetPose;
  final double alignmentScore;
  final Color contourColor;

  /// Outer stroke thickness forming the body blob.
  static const double outerStrokeWidth = 50.0;

  /// Desired contour line width in logical pixels.
  static const double contourWidth = 4.0;

  /// Inner stroke = outer − 2×contour. Used with DstOut to hollow the blob.
  static const double innerStrokeWidth =
      outerStrokeWidth - (contourWidth * 2); // 42.0

  /// Head circle radius factor relative to the reference stroke width.
  static const double _headRadiusFactor = 0.7;

  /// COCO skeleton segment connections as [from, to] keypoint pairs.
  static const List<List<String>> _segments = [
    // Head connections
    ['nose', 'left_eye'],
    ['nose', 'right_eye'],
    ['left_eye', 'left_ear'],
    ['right_eye', 'right_ear'],
    // Torso frame
    ['left_shoulder', 'right_shoulder'],
    ['left_shoulder', 'left_hip'],
    ['right_shoulder', 'right_hip'],
    ['left_hip', 'right_hip'],
    // Left arm chain
    ['left_shoulder', 'left_elbow'],
    ['left_elbow', 'left_wrist'],
    // Right arm chain
    ['right_shoulder', 'right_elbow'],
    ['right_elbow', 'right_wrist'],
    // Left leg chain
    ['left_hip', 'left_knee'],
    ['left_knee', 'left_ankle'],
    // Right leg chain
    ['right_hip', 'right_knee'],
    ['right_knee', 'right_ankle'],
  ];

  DynamicSilhouettePainter({
    required this.targetPose,
    required this.alignmentScore,
    required this.contourColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final layerBounds = Offset.zero & size;

    // ── Isolate canvas layer ──────────────────────────────────────────
    // Without saveLayer, BlendMode.dstOut would erase into the camera
    // background, producing black rectangles instead of transparency.
    canvas.saveLayer(layerBounds, Paint());

    // ── OUTER PASS: thick body blob ──────────────────────────────────
    final outerPaint = Paint()
      ..color = contourColor
      ..strokeWidth = outerStrokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    _drawSegments(canvas, size, outerPaint);
    _drawHead(canvas, size, outerStrokeWidth, fillColor: contourColor);

    // ── INNER PASS: hollow out the centre ────────────────────────────
    final innerPaint = Paint()
      ..blendMode = BlendMode.dstOut
      ..color = Colors.white // opaque required for DstOut to erase
      ..strokeWidth = innerStrokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    _drawSegments(canvas, size, innerPaint);
    _drawHead(canvas, size, innerStrokeWidth,
        fillColor: Colors.white, blendMode: BlendMode.dstOut);

    // ── Restore ──────────────────────────────────────────────────────
    // Composites the hollow silhouette onto the real canvas.
    canvas.restore();
  }

  /// Draws all COCO skeleton segments between connected keypoints.
  void _drawSegments(Canvas canvas, Size size, Paint paint) {
    for (final seg in _segments) {
      final from = targetPose.keypoints[seg[0]];
      final to = targetPose.keypoints[seg[1]];
      if (from == null || to == null) continue;

      canvas.drawLine(
        Offset(from.x * size.width, from.y * size.height),
        Offset(to.x * size.width, to.y * size.height),
        paint,
      );
    }
  }

  /// Draws a filled circle at the nose position representing the head.
  void _drawHead(
    Canvas canvas,
    Size size,
    double refStrokeWidth, {
    required Color fillColor,
    BlendMode? blendMode,
  }) {
    final nose = targetPose.keypoints['nose'];
    if (nose == null) return;

    final headPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    if (blendMode != null) headPaint.blendMode = blendMode;

    canvas.drawCircle(
      Offset(nose.x * size.width, nose.y * size.height),
      refStrokeWidth * _headRadiusFactor,
      headPaint,
    );
  }

  @override
  bool shouldRepaint(DynamicSilhouettePainter oldDelegate) {
    return oldDelegate.contourColor != contourColor ||
        oldDelegate.alignmentScore != alignmentScore ||
        oldDelegate.targetPose.poseId != targetPose.poseId;
  }
}
