import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:gal/gal.dart';
import '../theme/app_theme.dart';
import '../utils/permissions_handler.dart';
import '../widgets/top_bar.dart';
import '../widgets/camera_preview_area.dart';
import '../widgets/bottom_controls.dart';
import '../widgets/settings_panel.dart';
import '../widgets/mode_carousel.dart';
import '../services/pose_retrieval_service.dart';
import '../services/pose_detection_service.dart';
import '../services/pose_comparison_engine.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  final List<PoseTemplate> poseTemplates;

  const CameraScreen({
    super.key,
    required this.cameras,
    required this.poseTemplates,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isInitialized = false;
  String _errorMessage = '';

  // Camera settings state
  FlashMode _flashMode = FlashMode.off;
  bool _hdrEnabled = false;
  String _aspectRatio = '4:3';
  bool _gridEnabled = true;
  bool _audioEnabled = true;
  ResolutionPreset _resolutionPreset = ResolutionPreset.high;
  bool _mirrorFrontCamera = true;

  // Active feature state
  int _selectedVibeIndex = 0; // index of active filter
  int _selectedModeIndex = 3; // index of CAM by default (NIGHT, PANO, VIDEO, CAM, BEAUTY, PORTRAIT, PRO)
  String? _lastImagePath;
  bool _isRecording = false;
  bool _isCapturingNightMode = false;

  // Pro mode controls
  double _exposureOffset = 0.0;
  double _zoomLevel = 1.0;

  // ── Pose detection state ───────────────────────────────────────────
  late final PoseDetectionService _poseDetectionService;
  final PoseComparisonEngine _comparisonEngine = PoseComparisonEngine();
  double _alignmentScore = 0.0;
  bool _autoCapturePending = false;
  PoseTemplate? _activeTargetPose;
  bool _poseStreamActive = false;
  DateTime _lastAutoCapture = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _autoCaptureCooldown = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _poseDetectionService = PoseDetectionService();
    _checkPermissionsAndInit();
  }

  Future<void> _checkPermissionsAndInit() async {
    final cameraGranted = await PermissionsHelper.requestCameraPermission();
    if (cameraGranted) {
      if (widget.cameras.isNotEmpty) {
        // Initialize with default back camera or first available
        final defaultCamera = widget.cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => widget.cameras.first,
        );
        await _initializeCameraController(defaultCamera);
      } else {
        setState(() {
          _errorMessage = 'No camera hardware found on this device.';
        });
      }
    } else {
      setState(() {
        _errorMessage = 'Camera permission was denied. Please grant permission in settings.';
      });
    }
  }

  Future<void> _initializeCameraController(CameraDescription cameraDescription) async {
    // Stop active pose stream before disposing old controller
    if (_poseStreamActive) {
      await _stopPoseStream();
    }

    setState(() {
      _isInitialized = false;
      _errorMessage = '';
    });

    if (_controller != null) {
      await _controller!.dispose();
    }

    _controller = CameraController(
      cameraDescription,
      _resolutionPreset,
      enableAudio: _audioEnabled,
      // ML Kit requires NV21 on Android and BGRA8888 on iOS for image stream
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    try {
      await _controller!.initialize();
      await _controller!.setFlashMode(_flashMode);

      // Set initial zoom and exposure values
      _exposureOffset = 0.0;
      _zoomLevel = 1.0;
      await _controller!.setExposureOffset(_exposureOffset);
      await _controller!.setZoomLevel(_zoomLevel);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });

        // Start pose detection stream if a target pose is active
        if (_activeTargetPose != null) {
          await _startPoseStream();
        }
      }
    } on CameraException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize camera: ${e.description}';
          _isInitialized = false;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poseDetectionService.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _poseStreamActive = false; // Mark as stopped (controller will be disposed)
      cameraController.dispose();
      setState(() {
        _isInitialized = false;
      });
    } else if (state == AppLifecycleState.resumed) {
      _initializeCameraController(cameraController.description);
    }
  }

  // ── Pose stream lifecycle ──────────────────────────────────────────

  /// Starts the camera image stream for real-time ML Kit pose detection.
  Future<void> _startPoseStream() async {
    if (_controller == null || !_isInitialized || _poseStreamActive) return;
    try {
      await _controller!.startImageStream(_onCameraFrame);
      _poseStreamActive = true;
    } catch (e) {
      debugPrint('Failed to start pose stream: $e');
    }
  }

  /// Stops the camera image stream.
  Future<void> _stopPoseStream() async {
    if (_controller == null || !_poseStreamActive) return;
    try {
      await _controller!.stopImageStream();
    } catch (e) {
      debugPrint('Failed to stop pose stream: $e');
    }
    _poseStreamActive = false;
  }

  /// Called for each camera frame when the image stream is active.
  void _onCameraFrame(CameraImage image) {
    if (_activeTargetPose == null || _controller == null) return;

    _poseDetectionService
        .processFrame(image, _controller!.description)
        .then((pose) {
      if (pose == null || !mounted) return;

      final score =
          _comparisonEngine.calculateAlignmentScore(pose, _activeTargetPose!);

      setState(() {
        _alignmentScore = score;
      });

      // Auto-capture when aligned (non-video, non-pano modes only)
      final mode = ModeCarousel.modes[_selectedModeIndex];
      if (score >= PoseComparisonEngine.alignedThreshold &&
          !_autoCapturePending &&
          mode != 'VIDEO' &&
          mode != 'PANO' &&
          DateTime.now().difference(_lastAutoCapture) > _autoCaptureCooldown) {
        _triggerAutoCapture();
      }
    });
  }

  /// Handles pose template selection from the picker carousel.
  void _onPoseSelected(PoseTemplate? pose) {
    setState(() {
      _activeTargetPose = pose;
      _alignmentScore = 0.0;
      _autoCapturePending = false;
    });

    if (pose != null && !_poseStreamActive && _isInitialized) {
      _startPoseStream();
    } else if (pose == null && _poseStreamActive) {
      _stopPoseStream();
    }
  }

  /// Auto-capture: stop stream → take photo → restart stream.
  Future<void> _triggerAutoCapture() async {
    if (_autoCapturePending) return;
    _autoCapturePending = true;
    _lastAutoCapture = DateTime.now();

    // Must stop image stream before takePicture (camera plugin requirement)
    await _stopPoseStream();
    await Future.delayed(const Duration(milliseconds: 100));

    final mode = ModeCarousel.modes[_selectedModeIndex];
    if (mode == 'NIGHT') {
      await _handleNightModeCapture();
    } else {
      await _handleStandardPhotoCapture();
    }

    // Restart pose stream after capture
    if (_activeTargetPose != null && mounted) {
      await Future.delayed(const Duration(milliseconds: 200));
      await _startPoseStream();
    }

    _autoCapturePending = false;
  }

  // ── Camera actions ─────────────────────────────────────────────────

  // Camera flipping handler
  Future<void> _handleCameraFlip() async {
    if (widget.cameras.length < 2 || _controller == null) return;

    final currentLens = _controller!.description.lensDirection;
    final targetLens = currentLens == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;

    final nextCamera = widget.cameras.firstWhere(
      (c) => c.lensDirection == targetLens,
      orElse: () => widget.cameras.first,
    );

    // _initializeCameraController handles stopping/restarting pose stream
    await _initializeCameraController(nextCamera);
  }

  // Flash cycling handler
  Future<void> _handleFlashModeChanged(FlashMode mode) async {
    if (_controller == null || !_isInitialized) return;
    try {
      await _controller!.setFlashMode(mode);
      setState(() {
        _flashMode = mode;
      });
    } catch (e) {
      debugPrint('Failed to set flash mode: $e');
    }
  }

  // Shutter action handler
  Future<void> _handleShutterPressed() async {
    if (_controller == null || !_isInitialized) return;

    // Pause pose stream before capture (camera plugin requirement)
    final shouldResumeStream = _poseStreamActive;
    if (_poseStreamActive) {
      await _stopPoseStream();
      await Future.delayed(const Duration(milliseconds: 100));
    }

    final mode = ModeCarousel.modes[_selectedModeIndex];

    if (mode == 'VIDEO') {
      await _handleVideoRecording();
    } else if (mode == 'NIGHT') {
      await _handleNightModeCapture();
    } else {
      await _handleStandardPhotoCapture();
    }

    // Resume pose stream if it was active and we're not in video mode
    if (shouldResumeStream && _activeTargetPose != null && mounted && mode != 'VIDEO') {
      await Future.delayed(const Duration(milliseconds: 200));
      await _startPoseStream();
    }
  }

  Future<void> _handleStandardPhotoCapture() async {
    if (_controller!.value.isTakingPicture) return;

    try {
      // Capture image
      final XFile rawFile = await _controller!.takePicture();
      await _savePhotoToGallery(rawFile.path);
    } on CameraException catch (e) {
      _showSnackBar('Capture error: ${e.description}');
    }
  }

  Future<void> _handleNightModeCapture() async {
    if (_controller!.value.isTakingPicture) return;

    setState(() {
      _isCapturingNightMode = true;
    });

    // Simulate longer exposure (2 seconds countdown)
    await Future.delayed(const Duration(seconds: 2));

    try {
      final XFile rawFile = await _controller!.takePicture();
      await _savePhotoToGallery(rawFile.path);
    } on CameraException catch (e) {
      _showSnackBar('Capture error: ${e.description}');
    } finally {
      setState(() {
        _isCapturingNightMode = false;
      });
    }
  }

  Future<void> _handleVideoRecording() async {
    if (_isRecording) {
      // Stop recording
      try {
        final XFile videoFile = await _controller!.stopVideoRecording();
        setState(() {
          _isRecording = false;
        });
        await _saveVideoToGallery(videoFile.path);
      } on CameraException catch (e) {
        _showSnackBar('Stop recording error: ${e.description}');
      }
    } else {
      // Start recording
      try {
        await _controller!.startVideoRecording();
        setState(() {
          _isRecording = true;
        });
      } on CameraException catch (e) {
        _showSnackBar('Start recording error: ${e.description}');
      }
    }
  }

  Future<void> _savePhotoToGallery(String rawPath) async {
    final hasAccess = await PermissionsHelper.requestStoragePermission();
    if (!hasAccess) {
      if (mounted) {
        PermissionsHelper.showPermissionDeniedDialog(context, 'Photo Library');
      }
      return;
    }

    try {
      // If front camera and mirror mode enabled, we can optionally process the image here.
      // For standard gallery saving, the gal package works directly with file path.
      await Gal.putImage(rawPath);
      
      setState(() {
        _lastImagePath = rawPath;
      });

      _showSnackBar('Photo saved to Native Device Gallery');
    } catch (e) {
      _showSnackBar('Failed to save photo: $e');
    }
  }

  Future<void> _saveVideoToGallery(String rawPath) async {
    final hasAccess = await PermissionsHelper.requestStoragePermission();
    if (!hasAccess) {
      if (mounted) {
        PermissionsHelper.showPermissionDeniedDialog(context, 'Photo Library');
      }
      return;
    }

    try {
      await Gal.putVideo(rawPath);
      _showSnackBar('Video saved to Native Device Gallery');
    } catch (e) {
      _showSnackBar('Failed to save video: $e');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.surface,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Open settings panel bottom sheet
  void _openSettingsPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setPanelState) => SettingsPanel(
          gridEnabled: _gridEnabled,
          onGridChanged: (val) {
            setState(() => _gridEnabled = val);
            setPanelState(() {});
          },
          audioEnabled: _audioEnabled,
          onAudioChanged: (val) {
            setState(() => _audioEnabled = val);
            setPanelState(() {});
            // Reinitialize camera description to apply audio toggle
            if (_controller != null) {
              _initializeCameraController(_controller!.description);
            }
          },
          selectedPreset: _resolutionPreset,
          onPresetChanged: (val) {
            setState(() => _resolutionPreset = val);
            setPanelState(() {});
            if (_controller != null) {
              _initializeCameraController(_controller!.description);
            }
          },
          mirrorFrontCamera: _mirrorFrontCamera,
          onMirrorFrontCameraChanged: (val) {
            setState(() => _mirrorFrontCamera = val);
            setPanelState(() {});
          },
        ),
      ),
    );
  }

  // View last image in full screen preview
  void _viewLastImage() {
    if (_lastImagePath == null) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(_lastImagePath!),
                    fit: BoxFit.contain,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeMode = ModeCarousel.modes[_selectedModeIndex];

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 60),
                const SizedBox(height: 16),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.white, fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: _checkPermissionsAndInit,
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Column(
            children: [
              // Top Control Bar
              TopBar(
                onSettingsPressed: _openSettingsPanel,
                currentFlashMode: _flashMode,
                onFlashModeChanged: _handleFlashModeChanged,
                hdrEnabled: _hdrEnabled,
                onHdrChanged: (val) => setState(() => _hdrEnabled = val),
                currentAspectRatio: _aspectRatio,
                onAspectRatioChanged: (val) => setState(() => _aspectRatio = val),
              ),

              // Camera Preview Layer (sandwich view)
              Expanded(
                child: CameraPreviewArea(
                  controller: _controller,
                  isInitialized: _isInitialized,
                  gridEnabled: _gridEnabled,
                  selectedVibeIndex: _selectedVibeIndex,
                  onVibeSelected: (val) => setState(() => _selectedVibeIndex = val),
                  currentAspectRatio: _aspectRatio,
                  currentMode: activeMode,
                  exposureOffset: _exposureOffset,
                  onExposureChanged: (val) async {
                    setState(() => _exposureOffset = val);
                    await _controller?.setExposureOffset(val);
                  },
                  zoomLevel: _zoomLevel,
                  onZoomChanged: (val) async {
                    setState(() => _zoomLevel = val);
                    await _controller?.setZoomLevel(val);
                  },
                  // Silhouette overlay props
                  targetPose: _activeTargetPose,
                  alignmentScore: _alignmentScore,
                ),
              ),

              // Bottom Control Panel
              BottomControls(
                selectedModeIndex: _selectedModeIndex,
                onModeChanged: (val) {
                  setState(() {
                    _selectedModeIndex = val;
                  });
                },
                lastImagePath: _lastImagePath,
                onGalleryTap: _viewLastImage,
                onShutterPressed: _handleShutterPressed,
                isRecording: _isRecording,
                onFlipPressed: _handleCameraFlip,
                // Pose picker props
                poses: widget.poseTemplates,
                selectedPose: _activeTargetPose,
                onPoseSelected: _onPoseSelected,
              ),
            ],
          ),

          // Night Sight exposure indicator
          if (_isCapturingNightMode)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: AppColors.accent,
                      strokeWidth: 5,
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Hold still...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Capturing night sight details',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
