import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import '../services/pdf_service.dart';
import '../services/storage_service.dart';
import '../services/unity_ads_service.dart';
import '../utils/constants.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool _isConverting = false;

  Future<void> _captureImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile == null) return;

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
      final path = await PdfService.createPdfFromImages(
        [pickedFile.path],
        fileName: 'Scan_${DateTime.now().millisecondsSinceEpoch}',
      );
      await StorageService.incrementConversionCount();

      if (!mounted) return;

      setState(() => _isConverting = false);
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt,
              size: 80,
              color: AppColors.primary,
            ),
            const SizedBox(height: 24),
            const Text(
              'الماسح الضوئي',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'التقط صورة وتحولها مباشرة إلى PDF',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grey, fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _isConverting ? null : _captureImage,
              icon: _isConverting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.camera),
              label: Text(_isConverting ? 'جاري التحويل...' : 'التقاط صورة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                minimumSize: const Size(double.infinity, 56),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
