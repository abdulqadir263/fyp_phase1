import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../app/themes/app_colors.dart';
import '../models/field_visit_model.dart';

/// AppointmentDetailView — Shows full details of a single field visit
/// Used by both farmer and expert (read-only detail view)
class AppointmentDetailView extends StatelessWidget {
  const AppointmentDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the visit from route arguments
    final FieldVisitModel? visit = Get.arguments as FieldVisitModel?;

    if (visit == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Visit Details')),
        body: const Center(child: Text('Visit not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visit Details'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge
            Center(child: _buildStatusBadge(visit.status)),
            const SizedBox(height: 20),

            // Farmer & Expert info
            _buildSection('Farmer', visit.farmerName),
            _buildSection('Expert', visit.expertName),

            const Divider(height: 24),

            // Problem details
            _buildSection('Crop Type', visit.cropType),
            _buildSection('Problem', visit.problemCategory),
            _buildSection('Description', visit.description),

            // Images
            if (visit.imageUrls != null && visit.imageUrls!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Photos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: visit.imageUrls!.length,
                  itemBuilder: (context, idx) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: visit.imageUrls![idx],
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            const Divider(height: 24),

            // Location
            _buildSection('Location', visit.farmLocationName),
            _buildSection('Address', visit.fullAddress),
            _buildSection('Farm Size', '${visit.farmSize} acres'),

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final url = Uri.parse(visit.googleMapsUrl);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.map, color: AppColors.primaryGreen),
                label: const Text(
                  'Open in Google Maps',
                  style: TextStyle(color: AppColors.primaryGreen),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primaryGreen),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

            const Divider(height: 24),

            // Dates
            _buildSection(
              'Preferred Date',
              DateFormat('EEEE, dd MMM yyyy').format(visit.preferredDate),
            ),
            if (visit.confirmedDate != null)
              _buildSection(
                'Confirmed Date',
                DateFormat('EEEE, dd MMM yyyy').format(visit.confirmedDate!),
              ),
            _buildSection(
              'Requested On',
              DateFormat('dd MMM yyyy, hh:mm a').format(visit.createdAt),
            ),

            // Expert notes
            if (visit.expertNotes != null &&
                visit.expertNotes!.isNotEmpty) ...[
              const Divider(height: 24),
              const Text(
                'Expert Notes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  visit.expertNotes!,
                  style: const TextStyle(fontSize: 15, height: 1.5),
                ),
              ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Build a labeled section
  Widget _buildSection(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  /// Build a color-coded status badge
  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'pending':
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        break;
      case 'accepted':
      case 'scheduled':
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        break;
      case 'rejected':
      case 'cancelled':
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        break;
      case 'completed':
        bgColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        break;
      default:
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
    }

    final label = status.isNotEmpty
        ? '${status[0].toUpperCase()}${status.substring(1)}'
        : 'Unknown';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}

