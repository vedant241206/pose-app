import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class PermissionsHelper {
  /// Request camera permission. Returns true if granted.
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Request storage/photos permission for saving images.
  static Future<bool> requestStoragePermission() async {
    final status = await Permission.photos.request();
    if (status.isGranted) return true;
    // Fallback for older Android
    final storageStatus = await Permission.storage.request();
    return storageStatus.isGranted;
  }

  /// Check if camera permission is granted.
  static Future<bool> hasCameraPermission() async {
    return await Permission.camera.isGranted;
  }

  /// Show a dialog when permission is permanently denied.
  static Future<void> showPermissionDeniedDialog(
    BuildContext context,
    String permissionName,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          '$permissionName Permission Required',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          'Please enable $permissionName permission in your device settings to use this feature.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings', style: TextStyle(color: Color(0xFFFFD700))),
          ),
        ],
      ),
    );
  }
}
