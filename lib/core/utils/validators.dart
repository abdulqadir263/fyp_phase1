import 'package:get/get.dart';

/// Input validation utilities
class Validators {
  // Prevent instantiation
  Validators._();

  /// Validate email format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!GetUtils.isEmail(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validate password strength
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validate confirm password
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Validate name
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 3) {
      return 'Name must be at least 3 characters';
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Name can only contain letters and spaces';
    }
    return null;
  }

  /// Validate phone number
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (value.length < 10 || value.length > 15) {
      return 'Please enter a valid phone number';
    }
    if (!GetUtils.isNumericOnly(value.replaceAll(RegExp(r'[\s\-\+]'), ''))) {
      return 'Phone number can only contain digits';
    }
    return null;
  }

  /// Validate OTP
  static String? validateOTP(String? value) {
    if (value == null || value.isEmpty) {
      return 'OTP is required';
    }
    if (value.length != 6) {
      return 'OTP must be 6 digits';
    }
    if (!GetUtils.isNumericOnly(value)) {
      return 'OTP can only contain digits';
    }
    return null;
  }

  /// Validate message length (for chatbot)
  static String? validateMessage(String? value, {int maxLength = 500}) {
    if (value == null || value.trim().isEmpty) {
      return 'Message cannot be empty';
    }
    if (value.length > maxLength) {
      return 'Message cannot exceed $maxLength characters';
    }
    return null;
  }

  /// Validate required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate URL format
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return null; // URL is optional
    }
    if (!GetUtils.isURL(value)) {
      return 'Please enter a valid URL';
    }
    return null;
  }

  /// Check if string contains only alphabets
  static bool isAlphabetOnly(String value) {
    return RegExp(r'^[a-zA-Z]+$').hasMatch(value);
  }

  /// Check if string is a valid number
  static bool isValidNumber(String value) {
    return double.tryParse(value) != null;
  }
}
