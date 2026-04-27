import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_constants.dart';

/// Optimized snackbar utilities for faster and smoother feedback
class AppSnackbar {
  AppSnackbar._();

  /// Check if GetX overlay is available
  static bool _isOverlayAvailable() {
    return Get.overlayContext != null;
  }

  static void _show({
    required String title,
    required String message,
    required Color backgroundColor,
    required Icon icon,
    required Duration duration,
  }) {
    //  800ms delay — navgation complete hone ke baad overlay ready hoti hai
    Future.delayed(const Duration(milliseconds: 800), () {
      try {
        if (!_isOverlayAvailable()) {
          if (kDebugMode) debugPrint('AppSnackbar: Overlay not available → "$message"');
          return;
        }
        Get.snackbar(
          title,
          message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: backgroundColor,
          colorText: Colors.white,
          duration: duration,
          margin: const EdgeInsets.all(12),
          borderRadius: 8,
          isDismissible: true,
          forwardAnimationCurve: Curves.easeOutCubic,
          reverseAnimationCurve: Curves.easeInCubic,
          animationDuration: AppConstants.shortAnimation,
          icon: icon,
        );
      } catch (e) {
        if (kDebugMode) debugPrint('AppSnackbar: Failed → $e');
      }
    });
  }
  static void success(String message, {String? title}) => _show(
    title: title ?? 'Success',
    message: message,
    backgroundColor: Colors.green.shade600,
    icon: const Icon(Icons.check_circle, color: Colors.white),
    duration: AppConstants.snackbarDuration,
  );

  static void error(String message, {String? title}) => _show(
    title: title ?? 'Error',
    message: message,
    backgroundColor: Colors.red.shade600,
    icon: const Icon(Icons.error, color: Colors.white),
    duration: AppConstants.snackbarLongDuration,
  );

  static void info(String message, {String? title}) => _show(
    title: title ?? 'Info',
    message: message,
    backgroundColor: Colors.blue.shade600,
    icon: const Icon(Icons.info, color: Colors.white),
    duration: AppConstants.snackbarDuration,
  );

  static void warning(String message, {String? title}) => _show(
    title: title ?? 'Warning',
    message: message,
    backgroundColor: Colors.orange.shade600,
    icon: const Icon(Icons.warning, color: Colors.white),
    duration: AppConstants.snackbarDuration,
  );
}