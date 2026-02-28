import 'package:flutter/material.dart';

// App ki sare constants yahan par rakhenge
class AppConstants {
  // App Info
  static const String APP_NAME = 'Aasaan Kisaan';
  static const String APP_VERSION = '1.0.0';

  // API Keys (Yahan apni actual keys lagayein)
  static const String WEATHER_API_KEY = 'YOUR_OPENWEATHERMAP_API_KEY';
  static const String WEATHER_BASE_URL = 'https://api.openweathermap.org/data/2.5';

  // Firebase Collections ke names
  static const String USERS_COLLECTION = 'users';
  static const String APPOINTMENTS_COLLECTION = 'appointments';
  static const String PRODUCTS_COLLECTION = 'products';
  static const String CROPS_COLLECTION = 'crops';
  static const String COMMUNITY_POSTS_COLLECTION = 'communityPosts';
  static const String COMMENTS_COLLECTION = 'comments';
  static const String FIELD_VISITS_COLLECTION = 'fieldVisits';

  // Firebase Storage paths
  static const String PROFILE_IMAGES_PATH = 'profile_images';
  static const String PRODUCT_IMAGES_PATH = 'product_images';
  static const String POST_IMAGES_PATH = 'post_images';
  static const String CROP_IMAGES_PATH = 'crop_images';

  // App Colors (Theme file bhi hai, lekin urgent ke liye yahan bhi)
  static const Color PRIMARY_GREEN = Color(0xFF2E7D32);
  static const Color PARROT_GREEN = Color(0xFF66BB6A);
  static const Color LIGHT_GREEN = Color(0xFFA5D6A7);

  // User types
  static const String USER_TYPE_FARMER = 'farmer';
  static const String USER_TYPE_EXPERT = 'expert';
  static const String USER_TYPE_COMPANY = 'company';

  // App settings
  static const bool ENABLE_LOGGING = true;
  static const int DEFAULT_PAGE_SIZE = 20;
}