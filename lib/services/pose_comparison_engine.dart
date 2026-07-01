import 'dart:math';
import 'dart:ui';
import 'pose_detection_service.dart';
import 'pose_retrieval_service.dart';

/// Compares a live-detected pose against a target template using normalised
/// Euclidean distance to produce an alignment score.
///
/// **Score semantics:**
/// - `1.0` = perfect alignment (all joints overlap exactly)
/// - `0.0` = no match (maximum possible deviation)
/// - `≥ 0.85` = error ≤ 15 % → triggers aligned state
class PoseComparisonEngine {
  /// Maximum possible distance between two points in the unit square: √2.
  static const double _maxSingleJointDistance = 1.4142135623730951;

  /// Alignment threshold — score at or above this value means "aligned".
  static const double alignedThreshold = 0.85;

  /// Calculates the alignment score between a [detected] live pose and a
  /// [target] template pose.
  ///
  /// For each of the 17 COCO keypoints present in **both** poses:
  /// 1. Euclidean distance = √(Δx² + Δy²)
  /// 2. Normalise by √2 → per-joint error in 0.0–1.0
  /// 3. Average across all matched joints
  /// 4. Return `1.0 − averageError`
  double calculateAlignmentScore(
    NormalizedPose detected,
    PoseTemplate target,
  ) {
    double totalNormalisedError = 0.0;
    int matchedJoints = 0;

    for (final entry in target.keypoints.entries) {
      final detectedPoint = detected.keypoints[entry.key];
      if (detectedPoint == null) continue;

      final targetOffset = Offset(entry.value.x, entry.value.y);
      final dx = detectedPoint.dx - targetOffset.dx;
      final dy = detectedPoint.dy - targetOffset.dy;
      final distance = sqrt(dx * dx + dy * dy);

      totalNormalisedError += distance / _maxSingleJointDistance;
      matchedJoints++;
    }

    if (matchedJoints == 0) return 0.0;

    final averageError = totalNormalisedError / matchedJoints;
    return (1.0 - averageError).clamp(0.0, 1.0);
  }
}
