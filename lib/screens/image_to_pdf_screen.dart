import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import '../services/pdf_service.dart';
import '../services/storage_service.dart';
import '../services/unity_ads_service.dart';
import '../utils/constants.dart';

class ImageToPdfScreen extends StatefulWidget {
  const ImageToPdfScreen({super.key});

  @override
  State<ImageToPdfScreen> createState() => _ImageToPdfScreenState();
}

class _ImageToPdfScreenState extends State<ImageToPdfScreen> {
  final List<String> _selectedImages = [];
  bool _isConverting = false;

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(pickedFiles.map((f) => f.path));
      });
    }
  }

  Future<void> _reorderImages(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    setState(() {
      final item = _selectedImages.removeAt(oldIndex);
      _selectedImages.insert(newIndex, item);
    });
  }

  Future<void> _removeImage(int index) async {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _convertToPdf() async {
    if (_selectedImages.isEmpty) return;

    final shouldShowAd = await StorageService.shouldShowAd();

    if (shouldShowAd) {
      final result = await _showAdDialog();
      if (result != true) return;

      bool adCompleted = false;
      await UnityAdsService.showAd(
        onComplete: () => adCompleted = true,
        onFailed: () => adCompleted = false,
      );

      int waitCount = 0;
      while (!adCompleted && waitCount < 120) {
        await Future.delayed(const Duration(milliseconds: 500));
        waitCount++;
      }

      if (!adCompleted) {
        if (!mounted) return;
        _showError('لم يكتمل الإعلان');
        return;
      }
    }

    if (!mounted) return;
    setState(() => _isConverting = true);

    try {
      final path = await PdfService.createPdfFromImages(_selectedImages);
      await StorageService.incrementConversionCount();

      if (!mounted) return;

      setState(() {
        _isConverting = false;
        _selectedImages.clear();
      });

      _showSuccessDialog(path);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isConverting = false);
      _showError('حدث خطأ أثناء التحويل: $e');
    }
  }

  Future<bool?> _showAdDialog() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('تحويل PDF'),
        content: const Text(AppStrings.watchAd),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.no),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text(AppStrings.yes, style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String path) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تم بنجاح!'),
        content: const Text('تم إنشاء ملف PDF بنجاح'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              OpenFile.open(path);
            },
            child: const Text('فتح'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Share.shareXFiles([XFile(path)]);
            },
            child: const Text('مشاركة'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: _pickImages,
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('اختيار صور'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _selectedImages.isEmpty
                ? const Center(
                    child: Text(
                      'لم يتم اختيار أي صور',
                      style: TextStyle(color: AppColors.grey, fontSize: 16),
                    ),
                  )
                : ReorderableListView.builder(
                    itemCount: _selectedImages.length,
                    onReorder: _reorderImages,
                    itemBuilder: (context, index) {
                      return Card(
                        key: ValueKey(_selectedImages[index]),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Image.file(
                            File(_selectedImages[index]),
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                          title: Text('صورة ${index + 1}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeImage(index),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_selectedImages.isNotEmpty)
            ElevatedButton.icon(
              onPressed: _isConverting ? null : _convertToPdf,
              icon: _isConverting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.picture_as_pdf),
              label: Text(_isConverting ? 'جاري التحويل...' : 'تحويل إلى PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: AppColors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
        ],
      ),
    );
  }
}
