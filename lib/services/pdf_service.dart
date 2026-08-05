import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/pdf_file_model.dart';

class PdfService {
  static Future<String> createPdfFromImages(
    List<String> imagePaths, {
    String? fileName,
  }) async {
    final pdf = pw.Document();

    for (final imagePath in imagePaths) {
      final file = File(imagePath);
      if (!file.existsSync()) continue;

      final imageBytes = await file.readAsBytes();
      final image = pw.MemoryImage(imageBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(image, fit: pw.BoxFit.contain),
            );
          },
        ),
      );
    }

    final output = await _getOutputPath(fileName);
    final file = File(output);
    await file.writeAsBytes(await pdf.save());
    return output;
  }

  static Future<String> _getOutputPath(String? fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final pdfDir = Directory('${dir.path}/pdfs');
    if (!pdfDir.existsSync()) {
      pdfDir.createSync(recursive: true);
    }

    final name = fileName ?? 'PDF_${DateTime.now().millisecondsSinceEpoch}';
    return '${pdfDir.path}/${name}.pdf';
  }

  static Future<List<PdfFileModel>> getPdfFiles() async {
    final dir = await getApplicationDocumentsDirectory();
    final pdfDir = Directory('${dir.path}/pdfs');

    if (!pdfDir.existsSync()) return [];

    final files = pdfDir.listSync().whereType<File>().where(
      (f) => f.path.toLowerCase().endsWith('.pdf'),
    ).toList();

    files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

    return files.map((file) {
      final stat = file.statSync();
      return PdfFileModel(
        path: file.path,
        name: file.path.split('/').last,
        createdAt: stat.modified,
        size: stat.size,
      );
    }).toList();
  }

  static Future<void> deletePdf(String path) async {
    final file = File(path);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (status.isGranted) return true;

      final photos = await Permission.photos.request();
      return photos.isGranted;
    }
    return true;
  }
}
