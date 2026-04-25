import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_constants.dart';

/// Optimized snackbar utilities for faster and smoother feedback
class AppSnackbar {
  AppSnackbar._();

  /// Check if overlay is available in current context (safer approach)
  static bool _isOverlayAvailable() {
    try {
      final context = Get.context;
      if (context == null) return false;
      // Try to find Navigator in the context tree
      Navigator.of(context);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Show success snackbar with optimized settings
  static void success(String message, {String? title}) {
    // Delay slightly to ensure widget tree is ready
    Future.microtask(() {
      try {
        if (!_isOverlayAvailable()) {
          if (kDebugMode) {
            debugPrint('Overlay not available for success snackbar: $message');
          }
          return;
        }
        Get.snackbar(
          title ?? 'Success',
          message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade600,
          colorText: Colors.white,
          duration: AppConstants.snackbarDuration,
          margin: const EdgeInsets.all(12),
          borderRadius: 8,
          isDismissible: true,
          forwardAnimationCurve: Curves.easeOutCubic,
          reverseAnimationCurve: Curves.easeInCubic,
          animationDuration: AppConstants.shortAnimation,
          icon: const Icon(Icons.check_circle, color: Colors.white),
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error showing success snackbar: $e');
        }
      }
    });
  }

  /// Show error snackbar with optimized settings
  static void error(String message, {String? title}) {
    // Delay slightly to ensure widget tree is ready
    Future.microtask(() {
      try {
        if (!_isOverlayAvailable()) {
          if (kDebugMode) {
            debugPrint('Overlay not available for error snackbar: $message');
          }
          return;
        }
        Get.snackbar(
          title ?? 'Error',
          message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade600,
          colorText: Colors.white,
          duration: AppConstants.snackbarLongDuration,
          margin: const EdgeInsets.all(12),
          borderRadius: 8,
          isDismissible: true,
          forwardAnimationCurve: Curves.easeOutCubic,
          reverseAnimationCurve: Curves.easeInCubic,
          animationDuration: AppConstants.shortAnimation,
          icon: const Icon(Icons.error, color: Colors.white),
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error showing error snackbar: $e');
        }
      }
    });
  }

  /// Show info snackbar with optimized settings
  static void info(String message, {String? title}) {
    // Delay slightly to ensure widget tree is ready
    Future.microtask(() {
      try {
        if (!_isOverlayAvailable()) {
          if (kDebugMode) {
            debugPrint('Overlay not available for info snackbar: $message');
          }
          return;
        }
        Get.snackbar(
          title ?? 'Info',
          message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.blue.shade600,
          colorText: Colors.white,
          duration: AppConstants.snackbarDuration,
          margin: const EdgeInsets.all(12),
          borderRadius: 8,
          isDismissible: true,
          forwardAnimationCurve: Curves.easeOutCubic,
          reverseAnimationCurve: Curves.easeInCubic,
          animationDuration: AppConstants.shortAnimation,
          icon: const Icon(Icons.info, color: Colors.white),
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error showing info snackbar: $e');
        }
      }
    });
  }

  /// Show warning snackbar with optimized settings
  static void warning(String message, {String? title}) {
    // Delay slightly to ensure widget tree is ready
    Future.microtask(() {
      try {
        if (!_isOverlayAvailable()) {
          if (kDebugMode) {
            debugPrint('Overlay not available for warning snackbar: $message');
          }
          return;
        }
        Get.snackbar(
          title ?? 'Warning',
          message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade600,
          colorText: Colors.white,
          duration: AppConstants.snackbarDuration,
          margin: const EdgeInsets.all(12),
          borderRadius: 8,
          isDismissible: true,
          forwardAnimationCurve: Curves.easeOutCubic,
          reverseAnimationCurve: Curves.easeInCubic,
          animationDuration: AppConstants.shortAnimation,
          icon: const Icon(Icons.warning, color: Colors.white),
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error showing warning snackbar: $e');
        }
      }
    });
  }
}
