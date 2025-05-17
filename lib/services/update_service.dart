import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

class UpdateService {
  // Singleton pattern
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  Future<void> checkForUpdate(BuildContext context) async {
    try {
      final status = await InAppUpdate.checkForUpdate();

      if (status.updateAvailability == UpdateAvailability.updateAvailable) {
        if (status.immediateUpdateAllowed) {
          // Perform immediate update
          await _startImmediateUpdate();
        } else if (status.flexibleUpdateAllowed) {
          // Perform flexible update
          await _startFlexibleUpdate(context);
        }
      }
    } catch (e) {
      debugPrint('In-app update error: $e');
    }
  }

  Future<void> _startImmediateUpdate() async {
    try {
      await InAppUpdate.performImmediateUpdate();
    } catch (e) {
      debugPrint('Immediate update error: $e');
    }
  }

  Future<void> _startFlexibleUpdate(BuildContext context) async {
    try {
      await InAppUpdate.startFlexibleUpdate();

      // Show completion dialog when update is downloaded
      InAppUpdate.completeFlexibleUpdate().then((_) {
        _showUpdateCompletedDialog(context);
      });
    } catch (e) {
      debugPrint('Flexible update error: $e');
    }
  }

  void _showUpdateCompletedDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Update Ready'),
        content: const Text(
            'An update has been downloaded. Restart the app to apply the update.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Later'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await InAppUpdate.completeFlexibleUpdate();
            },
            child: const Text('Restart Now'),
          ),
        ],
      ),
    );
  }

  // Helper method to log app signing information (for debugging)
  void logSigningInfo() {
    debugPrint('Checking app signing configuration...');
    // Note: This is just for logging. Actual signing is done during build.
    // You cannot determine signing status programmatically at runtime.
  }
}
