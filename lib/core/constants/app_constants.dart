import 'package:flutter/material.dart';

/// Application-wide constants
class AppConstants {
  // Prevent instantiation
  AppConstants._();

  // App Info
  static const String appName = 'Aasaan Kisaan';
  static const String appVersion = '1.0.0';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String appointmentsCollection = 'appointments';
  static const String productsCollection = 'products';
  static const String cropsCollection = 'crops';
  static const String communityPostsCollection = 'communityPosts';
  static const String commentsCollection = 'comments';
  static const String chatMessagesCollection = 'chatMessages';
  static const String otpCollection = 'password_reset_otps';

  // Firebase Storage paths
  static const String profileImagesPath = 'profile_images';
  static const String productImagesPath = 'product_images';
  static const String postImagesPath = 'post_images';
  static const String cropImagesPath = 'crop_images';

  // App Colors
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color darkGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFFA5D6A7);
  static const Color parrotGreen = Color(0xFF66BB6A);

  // User types
  static const String userTypeFarmer = 'farmer';
  static const String userTypeExpert = 'expert';
  static const String userTypeCompany = 'company';
  static const String userTypeGuest = 'guest';

  // OTP Settings
  static const int otpLength = 6;
  static const int otpExpiryMinutes = 5;

  // Chatbot Settings
  static const int maxMessageLength = 500;
  static const String geminiModel = 'gemini-2.0-flash';

  // App settings
  static const bool enableLogging = true;
  static const int defaultPageSize = 20;

  // API URLs
  static const String weatherBaseUrl = 'https://api.openweathermap.org/data/2.5';

  // Optimized Animation durations for smoother UX
  static const Duration instantAnimation = Duration(milliseconds: 100);
  static const Duration shortAnimation = Duration(milliseconds: 150);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Snackbar durations - optimized for quick feedback
  static const Duration snackbarDuration = Duration(seconds: 2);
  static const Duration snackbarLongDuration = Duration(seconds: 4);
  
  // Debounce durations for search/filter operations
  static const Duration debounceDelay = Duration(milliseconds: 300);
  static const Duration throttleDelay = Duration(milliseconds: 500);
}
