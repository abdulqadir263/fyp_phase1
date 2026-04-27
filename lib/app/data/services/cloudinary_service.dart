import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

// dart:io File removed — not supported on Flutter Web
// uploadImage now accepts Uint8List bytes (works on web + mobile)
class CloudinaryService extends GetxService {
  final String cloudName = 'dybx88bzo';
  final String apiKey = '928852253344424';
  final String apiSecret = 'tTV8Gr4qXhyPYBZHOU8PbfGq2zA';
  final String uploadPreset = 'ml_default';

  Future<String?> uploadImage(
      Uint8List imageBytes,
      String fileName, {
        String folder = 'profile_images',
      }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload'),
      );

      request.fields['upload_preset'] = uploadPreset;
      request.fields['folder'] = folder;

      request.files.add(http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: fileName,
      ));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonData = json.decode(responseData);

      if (response.statusCode == 200) {
        return jsonData['secure_url'] as String?;
      } else {
        throw Exception('Upload failed: ${jsonData['error']['message']}');
      }
    } catch (e) {
      debugPrint('CloudinaryService: upload error → $e');
      return null;
    }
  }
}