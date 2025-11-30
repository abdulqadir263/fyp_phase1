import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_constants.dart';

/// Optimized snackbar utilities for faster and smoother feedback
class AppSnackbar {
  AppSnackbar._();

  /// Show success snackbar with optimized settings
  static void success(String message, {String? title}) {
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
  }

  /// Show error snackbar with optimized settings
  static void error(String message, {String? title}) {
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
  }

  /// Show info snackbar with optimized settings
  static void info(String message, {String? title}) {
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
  }

  /// Show warning snackbar with optimized settings
  static void warning(String message, {String? title}) {
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
  }
}
