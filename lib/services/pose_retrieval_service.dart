import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// Represents a single keypoint with normalized x/y coordinates (0.0–1.0).
class Keypoint {
  final double x;
  final double y;

  const Keypoint({required this.x, required this.y});

  factory Keypoint.fromJson(Map<String, dynamic> json) {
    return Keypoint(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  @override
  String toString() => 'Keypoint(x: $x, y: $y)';
}

/// Represents a full pose template with 17 COCO keypoints and scene metadata.
class PoseTemplate {
  final String poseId;
  final String sceneTag;
  final String displayName;
  final Map<String, Keypoint> keypoints;

  const PoseTemplate({
    required this.poseId,
    required this.sceneTag,
    required this.displayName,
    required this.keypoints,
  });

  factory PoseTemplate.fromJson(Map<String, dynamic> json) {
    final rawKeypoints = json['keypoints'] as Map<String, dynamic>;
    final parsedKeypoints = rawKeypoints.map(
      (key, value) => MapEntry(key, Keypoint.fromJson(value as Map<String, dynamic>)),
    );

    return PoseTemplate(
      poseId: json['pose_id'] as String,
      sceneTag: json['scene_tag'] as String,
      displayName: json['display_name'] as String? ?? json['pose_id'] as String,
      keypoints: parsedKeypoints,
    );
  }

  Map<String, dynamic> toJson() => {
        'pose_id': poseId,
        'scene_tag': sceneTag,
        'display_name': displayName,
        'keypoints': keypoints.map((key, value) => MapEntry(key, value.toJson())),
      };

  @override
  String toString() => 'PoseTemplate(poseId: $poseId, sceneTag: $sceneTag, displayName: $displayName)';
}

/// The 17 standard COCO human joint identifiers.
class CocoKeypoints {
  static const List<String> all = [
    'nose',
    'left_eye',
    'right_eye',
    'left_ear',
    'right_ear',
    'left_shoulder',
    'right_shoulder',
    'left_elbow',
    'right_elbow',
    'left_wrist',
    'right_wrist',
    'left_hip',
    'right_hip',
    'left_knee',
    'right_knee',
    'left_ankle',
    'right_ankle',
  ];
}

/// Service responsible for loading pose templates from the local asset bundle
/// and providing scene-based pose retrieval.
///
/// Usage:
/// ```dart
/// final service = PoseRetrievalService();
/// await service.initialize();
/// final pose = service.getBestPoseForScene('garden');
/// ```
class PoseRetrievalService {
  static const String _assetPath = 'assets/pose_templates.json';

  List<PoseTemplate> _templates = [];
  bool _isInitialized = false;

  /// Whether the service has successfully loaded pose data.
  bool get isInitialized => _isInitialized;

  /// All loaded pose templates.
  List<PoseTemplate> get templates => List.unmodifiable(_templates);

  /// Loads the pose_templates.json asset file into memory.
  ///
  /// Must be called once during app initialization before accessing poses.
  /// Throws [FlutterError] if the asset cannot be loaded or parsed.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final jsonString = await rootBundle.loadString(_assetPath);
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;

      _templates = jsonList
          .map((item) => PoseTemplate.fromJson(item as Map<String, dynamic>))
          .toList();

      _isInitialized = true;
    } catch (e) {
      throw Exception(
        'PoseRetrievalService: Failed to load pose templates from "$_assetPath". '
        'Ensure the asset is declared in pubspec.yaml. Error: $e',
      );
    }
  }

  /// Returns the optimal [PoseTemplate] matching the given [sceneTag].
  ///
  /// The "best" pose is determined by a symmetry score — poses with more
  /// balanced left/right keypoint placement are considered more universally
  /// flattering and are ranked higher.
  ///
  /// Returns `null` if no poses match the given scene tag or if the service
  /// has not been initialized.
  PoseTemplate? getBestPoseForScene(String sceneTag) {
    if (!_isInitialized) return null;

    final candidates = _templates
        .where((t) => t.sceneTag.toLowerCase() == sceneTag.toLowerCase())
        .toList();

    if (candidates.isEmpty) return null;
    if (candidates.length == 1) return candidates.first;

    // Score each candidate by keypoint symmetry (lower deviation = better).
    // We compare left/right counterpart distances from the vertical center.
    PoseTemplate? best;
    double bestScore = double.infinity;

    const symmetryPairs = [
      ['left_eye', 'right_eye'],
      ['left_ear', 'right_ear'],
      ['left_shoulder', 'right_shoulder'],
      ['left_elbow', 'right_elbow'],
      ['left_wrist', 'right_wrist'],
      ['left_hip', 'right_hip'],
      ['left_knee', 'right_knee'],
      ['left_ankle', 'right_ankle'],
    ];

    for (final candidate in candidates) {
      double totalDeviation = 0.0;
      int pairsEvaluated = 0;

      for (final pair in symmetryPairs) {
        final left = candidate.keypoints[pair[0]];
        final right = candidate.keypoints[pair[1]];
        if (left != null && right != null) {
          // Measure how symmetric the pair is around x = 0.5
          final leftDist = (left.x - 0.5).abs();
          final rightDist = (right.x - 0.5).abs();
          totalDeviation += (leftDist - rightDist).abs();

          // Also penalize vertical asymmetry
          totalDeviation += (left.y - right.y).abs();
          pairsEvaluated++;
        }
      }

      final score = pairsEvaluated > 0 ? totalDeviation / pairsEvaluated : double.infinity;

      if (score < bestScore) {
        bestScore = score;
        best = candidate;
      }
    }

    return best;
  }

  /// Returns all [PoseTemplate] objects matching the given [sceneTag].
  List<PoseTemplate> getAllPosesForScene(String sceneTag) {
    if (!_isInitialized) return [];
    return _templates
        .where((t) => t.sceneTag.toLowerCase() == sceneTag.toLowerCase())
        .toList();
  }

  /// Returns a [PoseTemplate] by its exact [poseId], or `null` if not found.
  PoseTemplate? getPoseById(String poseId) {
    if (!_isInitialized) return null;
    try {
      return _templates.firstWhere((t) => t.poseId == poseId);
    } catch (_) {
      return null;
    }
  }

  /// Returns all unique scene tags present in the loaded templates.
  List<String> get availableSceneTags {
    if (!_isInitialized) return [];
    return _templates.map((t) => t.sceneTag).toSet().toList()..sort();
  }
}
