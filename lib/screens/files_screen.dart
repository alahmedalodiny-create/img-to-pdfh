import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import '../models/pdf_file_model.dart';
import '../services/pdf_service.dart';
import '../utils/constants.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  List<PdfFileModel> _files = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() => _isLoading = true);
    final files = await PdfService.getPdfFiles();
    setState(() {
      _files = files;
      _isLoading = false;
    });
  }

  Future<void> _openFile(String path) async {
    await OpenFile.open(path);
  }

  Future<void> _shareFile(String path) async {
    await Share.shareXFiles([XFile(path)]);
  }

  Future<void> _deleteFile(PdfFileModel file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الملف'),
        content: Text('هل تريد حذف ${file.name}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await PdfService.deletePdf(file.path);
      _loadFiles();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_files.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: AppColors.grey),
            SizedBox(height: 16),
            Text(
              'لا توجد ملفات PDF',
              style: TextStyle(color: AppColors.grey, fontSize: 18),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFiles,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _files.length,
        itemBuilder: (context, index) {
          final file = _files[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Icon(Icons.picture_as_pdf, color: Colors.white),
              ),
              title: Text(
                file.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${file.sizeFormatted} • ${_formatDate(file.createdAt)}',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'open':
                      _openFile(file.path);
                      break;
                    case 'share':
                      _shareFile(file.path);
                      break;
                    case 'delete':
                      _deleteFile(file);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'open', child: Text('فتح')),
                  const PopupMenuItem(value: 'share', child: Text('مشاركة')),
                  const PopupMenuItem(value: 'delete', child: Text('حذف', style: TextStyle(color: Colors.red))),
                ],
              ),
              onTap: () => _openFile(file.path),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
