import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Cloudinary se image upload karne ke liye service (HTTP-based)
class CloudinaryService extends GetxService {
  // Cloudinary credentials
  final String cloudName = 'dybx88bzo';
  final String apiKey = '928852253344424';
  final String apiSecret = 'tTV8Gr4qXhyPYBZHOU8PbfGq2zA';
  final String uploadPreset = 'ml_default'; // Create this in your Cloudinary settings

  // Image upload karna using HTTP
  Future<String?> uploadImage(File imageFile, {String folder = 'profile_images'}) async {
    try {
      // Create a multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload'),
      );

      // Add fields
      request.fields['upload_preset'] = uploadPreset;
      request.fields['folder'] = folder;

      // Add file
      final fileBytes = await imageFile.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: imageFile.path.split('/').last,
      );
      request.files.add(multipartFile);

      // Send request
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonData = json.decode(responseData);

      if (response.statusCode == 200) {
        // Return the secure URL
        return jsonData['secure_url'];
      } else {
        throw Exception('Image upload failed: ${jsonData['error']['message']}');
      }
    } catch (e) {
      debugPrint('Error uploading image to Cloudinary: $e');
      Get.snackbar('Error', 'Failed to upload image: $e');
      return null;
    }
  }
}