class PdfFileModel {
  final String path;
  final String name;
  final DateTime createdAt;
  final int size;

  PdfFileModel({
    required this.path,
    required this.name,
    required this.createdAt,
    required this.size,
  });

  String get sizeFormatted {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
