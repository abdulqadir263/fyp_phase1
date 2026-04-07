import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/themes/app_colors.dart';
import '../../../core/utils/responsive_helper.dart';
import '../controllers/seller_controller.dart';
import '../models/product_model.dart';

/// AddProductView — Form for seller to add/edit a product
class AddProductView extends GetView<SellerController> {
  const AddProductView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          controller.imageUrl.value.isEmpty && controller.nameCtrl.text.isEmpty
              ? 'Add Product'
              : 'Edit Product',
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveHelper.tabletCenter(
          child: Obx(() {
            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Image ──
                      Text(
                        'product_image'.tr,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: controller.pickImage,
                        child: Container(
                          width: double.infinity,
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade400),
                          ),
                          child: _buildImagePreview(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Name ──
                      _label('Product Name'),
                      TextField(
                        controller: controller.nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: _deco('e.g., Wheat Seeds 10kg'),
                      ),

                      const SizedBox(height: 16),

                      // ── Category ──
                      _label('Category'),
                      Obx(
                        () => DropdownButtonFormField<String>(
                          initialValue: controller.selectedCategory.value,
                          decoration: _deco(null),
                          items: ProductModel.categories.map((c) {
                            final label =
                                '${c[0].toUpperCase()}${c.substring(1)}';
                            return DropdownMenuItem(
                              value: c,
                              child: Text(label),
                            );
                          }).toList(),
                          onChanged: (v) {
                            if (v != null) {
                              controller.selectedCategory.value = v;
                            }
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Price ──
                      _label('Price (Rs.)'),
                      TextField(
                        controller: controller.priceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: _deco('e.g., 500'),
                      ),

                      const SizedBox(height: 16),

                      // ── Stock ──
                      _label('Stock Quantity'),
                      TextField(
                        controller: controller.stockCtrl,
                        keyboardType: TextInputType.number,
                        decoration: _deco('e.g., 100'),
                      ),

                      const SizedBox(height: 16),

                      // ── Description ──
                      _label('Description'),
                      TextField(
                        controller: controller.descCtrl,
                        maxLines: 3,
                        maxLength: 300,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: _deco('Describe the product...'),
                      ),

                      const SizedBox(height: 24),

                      // ── Save button ──
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: controller.isSaving.value
                              ? null
                              : controller.saveProduct,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'save_product'.tr,
                            style: TextStyle(fontSize: 17, color: Colors.white),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                // Uploading overlay
                if (controller.isSaving.value || controller.isUploading.value)
                  Container(
                    color: Colors.black26,
                    child: Center(
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(
                                color: AppColors.primaryGreen,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                controller.isUploading.value
                                    ? 'Uploading image...'
                                    : 'Saving product...',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (controller.selectedImage.value != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(controller.selectedImage.value!, fit: BoxFit.cover),
      );
    }
    if (controller.imageUrl.value.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(controller.imageUrl.value, fit: BoxFit.cover),
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey.shade500),
        const SizedBox(height: 8),
        Text('Tap to add image', style: TextStyle(color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }

  InputDecoration _deco(String? hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
